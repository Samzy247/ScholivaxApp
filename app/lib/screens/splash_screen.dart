import 'package:flutter/material.dart';
import '../services/session_store.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'school_select_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    final session = await SessionStore.load();
    // Small delay so the splash is actually visible, not a flash.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (session != null) {
      try {
        await NotificationService.registerAndKeepInSync(session);
      } catch (_) {}
      // No fresh cookies to hand over here — flutter_inappwebview's
      // CookieManager already persists the ci_session cookie from last
      // time (see WebCookieBridge), same as a normal browser. If it's
      // expired, any embedded page will simply show the site's own login
      // form, same as a browser would.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(session: session)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SchoolSelectScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A2E45),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 84, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Scholivax',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
