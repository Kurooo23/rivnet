import 'package:flutter/material.dart';
import 'package:rivnet/theme/app_colors.dart';
import 'package:rivnet/models/match.dart';

String roundName(String babak) =>
    babak.replaceFirst(RegExp(r'^Leg [12] - '), '');

class BracketView extends StatelessWidget {
  final List<Pertandingan> matches;
  final Map<String, String> pesertaMap;
  final int legCount;
  final double columnWidth;
  final double connectorWidth;
  final double sidePadding;
  final ValueChanged<Pertandingan> onTapMatch;

  const BracketView({
    super.key,
    required this.matches,
    required this.pesertaMap,
    required this.legCount,
    required this.columnWidth,
    required this.connectorWidth,
    required this.sidePadding,
    required this.onTapMatch,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada pertandingan',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final matchesByRound = <String, List<Pertandingan>>{};
    for (final match in [
      ...matches,
    ]..sort((a, b) => a.urutan.compareTo(b.urutan))) {
      matchesByRound.putIfAbsent(roundName(match.babak), () => []).add(match);
    }

    final thirdPlace = matchesByRound.remove('Perebutan Juara 3') ?? [];
    final rounds = matchesByRound.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Final') return 1;
        if (b.key == 'Final') return -1;
        return a.value.first.urutan.compareTo(b.value.first.urutan);
      });

    List<Widget> ties(List<Pertandingan> list) => [
      for (var i = 0; i < list.length; i += legCount)
        BracketTie(
          legs: list.skip(i).take(legCount).toList(),
          pesertaMap: pesertaMap,
          onTap: onTapMatch,
        ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final round in rounds) ...[
              SizedBox(
                width: columnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 12),
                      child: Text(
                        round.key,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...ties(round.value),
                    if (round.key.contains('Semifinal') &&
                        thirdPlace.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 2, top: 8, bottom: 12),
                        child: Text(
                          'Perebutan Juara 3',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...ties(thirdPlace),
                    ],
                  ],
                ),
              ),
              if (round.key != rounds.last.key)
                SizedBox(
                  width: connectorWidth,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class BracketTie extends StatelessWidget {
  final List<Pertandingan> legs;
  final Map<String, String> pesertaMap;
  final ValueChanged<Pertandingan> onTap;

  const BracketTie({
    super.key,
    required this.legs,
    required this.pesertaMap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstLeg = legs.first;
    final homeParticipantId = firstLeg.idPeserta1;
    final awayParticipantId = firstLeg.idPeserta2;

    final homeName = homeParticipantId == null
        ? 'TBD'
        : (pesertaMap[homeParticipantId] ?? 'TBD');
    final awayName = awayParticipantId == null
        ? 'TBD'
        : (pesertaMap[awayParticipantId] ?? 'TBD');

    var homeScore = 0;
    var awayScore = 0;
    for (final leg in legs) {
      if (homeParticipantId != null && leg.idPeserta1 == homeParticipantId) {
        homeScore += leg.skor1;
        awayScore += leg.skor2;
      } else if (awayParticipantId != null &&
          leg.idPeserta1 == awayParticipantId) {
        awayScore += leg.skor1;
        homeScore += leg.skor2;
      }
    }

    final allFinished = legs.every((leg) => leg.status == 'Selesai');
    var homeWon = allFinished && homeScore > awayScore;
    var awayWon = allFinished && awayScore > homeScore;

    if (allFinished && homeScore == awayScore) {
      final penaltyLeg = legs
          .where((leg) => leg.penalti1 != null && leg.penalti2 != null)
          .firstOrNull;
      if (penaltyLeg != null) {
        final homeIsParticipant1 = penaltyLeg.idPeserta1 == homeParticipantId;
        final homePenalty = homeIsParticipant1
            ? penaltyLeg.penalti1!
            : penaltyLeg.penalti2!;
        final awayPenalty = homeIsParticipant1
            ? penaltyLeg.penalti2!
            : penaltyLeg.penalti1!;
        homeWon = homePenalty > awayPenalty;
        awayWon = awayPenalty > homePenalty;
      }
    }

    final editableLeg = legs.firstWhere(
      (leg) => leg.status != 'Selesai',
      orElse: () => legs.last,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(editableLeg),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ScoreLine(
                  name: homeName,
                  score: '$homeScore',
                  isWinner: homeWon,
                  compact: true,
                ),
                const Divider(color: Colors.white10, height: 16),
                ScoreLine(
                  name: awayName,
                  score: '$awayScore',
                  isWinner: awayWon,
                  compact: true,
                ),
                if (legs.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    legs.map((leg) => '${leg.skor1}-${leg.skor2}').join(' · '),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
                for (final leg in legs)
                  if (leg.penalti1 != null && leg.penalti2 != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Penalti ${leg.penalti1}-${leg.penalti2}',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScoreLine extends StatelessWidget {
  final String name;
  final String score;
  final bool isWinner;
  final bool isFinished;
  final bool compact;

  const ScoreLine({
    super.key,
    required this.name,
    required this.score,
    required this.isWinner,
    this.isFinished = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scoreText = Text(
      score,
      style: TextStyle(
        color: isWinner ? Colors.white : AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );

    return Row(
      children: [
        if (isWinner)
          Padding(
            padding: EdgeInsets.only(right: compact ? 5 : 6),
            child: Icon(
              Icons.emoji_events_rounded,
              color: AppColors.gold,
              size: compact ? 14 : 16,
            ),
          ),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWinner
                  ? AppColors.gold
                  : (isFinished
                        ? AppColors.textSecondary
                        : AppColors.textPrimary),
              fontSize: compact ? 12 : 13,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (compact)
          scoreText
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isWinner
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWinner
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: scoreText,
          ),
      ],
    );
  }
}
