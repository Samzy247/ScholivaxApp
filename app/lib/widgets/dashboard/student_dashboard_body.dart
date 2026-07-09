import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'dashboard_widgets.dart';

class StudentDashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const StudentDashboardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.headerGradient('student').first;
    final subjects = (data['subjects'] as List).cast<Map>();
    final attendance = (data['attendance'] as Map).cast<String, dynamic>();
    final fees = (data['fees'] as Map).cast<String, dynamic>();
    final currency = fees['currency'] as String? ?? '₦';

    final attPct = (attendance['percent'] as num?)?.toInt() ?? 0;
    final attColor = attPct >= 75 ? const Color(0xFF16A34A) : (attPct >= 50 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    final payPct = (fees['percent'] as num?)?.toInt() ?? 0;
    final payColor = payPct >= 100 ? const Color(0xFF16A34A) : (payPct >= 50 ? const Color(0xFFD97706) : const Color(0xFFDC2626));
    final balance = (fees['balance'] as num?)?.toDouble() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Profile bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
          ]),
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(
                (data['name'] as String? ?? '?').isNotEmpty ? (data['name'] as String).substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['name'] as String? ?? 'Student', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  _pill('${data['class_name']}', const Color(0xFFEEF2FF), const Color(0xFF3730A3)),
                  Text('Reg No: ${data['roll'] ?? '-'}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  Text('Term ${data['term']}, ${data['session']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        StatGrid(cards: [
          StatCard(icon: Icons.emoji_events_rounded, value: '${data['average']}', label: 'Score Average', color: const Color(0xFF16A34A)),
          StatCard(icon: Icons.grade_rounded, value: '${data['grade']}', label: 'Current Grade', color: const Color(0xFF15803D)),
        ]),
        const SizedBox(height: 20),

        SectionCard(
          title: 'Subject Scores — Term ${data['term']}',
          accent: accent,
          child: subjects.isEmpty
              ? const Text('No scores entered yet for this term.', style: TextStyle(color: Colors.grey))
              : Column(children: [for (final s in subjects) _subjectRow(s)]),
        ),
        const SizedBox(height: 16),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _overviewCard(
              icon: Icons.calendar_month_rounded,
              title: 'Attendance',
              subtitle: 'Term ${data['term']} — ${data['session']}',
              percent: attPct,
              color: attColor,
              stats: [
                _StatBit('${attendance['days_open'] ?? '—'}', 'Days Open'),
                _StatBit('${attendance['days_present']}', 'Present'),
                _StatBit('${attendance['days_absent']}', 'Absent'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _overviewCard(
              icon: Icons.credit_card_rounded,
              title: 'Bill Payment',
              subtitle: '${data['session']} Session',
              percent: payPct > 100 ? 100 : payPct,
              color: payColor,
              stats: [
                _StatBit('$currency${_fmt(fees['total_billed'])}', 'Billed'),
                _StatBit('$currency${_fmt(fees['total_paid'])}', 'Paid'),
                _StatBit('$currency${_fmt(balance.abs())}', balance > 0 ? 'Balance' : 'Cleared'),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _subjectRow(Map s) {
    final total = (s['total'] as num?)?.toInt() ?? 0;
    final classAvg = (s['class_average'] as num?)?.toDouble() ?? 0;
    final isComplete = s['is_complete'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${s['name']}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          Text('$total/100', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          if (!isComplete) ...[
            const SizedBox(width: 6),
            const Text('(pending)', style: TextStyle(fontSize: 10.5, color: Colors.orange)),
          ],
        ]),
        const SizedBox(height: 5),
        Stack(children: [
          Container(height: 8, decoration: BoxDecoration(color: const Color(0xFFE9ECEF), borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(
            widthFactor: (total / 100).clamp(0.0, 1.0).toDouble(),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B7DD8), Color(0xFF28A745)]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ]),
        if (classAvg > 0) Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text('Class average: ${classAvg.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ),
      ]),
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int percent,
    required Color color,
    required List<_StatBit> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7F96))),
          ])),
          Text('$percent%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: percent / 100, minHeight: 7, backgroundColor: Colors.black.withOpacity(0.08), color: color),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in stats)
            Container(
              width: 78,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
              child: Column(children: [
                Text(s.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                Text(s.label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF6B7F96))),
              ]),
            ),
        ]),
      ]),
    );
  }

  String _fmt(dynamic n) {
    final v = (n is num) ? n : num.tryParse('$n') ?? 0;
    return v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}

class _StatBit {
  final String value;
  final String label;
  _StatBit(this.value, this.label);
}
