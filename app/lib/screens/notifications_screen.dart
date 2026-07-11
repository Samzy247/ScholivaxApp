import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/user_session.dart';
import '../services/notifications_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final UserSession session;
  const NotificationsScreen({super.key, required this.session});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = await NotificationsService.loadCached(widget.session);
    if (mounted) setState(() { _notifications = cached; _loading = false; });
    try {
      final fresh = await NotificationsService.refresh(widget.session);
      if (mounted) setState(() => _notifications = fresh);
    } catch (_) {
      // offline — cached list still shown
    }
  }

  Future<void> _markAllRead() async {
    await NotificationsService.markRead(widget.session);
    final cached = await NotificationsService.loadCached(widget.session);
    if (mounted) setState(() => _notifications = cached);
  }

  Future<void> _tap(AppNotification n) async {
    if (!n.read) {
      await NotificationsService.markRead(widget.session, id: n.id);
      final cached = await NotificationsService.loadCached(widget.session);
      if (mounted) setState(() => _notifications = cached);
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailSheet(notification: n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.read);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Center(child: Text('No notifications yet', style: TextStyle(color: AppColors.textMuted))),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _NotificationTile(notification: _notifications[index], onTap: () => _tap(_notifications[index])),
                    ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.read ? Colors.white : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!notification.read)
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700, fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final AppNotification notification;
  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: controller,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(notification.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(notification.createdAt, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 16),
            Text(notification.body, style: const TextStyle(fontSize: 14.5, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
