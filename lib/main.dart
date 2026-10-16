import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rivnet/routes/app_pages.dart';
import 'package:rivnet/routes/app_routes.dart';
import 'package:rivnet/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RivNet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
    );
  }
}
