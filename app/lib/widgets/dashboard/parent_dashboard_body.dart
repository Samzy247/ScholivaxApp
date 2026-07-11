import 'package:flutter/material.dart';

import '../../models/user_session.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';
import 'dashboard_widgets.dart';

class ParentDashboardBody extends StatefulWidget {
  final Map<String, dynamic> data;
  final UserSession session;
  final Future<void> Function() onSwitched;

  const ParentDashboardBody({
    super.key,
    required this.data,
    required this.session,
    required this.onSwitched,
  });

  @override
  State<ParentDashboardBody> createState() => _ParentDashboardBodyState();
}

class _ParentDashboardBodyState extends State<ParentDashboardBody> {
  int? _switchingStudentId;

  Future<void> _switchTo(Map child) async {
    final studentId = child['student_id'] as int?;
    if (studentId == null || _switchingStudentId != null) return;

    setState(() => _switchingStudentId = studentId);
    try {
      await ParentService.switchChild(widget.session, studentId);
      await widget.onSwitched();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Now viewing ${child['name']}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't switch child. Check your internet and try again.")),
      );
    } finally {
      if (mounted) setState(() => _switchingStudentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.headerGradient('parent').first;
    final children = (widget.data['children'] as List).cast<Map>();

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
                    if (children.length > 1)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Tap a child to view their profile, fees, attendance, and results.',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ),
                    for (final c in children)
                      _ChildTile(
                        child: c,
                        loading: _switchingStudentId == c['student_id'],
                        tappable: children.length > 1,
                        onTap: () => _switchTo(c),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChildTile extends StatelessWidget {
  final Map child;
  final bool loading;
  final bool tappable;
  final VoidCallback onTap;

  const _ChildTile({
    required this.child,
    required this.loading,
    required this.tappable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = child['name'] as String? ?? '?';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    final row = Row(children: [
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
      if (loading)
        const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
      else if (tappable)
        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    ]);

    if (!tappable) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: row);
    }

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: row),
    );
  }
}
