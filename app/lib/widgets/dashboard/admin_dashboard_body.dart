import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import 'dashboard_widgets.dart';

class AdminDashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const AdminDashboardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final counts = (data['counts'] as Map).cast<String, dynamic>();
    final attToday = (data['attendance_today'] as Map).cast<String, dynamic>();
    final finance = (data['finance'] as Map).cast<String, dynamic>();
    final monthly = (data['monthly_finance'] as Map).cast<String, dynamic>();
    final classDist = (data['class_distribution'] as Map).cast<String, dynamic>();
    final recentTeachers = (data['recent_teachers'] as List).cast<Map>();
    final recentStudents = (data['recent_students'] as List).cast<Map>();
    final currency = finance['currency'] as String? ?? '₦';
    final accent = AppColors.headerGradient('admin').first;

    final months = (monthly['months'] as List).cast<String>();
    final income = (monthly['income'] as List).map((e) => (e as num).toDouble()).toList();
    final expense = (monthly['expense'] as List).map((e) => (e as num).toDouble()).toList();
    final maxY = ([...income, ...expense].fold<double>(0, (a, b) => b > a ? b : a)) * 1.2 + 1;

    final classNames = (classDist['names'] as List).cast<String>();
    final classCounts = (classDist['counts'] as List).map((e) => (e as num).toDouble()).toList();
    const palette = [
      Color(0xFF1E40AF), Color(0xFF16A34A), Color(0xFFD97706), Color(0xFFDC2626),
      Color(0xFF7C3AED), Color(0xFF0EA5E9), Color(0xFFE11D48), Color(0xFF0F766E),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        StatGrid(cards: [
          StatCard(icon: Icons.groups_rounded, value: '${counts['students']}', label: 'Total Students', color: const Color(0xFF1E40AF)),
          StatCard(icon: Icons.school_rounded, value: '${counts['teachers']}', label: 'Total Teachers', color: const Color(0xFF16A34A)),
          StatCard(icon: Icons.family_restroom_rounded, value: '${counts['parents']}', label: 'Total Parents', color: const Color(0xFFD97706)),
          StatCard(icon: Icons.apartment_rounded, value: '${counts['classes']}', label: 'Classes', color: const Color(0xFF7C3AED)),
          StatCard(icon: Icons.event_available_rounded, value: '${attToday['present']}', label: 'Present Today', color: const Color(0xFF0EA5E9)),
          StatCard(icon: Icons.event_busy_rounded, value: '${attToday['absent']}', label: 'Absent Today', color: const Color(0xFFDC2626)),
        ]),
        const SizedBox(height: 20),

        // Finance summary
        Row(children: [
          Expanded(child: _financeTile('Total Income', '$currency${_fmt(finance['income'])}', const Color(0xFF16A34A), Icons.arrow_downward_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _financeTile('Total Expense', '$currency${_fmt(finance['expense'])}', const Color(0xFFDC2626), Icons.arrow_upward_rounded)),
        ]),
        const SizedBox(height: 20),

        SectionCard(
          title: 'Income vs Expense — Last 6 Months',
          accent: accent,
          child: SizedBox(
            height: 200,
            child: months.isEmpty
                ? const Center(child: Text('No finance data yet', style: TextStyle(color: Colors.grey)))
                : BarChart(BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(enabled: false),
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= months.length) return const SizedBox.shrink();
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(months[i], style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))));
                        },
                      )),
                    ),
                    barGroups: List.generate(months.length, (i) => BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: income[i], color: const Color(0xFF16A34A), width: 7, borderRadius: BorderRadius.circular(3)),
                      BarChartRodData(toY: expense[i], color: const Color(0xFFDC2626), width: 7, borderRadius: BorderRadius.circular(3)),
                    ])),
                  )),
          ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: 'Students per Class',
          accent: accent,
          child: classNames.isEmpty
              ? const Text('No classes yet', style: TextStyle(color: Colors.grey))
              : SizedBox(
                  height: 200,
                  child: Row(children: [
                    Expanded(
                      child: PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: List.generate(classNames.length, (i) => PieChartSectionData(
                          value: classCounts[i] <= 0 ? 0.001 : classCounts[i],
                          title: classCounts[i].toInt().toString(),
                          color: palette[i % palette.length],
                          radius: 46,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                        )),
                      )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: classNames.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: palette[i % palette.length], shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(classNames[i], style: const TextStyle(fontSize: 11.5), overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: 'Recently Added Teachers',
          accent: accent,
          child: recentTeachers.isEmpty
              ? const Text('No teachers yet', style: TextStyle(color: Colors.grey))
              : Column(children: [
                  for (final t in recentTeachers) _personRow(t['name'] as String? ?? '', t['email'] as String? ?? ''),
                ]),
        ),
        const SizedBox(height: 16),

        SectionCard(
          title: 'Recently Added Students',
          accent: accent,
          child: recentStudents.isEmpty
              ? const Text('No students yet', style: TextStyle(color: Colors.grey))
              : Column(children: [
                  for (final s in recentStudents) _personRow(s['name'] as String? ?? '', s['class_name'] as String? ?? ''),
                ]),
        ),
      ],
    );
  }

  Widget _financeTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _personRow(String name, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        CircleAvatar(radius: 15, backgroundColor: const Color(0xFFEEF2FF), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 12))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(sub, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ])),
      ]),
    );
  }

  String _fmt(dynamic n) {
    final v = (n is num) ? n : num.tryParse('$n') ?? 0;
    return v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}
