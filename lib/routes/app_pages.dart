import 'package:get/get.dart';

import '../models/tournament.dart';
import '../screens/create_tournament_screen.dart';
import '../screens/detail_tournament_screen.dart';
import '../screens/edit_tournament_screen.dart';
import '../screens/main_shell.dart';
import 'app_routes.dart';

/// Daftar halaman terdaftar untuk GetX.
class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.home, page: () => const MainShell()),
    GetPage(name: AppRoutes.create, page: () => const CreateTournamentScreen()),
    GetPage(
      name: AppRoutes.detail,
      page: () =>
          DetailTournamentScreen(tournament: Get.arguments as Tournament),
    ),
    GetPage(
      name: AppRoutes.edit,
      page: () => EditTournamentScreen(tournament: Get.arguments as Tournament),
    ),
  ];
}
