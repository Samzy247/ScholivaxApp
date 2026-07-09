import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'dashboard_widgets.dart';

class TeacherDashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const TeacherDashboardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isClassTeacher = data['is_class_teacher'] == true;
    final className = data['class_teacher_class_name'] as String? ?? '';
    final subjects = (data['subjects'] as List).cast<Map>();
    final classes = (data['classes'] as List).cast<Map>();
    final accent = AppColors.headerGradient('teacher').first;

    final statCards = <StatCard>[
      StatCard(icon: Icons.menu_book_rounded, value: '${data['subjects_count']}', label: 'Subjects Assigned', color: const Color(0xFF2563EB)),
      StatCard(icon: Icons.school_rounded, value: '${data['classes_count']}', label: 'Classes Assigned', color: const Color(0xFF16A34A)),
    ];

    if (isClassTeacher) {
      statCards.add(StatCard(
        icon: Icons.wb_sunny_rounded,
        value: '${data['scanned_morning']} / ${data['scanned_afternoon']}',
        label: 'Scanned Today (AM/PM)',
        color: const Color(0xFFD97706),
      ));
      statCards.add(StatCard(
        icon: Icons.groups_rounded,
        value: '${data['total_students']}',
        label: 'Students in $className',
        color: const Color(0xFF7C3AED),
      ));
    } else {
      statCards.add(StatCard(
        icon: Icons.groups_rounded,
        value: '${data['total_students']}',
        label: 'Total Students I Teach',
        color: const Color(0xFFD97706),
      ));
      statCards.add(StatCard(
        icon: Icons.edit_rounded,
        value: '${data['entry_completion_percent']}%',
        label: 'Score Entry Completion',
        color: const Color(0xFF0D9488),
      ));
    }

    final week = isClassTeacher ? (data['attendance_last_7_days'] as List?)?.cast<Map>() ?? [] : <Map>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        StatGrid(cards: statCards),
        const SizedBox(height: 20),

        SectionCard(
          title: 'My Subjects',
          accent: accent,
          child: subjects.isEmpty
              ? const Text('No subjects assigned yet.', style: TextStyle(color: Colors.grey))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in subjects) _badge('${s['name']}  (${s['class_name']})', const Color(0xFFE8F0FE), const Color(0xFF3B7DD8)),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: 'My Classes',
          accent: accent,
          child: classes.isEmpty
              ? const Text('No classes assigned yet.', style: TextStyle(color: Colors.grey))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in classes) _badge('${c['name']} — ${c['student_count']} students', const Color(0xFFE6F4EA), const Color(0xFF28A745)),
                  ],
                ),
        ),

        if (isClassTeacher) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Attendance Overview — $className (Last 7 Days)',
            accent: accent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 34,
                dataRowMaxHeight: 40,
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('AM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('PM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('Absent', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('% Full Day', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
                ],
                rows: [
                  for (final day in week)
                    DataRow(cells: [
                      DataCell(Text('${day['date']}', style: const TextStyle(fontSize: 11.5))),
                      DataCell(Text('${day['morning']}', style: const TextStyle(fontSize: 11.5))),
                      DataCell(Text('${day['afternoon']}', style: const TextStyle(fontSize: 11.5))),
                      DataCell(Text('${day['absent']}', style: const TextStyle(fontSize: 11.5))),
                      DataCell(Text('${day['percent_full_day']}%', style: const TextStyle(fontSize: 11.5))),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
