import 'package:flutter/material.dart';

import '../constants/portal_menu.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/dashboard_service.dart';
import '../services/session_store.dart';
import '../services/notification_service.dart';
import '../services/web_cookie_bridge.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/native_dashboard.dart';
import '../widgets/notification_bell.dart';
import '../widgets/portal_grid.dart';
import 'chat_screen.dart';
import 'school_select_screen.dart';
import 'offline/marks_screen.dart';
import 'teacher_chat_inbox_screen.dart';
import 'webview_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserSession session;
  const DashboardScreen({super.key, required this.session});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardKey = GlobalKey<NativeDashboardState>();
  late final List<PortalSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = PortalMenu.forRole(widget.session.userType);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.logout(widget.session);
    try {
      await NotificationService.unregister(widget.session);
    } catch (_) {}
    await SessionStore.clear();
    await WebCookieBridge.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SchoolSelectScreen()),
      (route) => false,
    );
  }

  void _openItem(PortalItem item) {
    if (item.nativeRoute == 'marks') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MarksScreen(session: widget.session)),
      );
      return;
    }
    if (item.nativeRoute == 'chat_inbox') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TeacherChatInboxScreen(session: widget.session)),
      );
      return;
    }
    if (item.nativeRoute == 'chat_teacher') {
      _openChatTeacher();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(title: item.label, path: item.path, session: widget.session),
      ),
    );
  }

  /// "Chat Teacher": one child → straight into that conversation. More
  /// than one → a bottom sheet to pick which child first.
  Future<void> _openChatTeacher() async {
    List<Map> children;
    try {
      final summary = await DashboardService.fetchSummary(widget.session);
      children = (summary['children'] as List).cast<Map>();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load your children — check your connection and try again.")),
      );
      return;
    }

    if (children.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No children linked to your account yet.')),
      );
      return;
    }

    if (children.length == 1) {
      _openChatFor(children.first);
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChildPickerSheet(children: children, onSelect: _openChatFor),
    );
  }

  Future<void> _openChatFor(Map child) async {
    try {
      final thread = await ChatService.openThreadForChild(widget.session, child['student_id'] as int);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open chat for ${child['name']}: ${e.message}")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open chat for ${child['name']} — check your connection and try again.")),
      );
    }
  }

  /// A section with exactly one link goes straight there — a bottom sheet
  /// with a single row in it is just an extra tap for no reason.
  void _openSection(PortalSection section) {
    if (section.items.length == 1) {
      _openItem(section.items.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionSheet(section: section, onSelect: _openItem),
    );
  }

  /// Sections not already reachable via a bottom-nav shortcut — shown
  /// together in one scrollable sheet instead of a dedicated "More" page.
  void _openMore(List<PortalSection> sections) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreSheet(sections: sections, onSelect: _openItem),
    );
  }

  /// Section titles surfaced as bottom-nav shortcuts, curated per role —
  /// tapping one pops up a bottom sheet with that section's links.
  List<String> get _shortcutTitles {
    switch (widget.session.userType) {
      case 'admin':
        return const ['Students', 'Staff & HR', 'Exams & CBT'];
      case 'teacher':
        return const ['Classes', 'Exams & CBT', 'Report Card', 'Messages', 'Profile'];
      case 'student':
        return const ['Academics', 'Exams', 'Classes', 'Fees & Profile'];
      case 'parent':
        return const ['Chat Teacher', 'Academics', 'Profile'];
      default:
        return const [];
    }
  }

  // Short, bottom-nav-friendly label per section title (falls back to the
  // first word of the title when there's no override needed).
  static const _navLabelOverrides = <String, String>{
    'Exams & CBT': 'Exams',
    'Staff & HR': 'Staff',
    'Fees & Profile': 'Profile',
    'Report Card': 'Report',
    'Chat Teacher': 'Chat',
  };

  String _navLabel(String title) => _navLabelOverrides[title] ?? title.split(' ').first;

  String _roleLabel(String userType) {
    switch (userType) {
      case 'admin':
        return 'Admin';
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

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final gradient = AppColors.headerGradient(session.userType);
    final shortcuts = _shortcutTitles;
    final leftoverSections = _sections.where((s) => !shortcuts.contains(s.title)).toList();

    final navItems = <_NavEntry>[
      _NavEntry(icon: Icons.home_rounded, label: 'Home', onTap: () {}),
      for (final title in shortcuts)
        _NavEntry(
          icon: _sections.firstWhere((s) => s.title == title).items.first.icon,
          label: _navLabel(title),
          onTap: () => _openSection(_sections.firstWhere((s) => s.title == title)),
        ),
      if (leftoverSections.isNotEmpty)
        _NavEntry(
          icon: Icons.apps_rounded,
          label: 'More',
          onTap: () => _openMore(leftoverSections),
        ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_roleLabel(session.userType)} Dashboard',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _dashboardKey.currentState?.reload(),
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
                NotificationBell(session: session),
                IconButton(
                  onPressed: _logout,
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          if (session.userType == 'teacher')
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: OfflineQuickActions(session: session),
            ),
          Expanded(
            child: NativeDashboard(key: _dashboardKey, session: session),
          ),
        ],
      ),
      bottomNavigationBar: navItems.length > 1
          ? BottomNavigationBar(
              currentIndex: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: gradient.first,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              onTap: (index) => navItems[index].onTap(),
              items: [
                for (final item in navItems)
                  BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
              ],
            )
          : null,
    );
  }
}

