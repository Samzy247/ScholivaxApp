import 'package:flutter/material.dart';
import '../constants/portal_menu.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';
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
    await AuthService.logout(widget.session);
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SchoolSelectScreen()),
      (route) => false,
    );
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  void _scrollToSection(String title) {
    final ctx = _sectionKeys[title]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    }
  }

  /// A handful of section titles surfaced as bottom-nav shortcuts, curated
  /// per role. Everything is still reachable by scrolling — these are just
  /// quick jumps, same idea as the reference dashboards' bottom tab bar.
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
      _NavEntry(icon: Icons.home_rounded, label: 'Home', onTap: _scrollToTop),
      for (final title in shortcuts)
        _NavEntry(
          icon: _sections.firstWhere((s) => s.title == title).items.first.icon,
          label: title.split(' ').first,
          onTap: () => _scrollToSection(title),
        ),
      if (_sections.isNotEmpty)
        _NavEntry(
          icon: Icons.apps_rounded,
          label: 'More',
          onTap: () => _scrollToSection(_sections.last.title),
        ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _Header(session: session, gradient: gradient, roleLabel: _roleLabel(session.userType), onLogout: _logout)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  OfflineQuickActions(),
                  const SizedBox(height: 28),
                  for (final section in _sections) ...[
                    Container(key: _sectionKeys[section.title]),
                    PortalSectionView(section: section, session: session, accent: accent),
                    const SizedBox(height: 28),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: navItems.length > 1
          ? BottomNavigationBar(
              currentIndex: _navIndex.clamp(0, navItems.length - 1),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: accent,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              onTap: (index) {
                setState(() => _navIndex = index);
                navItems[index].onTap();
              },
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

class _Header extends StatelessWidget {
  final UserSession session;
  final List<Color> gradient;
  final String roleLabel;
  final VoidCallback onLogout;

  const _Header({required this.session, required this.gradient, required this.roleLabel, required this.onLogout});

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
                    Text(
                      '$roleLabel Dashboard',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
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
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications yet.')),
                ),
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    (session.name?.isNotEmpty == true ? session.name![0] : '?').toUpperCase(),
                    style: TextStyle(color: gradient.first, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${session.name ?? roleLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap any card below to open it',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
