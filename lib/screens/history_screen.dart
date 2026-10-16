import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/tournament.dart';
import '../routes/app_routes.dart';

// halaman riwayat, cuma menampilkan turnamen yang sudah selesai
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.tournaments, this.onRefresh});

  final List<Tournament> tournaments;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    // MediaQuery: padding 5% lebar, kolom 1 (HP) / 2 (tablet) / 3 (lebar)
    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width * 0.05;
    final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
    final contentWidth = width - sidePadding * 2;
    // kotak ikon = 13% lebar kartu, dibatasi 40-56
    final iconBox = (contentWidth / columns * 0.13).clamp(40.0, 56.0);

    if (tournaments.isEmpty) return const _EmptyState();

    return ListView(
      padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 24),
      children: [
        _CardGrid(
          columns: columns,
          children: [
            for (final t in tournaments)
              _HistoryCard(
                tournament: t,
                iconBox: iconBox,
                onTap: () async {
                  await Get.toNamed(AppRoutes.detail, arguments: t);
                  onRefresh?.call();
                },
              ),
          ],
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
            const Icon(Icons.history_toggle_off_rounded, size: 56),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Turnamen yang selesai akan muncul di sini.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.tournament,
    required this.iconBox,
    required this.onTap,
  });

  final Tournament tournament;
  final double iconBox;
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
                  Icons.emoji_events_rounded,
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // kolom 3: status (ukuran isi)
              const Chip(
                label: Text('Selesai'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
