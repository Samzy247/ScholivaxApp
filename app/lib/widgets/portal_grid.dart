import 'package:flutter/material.dart';
import '../constants/portal_menu.dart';
import '../models/user_session.dart';
import '../screens/webview_screen.dart';
import '../theme/app_theme.dart';

/// A titled grid of [PortalItem] cards. Tapping one opens that page of the
/// full website inside [WebViewScreen].
class PortalSectionView extends StatelessWidget {
  final PortalSection section;
  final UserSession session;
  final Color accent;

  const PortalSectionView({
    super.key,
    required this.section,
    required this.session,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: section.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final item = section.items[index];
            return _PortalTile(item: item, session: session, accent: accent);
          },
        ),
      ],
    );
  }
}

class _PortalTile extends StatelessWidget {
  final PortalItem item;
  final UserSession session;
  final Color accent;

  const _PortalTile({required this.item, required this.session, required this.accent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WebViewScreen(title: item.label, path: item.path, session: session),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: accent, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}

/// The three native, offline-first cards (Circulars, Attendance, Marks) —
/// these do NOT open the WebView. They stay as placeholders here until
/// Phase 3 wires up local SQLite storage so they work without internet.
class OfflineQuickActions extends StatelessWidget {
  final VoidCallback? onTap;

  const OfflineQuickActions({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tiles = const [
      (icon: Icons.campaign_outlined, label: 'Circulars'),
      (icon: Icons.qr_code_scanner_rounded, label: 'Attendance'),
      (icon: Icons.grade_outlined, label: 'Scores / Marks'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Offline Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Works without internet', style: TextStyle(fontSize: 10.5, color: Color(0xFF92600A), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: tiles
              .map((t) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _OfflineTile(icon: t.icon, label: t.label, onTap: onTap),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _OfflineTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _OfflineTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offline support for this is coming in the next update.')),
                ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: AppColors.navy),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
