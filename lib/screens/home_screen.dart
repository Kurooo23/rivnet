import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/tournament.dart';
import '../routes/app_routes.dart';
import '../widgets/tournament_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.tournaments,
    required this.onStart,
    required this.onFinish,
    this.onRefresh,
  });

  final List<Tournament> tournaments;
  final ValueChanged<Tournament> onStart;
  final ValueChanged<Tournament> onFinish;
  final VoidCallback? onRefresh;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _filters = ['Semua', 'Akan Datang', 'Berlangsung'];

  String _selectedFilter = _filters.first;

  List<Tournament> get _filteredTournaments => widget.tournaments
      .where(
        (tournament) =>
            _selectedFilter == _filters.first ||
            tournament.status == _selectedFilter,
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth * 0.05;
    final tournaments = _filteredTournaments;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            4,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final filter in _filters)
                  ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: tournaments.isEmpty
              ? const TournamentEmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'Belum ada turnamen',
                  message: 'Klik "Buat Turnamen" untuk memulai.',
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    80,
                  ),
                  children: [
                    TournamentCardGrid(
                      tournaments: tournaments,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      itemBuilder: (context, tournament, iconSize) {
                        return TournamentSummaryCard(
                          tournament: tournament,
                          iconSize: iconSize,
                          onStart: tournament.status == 'Akan Datang'
                              ? () => widget.onStart(tournament)
                              : null,
                          onFinish: () => widget.onFinish(tournament),
                          onTap: () => _openTournament(tournament),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openTournament(Tournament tournament) async {
    await Get.toNamed(AppRoutes.detail, arguments: tournament);
    widget.onRefresh?.call();
  }
}
