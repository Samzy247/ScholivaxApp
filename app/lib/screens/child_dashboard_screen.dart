import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/dashboard_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/dashboard_widgets.dart';
import 'chat_screen.dart';

/// Shows one child's academics — attendance, average/grade, subject
/// scores, fees — with a switcher up top when there's more than one
/// child, so flipping between siblings is just re-fetching data on this
/// same screen instead of the old (broken) approach of mutating the
/// website's PHP session and hoping the native dashboard reflected it.
class ChildDashboardScreen extends StatefulWidget {
  final UserSession session;
  final List<Map> children;
  final int initialStudentId;

  const ChildDashboardScreen({
    super.key,
    required this.session,
    required this.children,
    required this.initialStudentId,
  });

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  late int _studentId;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _studentId = widget.initialStudentId;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await DashboardService.fetchChildSummary(widget.session, _studentId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = "Couldn't load this child's dashboard — check your connection.";
      });
    }
  }

  void _switchTo(int studentId) {
    if (studentId == _studentId) return;
    setState(() => _studentId = studentId);
    _load();
  }

  Future<void> _messageTeacher() async {
    try {
      final thread = await ChatService.openThreadForChild(widget.session, _studentId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            session: widget.session,
            threadId: thread['thread_id'] as int,
            title: thread['teacher_name']?.toString() ?? 'Class Teacher',
            initialMessages: (thread['messages'] as List).cast<Map<String, dynamic>>(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the chat — check your connection and try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.headerGradient('parent').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(_data?['name']?.toString() ?? 'Child Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: Column(
        children: [
          if (widget.children.length > 1)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final child in widget.children)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(child['name'].toString()),
                          selected: child['student_id'] == _studentId,
                          onSelected: (_) => _switchTo(child['student_id'] as int),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                : _error != null
                    ? DashboardErrorView(message: _error!, onRetry: _load)
                    : RefreshIndicator(onRefresh: _load, child: _body(accent)),
          ),
        ],
      ),
    );
  }

  Widget _body(Color accent) {
    final data = _data!;
    final attendance = (data['attendance'] as Map?)?.cast<String, dynamic>() ?? {};
    final fees = (data['fees'] as Map?)?.cast<String, dynamic>() ?? {};
    final subjects = (data['subjects'] as List?)?.cast<Map>() ?? [];
    final classTeacher = (data['class_teacher'] as Map?)?.cast<String, dynamic>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('${data['class_name'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        StatGrid(cards: [
          StatCard(icon: Icons.grade_rounded, value: '${data['average'] ?? '-'}', label: 'Average (${data['grade'] ?? '-'})', color: accent),
          StatCard(icon: Icons.qr_code_scanner_rounded, value: '${attendance['percent'] ?? 0}%', label: 'Attendance', color: Colors.green),
          StatCard(
            icon: Icons.payments_rounded,
            value: '${fees['currency'] ?? ''}${fees['balance'] ?? 0}',
            label: 'Fee Balance',
            color: (fees['balance'] ?? 0) > 0 ? Colors.red : Colors.green,
          ),
          StatCard(icon: Icons.menu_book_rounded, value: '${subjects.length}', label: 'Subjects', color: Colors.indigo),
        ]),
        const SizedBox(height: 20),
        if (classTeacher != null)
          SectionCard(
            title: 'Class Teacher',
            accent: accent,
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: accent.withOpacity(0.12), child: Icon(Icons.person_rounded, color: accent, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(classTeacher['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                TextButton.icon(onPressed: _messageTeacher, icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16), label: const Text('Message')),
              ],
            ),
          ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Subjects',
          accent: accent,
          child: subjects.isEmpty
              ? const Text('No subject scores recorded yet this term.', style: TextStyle(color: Colors.grey))
              : Column(
                  children: [
                    for (final s in subjects)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(s['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5))),
                            Text(
                              s['is_complete'] == true ? '${s['total']}' : 'In progress',
                              style: TextStyle(fontSize: 13, color: s['is_complete'] == true ? Colors.black87 : AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
