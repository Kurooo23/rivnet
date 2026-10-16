import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/tournament.dart';
import '../routes/app_routes.dart';

// isi tab home: filter + daftar turnamen aktif
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.tournaments,
    required this.onStart,
    required this.onFinish,
    this.onRefresh,
  });

  final List<Tournament> tournaments; // sudah difilter: belum selesai
  final ValueChanged<Tournament> onStart;
  final ValueChanged<Tournament> onFinish;
  final VoidCallback? onRefresh;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'Semua';

  List<Tournament> get _visible => widget.tournaments
      .where((t) => _filter == 'Semua' || t.status == _filter)
      .toList();

  @override
  Widget build(BuildContext context) {
    // MediaQuery: padding 5% lebar, kolom 1 (HP) / 2 (tablet) / 3 (lebar)
    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width * 0.05;
    final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
    final contentWidth = width - sidePadding * 2;
    // kotak ikon = 13% lebar kartu, dibatasi 40-56
    final iconBox = (contentWidth / columns * 0.13).clamp(40.0, 56.0);

    final visible = _visible;

    return Column(
      children: [
        // baris 1: filter
        Padding(
          padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _FilterChips(
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
          ),
        ),

        // baris 2: daftar (ambil sisa tinggi layar)
        Expanded(
          child: visible.isEmpty
              ? const _EmptyState()
              : ListView(
                  padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 80),
                  children: [
                    _CardGrid(
                      columns: columns,
                      children: [
                        for (final t in visible)
                          _TournamentCard(
                            tournament: t,
                            iconBox: iconBox,
                            onStart: t.status == 'Akan Datang'
                                ? () => widget.onStart(t)
                                : null,
                            onFinish: () => widget.onFinish(t),
                            onTap: () async {
                              await Get.toNamed(AppRoutes.detail, arguments: t);
                              widget.onRefresh?.call();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// chip turun ke baris berikut kalau tidak muat
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  static const _filters = ['Semua', 'Akan Datang', 'Berlangsung'];

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final f in _filters)
          ChoiceChip(
            label: Text(f),
            selected: selected == f,
            onSelected: (_) => onSelected(f),
          ),
      ],
    );
  }
}

// kolom sama lebar (1 : 1 : 1)
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) cells.add(const SizedBox(width: 12));
        final index = i + c;
        cells.add(
          Expanded(
            child: index < children.length ? children[index] : const SizedBox(),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cells,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Belum ada turnamen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Klik "Buat Turnamen" untuk memulai.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    required this.iconBox,
    required this.onStart,
    required this.onFinish,
    required this.onTap,
  });

  final Tournament tournament;
  final double iconBox;
  final VoidCallback? onStart;
  final VoidCallback onFinish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = tournament;
    final scheme = Theme.of(context).colorScheme;
    final date =
        '${t.date.day.toString().padLeft(2, '0')}/'
        '${t.date.month.toString().padLeft(2, '0')}/${t.date.year}';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // kolom 1: ikon (ukuran dari MediaQuery)
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_soccer_rounded,
                  color: scheme.primary,
                  size: iconBox * 0.5,
                ),
              ),
              const SizedBox(width: 12),
              // kolom 2: info (ambil sisa lebar)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.game} · $date',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(t.status),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              // kolom 3: tombol aksi (ukuran isi)
              if (onStart != null)
                IconButton(
                  tooltip: 'Mulai turnamen',
                  onPressed: onStart,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                ),
              IconButton(
                tooltip: 'Tandai selesai',
                onPressed: onFinish,
                icon: const Icon(Icons.check_circle_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
