import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rivnet/models/tournament.dart';
import 'package:rivnet/routes/app_routes.dart';
import 'package:rivnet/widgets/tournament_list.dart';

class HistoryScreen extends StatelessWidget {
  final List<Tournament> tournaments;
  final VoidCallback? onRefresh;

  const HistoryScreen({super.key, required this.tournaments, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth * 0.05;

    if (tournaments.isEmpty) {
      return const TournamentEmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: 'Belum ada riwayat',
        message: 'Turnamen yang selesai akan muncul di sini.',
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        24,
      ),
      children: [
        TournamentCardGrid(
          tournaments: tournaments,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          itemBuilder: (context, tournament, iconSize) {
            return TournamentSummaryCard(
              tournament: tournament,
              iconSize: iconSize,
              isFinished: true,
              onTap: () => _openTournament(tournament),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openTournament(Tournament tournament) async {
    await Get.toNamed(AppRoutes.detail, arguments: tournament);
    onRefresh?.call();
  }
}
