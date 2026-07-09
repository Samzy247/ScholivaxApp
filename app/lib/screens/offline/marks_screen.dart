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

enum _Step { subject, exam, roster }

class _MarksScreenState extends State<MarksScreen> {
  _Step _step = _Step.subject;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _exams = [];
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _selectedExam;
  List<Map<String, dynamic>> _roster = [];
  int _pendingCount = 0;
  bool _loading = true;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
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
    setState(() { _selectedSubject = subject; _loading = true; _step = _Step.exam; });
    final cached = await MarksService.loadCachedExams(widget.session);
    if (mounted) setState(() { _exams = cached; _loading = false; });
    try {
      final fresh = await MarksService.refreshExams(widget.session);
      if (mounted) setState(() => _exams = fresh);
    } catch (_) {}
  }

  Future<void> _pickExam(Map<String, dynamic> exam) async {
    setState(() { _selectedExam = exam; _loading = true; _step = _Step.roster; });
    final examId = int.parse('${exam['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;

    final cached = await MarksService.loadCachedRoster(widget.session, examId, classId, subjectId);
    if (mounted) { setState(() { _roster = cached; _loading = false; }); _buildControllers(); }

    try {
      final fresh = await MarksService.refreshRoster(widget.session, examId, classId, subjectId);
      if (mounted) { setState(() => _roster = fresh); _buildControllers(); }
    } catch (_) {}
    _refreshPendingCount();
  }

  void _buildControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    for (final student in _roster) {
      final id = student['student_id'] as int;
      _controllers[id] = TextEditingController(text: student['exam_score']?.toString() ?? '');
    }
  }

  Future<void> _refreshPendingCount() async {
    final examId = int.parse('${_selectedExam!['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;
    final count = await MarksService.pendingCount(widget.session, examId, classId, subjectId);
    if (mounted) setState(() => _pendingCount = count);
  }

  Future<void> _onScoreChanged(int studentId, String score) async {
    final examId = int.parse('${_selectedExam!['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;
    await MarksService.editScoreLocally(widget.session, examId, classId, subjectId, studentId, score, '');
    _refreshPendingCount();
  }

  Future<void> _submit() async {
    final examId = int.parse('${_selectedExam!['exam_id']}');
    final classId = _selectedSubject!['class_id'] as int;
    final subjectId = _selectedSubject!['subject_id'] as int;
    final sent = await MarksService.submitPending(widget.session, examId, classId, subjectId);
    if (!mounted) return;
    if (sent > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submitted $sent score(s).')));
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
      case _Step.exam:
        return 'Scores — Pick Exam';
      case _Step.roster:
        return '${_selectedSubject!['subject_name']} · ${_selectedExam!['name'] ?? _selectedExam!['title'] ?? ''}';
    }
  }

  void _back() {
    setState(() {
      if (_step == _Step.roster) {
        _step = _Step.exam;
      } else if (_step == _Step.exam) {
        _step = _Step.subject;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, overflow: TextOverflow.ellipsis),
        leading: _step == _Step.subject ? null : IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _back),
        actions: [
          if (_step == _Step.roster && _pendingCount > 0)
            IconButton(icon: Badge(label: Text('$_pendingCount'), child: const Icon(Icons.cloud_upload_rounded)), tooltip: 'Submit scores', onPressed: _submit),
          IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Home', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.navy)) : _body(),
      floatingActionButton: _step == _Step.roster && _pendingCount > 0
          ? FloatingActionButton.extended(onPressed: _submit, icon: const Icon(Icons.cloud_upload_rounded), label: Text('Submit ($_pendingCount)'))
          : null,
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.subject:
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
      case _Step.exam:
        return _exams.isEmpty
            ? const Center(child: Text('No exams found.', style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _exams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _PickerTile(
                  icon: Icons.fact_check_rounded,
                  title: (_exams[i]['name'] ?? _exams[i]['title'] ?? 'Exam').toString(),
                  subtitle: null,
                  onTap: () => _pickExam(_exams[i]),
                ),
              );
      case _Step.roster:
        if (_roster.isEmpty) {
          return const Center(child: Text('No students found for this class.', style: TextStyle(color: AppColors.textMuted)));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: _roster.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final student = _roster[i];
            final id = student['student_id'] as int;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Roll: ${student['roll']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _controllers[id],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(hintText: 'Score', isDense: true, border: OutlineInputBorder()),
                      onChanged: (value) => _onScoreChanged(id, value),
                    ),
                  ),
                ],
              ),
            );
          },
        );
    }
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
