import 'package:get/get.dart';
import 'package:rivnet/models/tournament.dart';
import 'package:rivnet/screens/create_tournament_screen.dart';
import 'package:rivnet/screens/detail_tournament_screen.dart';
import 'package:rivnet/screens/edit_tournament_screen.dart';
import 'package:rivnet/screens/main_shell.dart';
import 'package:rivnet/routes/app_routes.dart';

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
