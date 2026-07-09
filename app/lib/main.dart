import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guarded: DefaultFirebaseOptions still has placeholder values until a
  // real Android app config is added (see firebase_options.dart) — until
  // then this fails quietly and the app runs completely normally, just
  // without push notifications.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    await NotificationService.init();
  } catch (_) {
    // No valid Firebase config yet — rest of the app is unaffected.
  }

  runApp(const ScholivaxApp());
}

class ScholivaxApp extends StatelessWidget {
  const ScholivaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();
    return MaterialApp(
      title: 'Scholivax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A2E45),
        textTheme: baseTextTheme,
        primaryTextTheme: baseTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A2E45),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A2E45),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
