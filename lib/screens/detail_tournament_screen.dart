import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rivnet/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:rivnet/database/database_helper.dart';
import 'package:rivnet/models/klasemen_item.dart';
import 'package:rivnet/models/match.dart';
import 'package:rivnet/models/tournament.dart';
import 'package:rivnet/routes/app_routes.dart';
import 'package:rivnet/widgets/bracket_view.dart';
import 'package:rivnet/widgets/detail_header_card.dart';
import 'package:rivnet/widgets/detail_tab_bar.dart';
import 'package:rivnet/widgets/input_skor_dialog.dart';
import 'package:rivnet/widgets/klasemen_view.dart';
import 'package:rivnet/widgets/match_list_view.dart';
import 'package:rivnet/widgets/page_layout.dart';

class _PesertaData {
  final String id;
  final String nama;
  final int urutan;
  final bool isWo;

  _PesertaData({
    required this.id,
    required this.nama,
    required this.urutan,
    this.isWo = false,
  });
}

class DetailTournamentScreen extends StatefulWidget {
  final Tournament tournament;

  const DetailTournamentScreen({super.key, required this.tournament});

  @override
  State<DetailTournamentScreen> createState() => _DetailTournamentScreenState();
}

class _DetailTournamentScreenState extends State<DetailTournamentScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);
  late Tournament _turnamen = widget.tournament;

  List<Pertandingan> _pertandinganList = [];
  List<_PesertaData> _pesertaList = [];
  Map<String, String> _pesertaMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isKnockout =>
      _turnamen.format == 'Single Elimination' ||
      _turnamen.format == 'Double Elimination';

  @override
  void initState() {
    super.initState();
    _loadTournamentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournamentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = DatabaseHelper.instance;
    try {
      final savedTournaments = await db.getTournaments();
      final currentTournament = savedTournaments.firstWhere(
        (tournament) => tournament.id == _turnamen.id,
        orElse: () => _turnamen,
      );

      final participantRows = await db.getPeserta(_turnamen.id!);
      final pesertaList = [
        for (final row in participantRows)
          _PesertaData(
            id: row['id_peserta'] as String,
            nama: row['nama_peserta'] as String,
            urutan: row['urutan'] as int,
            isWo: row['is_wo'] == 1,
          ),
      ];

      final pesertaMap = {
        for (final p in pesertaList) p.id: p.isWo ? '${p.nama} (WO)' : p.nama,
      };
      final woIds = {
        for (final p in pesertaList)
          if (p.isWo) p.id,
      };

      var matches = await db.getMatches(_turnamen.id!);

      if (matches.isEmpty && pesertaList.length >= 2) {
        matches = await _generateAndSaveMatches(currentTournament, pesertaList);
      }

      // dua kali: WO bisa mengubah pemenang, lalu peserta WO bisa
      // terdorong ke laga perebutan juara 3 yang juga harus di-WO
      for (var i = 0; i < 2; i++) {
        await _applyWalkover(matches, woIds);
        await _propagateBracket(matches);
      }

      if (!mounted) return;
      setState(() {
        _turnamen = currentTournament;
        _pesertaList = pesertaList;
        _pesertaMap = pesertaMap;
        _pertandinganList = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Peserta yang dihapus kalah WO 3-0 di semua laganya.
  Future<void> _applyWalkover(
    List<Pertandingan> matches,
    Set<String> woIds,
  ) async {
    if (woIds.isEmpty) return;
    final db = DatabaseHelper.instance;

    for (final match in matches) {
      if (match.idPeserta1 == null || match.idPeserta2 == null) continue;
      final p1Wo = woIds.contains(match.idPeserta1);
      final p2Wo = woIds.contains(match.idPeserta2);
      if (p1Wo == p2Wo) continue;

      final skor1 = p1Wo ? 0 : 3;
      final skor2 = p1Wo ? 3 : 0;
      final alreadyWo =
          match.status == 'Selesai' &&
          match.skor1 == skor1 &&
          match.skor2 == skor2 &&
          match.penalti1 == null &&
          match.penalti2 == null;
      if (alreadyWo) continue;

      await db.saveScore(match.id, skor1: skor1, skor2: skor2);
      match.skor1 = skor1;
      match.skor2 = skor2;
      match.penalti1 = null;
      match.penalti2 = null;
      match.status = 'Selesai';
    }
  }

  // peserta hanya boleh ditambah kalau belum ada laga yang dimainkan
  bool get _canAddPeserta =>
      !_turnamen.isFinished &&
      _pertandinganList.every((m) => m.status != 'Selesai');

  Future<String?> _showNamaDialog(String title, String initial) async {
    var nama = initial;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Peserta'),
          onChanged: (value) {
            nama = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nama.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isEmpty) {
      _showSnack('Nama peserta tidak boleh kosong', color: AppColors.error);
      return null;
    }
    return result;
  }

  Future<void> _tambahPeserta() async {
    final aktif = _pesertaList.where((p) => !p.isWo).length;
    final nama = await _showNamaDialog(
      'Tambah Peserta',
      'Peserta ${aktif + 1}',
    );
    if (nama == null) return;

    await DatabaseHelper.instance.addPeserta(_turnamen.id!, nama);
    if (!mounted) return;
    _showSnack(
      '$nama ditambahkan, jadwal dibuat ulang',
      color: AppColors.success,
    );
    _loadTournamentData();
  }

  Future<void> _editPeserta(_PesertaData peserta) async {
    final result = await _showNamaDialog('Edit Nama Peserta', peserta.nama);
    if (result == null || result == peserta.nama) return;

    await DatabaseHelper.instance.renamePeserta(peserta.id, result);
    if (!mounted) return;
    _showSnack('Nama peserta diubah', color: AppColors.success);
    _loadTournamentData();
  }

  Future<void> _hapusPeserta(_PesertaData peserta) async {
    final confirmed = await _showConfirmDialog(
      icon: Icons.person_remove_rounded,
      color: AppColors.error,
      title: 'Hapus Peserta',
      message:
          'Hapus "${peserta.nama}" dari turnamen?\n\n'
          'Semua laga peserta ini akan dianggap kalah WO 3-0.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed) return;

    await DatabaseHelper.instance.setPesertaWo(peserta.id);
    if (!mounted) return;
    _showSnack('${peserta.nama} dihapus (WO)', color: AppColors.success);
    _loadTournamentData();
  }

  // Mengisi peserta babak berikutnya dari hasil babak sebelumnya.
  // Laga ke-i masuk ke laga ke-(i ~/ 2) babak berikutnya:
  // i genap jadi tuan rumah, i ganjil jadi tamu.
  Future<void> _propagateBracket(List<Pertandingan> matches) async {
    if (!_isKnockout) return;

    final legCount = _turnamen.jumlahLeg;
    final sorted = [...matches]..sort((a, b) => a.urutan.compareTo(b.urutan));

    final byRound = <String, List<Pertandingan>>{};
    for (final match in sorted) {
      byRound.putIfAbsent(roundName(match.babak), () => []).add(match);
    }
    final juara3 = byRound.remove('Perebutan Juara 3');

    final rounds = [
      for (final list in byRound.values) _splitTies(list, legCount),
    ];

    // menandai laga yang tidak punya peserta sama sekali (bagan tidak penuh)
    var prevEmpty = <bool>[];

    for (var r = 0; r < rounds.length; r++) {
      final ties = rounds[r];
      final isSemifinal = r == rounds.length - 2;
      final emptyNow = <bool>[];

      for (var i = 0; i < ties.length; i++) {
        final legs = ties[i];
        final home = legs.first.idPeserta1;
        final away = legs.first.idPeserta2;

        final homeEmpty = r == 0 ? home == null : prevEmpty[i * 2];
        final awayEmpty = r == 0 ? away == null : prevEmpty[i * 2 + 1];
        emptyNow.add(homeEmpty && awayEmpty);

        String? winner;
        String? loser;
        if (home != null && awayEmpty) {
          winner = home;
        } else if (away != null && homeEmpty) {
          winner = away;
        } else if (home != null && away != null) {
          winner = _tieWinner(legs);
          if (winner != null) loser = winner == home ? away : home;
        }

        if (winner != null && r + 1 < rounds.length) {
          await _setSlot(rounds[r + 1][i ~/ 2], i.isEven, winner);
        }
        if (loser != null && isSemifinal && juara3 != null) {
          await _setSlot(_splitTies(juara3, legCount).first, i.isEven, loser);
        }
      }
      prevEmpty = emptyNow;
    }
  }

  List<List<Pertandingan>> _splitTies(List<Pertandingan> list, int legCount) {
    return [
      for (var i = 0; i < list.length; i += legCount)
        list.skip(i).take(legCount).toList(),
    ];
  }

  // Pemenang satu pertemuan (agregat semua leg, lalu adu penalti kalau imbang).
  String? _tieWinner(List<Pertandingan> legs) {
    if (legs.any((leg) => leg.status != 'Selesai')) return null;

    final home = legs.first.idPeserta1;
    final away = legs.first.idPeserta2;
    var homeScore = 0;
    var awayScore = 0;

    for (final leg in legs) {
      if (leg.idPeserta1 == home) {
        homeScore += leg.skor1;
        awayScore += leg.skor2;
      } else {
        homeScore += leg.skor2;
        awayScore += leg.skor1;
      }
    }

    if (homeScore > awayScore) return home;
    if (awayScore > homeScore) return away;

    final penaltyLeg = legs
        .where((leg) => leg.penalti1 != null && leg.penalti2 != null)
        .lastOrNull;
    if (penaltyLeg == null) return null;

    final homeIsP1 = penaltyLeg.idPeserta1 == home;
    final homePenalty = homeIsP1 ? penaltyLeg.penalti1! : penaltyLeg.penalti2!;
    final awayPenalty = homeIsP1 ? penaltyLeg.penalti2! : penaltyLeg.penalti1!;

    if (homePenalty > awayPenalty) return home;
    if (awayPenalty > homePenalty) return away;
    return null;
  }

  // Leg 1: tuan rumah di slot 1. Leg 2: kebalikannya.
  Future<void> _setSlot(
    List<Pertandingan> legs,
    bool isHome,
    String pesertaId,
  ) async {
    final db = DatabaseHelper.instance;

    for (final leg in legs) {
      final useSlot1 = leg.leg == 1 ? isHome : !isHome;
      final current = useSlot1 ? leg.idPeserta1 : leg.idPeserta2;
      if (current == pesertaId) continue;

      if (useSlot1) {
        leg.idPeserta1 = pesertaId;
      } else {
        leg.idPeserta2 = pesertaId;
      }
      await db.setPeserta(leg.id, useSlot1 ? 1 : 2, pesertaId);
    }
  }

  Future<List<Pertandingan>> _generateAndSaveMatches(
    Tournament t,
    List<_PesertaData> peserta,
  ) async {
    final db = DatabaseHelper.instance;
    final matches = <Pertandingan>[];
    final isTwoLeg = t.jumlahLeg == 2;
    var matchCounter = 1;

    if (_isKnockout) {
      int n = peserta.length;
      int rounds = max(1, (log(n) / log(2)).ceil());
      int totalBracketSize = 1 << rounds;

      final roundNames = _getRoundNames(rounds);
      final babak1Name = roundNames[0];

      for (var i = 0; i < totalBracketSize / 2; i++) {
        final p1 = (i * 2 < peserta.length) ? peserta[i * 2].id : null;
        final p2 = (i * 2 + 1 < peserta.length) ? peserta[i * 2 + 1].id : null;

        if (isTwoLeg) {
          final m1Id = 'm_${t.id}_${matchCounter++}';
          final m2Id = 'm_${t.id}_${matchCounter++}';

          matches.add(
            Pertandingan(
              id: m1Id,
              idTurnamen: t.id!,
              idPeserta1: p1,
              idPeserta2: p2,
              babak: 'Leg 1 - $babak1Name',
              leg: 1,
              urutan: matches.length + 1,
              nextId: m2Id,
            ),
          );
          matches.add(
            Pertandingan(
              id: m2Id,
              idTurnamen: t.id!,
              idPeserta1: p2,
              idPeserta2: p1,
              babak: 'Leg 2 - $babak1Name',
              leg: 2,
              urutan: matches.length + 1,
            ),
          );
        } else {
          final mId = 'm_${t.id}_${matchCounter++}';
          matches.add(
            Pertandingan(
              id: mId,
              idTurnamen: t.id!,
              idPeserta1: p1,
              idPeserta2: p2,
              babak: babak1Name,
              leg: 1,
              urutan: matches.length + 1,
            ),
          );
        }
      }

      for (var r = 1; r < rounds; r++) {
        final rName = roundNames[r];
        final numMatchesInRound = totalBracketSize >> (r + 1);

        for (var i = 0; i < numMatchesInRound; i++) {
          final mId = 'm_${t.id}_${matchCounter++}';

          if (isTwoLeg) {
            final m1Id = mId;
            final m2Id = 'm_${t.id}_${matchCounter++}';

            matches.add(
              Pertandingan(
                id: m1Id,
                idTurnamen: t.id!,
                babak: 'Leg 1 - $rName',
                leg: 1,
                urutan: matches.length + 1,
                nextId: m2Id,
              ),
            );
            matches.add(
              Pertandingan(
                id: m2Id,
                idTurnamen: t.id!,
                babak: 'Leg 2 - $rName',
                leg: 2,
                urutan: matches.length + 1,
              ),
            );
          } else {
            matches.add(
              Pertandingan(
                id: mId,
                idTurnamen: t.id!,
                babak: rName,
                leg: 1,
                urutan: matches.length + 1,
              ),
            );
          }
        }
      }

      if (peserta.length >= 4) {
        if (isTwoLeg) {
          final m1Id = 'm_${t.id}_juara3_leg1';
          final m2Id = 'm_${t.id}_juara3_leg2';

          matches.add(
            Pertandingan(
              id: m1Id,
              idTurnamen: t.id!,
              babak: 'Leg 1 - Perebutan Juara 3',
              leg: 1,
              urutan: matches.length + 1,
              nextId: m2Id,
            ),
          );
          matches.add(
            Pertandingan(
              id: m2Id,
              idTurnamen: t.id!,
              babak: 'Leg 2 - Perebutan Juara 3',
              leg: 2,
              urutan: matches.length + 1,
            ),
          );
        } else {
          final p3Id = 'm_${t.id}_juara3';
          matches.add(
            Pertandingan(
              id: p3Id,
              idTurnamen: t.id!,
              babak: 'Perebutan Juara 3',
              leg: 1,
              urutan: matches.length + 1,
            ),
          );
        }
      }
    } else {
      final pList = List<_PesertaData>.from(peserta);
      if (pList.length % 2 != 0) {
        pList.add(_PesertaData(id: 'bye', nama: 'BYE', urutan: 999));
      }

      final totalRounds = pList.length - 1;
      final half = pList.length ~/ 2;

      for (var r = 0; r < totalRounds; r++) {
        final rName = 'Pekan ${r + 1}';
        for (var i = 0; i < half; i++) {
          final home = pList[i];
          final away = pList[pList.length - 1 - i];

          if (home.id == 'bye' || away.id == 'bye') continue;

          matches.add(
            Pertandingan(
              id: 'm_${t.id}_${matchCounter++}',
              idTurnamen: t.id!,
              idPeserta1: home.id,
              idPeserta2: away.id,
              babak: isTwoLeg ? 'Leg 1 - $rName' : rName,
              leg: 1,
              urutan: matches.length + 1,
            ),
          );
        }
        pList.insert(1, pList.removeLast());
      }

      if (isTwoLeg) {
        final leg1Matches = List<Pertandingan>.from(matches);
        for (final m in leg1Matches) {
          final pekanNum = m.babak.replaceFirst('Leg 1 - Pekan ', '');
          matches.add(
            Pertandingan(
              id: 'm_${t.id}_${matchCounter++}',
              idTurnamen: t.id!,
              idPeserta1: m.idPeserta2,
              idPeserta2: m.idPeserta1,
              babak: 'Leg 2 - Pekan $pekanNum',
              leg: 2,
              urutan: matches.length + 1,
            ),
          );
        }
      }
    }

    if (matches.isNotEmpty) {
      await db.insertMatches(matches);
    }
    return matches;
  }

  List<String> _getRoundNames(int totalRounds) {
    if (totalRounds == 1) return ['Final'];
    if (totalRounds == 2) return ['Semifinal', 'Final'];
    if (totalRounds == 3) return ['Perempat Final', 'Semifinal', 'Final'];
    if (totalRounds == 4) {
      return ['Babak 16 Besar', 'Perempat Final', 'Semifinal', 'Final'];
    }
    return [
      for (var i = totalRounds; i > 3; i--) 'Babak 1 dari ${1 << i}',
      'Perempat Final',
      'Semifinal',
      'Final',
    ];
  }

  List<KlasemenItem> _calculateKlasemen() {
    final stats = {
      for (final p in _pesertaList)
        p.id: KlasemenItem(idPeserta: p.id, namaPeserta: p.nama),
    };

    for (final m in _pertandinganList) {
      if (m.status != 'Selesai') continue;
      final p1 = stats[m.idPeserta1];
      final p2 = stats[m.idPeserta2];
      if (p1 == null || p2 == null) continue;

      p1
        ..main += 1
        ..gm += m.skor1
        ..gk += m.skor2;
      p2
        ..main += 1
        ..gm += m.skor2
        ..gk += m.skor1;

      if (m.skor1 > m.skor2) {
        p1.menang++;
        p2.kalah++;
      } else if (m.skor2 > m.skor1) {
        p2.menang++;
        p1.kalah++;
      } else {
        p1.seri++;
        p2.seri++;
      }
    }

    final woIds = {
      for (final p in _pesertaList)
        if (p.isWo) p.id,
    };
    stats.removeWhere((id, _) => woIds.contains(id));

    return stats.values.toList()..sort((a, b) {
      if (b.poin != a.poin) return b.poin.compareTo(a.poin);
      if (b.sg != a.sg) return b.sg.compareTo(a.sg);
      if (b.gm != a.gm) return b.gm.compareTo(a.gm);
      if (b.menang != a.menang) return b.menang.compareTo(a.menang);
      return a.namaPeserta.compareTo(b.namaPeserta);
    });
  }

  Map<String, List<Pertandingan>> _groupedMatches() {
    final grouped = <String, List<Pertandingan>>{};
    for (final match in _pertandinganList) {
      final round = _isKnockout ? roundName(match.babak) : match.babak;
      grouped.putIfAbsent(round, () => []).add(match);
    }
    if (!_isKnockout) return grouped;

    final rounds = grouped.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Final' && b.key == 'Perebutan Juara 3') return 1;
        if (a.key == 'Perebutan Juara 3' && b.key == 'Final') return -1;
        return a.value.first.urutan.compareTo(b.value.first.urutan);
      });
    return Map.fromEntries(rounds);
  }

  Future<void> _deleteTurnamen() async {
    final confirmed = await _showConfirmDialog(
      icon: Icons.warning_amber_rounded,
      color: AppColors.error,
      title: 'Hapus Turnamen',
      message:
          'Apakah kamu yakin ingin menghapus turnamen "${_turnamen.name}"? '
          'Semua data peserta dan jadwal pertandingan akan dihapus secara permanen.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed) return;

    try {
      await DatabaseHelper.instance.deleteTournament(_turnamen.id!);
      if (!mounted) return;
      _showSnack('Turnamen berhasil dihapus', color: AppColors.success);
      Get.back(result: true);
    } catch (e) {
      if (mounted) _showSnack('Gagal menghapus: $e', color: AppColors.error);
    }
  }

  Future<void> _akhiriTurnamen() async {
    final confirmed = await _showConfirmDialog(
      icon: Icons.lock_rounded,
      color: AppColors.warning,
      title: 'Akhiri Turnamen?',
      message: 'Setelah turnamen diakhiri, semua skor akan dikunci.\n\nApakah kamu yakin?',
      confirmLabel: 'Ya, Akhiri Turnamen',
      confirmTextColor: Colors.black,
    );
    if (!confirmed) return;

    try {
      await DatabaseHelper.instance.updateStatus(_turnamen.id!, 'Selesai');
      await DatabaseHelper.instance.markFinished(_turnamen.id!);
      if (!mounted) return;
      _showSnack(
        'Turnamen telah diakhiri! Skor dikunci.',
        color: AppColors.success,
      );
      _loadTournamentData();
    } catch (e) {
      if (mounted) _showSnack('Gagal mengakhiri: $e', color: AppColors.error);
    }
  }

  Future<void> _openEditScreen() async {
    final result = await Get.toNamed(AppRoutes.edit, arguments: _turnamen);
    if (result == true) {
      _loadTournamentData();
    }
  }

  void _openInputSkor(Pertandingan match) {
    if (_turnamen.isFinished) {
      _showSnack(
        'Turnamen telah diakhiri. Skor tidak dapat diedit lagi.',
        color: AppColors.error,
      );
      return;
    }
    final isWoMatch = _pesertaList.any(
      (p) => p.isWo && (p.id == match.idPeserta1 || p.id == match.idPeserta2),
    );
    if (isWoMatch) {
      _showSnack(
        'Laga ini sudah WO, skor tidak bisa diubah.',
        color: AppColors.warning,
      );
      return;
    }
    if (match.idPeserta1 == null || match.idPeserta2 == null) {
      _showSnack(
        'Peserta pertandingan ini belum ditentukan (menunggu babak sebelumnya).',
        color: AppColors.warning,
      );
      return;
    }

    Pertandingan? previousLeg;
    if (_turnamen.jumlahLeg == 2 && match.babak.startsWith('Leg 2 - ')) {
      final round = roundName(match.babak);
      previousLeg = _pertandinganList
          .where(
            (leg) =>
                leg.babak == 'Leg 1 - $round' &&
                leg.idPeserta1 == match.idPeserta2 &&
                leg.idPeserta2 == match.idPeserta1,
          )
          .firstOrNull;
    }

    showDialog(
      context: context,
      builder: (_) => InputSkorDialog(
        match: match,
        pesertaMap: _pesertaMap,
        isKnockout: _isKnockout,
        isTwoLeg: _turnamen.jumlahLeg == 2,
        previousLegScore1: previousLeg?.skor2,
        previousLegScore2: previousLeg?.skor1,
        onSaved: _saveScoreAndPropagate,
      ),
    );
  }

  Future<void> _saveScoreAndPropagate(
    Pertandingan match,
    int skor1,
    int skor2,
    int? penalti1,
    int? penalti2,
  ) async {
    final db = DatabaseHelper.instance;
    await db.saveScore(
      match.id,
      skor1: skor1,
      skor2: skor2,
      penalti1: penalti1,
      penalti2: penalti2,
    );

    if (_turnamen.status == 'Akan Datang') {
      await db.updateStatus(_turnamen.id!, 'Berlangsung');
    }

    await _loadTournamentData();
  }

  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppColors.primary,
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmTextColor = Colors.white,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, color: color, size: 36),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: confirmTextColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Detail Turnamen')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTournamentData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final layout = PageLayout.of(context);
    final sidePadding = layout.sidePadding;
    final listColumns = layout.width >= 720 ? 2 : 1;
    final tournament = _turnamen;

    final selesaiCount = _pertandinganList
        .where((m) => m.status == 'Selesai')
        .length;
    final totalCount = _pertandinganList.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          tournament.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textPrimary),
            tooltip: 'Edit Turnamen',
            onPressed: _openEditScreen,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            tooltip: 'Hapus Turnamen',
            onPressed: _deleteTurnamen,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 12),
              child: DetailHeaderCard(
                turnamen: tournament,
                selesaiCount: selesaiCount,
                totalCount: totalCount,
                onAkhiri: _akhiriTurnamen,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: DetailTabBar(
                controller: _tabController,
                isKnockout: _isKnockout,
                matchCount: totalCount,
                pesertaCount: _pesertaList.length,
                showIcons: layout.width >= 380,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  if (_isKnockout)
                    BracketView(
                      matches: _pertandinganList,
                      pesertaMap: _pesertaMap,
                      legCount: tournament.jumlahLeg,
                      columnWidth: (layout.width * 0.62).clamp(200.0, 280.0),
                      connectorWidth: (layout.width * 0.07).clamp(20.0, 40.0),
                      sidePadding: sidePadding,
                      onTapMatch: _openInputSkor,
                    )
                  else
                    KlasemenView(
                      klasemen: _calculateKlasemen(),
                      sidePadding: sidePadding,
                    ),
                  MatchListView(
                    grouped: _groupedMatches(),
                    pesertaMap: _pesertaMap,
                    isLocked: tournament.isFinished,
                    columns: listColumns,
                    gap: layout.gap,
                    sidePadding: sidePadding,
                    onTapMatch: _openInputSkor,
                  ),
                  _pesertaView(sidePadding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pesertaView(double side) {
    final aktif = _pesertaList.where((p) => !p.isWo).toList();
    final canEdit = !_turnamen.isFinished;

    if (aktif.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada peserta terdaftar',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(side, 0, side, 20),
      children: [
        if (_canAddPeserta)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: _tambahPeserta,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Tambah Peserta'),
            ),
          )
        else if (!_turnamen.isFinished)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Peserta tidak bisa ditambah karena sudah ada laga yang dimainkan.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        for (var i = 0; i < aktif.length; i++)
          _PesertaTile(
            number: i + 1,
            nama: aktif[i].nama,
            onEdit: canEdit ? () => _editPeserta(aktif[i]) : null,
            onDelete: canEdit ? () => _hapusPeserta(aktif[i]) : null,
          ),
      ],
    );
  }
}

class _PesertaTile extends StatelessWidget {
  final int number;
  final String nama;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PesertaTile({
    required this.number,
    required this.nama,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onEdit == null)
            const Icon(
              Icons.shield_outlined,
              size: 18,
              color: AppColors.textMuted,
            )
          else ...[
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit nama',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Hapus peserta',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