class _NavEntry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _NavEntry({required this.icon, required this.label, required this.onTap});
}

/// Bottom sheet listing every link inside a single [PortalSection].
class _SectionSheet extends StatelessWidget {
  final PortalSection section;
  final ValueChanged<PortalItem> onSelect;
  const _SectionSheet({required this.section, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: section.title,
      children: [
        for (final item in section.items) _SheetTile(item: item, onTap: () => _pick(context, item)),
      ],
    );
  }

  void _pick(BuildContext context, PortalItem item) {
    Navigator.of(context).pop();
    onSelect(item);
  }
}

/// Bottom sheet for "Chat Teacher" when there's more than one child —
/// picking one opens the chat with THAT child's class teacher.
class _ChildPickerSheet extends StatelessWidget {
  final List<Map> children;
  final ValueChanged<Map> onSelect;
  const _ChildPickerSheet({required this.children, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Chat with which child\'s teacher?',
      children: [
        for (final child in children)
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.navy.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_outline_rounded, color: AppColors.navy),
            ),
            title: Text(child['name'].toString(), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
            subtitle: Text('${child['class_name'] ?? ''}'),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.of(context).pop();
              onSelect(child);
            },
          ),
      ],
    );
  }
}

/// Bottom sheet listing every section not already on the bottom nav,
/// grouped under their own headings — replaces the old dedicated "More"
/// page with something that doesn't leave the dashboard.
class _MoreSheet extends StatelessWidget {
  final List<PortalSection> sections;
  final ValueChanged<PortalItem> onSelect;
  const _MoreSheet({required this.sections, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'More',
      scrollable: true,
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(
              section.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ),
          for (final item in section.items) _SheetTile(item: item, onTap: () => _pick(context, item)),
        ],
      ],
    );
  }

  void _pick(BuildContext context, PortalItem item) {
    Navigator.of(context).pop();
    onSelect(item);
  }
}

/// Shared rounded-top sheet frame used by both sheet types above.
class _SheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool scrollable;
  const _SheetShell({required this.title, required this.children, this.scrollable = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
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
          child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        ...children,
        SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
      ],
    );

    final decorated = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: content,
    );

    if (!scrollable) return decorated;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: ListView(controller: controller, padding: const EdgeInsets.symmetric(horizontal: 16), children: [content]),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final PortalItem item;
  final VoidCallback onTap;
  const _SheetTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.navy.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(item.icon, color: AppColors.navy, size: 20),
      ),
      title: Text(item.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
