import 'package:flutter/material.dart';
import '../models/school.dart';
import 'login_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  final School school;
  const RoleSelectScreen({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(school.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How would you like to sign in?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            _RoleCard(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin / Teacher',
              subtitle: 'Sign in with your email address',
              onTap: () => _goToLogin(context, 'staff'),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.school_rounded,
              title: 'Student',
              subtitle: 'Sign in with your Registration Number',
              onTap: () => _goToLogin(context, 'student'),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.family_restroom_rounded,
              title: 'Parent',
              subtitle: 'Coming soon',
              enabled: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context, String roleGroup) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(school: school, roleGroup: roleGroup),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        color: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, size: 34, color: const Color(0xFF1A2E45)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                if (enabled) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
