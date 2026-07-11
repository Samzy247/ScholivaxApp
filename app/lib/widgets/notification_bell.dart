import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../screens/notifications_screen.dart';
import '../services/notifications_service.dart';

class NotificationBell extends StatefulWidget {
  final UserSession session;
  final Color color;
  const NotificationBell({super.key, required this.session, this.color = Colors.white});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> with WidgetsBindingObserver {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _poll();
  }

  Future<void> _poll() async {
    final count = await NotificationsService.unreadCount(widget.session);
    if (mounted) setState(() => _unread = count);
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationsScreen(session: widget.session)),
    );
    _poll(); // refresh badge in case things got marked read
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _open,
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 9 ? '9+' : '$_unread'),
        child: Icon(Icons.notifications_outlined, color: widget.color),
      ),
    );
  }
}
