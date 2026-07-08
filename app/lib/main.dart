import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ScholivaxApp());
}

class ScholivaxApp extends StatelessWidget {
  const ScholivaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scholivax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A2E45),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A2E45),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2E45),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
