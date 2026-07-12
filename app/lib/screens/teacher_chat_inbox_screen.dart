import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class TeacherChatInboxScreen extends StatefulWidget {
  final UserSession session;
  const TeacherChatInboxScreen({super.key, required this.session});

  @override
  State<TeacherChatInboxScreen> createState() => _TeacherChatInboxScreenState();
}

class _TeacherChatInboxScreenState extends State<TeacherChatInboxScreen> {
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final threads = await ChatService.fetchInbox(widget.session);
      if (mounted) setState(() { _threads = threads; _loading = false; });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = "Couldn't load messages — check your connection.";
      });
    }
  }

  Future<void> _open(Map<String, dynamic> thread) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          session: widget.session,
          threadId: thread['thread_id'] as int,
          title: thread['student_name']?.toString() ?? 'Parent',
        ),
      ),
    );
    _load(); // refresh unread counts after coming back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _threads.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.forum_outlined, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Center(child: Text('No messages from parents yet', style: TextStyle(color: AppColors.textMuted))),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _threads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => _ThreadTile(thread: _threads[index], onTap: () => _open(_threads[index])),
                        ),
                ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final Map<String, dynamic> thread;
  final VoidCallback onTap;
  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = (thread['unread_count'] as int?) ?? 0;
    return Material(
      color: unread > 0 ? AppColors.surfaceAlt : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.navy.withOpacity(0.1),
                child: const Icon(Icons.person_outline_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${thread['student_name']}'s parent",
                      style: TextStyle(fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600, fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (thread['last_message']?.toString().isNotEmpty ?? false) ? thread['last_message'].toString() : 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                  child: Text('$unread', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
