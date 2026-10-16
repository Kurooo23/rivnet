import 'package:flutter/material.dart';
import 'package:rivnet/models/match.dart';
import 'package:rivnet/widgets/bracket_view.dart';

class MatchListView extends StatelessWidget {
  final Map<String, List<Pertandingan>> grouped;
  final Map<String, String> pesertaMap;
  final bool isLocked;
  final int columns;
  final double gap;
  final double sidePadding;
  final ValueChanged<Pertandingan> onTapMatch;

  const MatchListView({
    super.key,
    required this.grouped,
    required this.pesertaMap,
    required this.isLocked,
    required this.columns,
    required this.gap,
    required this.sidePadding,
    required this.onTapMatch,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Colors.white;
    const textSecondary = Color(0xFF94A3B8);
    const textMuted = Color(0xFF64748B);
    const warningColor = Color(0xFFF59E0B);

    if (grouped.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada pertandingan',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    final rounds = grouped.entries.toList();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 20),
      itemCount: rounds.length,
      itemBuilder: (context, index) {
        final round = rounds[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      size: 16,
                      color: warningColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      round.key,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${round.value.length} Laga',
                    style: const TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            for (final match in round.value)
              MatchCard(
                match: match,
                pesertaMap: pesertaMap,
                isLocked: isLocked,
                onTap: () => onTapMatch(match),
              ),
          ],
        );
      },
    );
  }
}

class MatchCard extends StatelessWidget {
  final Pertandingan match;
  final Map<String, String> pesertaMap;
  final bool isLocked;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.pesertaMap,
    required this.isLocked,
    required this.onTap,
  });

  bool _wins(
    int ownScore,
    int opponentScore,
    int? ownPenalty,
    int? opponentPenalty,
  ) {
    if (match.status != 'Selesai') return false;
    if (ownScore > opponentScore) return true;
    return ownScore == opponentScore &&
        ownPenalty != null &&
        opponentPenalty != null &&
        ownPenalty > opponentPenalty;
  }

  @override
  Widget build(BuildContext context) {
    const bgCard = Color(0xFF1E293B);
    const textMuted = Color(0xFF64748B);
    const successColor = Color(0xFF22C55E);
    const warningColor = Color(0xFFF59E0B);

    final isFinished = match.status == 'Selesai';
    final firstParticipant = match.idPeserta1 != null
        ? (pesertaMap[match.idPeserta1] ?? 'TBD')
        : 'TBD';
    final secondParticipant = match.idPeserta2 != null
        ? (pesertaMap[match.idPeserta2] ?? 'TBD')
        : 'TBD';

    Color badgeColor = textMuted;
    if (isFinished) {
      badgeColor = successColor;
    } else if (match.idPeserta1 != null && match.idPeserta2 != null) {
      badgeColor = warningColor;
    }

    final Color borderColor = isLocked
        ? Colors.white.withValues(alpha: 0.04)
        : (isFinished
              ? successColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Laga #${match.urutan}',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        match.status,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isLocked ? Icons.lock_rounded : Icons.edit_note_rounded,
                      size: isLocked ? 14 : 16,
                      color: isLocked ? textMuted : warningColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ScoreLine(
                  name: firstParticipant,
                  score: '${match.skor1}',
                  isWinner: _wins(
                    match.skor1,
                    match.skor2,
                    match.penalti1,
                    match.penalti2,
                  ),
                  isFinished: isFinished,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                ScoreLine(
                  name: secondParticipant,
                  score: '${match.skor2}',
                  isWinner: _wins(
                    match.skor2,
                    match.skor1,
                    match.penalti2,
                    match.penalti1,
                  ),
                  isFinished: isFinished,
                ),
                if (match.penalti1 != null && match.penalti2 != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Adu penalti ${match.penalti1}-${match.penalti2}',
                    style: const TextStyle(
                      color: warningColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
