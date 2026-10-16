import 'package:flutter/material.dart';

import '../models/tournament.dart';

class TournamentCardGrid extends StatelessWidget {
  const TournamentCardGrid({
    super.key,
    required this.tournaments,
    required this.padding,
    required this.itemBuilder,
  });

  final List<Tournament> tournaments;
  final EdgeInsets padding;
  final Widget Function(
    BuildContext context,
    Tournament tournament,
    double iconSize,
  )
  itemBuilder;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columnCount = screenWidth >= 900
        ? 3
        : screenWidth >= 600
        ? 2
        : 1;
    final availableWidth = screenWidth - padding.left - padding.right;
    final iconSize = (availableWidth / columnCount * 0.13).clamp(40.0, 56.0);

    final rows = <Widget>[];
    for (var start = 0; start < tournaments.length; start += columnCount) {
      final rowChildren = <Widget>[];

      for (var column = 0; column < columnCount; column++) {
        if (column > 0) rowChildren.add(const SizedBox(width: 12));

        final itemIndex = start + column;
        rowChildren.add(
          Expanded(
            child: itemIndex < tournaments.length
                ? itemBuilder(context, tournaments[itemIndex], iconSize)
                : const SizedBox.shrink(),
          ),
        );
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class TournamentSummaryCard extends StatelessWidget {
  const TournamentSummaryCard({
    super.key,
    required this.tournament,
    required this.iconSize,
    required this.onTap,
    this.onStart,
    this.onFinish,
    this.isFinished = false,
  });

  final Tournament tournament;
  final double iconSize;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onFinish;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFinished
                      ? Icons.emoji_events_rounded
                      : Icons.sports_soccer_rounded,
                  color: colors.primary,
                  size: iconSize * 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TournamentDetails(
                  tournament: tournament,
                  isFinished: isFinished,
                ),
              ),
              if (isFinished)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Chip(
                    label: Text('Selesai'),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else ...[
                if (onStart != null)
                  IconButton(
                    tooltip: 'Mulai turnamen',
                    onPressed: onStart,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                  ),
                if (onFinish != null)
                  IconButton(
                    tooltip: 'Tandai selesai',
                    onPressed: onFinish,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentDetails extends StatelessWidget {
  const _TournamentDetails({
    required this.tournament,
    required this.isFinished,
  });

  final Tournament tournament;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    final date = tournament.date;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tournament.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '${tournament.game} · $formattedDate',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (!isFinished) ...[
          const SizedBox(height: 6),
          Chip(
            label: Text(tournament.status),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }
}

class TournamentEmptyState extends StatelessWidget {
  const TournamentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
