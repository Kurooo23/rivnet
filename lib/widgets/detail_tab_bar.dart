import 'package:flutter/material.dart';
import 'package:rivnet/theme/app_colors.dart';

class DetailTabBar extends StatelessWidget {
  final TabController controller;
  final bool isKnockout;
  final int matchCount;
  final int pesertaCount;
  final bool showIcons;

  const DetailTabBar({
    super.key,
    required this.controller,
    required this.isKnockout,
    required this.matchCount,
    required this.pesertaCount,
    required this.showIcons,
  });

  Tab _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcons) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: [
          isKnockout
              ? _buildTab(Icons.account_tree_rounded, 'Bagan')
              : _buildTab(Icons.leaderboard_rounded, 'Klasemen'),
          _buildTab(Icons.sports_esports_rounded, 'Laga ($matchCount)'),
          _buildTab(Icons.groups_rounded, 'Peserta'),
        ],
      ),
    );
  }
}
