import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../database/database_helper.dart';
import '../models/tournament.dart';
import '../routes/app_routes.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final DatabaseHelper _database = DatabaseHelper.instance;

  List<Tournament> _tournaments = [];
  int _selectedTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    final tournaments = await _database.getTournaments();
    if (!mounted) return;

    setState(() {
      _tournaments = tournaments;
      _isLoading = false;
    });
  }

  Future<void> _createTournament() async {
    final tournament = await Get.toNamed(AppRoutes.create) as Tournament?;
    if (tournament == null) return;

    await _database.insertTournament(tournament);
    await _loadTournaments();
  }

  Future<void> _startTournament(Tournament tournament) async {
    await _database.updateStatus(tournament.id!, 'Berlangsung');
    await _loadTournaments();
  }

  Future<void> _finishTournament(Tournament tournament) async {
    await _database.markFinished(tournament.id!);
    await _loadTournaments();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Turnamen dipindahkan ke riwayat.')),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final activeTournaments = _tournaments
        .where((tournament) => !tournament.isFinished)
        .toList();
    final finishedTournaments = _tournaments
        .where((tournament) => tournament.isFinished)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTab == 0 ? 'RivNet Offline' : 'Riwayat Turnamen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedTab,
              children: [
                HomeScreen(
                  tournaments: activeTournaments,
                  onStart: _startTournament,
                  onFinish: _finishTournament,
                  onRefresh: _loadTournaments,
                ),
                HistoryScreen(
                  tournaments: finishedTournaments,
                  onRefresh: _loadTournaments,
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _selectTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Daftar Turnamen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat Selesai',
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? SafeArea(
              child: FloatingActionButton.extended(
                onPressed: _createTournament,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Buat Turnamen'),
              ),
            )
          : null,
    );
  }
}
