import 'package:flutter/material.dart';
import 'package:rivnet/theme/app_colors.dart';
import 'package:rivnet/models/klasemen_item.dart';

class KlasemenView extends StatelessWidget {
  final List<KlasemenItem> klasemen;
  final double sidePadding;

  const KlasemenView({
    super.key,
    required this.klasemen,
    required this.sidePadding,
  });

  @override
  Widget build(BuildContext context) {
    if (klasemen.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data klasemen',
          style: TextStyle(color: AppColors.textSecondary),
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
  final List<KlasemenItem> klasemen;
  final double unit;
  final bool showGoals;

  const KlasemenTable({
    super.key,
    required this.klasemen,
    required this.unit,
    required this.showGoals,
  });

  Widget _cell(
    String text,
    double widthFactor, {
    Color color = AppColors.textSecondary,
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
        color: AppColors.background,
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
                color: AppColors.textSecondary,
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
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _cell('M', 1),
          _cell('W', 1, color: AppColors.success),
          _cell('D', 1, color: AppColors.warning),
          _cell('L', 1, color: AppColors.error),
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
      1: AppColors.podiumGold,
      2: AppColors.podiumSilver,
      3: AppColors.podiumBronze,
    };
    final goalDifferenceColor = item.sg > 0
        ? AppColors.success
        : (item.sg < 0 ? AppColors.error : AppColors.textSecondary);

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
                color: rank == 1 ? AppColors.gold : AppColors.textPrimary,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          _cell('${item.main}', 1, color: AppColors.textPrimary, bold: false),
          _cell('${item.menang}', 1, color: AppColors.success),
          _cell('${item.seri}', 1, color: AppColors.warning),
          _cell('${item.kalah}', 1, color: AppColors.error),
          if (showGoals) ...[
            _cell(
              _formatNumber(item.gm),
              1.1,
              color: AppColors.textPrimary,
              bold: false,
            ),
            _cell(
              _formatNumber(item.gk),
              1.1,
              color: AppColors.textMuted,
              bold: false,
            ),
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
                gradient: rank == 1 ? AppColors.primaryGradient : null,
                color: rank != 1
                    ? AppColors.primary.withValues(alpha: 0.2)
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
        color: AppColors.backgroundAlt,
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
  final int rank;

  const RankBadge({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    const gradients = {
      1: [AppColors.gold, AppColors.warning],
      2: [AppColors.silver, AppColors.textSecondary],
      3: [AppColors.bronze, AppColors.bronzeDark],
    };
    final colors = gradients[rank];

    if (colors == null) {
      return Text(
        '$rank',
        style: const TextStyle(
          color: AppColors.textSecondary,
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
    const items = [
      ('• M = Main', AppColors.textSecondary),
      ('• W = Menang (3 Pts)', AppColors.success),
      ('• D = Seri (1 Pt)', AppColors.warning),
      ('• L = Kalah (0 Pt)', AppColors.error),
      ('• GF = Gol Masuk', AppColors.textSecondary),
      ('• GA = Gol Kebobolan', AppColors.textSecondary),
      ('• GD = Selisih Gol (GF - GA)', AppColors.textSecondary),
      ('• PTS = Total Poin', AppColors.primaryLight),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppColors.warning,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Keterangan & Sistem Poin Sepak Bola / Futsal',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
