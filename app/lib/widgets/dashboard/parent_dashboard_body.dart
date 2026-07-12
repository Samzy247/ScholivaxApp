import 'package:flutter/material.dart';

import '../../models/user_session.dart';
import '../../screens/child_dashboard_screen.dart';
import '../../theme/app_theme.dart';
import 'dashboard_widgets.dart';

class ParentDashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final UserSession session;
  final Future<void> Function() onSwitched;

  const ParentDashboardBody({
    super.key,
    required this.data,
    required this.session,
    required this.onSwitched,
  });

  void _openChild(BuildContext context, List<Map> children, Map child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChildDashboardScreen(
          session: session,
          children: children,
          initialStudentId: child['student_id'] as int,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.headerGradient('parent').first;
    final children = (data['children'] as List).cast<Map>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        StatGrid(cards: [
          StatCard(icon: Icons.family_restroom_rounded, value: '${children.length}', label: 'Children Enrolled', color: accent),
        ]),
        const SizedBox(height: 20),
        SectionCard(
          title: 'My Children',
          accent: accent,
          child: children.isEmpty
              ? const Text('No children linked to this account yet.', style: TextStyle(color: Colors.grey))
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Tap a child to view their attendance, scores, and fees.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
                    ),
                    for (final c in children)
                      _ChildTile(child: c, onTap: () => _openChild(context, children, c)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChildTile extends StatelessWidget {
  final Map child;
  final VoidCallback onTap;

  const _ChildTile({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = child['name'] as String? ?? '?';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE0F2FE),
            child: Text(initial, style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              Text('${child['class_name']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
        ]),
      ),
    );
  }
}
