import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/chat_service.dart';

class ChatBadgeIcon extends StatefulWidget {
  final UserSession session;
  final IconData icon;
  const ChatBadgeIcon({super.key, required this.session, required this.icon});

  @override
  State<ChatBadgeIcon> createState() => ChatBadgeIconState();
}

class ChatBadgeIconState extends State<ChatBadgeIcon> with WidgetsBindingObserver {
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

  /// Called by the dashboard right after returning from any chat screen,
  /// since opening/reading messages there doesn't rebuild this widget on
  /// its own — the badge would otherwise only clear on the next app
  /// resume-from-background instead of immediately.
  Future<void> refresh() => _poll();

  Future<void> _poll() async {
    final count = await ChatService.unreadCount(widget.session);
    if (mounted) setState(() => _unread = count);
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: _unread > 0,
      label: Text(_unread > 9 ? '9+' : '$_unread'),
      child: Icon(widget.icon),
    );
  }
}
