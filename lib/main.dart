import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RivNet Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6658E8),
          secondary: Color(0xFF39D0B1),
          surface: Color(0xFF1A1B2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF10111D),
      ),
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
    );
  }
}
