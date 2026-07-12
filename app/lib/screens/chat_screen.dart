import 'dart:async';
import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final UserSession session;
  final int threadId;
  final String title;
  final List<Map<String, dynamic>> initialMessages;

  const ChatScreen({
    super.key,
    required this.session,
    required this.threadId,
    required this.title,
    this.initialMessages = const [],
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Map<String, dynamic>> _messages;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = List.of(widget.initialMessages);
    ChatService.markRead(widget.session, widget.threadId).catchError((_) {});
    if (_messages.isEmpty) _loadInitial();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final messages = await ChatService.fetchMessages(widget.session, widget.threadId);
      if (mounted) setState(() => _messages = messages);
      _scrollToBottom();
    } catch (_) {
      // stays empty — user can pull to refresh via the reload button
    }
  }

  Future<void> _poll() async {
    if (_messages.isEmpty) return _loadInitial();
    final sinceId = int.tryParse('${_messages.last['id']}') ?? 0;
    try {
      final fresh = await ChatService.fetchMessages(widget.session, widget.threadId, sinceId: sinceId);
      if (fresh.isNotEmpty && mounted) {
        setState(() => _messages.addAll(fresh));
        ChatService.markRead(widget.session, widget.threadId).catchError((_) {});
        _scrollToBottom();
      }
    } catch (_) {
      // offline — just try again on the next poll tick
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      await ChatService.sendMessage(widget.session, threadId: widget.threadId, body: text);
      await _poll();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't send — check your connection and try again.")),
        );
        _textController.text = text; // give it back so nothing is lost
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isMine(Map<String, dynamic> message) {
    return message['sender_type'] == widget.session.userType &&
        int.tryParse('${message['sender_id']}') == widget.session.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Say hello 👋', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: _messages[index], mine: _isMine(_messages[index])),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool mine;
  const _MessageBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : Colors.white,
          border: mine ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 2),
            bottomRight: Radius.circular(mine ? 2 : 14),
          ),
        ),
        child: Text(
          message['body']?.toString() ?? '',
          style: TextStyle(color: mine ? Colors.white : Colors.black87, fontSize: 14.5),
        ),
      ),
    );
  }
}
