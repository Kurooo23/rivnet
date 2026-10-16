import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rivnet/models/tournament.dart';
import 'package:rivnet/widgets/kuota_section.dart';
import 'package:rivnet/widgets/page_layout.dart';
import 'package:rivnet/widgets/peserta_grid.dart';
import 'package:rivnet/widgets/section_card.dart';

const _game = 'Sepak Bola / Futsal';
const _singleElim = 'Single Elimination';

class _BracketFormat {
  final String name;
  final String desc;
  final IconData icon;

  const _BracketFormat(this.name, this.desc, this.icon);
}

const _formats = [
  _BracketFormat(
    _singleElim,
    'Sistem gugur tunggal (1x kalah langsung gugur, min. 2 peserta)',
    Icons.account_tree_rounded,
  ),
  _BracketFormat(
    'Round Robin',
    'Semua peserta bertemu satu sama lain (1 leg)',
    Icons.loop_rounded,
  ),
  _BracketFormat(
    'Liga',
    'Format kompetisi penuh (Home & Away / 2 leg)',
    Icons.format_list_numbered_rounded,
  ),
];

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _pesertaControllers = <TextEditingController>[];

  _BracketFormat _format = _formats.first;
  int _jumlahLeg = 1;
  int _kuota = 4;

  bool get _isElimination => _format.name == _singleElim;

  // single elimination harus kelipatan 2 biar bagannya pas
  List<int> get _kuotaOptions => _isElimination
      ? const [2, 4, 8, 16, 32, 64]
      : const [2, 3, 4, 5, 6, 8, 10, 12, 16];

  @override
  void initState() {
    super.initState();
    _updateParticipantFields(_kuota);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    for (final c in _pesertaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateParticipantFields(int count) {
    while (_pesertaControllers.length < count) {
      _pesertaControllers.add(
        TextEditingController(
          text: 'Peserta ${_pesertaControllers.length + 1}',
        ),
      );
    }
    while (_pesertaControllers.length > count) {
      _pesertaControllers.removeLast().dispose();
    }
  }

  void _onFormatChanged(_BracketFormat format) {
    setState(() {
      _format = format;
      if (_isElimination && !_kuotaOptions.contains(_kuota)) _kuota = 4;
      _updateParticipantFields(_kuota);
    });
  }

  void _changeKuota(int value) {
    if (value < 2) return;
    setState(() {
      _kuota = value;
      _updateParticipantFields(value);
    });
  }

  Future<void> _openCustomKuota() async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => KuotaDialog(initial: _kuota),
    );
    if (value != null) _changeKuota(value);
  }

  List<String> _participantNames() {
    final names = <String>[];
    for (var i = 0; i < _pesertaControllers.length; i++) {
      final name = _pesertaControllers[i].text.trim();
      names.add(name.isEmpty ? 'Peserta ${i + 1}' : name);
    }
    return names;
  }

  Widget _legChip(int leg, String label) {
    return Expanded(
      child: ChoiceChip(
        label: SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        selected: _jumlahLeg == leg,
        onSelected: (_) => setState(() {
          _jumlahLeg = leg;
        }),
      ),
    );
  }

  void _createTournament() {
    if (!_formKey.currentState!.validate()) return;
    final deskripsi = _deskripsiController.text.trim();

    Get.back(
      result: Tournament(
        name: _namaController.text.trim(),
        game: _game,
        date: DateTime.now(),
        deskripsi: deskripsi.isEmpty ? null : deskripsi,
        format: _format.name,
        jumlahLeg: _jumlahLeg,
        kuota: _kuota,
        peserta: _participantNames(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = PageLayout.of(context);
    final sectionGap = layout.isShort ? 14.0 : layout.gap;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Turnamen Baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.maxWidth),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.sidePadding,
                  vertical: sectionGap,
                ),
                children: [
                  PairRow(
                    isWide: layout.isWide,
                    gap: layout.gap,
                    left: SectionCard(
                      icon: Icons.info_outline_rounded,
                      title: 'Informasi Turnamen',
                      children: [
                        TextFormField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Turnamen',
                            hintText: 'cth: Turnamen Futsal Cup 2026',
                            prefixIcon: Icon(Icons.emoji_events_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama turnamen wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _deskripsiController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi (Opsional)',
                            hintText: 'Catatan atau aturan turnamen...',
                            prefixIcon: Icon(Icons.notes_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                    right: const SectionCard(
                      icon: Icons.sports_soccer_rounded,
                      title: 'Cabang Olahraga',
                      children: [
                        Chip(
                          avatar: Icon(Icons.sports_soccer_rounded, size: 18),
                          label: Text(_game),
                        ),
                        SizedBox(height: 10),
                        HintText(
                          'Skor gol. Sistem liga: menang 3 pts, seri 1 pt, kalah 0 pt.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),

                  PairRow(
                    isWide: layout.isWide,
                    gap: layout.gap,
                    left: SectionCard(
                      icon: Icons.hub_rounded,
                      title: 'Format Bagan Turnamen',
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in _formats)
                              ChoiceChip(
                                avatar: Icon(f.icon, size: 16),
                                label: Text(f.name),
                                selected: _format == f,
                                onSelected: (_) => _onFormatChanged(f),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        HintText(_format.desc),
                      ],
                    ),
                    right: SectionCard(
                      icon: Icons.repeat_rounded,
                      title: 'Sistem Pertemuan (Jumlah Leg)',
                      children: [
                        Row(
                          children: [
                            _legChip(1, '1x Tanding'),
                            const SizedBox(width: 8),
                            _legChip(2, 'Home & Away'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        HintText(
                          _jumlahLeg == 1
                              ? '1x Tanding: setiap pertemuan hanya 1 laga.'
                              : '2x Tanding: kandang & tandang (2 leg) untuk setiap pertemuan.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),

                  KuotaSection(
                    kuota: _kuota,
                    format: _format.name,
                    isElimination: _isElimination,
                    options: _kuotaOptions,
                    onChanged: _changeKuota,
                    onCustom: _openCustomKuota,
                  ),
                  SizedBox(height: sectionGap + 12),
                  PesertaGrid(
                    columns: layout.isWide ? 2 : 1,
                    gap: layout.gap,
                    controllers: _pesertaControllers,
                  ),
                  SizedBox(height: sectionGap + 8),

                  FilledButton(
                    onPressed: _createTournament,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Simpan & Generate Pertandingan'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
