import 'package:flutter/material.dart';

import '../../models/user_session.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  final UserSession session;
  const AttendanceScreen({super.key, required this.session});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _selectedClass;
  List<Map<String, dynamic>> _roster = [];
  Set<String> _markedToday = {};
  int _pendingCount = 0;
  bool _loading = true;
  final String _today = DateTime.now().toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final cached = await AttendanceService.loadCachedClasses(widget.session);
    if (mounted) setState(() { _classes = cached; _loading = false; });
    try {
      final fresh = await AttendanceService.refreshClasses(widget.session);
      if (mounted) setState(() => _classes = fresh);
    } catch (_) {
      // offline — cached list (if any) is still usable
    }
    _refreshPendingCount();
    _trySync();
  }

  Future<void> _refreshPendingCount() async {
    final pending = await AttendanceService.loadPending(widget.session);
    if (mounted) setState(() => _pendingCount = pending.length);
  }

  Future<void> _trySync() async {
    final synced = await AttendanceService.syncPending(widget.session);
    if (synced > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Synced $synced queued attendance record(s).')));
      _refreshPendingCount();
    }
  }

  Future<void> _selectClass(Map<String, dynamic> cls) async {
    setState(() { _selectedClass = cls; _loading = true; _roster = []; });
    final classId = cls['class_id'] as int;

    final cached = await AttendanceService.loadCachedRoster(widget.session, classId);
    final marked = await AttendanceService.loadMarkedRolls(widget.session, classId, _today);
    if (mounted) setState(() { _roster = cached; _markedToday = marked; _loading = false; });

    try {
      final fresh = await AttendanceService.refreshRoster(widget.session, classId);
      if (mounted) setState(() => _roster = fresh);
    } catch (_) {
      // offline — cached roster still shown
    }
  }

  Future<void> _markPresent(String roll) async {
    final classId = _selectedClass!['class_id'] as int;
    setState(() => _markedToday = {..._markedToday, roll}); // instant feedback
    final synced = await AttendanceService.markPresent(widget.session, classId, roll, _today);
    if (!synced) _refreshPendingCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedClass == null ? 'Attendance' : _selectedClass!['name']),
        leading: _selectedClass == null
            ? null
            : IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => setState(() => _selectedClass = null)),
        actions: [
          if (_pendingCount > 0)
            IconButton(
              icon: Badge(label: Text('$_pendingCount'), child: const Icon(Icons.sync_rounded)),
              tooltip: 'Sync queued records',
              onPressed: _trySync,
            ),
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : _selectedClass == null
              ? _ClassPicker(classes: _classes, onSelect: _selectClass)
              : _RosterList(roster: _roster, markedRolls: _markedToday, onMark: _markPresent),
    );
  }
}

class _ClassPicker extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _ClassPicker({required this.classes, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(child: Text('No classes assigned to you yet.', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cls = classes[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelect(cls),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  const Icon(Icons.class_rounded, color: AppColors.navy),
                  const SizedBox(width: 12),
                  Expanded(child: Text(cls['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RosterList extends StatelessWidget {
  final List<Map<String, dynamic>> roster;
  final Set<String> markedRolls;
  final ValueChanged<String> onMark;
  const _RosterList({required this.roster, required this.markedRolls, required this.onMark});

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) {
      return const Center(child: Text('No students found for this class.', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: roster.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = roster[index];
        final roll = student['roll'].toString();
        final present = markedRolls.contains(roll);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            title: Text(student['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Roll: $roll'),
            trailing: present
                ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                : OutlinedButton(onPressed: () => onMark(roll), child: const Text('Mark Present')),
          ),
        );
      },
    );
  }
}
