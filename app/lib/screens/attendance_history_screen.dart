import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/parent_service.dart';
import '../theme/app_theme.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final UserSession session;
  final int studentId;
  final String studentName;

  const AttendanceHistoryScreen({
    super.key,
    required this.session,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _range = '30';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ParentService.fetchAttendanceHistory(widget.session, widget.studentId, _range);
      if (!mounted) return;
      setState(() {
        _records = result['records'];
        _summary = result['summary'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = "Couldn't load attendance history."; });
    }
  }

  void _setRange(String range) {
    if (range == _range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.studentName} — Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(child: _RangeChip(label: 'Last 7 days', selected: _range == '7', onTap: () => _setRange('7'))),
                const SizedBox(width: 8),
                Expanded(child: _RangeChip(label: 'Last 30 days', selected: _range == '30', onTap: () => _setRange('30'))),
                const SizedBox(width: 8),
                Expanded(child: _RangeChip(label: 'All time', selected: _range == 'all', onTap: () => _setRange('all'))),
              ],
            ),
          ),
          if (!_loading && _error == null) _SummaryRow(summary: _summary),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textMuted)))
                    : _records.isEmpty
                        ? const Center(child: Text('No attendance records in this range.', style: TextStyle(color: AppColors.textMuted)))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => _HistoryRow(record: _records[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.navy : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textMuted),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _summaryCard('Present', summary['present'], const Color(0xFF16A34A))),
          const SizedBox(width: 8),
          Expanded(child: _summaryCard('Half Day', summary['half_day'], const Color(0xFFD97706))),
          const SizedBox(width: 8),
          Expanded(child: _summaryCard('Absent', summary['absent'], const Color(0xFFDC2626))),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text('${value ?? 0}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> record;
  const _HistoryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as int?;
    late final String label;
    late final Color color;
    if (status == 2) {
      label = 'Present';
      color = const Color(0xFF16A34A);
    } else if (status == 1) {
      label = 'Half Day';
      color = const Color(0xFFD97706);
    } else {
      label = 'Absent';
      color = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(child: Text('${record['date']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}
