import 'package:flutter/material.dart';

import '../models/klasemen_item.dart';

class KlasemenView extends StatelessWidget {
  const KlasemenView({
    super.key,
    required this.klasemen,
    required this.sidePadding,
  });

  final List<KlasemenItem> klasemen;
  final double sidePadding;

  @override
  Widget build(BuildContext context) {
    const textSecondary = Color(0xFF94A3B8);

    if (klasemen.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data klasemen',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 24),
      children: [
        LayoutBuilder(
          builder: (context, constraints) => KlasemenTable(
            klasemen: klasemen,
            unit: (constraints.maxWidth * 0.06).clamp(20.0, 36.0),
            showGoals: constraints.maxWidth >= 360,
          ),
        ),
        const SizedBox(height: 14),
        const KlasemenLegend(),
      ],
    );
  }
}

class KlasemenTable extends StatelessWidget {
  const KlasemenTable({
    super.key,
    required this.klasemen,
    required this.unit,
    required this.showGoals,
  });

  final List<KlasemenItem> klasemen;
  final double unit;
  final bool showGoals;

  static const gold = Color(0xFFFFD700);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const successColor = Color(0xFF22C55E);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
  );

  Widget _cell(
    String text,
    double widthFactor, {
    Color color = textSecondary,
    bool bold = true,
  }) {
    return SizedBox(
      width: unit * widthFactor,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatNumber(int value, {bool signed = false}) {
    final absoluteValue = value.abs();
    if (value < 0) return '-$absoluteValue';
    if (signed && value > 0) return '+$absoluteValue';
    return '$absoluteValue';
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: unit * 1.2,
            child: const Text(
              '#',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'KLUB / PESERTA',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _cell('M', 1),
          _cell('W', 1, color: successColor),
          _cell('D', 1, color: warningColor),
          _cell('L', 1, color: errorColor),
          if (showGoals) ...[_cell('GF', 1.1), _cell('GA', 1.1)],
          _cell('GD', 1.3),
          _cell('PTS', 1.5, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildRow(KlasemenItem item, int rank) {
    final isLastRow = rank == klasemen.length;
    const podiumColors = {
      1: Color(0x0DFFD700),
      2: Color(0x08C0C0C0),
      3: Color(0x08CD7F32),
    };
    final goalDifferenceColor = item.sg > 0
        ? successColor
        : (item.sg < 0 ? errorColor : textSecondary);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            podiumColors[rank] ??
            (rank.isOdd
                ? Colors.white.withValues(alpha: 0.015)
                : Colors.transparent),
        borderRadius: isLastRow
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : null,
        border: isLastRow
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: unit * 1.2,
            child: RankBadge(rank: rank),
          ),
          Expanded(
            child: Text(
              item.namaPeserta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: rank == 1 ? gold : textPrimary,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          _cell('${item.main}', 1, color: textPrimary, bold: false),
          _cell('${item.menang}', 1, color: successColor),
          _cell('${item.seri}', 1, color: warningColor),
          _cell('${item.kalah}', 1, color: errorColor),
          if (showGoals) ...[
            _cell(_formatNumber(item.gm), 1.1, color: textPrimary, bold: false),
            _cell(_formatNumber(item.gk), 1.1, color: textMuted, bold: false),
          ],
          _cell(
            _formatNumber(item.sg, signed: true),
            1.3,
            color: goalDifferenceColor,
          ),
          SizedBox(
            width: unit * 1.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                gradient: rank == 1 ? primaryGradient : null,
                color: rank != 1
                    ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                    : null,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _formatNumber(item.poin),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF182234),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          for (var index = 0; index < klasemen.length; index++)
            _buildRow(klasemen[index], index + 1),
        ],
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    const textSecondary = Color(0xFF94A3B8);

    const gradients = {
      1: [gold, Color(0xFFF59E0B)],
      2: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
      3: [Color(0xFFF97316), Color(0xFFB45309)],
    };
    final colors = gradients[rank];

    if (colors == null) {
      return Text(
        '$rank',
        style: const TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$rank',
          style: TextStyle(
            color: rank == 3 ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class KlasemenLegend extends StatelessWidget {
  const KlasemenLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const textPrimary = Colors.white;
    const textSecondary = Color(0xFF94A3B8);
    const bgCard = Color(0xFF1E293B);
    const successColor = Color(0xFF22C55E);
    const warningColor = Color(0xFFF59E0B);
    const errorColor = Color(0xFFEF4444);

    const items = [
      ('• M = Main', textSecondary),
      ('• W = Menang (3 Pts)', successColor),
      ('• D = Seri (1 Pt)', warningColor),
      ('• L = Kalah (0 Pt)', errorColor),
      ('• GF = Gol Masuk', textSecondary),
      ('• GA = Gol Kebobolan', textSecondary),
      ('• GD = Selisih Gol (GF - GA)', textSecondary),
      ('• PTS = Total Poin', Color(0xFFA5B4FC)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: warningColor),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Keterangan & Sistem Poin Sepak Bola / Futsal',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final (text, color) in items)
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
