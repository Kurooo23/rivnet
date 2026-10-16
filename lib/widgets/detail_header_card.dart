import 'package:flutter/material.dart';
import 'package:rivnet/theme/app_colors.dart';
import 'package:rivnet/models/tournament.dart';

class DetailHeaderCard extends StatelessWidget {
  final Tournament turnamen;
  final int selesaiCount;
  final int totalCount;
  final VoidCallback onAkhiri;

  const DetailHeaderCard({
    super.key,
    required this.turnamen,
    required this.selesaiCount,
    required this.totalCount,
    required this.onAkhiri,
  });

  @override
  Widget build(BuildContext context) {
    final tournament = turnamen;
    final progress = totalCount > 0 ? selesaiCount / totalCount : 0.0;
    final isComplete = selesaiCount == totalCount && totalCount > 0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final date = tournament.date;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final legDescription = tournament.jumlahLeg == 2
        ? '2 Leg Home & Away'
        : '1 Leg';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((screenWidth * 0.04).clamp(12.0, 20.0)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.card, AppColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (tournament.isFinished
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tournament.isFinished
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: tournament.isFinished
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tournament.status,
                      style: TextStyle(
                        color: tournament.isFinished
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TagChip(
                text: tournament.game,
                background: Colors.white.withValues(alpha: 0.08),
                color: AppColors.textSecondary,
              ),
              _TagChip(
                text:
                    '${tournament.kuota} Peserta · ${tournament.format} ($legDescription)',
                background: AppColors.primary.withValues(alpha: 0.15),
                color: AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (tournament.deskripsi?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              tournament.deskripsi!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress Turnamen',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$selesaiCount / $totalCount Laga (${(progress * 100).toInt()}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(
                isComplete ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          if (tournament.isFinished) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 16, color: AppColors.success),
                  SizedBox(width: 8),
                  Text(
                    'Turnamen Telah Berakhir — Skor Dikunci',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isComplete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAkhiri,
                icon: const Icon(Icons.flag_rounded, size: 16),
                label: const Text(
                  'Akhiri Turnamen & Kunci Skor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;

  const _TagChip({
    required this.text,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
