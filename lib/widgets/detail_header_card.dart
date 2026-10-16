import 'package:flutter/material.dart';

import '../models/tournament.dart';

class DetailHeaderCard extends StatelessWidget {
  const DetailHeaderCard({
    super.key,
    required this.turnamen,
    required this.selesaiCount,
    required this.totalCount,
    required this.onAkhiri,
  });

  final Tournament turnamen;
  final int selesaiCount;
  final int totalCount;
  final VoidCallback onAkhiri;

  @override
  Widget build(BuildContext context) {
    final t = turnamen;
    final progress = totalCount > 0 ? selesaiCount / totalCount : 0.0;
    final isComplete = progress == 1.0;
    final width = MediaQuery.sizeOf(context).width;
    final dateStr =
        '${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}';
    final legStr = t.jumlahLeg == 2 ? '2 Leg Home & Away' : '1 Leg';

    const successColor = Color(0xFF22C55E);
    const warningColor = Color(0xFFF59E0B);
    const bgCard = Color(0xFF1E293B);
    const textSecondary = Color(0xFF94A3B8);
    const textMuted = Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((width * 0.04).clamp(12.0, 20.0)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [bgCard, Color(0xFF0F172A)],
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
                  color: (t.isFinished ? successColor : warningColor)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: t.isFinished ? successColor : warningColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: t.isFinished
                          ? successColor
                          : warningColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.status,
                      style: TextStyle(
                        color: t.isFinished ? successColor : warningColor,
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
                text: t.game,
                background: Colors.white.withValues(alpha: 0.08),
                color: textSecondary,
              ),
              _TagChip(
                text: '${t.kuota} Peserta · ${t.format} ($legStr)',
                background: const Color(0xFF6366F1).withValues(alpha: 0.15),
                color: const Color(0xFFA5B4FC),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          if (t.deskripsi?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              t.deskripsi!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Progress Turnamen',
                  style: TextStyle(
                    color: textSecondary,
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
                isComplete ? successColor : const Color(0xFF6366F1),
              ),
            ),
          ),
          if (t.isFinished) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: successColor),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 16, color: successColor),
                  SizedBox(width: 8),
                  Text(
                    'Turnamen Telah Berakhir — Skor Dikunci',
                    style: TextStyle(
                      color: successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isComplete && totalCount > 0) ...[
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
                  backgroundColor: warningColor,
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
  const _TagChip({
    required this.text,
    required this.background,
    required this.color,
  });

  final String text;
  final Color background;
  final Color color;

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
