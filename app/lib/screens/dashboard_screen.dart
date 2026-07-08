import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import 'school_select_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserSession session;
  const DashboardScreen({super.key, required this.session});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _logout() async {
    await AuthService.logout(widget.session);
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SchoolSelectScreen()),
      (route) => false,
    );
  }

  Future<void> _refresh() async {
    // Placeholder for now — once circulars/attendance/marks screens exist,
    // this is where each dashboard card's data gets re-fetched.
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.schoolName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              elevation: 0,
              color: const Color(0xFFF5F7FA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF1A2E45),
                      child: Text(
                        (session.name?.isNotEmpty == true ? session.name![0] : '?').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.name ?? 'Welcome',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _roleLabel(session.userType),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Coming up next',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _ComingSoonTile(icon: Icons.campaign_outlined, label: 'Circulars'),
            _ComingSoonTile(icon: Icons.qr_code_scanner_rounded, label: 'Attendance'),
            _ComingSoonTile(icon: Icons.grade_outlined, label: 'Scores / Marks'),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String userType) {
    switch (userType) {
      case 'admin':
        return 'Administrator';
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      case 'parent':
        return 'Parent';
      default:
        return userType;
    }
  }
}

class _ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ComingSoonTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E9F0)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A2E45)),
        title: Text(label),
        trailing: const Text('Soon', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}
