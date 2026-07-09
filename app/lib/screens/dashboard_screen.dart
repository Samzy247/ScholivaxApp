import 'package:flutter/material.dart';

import '../constants/portal_menu.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../services/web_cookie_bridge.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/native_dashboard.dart';
import '../widgets/portal_grid.dart';
import 'school_select_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserSession session;
  const DashboardScreen({super.key, required this.session});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scrollController = ScrollController();
  late final List<PortalSection> _sections;
  late final Map<String, GlobalKey> _sectionKeys;
  int _navIndex = 0;
  int _tabIndex = 0; // 0 = Home (live analytics), 1 = Menu (portal grid)

  @override
  void initState() {
    super.initState();
    _sections = PortalMenu.forRole(widget.session.userType);
    _sectionKeys = {for (final s in _sections) s.title: GlobalKey()};
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    await SessionStore.clear();
    await WebCookieBridge.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SchoolSelectScreen()),
      (route) => false,
    );
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _goHome() {
    setState(() {
      _navIndex = 0;
      _tabIndex = 0;
    });
  }

  void _scrollToSection(int navIndex, String title) {
    setState(() {
      _navIndex = navIndex;
      _tabIndex = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _sectionKeys[title]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  void _openMenu(int navIndex) {
    setState(() {
      _navIndex = navIndex;
      _tabIndex = 1;
    });
  }

  /// A handful of section titles surfaced as bottom-nav shortcuts, curated
  /// per role. Tapping one jumps into the Menu tab, scrolled to that
  /// section. Everything is still reachable by scrolling the Menu tab too.
  List<String> get _shortcutTitles {
    switch (widget.session.userType) {
      case 'admin':
        return const ['Students', 'Staff & HR', 'Exams & CBT'];
      case 'teacher':
        return const ['Classes', 'Exams & CBT', 'My Work'];
      case 'student':
        return const ['Academics', 'Exams', 'Classes'];
      case 'parent':
        return const ['My Child', 'Fees & Profile'];
      default:
        return const [];
    }
  }

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
    final accent = gradient.first;
    final shortcuts = _shortcutTitles;

    final navItems = <_NavEntry>[
      _NavEntry(icon: Icons.home_rounded, label: 'Home', onTap: _goHome),
      for (int i = 0; i < shortcuts.length; i++)
        _NavEntry(
          icon: _sections.firstWhere((s) => s.title == shortcuts[i]).items.first.icon,
          label: shortcuts[i].split(' ').first,
          onTap: () => _scrollToSection(i + 1, shortcuts[i]),
        ),
      if (_sections.isNotEmpty)
        _NavEntry(
          icon: Icons.apps_rounded,
          label: 'More',
          onTap: () => _openMenu(shortcuts.length + 1),
        ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _HomeAnalyticsTab(session: session, gradient: gradient, roleLabel: _roleLabel(session.userType), onLogout: _logout),
          _MenuTab(
            session: session,
            gradient: gradient,
            accent: accent,
            roleLabel: _roleLabel(session.userType),
            onLogout: _logout,
            onRefresh: _refresh,
            scrollController: _scrollController,
            sections: _sections,
            sectionKeys: _sectionKeys,
          ),
        ],
      ),
      bottomNavigationBar: navItems.length > 1
          ? BottomNavigationBar(
              currentIndex: _navIndex.clamp(0, navItems.length - 1),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: accent,
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

/// Home tab — loads the ACTUAL website dashboard page for this role (the
/// same charts/analytics visible in a browser), live, inside the
/// authenticated in-app WebView. This is intentionally not rebuilt
/// natively: it's the real page, so it always matches the site exactly.
class _HomeAnalyticsTab extends StatefulWidget {
  final UserSession session;
  final List<Color> gradient;
  final String roleLabel;
  final VoidCallback onLogout;

  const _HomeAnalyticsTab({
    required this.session,
    required this.gradient,
    required this.roleLabel,
    required this.onLogout,
  });

  @override
  State<_HomeAnalyticsTab> createState() => _HomeAnalyticsTabState();
}

class _HomeAnalyticsTabState extends State<_HomeAnalyticsTab> {
  final _dashboardKey = GlobalKey<NativeDashboardState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.roleLabel} Dashboard',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => _dashboardKey.currentState?.reload(),
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: widget.onLogout,
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: NativeDashboard(key: _dashboardKey, session: widget.session),
        ),
      ],
    );
  }
}

/// Menu tab — the native card grid used to jump to any page of the site
/// (Subjects, HRM, CBT, etc.), plus the offline-first quick actions.
class _MenuTab extends StatelessWidget {
  final UserSession session;
  final List<Color> gradient;
  final Color accent;
  final String roleLabel;
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final List<PortalSection> sections;
  final Map<String, GlobalKey> sectionKeys;

  const _MenuTab({
    required this.session,
    required this.gradient,
    required this.accent,
    required this.roleLabel,
    required this.onLogout,
    required this.onRefresh,
    required this.scrollController,
    required this.sections,
    required this.sectionKeys,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: _MenuHeader(session: session, gradient: gradient, roleLabel: roleLabel, onLogout: onLogout)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                OfflineQuickActions(),
                const SizedBox(height: 28),
                for (final section in sections) ...[
                  Container(key: sectionKeys[section.title]),
                  PortalSectionView(section: section, session: session, accent: accent),
                  const SizedBox(height: 28),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  final UserSession session;
  final List<Color> gradient;
  final String roleLabel;
  final VoidCallback onLogout;

  const _MenuHeader({required this.session, required this.gradient, required this.roleLabel, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.schoolName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap any card below to open it',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
