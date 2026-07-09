import 'package:flutter/material.dart';

import '../../models/circular.dart';
import '../../models/user_session.dart';
import '../../services/circulars_service.dart';
import '../../theme/app_theme.dart';

class CircularsScreen extends StatefulWidget {
  final UserSession session;
  const CircularsScreen({super.key, required this.session});

  @override
  State<CircularsScreen> createState() => _CircularsScreenState();
}

class _CircularsScreenState extends State<CircularsScreen> {
  List<Circular> _circulars = [];
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = await CircularsService.loadCached(widget.session);
    if (mounted) setState(() { _circulars = cached; _loading = false; });
    await _refresh(silent: true);
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final fresh = await CircularsService.refresh(widget.session);
      if (mounted) setState(() { _circulars = fresh; _offline = false; });
    } catch (_) {
      if (mounted) setState(() => _offline = true);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh — showing saved circulars.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Circulars'),
        actions: [
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _circulars.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.campaign_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Center(child: Text('No circulars yet', style: TextStyle(color: AppColors.textMuted))),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _circulars.length + (_offline ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (_offline && index == 0) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(child: Text('Offline — showing saved circulars', style: TextStyle(fontSize: 12.5))),
                              ],
                            ),
                          );
                        }
                        final circular = _circulars[index - (_offline ? 1 : 0)];
                        return _CircularCard(circular: circular);
                      },
                    ),
            ),
    );
  }
}

class _CircularCard extends StatelessWidget {
  final Circular circular;
  const _CircularCard({required this.circular});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CircularDetailSheet(circular: circular),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.navy.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.campaign_rounded, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circular.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(circular.date, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularDetailSheet extends StatelessWidget {
  final Circular circular;
  const _CircularDetailSheet({required this.circular});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: controller,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(circular.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('${circular.reference} · ${circular.date}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 16),
            Text(circular.content, style: const TextStyle(fontSize: 14.5, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
