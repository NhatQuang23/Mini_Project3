import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/camera_screen.dart';
import '../presentation/screens/stats_screen.dart';

/// Root MaterialApp widget with theme and routing configuration.
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/stats': (context) => const StatsScreen(),
      },
    );
  }
}
