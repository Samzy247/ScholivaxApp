import 'package:flutter/material.dart';

import '../../models/user_session.dart';
import '../../screens/attendance_history_screen.dart';
import '../../screens/child_dashboard_screen.dart';
import '../../services/parent_service.dart';
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
        // Daily attendance lives here now, not in the notification bell —
        // pushes still arrive the moment a child is marked, but this is
        // the place to actually check status at a glance.
        _AttendanceTrackerSection(session: session),
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

/// "Track Attendance" — today's marked-or-not status for every linked
/// child, fetched independently of the rest of the dashboard summary so
/// pulling to refresh the dashboard also refreshes this.
class _AttendanceTrackerSection extends StatefulWidget {
  final UserSession session;
  const _AttendanceTrackerSection({required this.session});

  @override
  State<_AttendanceTrackerSection> createState() => _AttendanceTrackerSectionState();
}

class _AttendanceTrackerSectionState extends State<_AttendanceTrackerSection> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.fetchTodayAttendance(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.headerGradient('parent').first;
    return SectionCard(
      title: "Today's Attendance",
      accent: accent,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          if (snapshot.hasError) {
            return const Text("Couldn't load today's attendance.", style: TextStyle(color: Colors.grey));
          }
          final children = snapshot.data ?? [];
          if (children.isEmpty) {
            return const Text('No children linked to this account yet.', style: TextStyle(color: Colors.grey));
          }
          return Column(children: [for (final c in children) _AttendanceRow(child: c, session: widget.session)]);
        },
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final Map<String, dynamic> child;
  final UserSession session;
  const _AttendanceRow({required this.child, required this.session});

  @override
  Widget build(BuildContext context) {
    final marked = child['marked'] == true;
    final status = child['status'] as int?;

    late final String label;
    late final Color color;
    if (!marked) {
      label = 'Not marked yet';
      color = const Color(0xFF94A3B8);
    } else if (status == 2) {
      label = 'Present';
      color = const Color(0xFF16A34A);
    } else if (status == 1) {
      label = 'Half Day';
      color = const Color(0xFFD97706);
    } else {
      label = 'Absent';
      color = const Color(0xFFDC2626);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AttendanceHistoryScreen(
            session: session,
            studentId: child['student_id'] as int,
            studentName: '${child['name']}',
          ),
        ),
      ),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Text('${child['name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
      ),
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
