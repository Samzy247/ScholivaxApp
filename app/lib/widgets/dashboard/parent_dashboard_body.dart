import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'dashboard_widgets.dart';

class ParentDashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const ParentDashboardBody({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.headerGradient('parent').first;
    final children = (data['children'] as List).cast<Map>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        StatGrid(cards: [
          StatCard(icon: Icons.family_restroom_rounded, value: '${children.length}', label: 'Children Enrolled', color: accent),
        ]),
        const SizedBox(height: 20),
        SectionCard(
          title: 'My Children',
          accent: accent,
          child: children.isEmpty
              ? const Text('No children linked to this account yet.', style: TextStyle(color: Colors.grey))
              : Column(
                  children: [
                    for (final c in children)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFE0F2FE),
                            child: Text(
                              (c['name'] as String? ?? '?').isNotEmpty ? (c['name'] as String).substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${c['name']}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              Text('${c['class_name']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            ]),
                          ),
                        ]),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
