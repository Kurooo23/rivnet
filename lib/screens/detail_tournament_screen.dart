import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../database/database_helper.dart';
import '../models/klasemen_item.dart';
import '../models/match.dart';
import '../models/tournament.dart';
import '../routes/app_routes.dart';
import '../widgets/bracket_view.dart';
import '../widgets/detail_header_card.dart';
import '../widgets/detail_tab_bar.dart';
import '../widgets/input_skor_dialog.dart';
import '../widgets/klasemen_view.dart';
import '../widgets/match_list_view.dart';
import '../widgets/page_layout.dart';

const _bgDark = Color(0xFF0F172A);
const _bgCard = Color(0xFF1E293B);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFF94A3B8);
const _textMuted = Color(0xFF64748B);
const _successColor = Color(0xFF22C55E);
const _warningColor = Color(0xFFF59E0B);
const _errorColor = Color(0xFFEF4444);

class _PesertaData {
  _PesertaData({required this.id, required this.nama, required this.urutan});
  final String id;
  final String nama;
  final int urutan;
}

class DetailTournamentScreen extends StatefulWidget {
  const DetailTournamentScreen({super.key, required this.tournament});

  final Tournament tournament;

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
          ),
      ];

      final pesertaMap = {for (final p in pesertaList) p.id: p.nama};

      var matches = await db.getMatches(_turnamen.id!);

      if (matches.isEmpty && pesertaList.length >= 2) {
        matches = await _generateAndSaveMatches(currentTournament, pesertaList);
      } else if (matches.isNotEmpty) {
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

  /// Meneruskan pemenang semifinal ke final dan yang kalah ke perebutan juara 3.
  Future<void> _propagateBracket(List<Pertandingan> matches) async {
    if (!_isKnockout) return;

    final db = DatabaseHelper.instance;
    final database = await db.database;
    final isTwoLeg = _turnamen.jumlahLeg == 2;

    final juara3Matches =
        matches.where((m) => roundName(m.babak) == 'Perebutan Juara 3').toList()
          ..sort((a, b) => a.leg.compareTo(b.leg));

    final semies = matches
        .where((m) => roundName(m.babak) == 'Semifinal')
        .toList();

    final List<List<Pertandingan>> semieTies = [];

    if (isTwoLeg) {
      final leg1s = semies.where((m) => m.leg == 1).toList();
      for (final l1 in leg1s) {
        final l2 = semies.firstWhereOrNull((m) => m.id == l1.nextId);
        if (l2 != null) {
          semieTies.add([l1, l2]);
        } else {
          semieTies.add([l1]);
        }
      }
    } else {
      for (final m in semies) {
        semieTies.add([m]);
      }
    }

    for (final legs in semieTies) {
      if (legs.every((leg) => leg.status == 'Selesai')) {
        final firstLeg = legs.first;
        final homeId = firstLeg.idPeserta1;
        final awayId = firstLeg.idPeserta2;

        if (homeId == null || awayId == null) continue;

        var homeScore = 0;
        var awayScore = 0;

        for (final leg in legs) {
          if (leg.idPeserta1 == homeId) {
            homeScore += leg.skor1;
            awayScore += leg.skor2;
          } else if (leg.idPeserta1 == awayId) {
            awayScore += leg.skor1;
            homeScore += leg.skor2;
          }
        }

        String? winnerId;
        String? loserId;

        if (homeScore > awayScore) {
          winnerId = homeId;
          loserId = awayId;
        } else if (awayScore > homeScore) {
          winnerId = awayId;
          loserId = homeId;
        } else {
          final penaltyLeg = legs
              .where((leg) => leg.penalti1 != null && leg.penalti2 != null)
              .lastOrNull;
          if (penaltyLeg != null) {
            final homeIsP1 = penaltyLeg.idPeserta1 == homeId;
            final homePenalty = homeIsP1
                ? penaltyLeg.penalti1!
                : penaltyLeg.penalti2!;
            final awayPenalty = homeIsP1
                ? penaltyLeg.penalti2!
                : penaltyLeg.penalti1!;

            if (homePenalty > awayPenalty) {
              winnerId = homeId;
              loserId = awayId;
            } else if (awayPenalty > homePenalty) {
              winnerId = awayId;
              loserId = homeId;
            }
          }
        }

        final targetNextId = legs.last.nextId ?? firstLeg.nextId;

        if (winnerId != null && targetNextId != null) {
          final nextIndex = matches.indexWhere((m) => m.id == targetNextId);
          if (nextIndex != -1) {
            final nextMatch = matches[nextIndex];
            if (nextMatch.idPeserta1 == null) {
              await database.update(
                'pertandingan',
                {'id_peserta_1': winnerId},
                where: 'id_pertandingan = ?',
                whereArgs: [nextMatch.id],
              );
            } else if (nextMatch.idPeserta2 == null &&
                nextMatch.idPeserta1 != winnerId) {
              await database.update(
                'pertandingan',
                {'id_peserta_2': winnerId},
                where: 'id_pertandingan = ?',
                whereArgs: [nextMatch.id],
              );
            }
          }
        }

        if (loserId != null && juara3Matches.isNotEmpty) {
          final j1 = juara3Matches.first;
          final j2 = juara3Matches.length > 1 ? juara3Matches[1] : null;

          if (j1.idPeserta1 == null) {
            await database.update(
              'pertandingan',
              {'id_peserta_1': loserId},
              where: 'id_pertandingan = ?',
              whereArgs: [j1.id],
            );
            if (j2 != null) {
              await database.update(
                'pertandingan',
                {'id_peserta_2': loserId},
                where: 'id_pertandingan = ?',
                whereArgs: [j2.id],
              );
            }
          } else if (j1.idPeserta2 == null && j1.idPeserta1 != loserId) {
            await database.update(
              'pertandingan',
              {'id_peserta_2': loserId},
              where: 'id_pertandingan = ?',
              whereArgs: [j1.id],
            );
            if (j2 != null) {
              await database.update(
                'pertandingan',
                {'id_peserta_1': loserId},
                where: 'id_pertandingan = ?',
                whereArgs: [j2.id],
              );
            }
          }
        }
      }
    }

    final otherRounds = matches.where(
      (m) =>
          roundName(m.babak) != 'Semifinal' &&
          roundName(m.babak) != 'Perebutan Juara 3' &&
          roundName(m.babak) != 'Final',
    );

    final otherTies = <String, List<Pertandingan>>{};
    if (isTwoLeg) {
      for (final m in otherRounds) {
        if (m.leg == 1) {
          final l2 = matches.firstWhereOrNull((other) => other.id == m.nextId);
          final key = l2?.nextId ?? m.id;
          otherTies.putIfAbsent(key, () => []).add(m);
          if (l2 != null) otherTies[key]!.add(l2);
        }
      }
    } else {
      for (final m in otherRounds) {
        otherTies[m.id] = [m];
      }
    }

    for (final entry in otherTies.entries) {
      final legs = entry.value;
      if (legs.every((leg) => leg.status == 'Selesai')) {
        final firstLeg = legs.first;
        final homeId = firstLeg.idPeserta1;
        final awayId = firstLeg.idPeserta2;

        if (homeId == null || awayId == null) continue;

        var homeScore = 0;
        var awayScore = 0;
        for (final leg in legs) {
          if (leg.idPeserta1 == homeId) {
            homeScore += leg.skor1;
            awayScore += leg.skor2;
          } else if (leg.idPeserta1 == awayId) {
            awayScore += leg.skor1;
            homeScore += leg.skor2;
          }
        }

        String? winnerId;
        if (homeScore > awayScore) {
          winnerId = homeId;
        } else if (awayScore > homeScore) {
          winnerId = awayId;
        } else {
          final penaltyLeg = legs
              .where((leg) => leg.penalti1 != null && leg.penalti2 != null)
              .lastOrNull;
          if (penaltyLeg != null) {
            final homeIsP1 = penaltyLeg.idPeserta1 == homeId;
            final homePenalty = homeIsP1
                ? penaltyLeg.penalti1!
                : penaltyLeg.penalti2!;
            final awayPenalty = homeIsP1
                ? penaltyLeg.penalti2!
                : penaltyLeg.penalti1!;

            if (homePenalty > awayPenalty) {
              winnerId = homeId;
            } else if (awayPenalty > homePenalty) {
              winnerId = awayId;
            }
          }
        }

        final targetNextId = legs.last.nextId ?? firstLeg.nextId;
        if (winnerId != null && targetNextId != null) {
          final nextIndex = matches.indexWhere((m) => m.id == targetNextId);
          if (nextIndex != -1) {
            final nextMatch = matches[nextIndex];
            if (nextMatch.idPeserta1 == null) {
              await database.update(
                'pertandingan',
                {'id_peserta_1': winnerId},
                where: 'id_pertandingan = ?',
                whereArgs: [nextMatch.id],
              );
            } else if (nextMatch.idPeserta2 == null &&
                nextMatch.idPeserta1 != winnerId) {
              await database.update(
                'pertandingan',
                {'id_peserta_2': winnerId},
                where: 'id_pertandingan = ?',
                whereArgs: [nextMatch.id],
              );
            }
          }
        }
      }
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

      final currentRoundMatchIds = <String>[];

      for (var i = 0; i < totalBracketSize / 2; i++) {
        final p1 = (i * 2 < peserta.length) ? peserta[i * 2].id : null;
        final p2 = (i * 2 + 1 < peserta.length) ? peserta[i * 2 + 1].id : null;

        if (isTwoLeg) {
          final m1Id = 'm_${t.id}_${matchCounter++}';
          final m2Id = 'm_${t.id}_${matchCounter++}';
          currentRoundMatchIds.add(m1Id);

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
          currentRoundMatchIds.add(mId);
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

      var prevRoundMatchIds = List<String>.from(currentRoundMatchIds);

      for (var r = 1; r < rounds; r++) {
        final rName = roundNames[r];
        final nextRoundMatchIds = <String>[];
        final numMatchesInRound = totalBracketSize >> (r + 1);

        for (var i = 0; i < numMatchesInRound; i++) {
          final mId = 'm_${t.id}_${matchCounter++}';
          nextRoundMatchIds.add(mId);

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

            if (i * 2 < prevRoundMatchIds.length) {
              _setNextId(matches, prevRoundMatchIds[i * 2], m1Id);
            }
            if (i * 2 + 1 < prevRoundMatchIds.length) {
              _setNextId(matches, prevRoundMatchIds[i * 2 + 1], m1Id);
            }
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

            if (i * 2 < prevRoundMatchIds.length) {
              _setNextId(matches, prevRoundMatchIds[i * 2], mId);
            }
            if (i * 2 + 1 < prevRoundMatchIds.length) {
              _setNextId(matches, prevRoundMatchIds[i * 2 + 1], mId);
            }
          }
        }
        prevRoundMatchIds = nextRoundMatchIds;
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

  void _setNextId(List<Pertandingan> matches, String matchId, String nextId) {
    for (var i = 0; i < matches.length; i++) {
      if (matches[i].id == matchId) {
        matches[i] = Pertandingan(
          id: matches[i].id,
          idTurnamen: matches[i].idTurnamen,
          idPeserta1: matches[i].idPeserta1,
          idPeserta2: matches[i].idPeserta2,
          babak: matches[i].babak,
          leg: matches[i].leg,
          skor1: matches[i].skor1,
          skor2: matches[i].skor2,
          penalti1: matches[i].penalti1,
          penalti2: matches[i].penalti2,
          status: matches[i].status,
          urutan: matches[i].urutan,
          nextId: nextId,
        );
        break;
      }
    }
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
      color: _errorColor,
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
      _showSnack('Turnamen berhasil dihapus', color: _successColor);
      Get.back(result: true);
    } catch (e) {
      if (mounted) _showSnack('Gagal menghapus: $e', color: _errorColor);
    }
  }

  Future<void> _akhiriTurnamen() async {
    final confirmed = await _showConfirmDialog(
      icon: Icons.lock_rounded,
      color: _warningColor,
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
        color: _successColor,
      );
      _loadTournamentData();
    } catch (e) {
      if (mounted) _showSnack('Gagal mengakhiri: $e', color: _errorColor);
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
        color: _errorColor,
      );
      return;
    }
    if (match.idPeserta1 == null || match.idPeserta2 == null) {
      _showSnack(
        'Peserta pertandingan ini belum ditentukan (menunggu babak sebelumnya).',
        color: _warningColor,
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
        backgroundColor: color ?? const Color(0xFF6366F1),
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
        backgroundColor: _bgDark,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(title: const Text('Detail Turnamen')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _errorColor,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: _textSecondary),
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
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        foregroundColor: _textPrimary,
        title: Text(
          tournament.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: _textPrimary),
            tooltip: 'Edit Turnamen',
            onPressed: _openEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: _errorColor),
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
    if (_pesertaList.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada peserta terdaftar',
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(side, 0, side, 20),
      children: [
        for (var i = 0; i < _pesertaList.length; i++)
          _PesertaTile(number: i + 1, nama: _pesertaList[i].nama),
      ],
    );
  }
}

class _PesertaTile extends StatelessWidget {
  const _PesertaTile({required this.number, required this.nama});

  final int number;
  final String nama;

  @override
  Widget build(BuildContext context) {
    const primaryGradient = LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bgCard,
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
              gradient: primaryGradient,
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
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.shield_outlined, size: 18, color: _textMuted),
        ],
      ),
    );
  }
}
