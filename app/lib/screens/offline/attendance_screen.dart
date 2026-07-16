import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

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
  int _pendingCount = 0;
  bool _loading = true;
  bool _scanMode = false;
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
      if (_selectedClass != null) _reloadRoster();
    }
  }

  Future<void> _selectClass(Map<String, dynamic> cls) async {
    setState(() { _selectedClass = cls; _loading = true; _roster = []; });
    await _reloadRoster();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reloadRoster() async {
    final classId = _selectedClass!['class_id'] as int;
    final cached = await AttendanceService.loadCachedRoster(widget.session, classId, _today);
    if (mounted) setState(() => _roster = cached);
    try {
      final fresh = await AttendanceService.refreshRoster(widget.session, classId, _today);
      if (mounted) setState(() => _roster = fresh);
    } catch (_) {
      // offline — cached roster still shown
    }
  }

  Future<void> _onScanned(String code) async {
    final classId = _selectedClass!['class_id'] as int;
    final name = await AttendanceService.markScannedPresent(widget.session, classId, _today, code, _roster);
    if (!mounted) return;
    if (name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No student found for "$code" in this class.'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() {
      final idx = _roster.indexWhere((r) => r['roll'].toString().toLowerCase() == code.toLowerCase());
      if (idx != -1) _roster[idx] = {..._roster[idx], 'status': AttendanceStatus.present};
    });
    _refreshPendingCount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name marked Present'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _setStatus(int studentId, int status) async {
    final classId = _selectedClass!['class_id'] as int;
    setState(() {
      final idx = _roster.indexWhere((r) => r['student_id'] == studentId);
      if (idx != -1) _roster[idx] = {..._roster[idx], 'status': status};
    });
    final (synced, errorMessage) = await AttendanceService.setStatus(widget.session, classId, studentId, _today, status);
    if (!mounted) return;
    if (!synced) {
      _refreshPendingCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage != null
              ? 'Server rejected the save: $errorMessage'
              : "Couldn't reach the server — queued, will save once you're back online."),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1), backgroundColor: Colors.green),
      );
    }
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
        bottom: _selectedClass == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _ModeToggle(scanMode: _scanMode, onChanged: _onModeChanged),
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
          : _selectedClass == null
              ? _ClassPicker(classes: _classes, onSelect: _selectClass)
              : _scanMode
                  ? _ScanView(onScanned: _onScanned)
                  : _RosterList(roster: _roster, onSetStatus: _setStatus),
    );
  }

  void _onModeChanged(bool wantsScan) => setState(() => _scanMode = wantsScan);
}

class _ModeToggle extends StatelessWidget {
  final bool scanMode;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.scanMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(child: _segment(context, 'Manual', !scanMode, () => onChanged(false))),
          Expanded(child: _segment(context, 'Scan', scanMode, () => onChanged(true))),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: selected ? AppColors.navy : Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

/// Camera-based scanning, calling the API directly (same /api/attendance/mark
/// endpoint the Manual tab uses) — no WebView involved. The key fix versus
/// an earlier attempt: the runtime CAMERA permission is explicitly requested
/// here, before the camera ever tries to start. Skipping that step is what
/// caused the "Permission denied" error before — having the permission in
/// the manifest alone isn't enough on Android 6+, the app has to actually
/// ask.
class _ScanView extends StatefulWidget {
  final Future<void> Function(String) onScanned;
  const _ScanView({required this.onScanned});

  @override
  State<_ScanView> createState() => _ScanViewState();
}

enum _PermissionState { checking, granted, denied, permanentlyDenied }

class _ScanViewState extends State<_ScanView> {
  MobileScannerController? _controller;
  _PermissionState _permissionState = _PermissionState.checking;
  String? _cameraError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() {
        _permissionState = _PermissionState.granted;
        _controller = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
      });
    } else if (status.isPermanentlyDenied) {
      setState(() => _permissionState = _PermissionState.permanentlyDenied);
    } else {
      setState(() => _permissionState = _PermissionState.denied);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;
    _busy = true;
    widget.onScanned(code).then((_) {
      Future.delayed(const Duration(milliseconds: 1200), () => _busy = false);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_permissionState) {
      case _PermissionState.checking:
        return const Center(child: CircularProgressIndicator(color: AppColors.navy));
      case _PermissionState.denied:
        return _PermissionMessage(
          message: 'Camera permission is needed to scan barcodes.',
          buttonLabel: 'Grant Permission',
          onPressed: _requestPermission,
        );
      case _PermissionState.permanentlyDenied:
        return _PermissionMessage(
          message: "Camera permission was denied. You'll need to enable it from your phone's Settings for this app.",
          buttonLabel: 'Open Settings',
          onPressed: openAppSettings,
        );
      case _PermissionState.granted:
        if (_cameraError != null) {
          return _CameraErrorMessage(
            message: _cameraError!,
            onRetry: () {
              setState(() {
                _cameraError = null;
                _controller = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
              });
            },
          );
        }
        return Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _cameraError = '${error.errorCode}: ${error.errorDetails?.message ?? error.toString()}');
                });
                return const SizedBox.shrink();
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Point the camera at a student ID barcode', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _PermissionMessage extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;
  const _PermissionMessage({required this.message, required this.buttonLabel, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CameraErrorMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text('Camera error: $message', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
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
  final void Function(int studentId, int status) onSetStatus;
  const _RosterList({required this.roster, required this.onSetStatus});

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
        final studentId = student['student_id'] as int;
        final status = student['status'] as int?;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              _StatusChip(label: 'A', color: Colors.red, selected: status == AttendanceStatus.absent, onTap: () => onSetStatus(studentId, AttendanceStatus.absent)),
              const SizedBox(width: 6),
              _StatusChip(label: 'H', color: Colors.orange, selected: status == AttendanceStatus.halfDay, onTap: () => onSetStatus(studentId, AttendanceStatus.halfDay)),
              const SizedBox(width: 6),
              _StatusChip(label: 'P', color: Colors.green, selected: status == AttendanceStatus.present, onTap: () => onSetStatus(studentId, AttendanceStatus.present)),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: selected ? 0 : 1),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}
