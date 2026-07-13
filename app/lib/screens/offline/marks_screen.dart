import 'package:flutter/material.dart';

import '../../models/user_session.dart';
import '../../services/marks_service.dart';
import '../../theme/app_theme.dart';

class MarksScreen extends StatefulWidget {
  final UserSession session;
  const MarksScreen({super.key, required this.session});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

enum _Step { subject, sheet }

class _MarksScreenState extends State<MarksScreen> {
  _Step _step = _Step.subject;
  List<Map<String, dynamic>> _subjects = [];
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _selectedExam;
  bool _noCurrentExam = false;

  Map<String, dynamic>? _sheet; // {template, fields, locked, locked_reason, students}
  int _pendingCount = 0;
  bool _loading = true;

  // controllers[studentId][fieldKey] -> TextEditingController
  final Map<int, Map<String, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    for (final m in _controllers.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final cached = await MarksService.loadCachedSubjects(widget.session);
    if (mounted) setState(() { _subjects = cached; _loading = false; });
    try {
      final fresh = await MarksService.refreshSubjects(widget.session);
      if (mounted) setState(() => _subjects = fresh);
    } catch (_) {}
  }

  Future<void> _pickSubject(Map<String, dynamic> subject) async {
    setState(() { _selectedSubject = subject; _loading = true; _noCurrentExam = false; });

    final examId = await MarksService.resolveCurrentExamId(widget.session);
    if (examId == null) {
      if (mounted) setState(() { _loading = false; _noCurrentExam = true; });
      return;
    }

    final exams = await MarksService.loadCachedExams(widget.session);
    final examRow = exams.firstWhere((e) => int.tryParse('${e['exam_id']}') == examId, orElse: () => {'exam_id': examId});
    await _loadSheetForExam(examRow);
  }

  Future<void> _loadSheetForExam(Map<String, dynamic> exam) async {
    setState(() { _selectedExam = exam; _loading = true; _step = _Step.sheet; });
    final examId = int.parse('${exam['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;

    final cached = await MarksService.loadCachedSheet(widget.session, examId, classId, subjectId);
    if (cached != null && mounted) {
      setState(() { _sheet = cached; _loading = false; });
      _buildControllers();
    }

    try {
      final fresh = await MarksService.refreshSheet(widget.session, examId, classId, subjectId);
      if (mounted) {
        setState(() { _sheet = fresh; _loading = false; });
        _buildControllers();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    _refreshPendingCount();
  }

  void _buildControllers() {
    for (final m in _controllers.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    _controllers.clear();

    if (_sheet == null) return;
    final fields = (_sheet!['fields'] as List).cast<Map<String, dynamic>>();
    final students = (_sheet!['students'] as List).cast<Map<String, dynamic>>();
    for (final student in students) {
      final id = student['student_id'] as int;
      final values = (student['values'] as Map?)?.cast<String, dynamic>() ?? {};
      _controllers[id] = {
        for (final f in fields) f['key'] as String: TextEditingController(text: values[f['key']]?.toString() ?? ''),
      };
    }
  }

  Future<void> _refreshPendingCount() async {
    final examId = int.parse('${_selectedExam!['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;
    final count = await MarksService.pendingCount(widget.session, examId, classId, subjectId);
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _onFieldChanged(int studentId) async {
    final examId = int.parse('${_selectedExam!['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;
    final values = {for (final e in _controllers[studentId]!.entries) e.key: e.value.text};
    await MarksService.editScoreLocally(widget.session, examId, classId, subjectId, studentId, values, '');
    _refreshPendingCount();
  }

  Future<void> _submit() async {
    final examId = int.parse('${_selectedExam!['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;
    final sent = await MarksService.submitPending(widget.session, examId, classId, subjectId);
    if (!mounted) return;
    if (sent > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submitted $sent score sheet(s).')));
      _refreshPendingCount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No connection — scores stay saved on this device until you try again.')),
      );
    }
  }

  String get _title {
    switch (_step) {
      case _Step.subject:
        return 'Scores — Pick Subject';
      case _Step.sheet:
        return '${_selectedSubject!['subject_name']} · ${_selectedExam!['name'] ?? _selectedExam!['title'] ?? ''}';
    }
  }

  void _back() {
    setState(() {
      if (_step == _Step.sheet) {
        _step = _Step.subject;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked = _sheet?['locked'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, overflow: TextOverflow.ellipsis),
        leading: _step == _Step.subject ? null : IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _back),
        actions: [
          if (_step == _Step.sheet && _pendingCount > 0 && !locked)
            IconButton(icon: Badge(label: Text('$_pendingCount'), child: const Icon(Icons.cloud_upload_rounded)), tooltip: 'Submit scores', onPressed: _submit),
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.navy)) : _body(),
      floatingActionButton: _step == _Step.sheet && _pendingCount > 0 && !locked
          ? FloatingActionButton.extended(onPressed: _submit, icon: const Icon(Icons.cloud_upload_rounded), label: Text('Submit ($_pendingCount)'))
          : null,
    );
  }

  Widget _body() {
    final locked = _sheet?['locked'] == true;
    switch (_step) {
      case _Step.subject:
        if (_noCurrentExam) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fact_check_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    "No exam found for the current term/session.\nAsk an admin to create one on the website first.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => setState(() => _noCurrentExam = false), child: const Text('Back to subjects')),
                ],
              ),
            ),
          );
        }
        return _subjects.isEmpty
            ? const Center(child: Text('No subjects assigned to you yet.', style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _subjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _PickerTile(
                  icon: Icons.menu_book_rounded,
                  title: _subjects[i]['subject_name'].toString(),
                  subtitle: _subjects[i]['class_name'].toString(),
                  onTap: () => _pickSubject(_subjects[i]),
                ),
              );
      case _Step.sheet:
        if (_sheet == null) {
          return const Center(child: Text('Could not load this score sheet.', style: TextStyle(color: AppColors.textMuted)));
        }
        final fields = (_sheet!['fields'] as List).cast<Map<String, dynamic>>();
        final students = (_sheet!['students'] as List).cast<Map<String, dynamic>>();
        if (students.isEmpty) {
          return const Center(child: Text('No students found for this class.', style: TextStyle(color: AppColors.textMuted)));
        }
        return Column(
          children: [
            if (locked)
              Container(
                width: double.infinity,
                color: Colors.orange.withOpacity(0.12),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_sheet!['locked_reason']?.toString() ?? 'These marks are locked.', style: const TextStyle(fontSize: 12.5))),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _StudentScoreCard(
                  student: students[i],
                  fields: fields,
                  controllers: _controllers[students[i]['student_id']]!,
                  readOnly: locked,
                  onChanged: () => _onFieldChanged(students[i]['student_id'] as int),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _StudentScoreCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> fields;
  final Map<String, TextEditingController> controllers;
  final bool readOnly;
  final VoidCallback onChanged;

  const _StudentScoreCard({
    required this.student,
    required this.fields,
    required this.controllers,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(student['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          Text('Roll: ${student['roll']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final field in fields)
                SizedBox(
                  width: 68,
                  child: TextField(
                    controller: controllers[field['key']],
                    enabled: !readOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(labelText: field['label'].toString(), isDense: true, border: const OutlineInputBorder()),
                    onChanged: (_) => onChanged(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _PickerTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Icon(icon, color: AppColors.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
