import 'package:flutter/material.dart';

import '../constants/portal_menu.dart';
import '../models/user_session.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/dashboard_service.dart';
import '../services/parent_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/dashboard_widgets.dart';
import 'chat_screen.dart';
import 'webview_screen.dart';

/// Fixes the broken child-switch flow AND gives it the full-portal feel
/// that was missing before: this is now a self-contained mini dashboard
/// with its own bottom nav (Academics / Fees / Chat), the same
/// bottom-sheet pattern as the main dashboard — as close to "logging into
/// that child's own student portal" as the website's session-scoped
/// pages allow.
///
/// The native stats (attendance/average/subjects/fees) come from the
/// token API and are always correct regardless of session state. The
/// Academics/Fees WebView pages, though, are the website's own
/// `/parents/...` pages, which read whichever child the PHP session is
/// currently pointed at — so switching child here re-runs
/// `ParentService.switchChild()` first, then those pages show the right
/// child's data once opened.
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
  Future<void>? _switchFuture;

  PortalSection get _academics => PortalMenu.childPortalSections.firstWhere((s) => s.title == 'Academics');
  PortalSection get _fees => PortalMenu.childPortalSections.firstWhere((s) => s.title == 'Fees');

  @override
  void initState() {
    super.initState();
    _studentId = widget.initialStudentId;
    _switchAndLoad();
  }

  void _switchAndLoad() {
    // Fired in parallel, not blocking the native stats from showing —
    // but awaited before any WebView link opens (see _openWebPath).
    _switchFuture = ParentService.switchChild(widget.session, _studentId);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await DashboardService.fetchChildSummary(widget.session, _studentId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
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
    _switchAndLoad();
  }

  Future<void> _openWebPath(PortalItem item) async {
    // Make sure the website session is actually pointed at this child
    // before opening one of its pages — otherwise it could briefly (or,
    // if the switch failed, permanently) show a sibling's data instead.
    if (_switchFuture != null) {
      try {
        await _switchFuture;
      } catch (_) {
        // best-effort — see ParentService.switchChild's own doc comment
      }
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WebViewScreen(title: item.label, path: item.path, session: widget.session)),
    );
  }

  void _openSection(PortalSection section) {
    if (section.items.length == 1) {
      _openWebPath(section.items.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChildSectionSheet(section: section, onSelect: _openWebPath),
    );
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
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't open chat: ${e.message}")));
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
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Back to my dashboard', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          switch (index) {
            case 1:
              _openSection(_academics);
              break;
            case 2:
              _openSection(_fees);
              break;
            case 3:
              _messageTeacher();
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Academics'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Fees'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
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

/// Same bottom-sheet look as the main dashboard's section sheets, just
/// scoped to this child-dashboard screen's own onSelect callback.
class _ChildSectionSheet extends StatelessWidget {
  final PortalSection section;
  final ValueChanged<PortalItem> onSelect;
  const _ChildSectionSheet({required this.section, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(section.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          for (final item in section.items)
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.navy.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Icon(item.icon, color: AppColors.navy, size: 20),
              ),
              title: Text(item.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () {
                Navigator.of(context).pop();
                onSelect(item);
              },
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
