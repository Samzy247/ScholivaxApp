import 'package:flutter/material.dart';

import '../../models/user_session.dart';
import '../../services/api_client.dart';
import '../../services/dashboard_service.dart';
import 'admin_dashboard_body.dart';
import 'dashboard_widgets.dart';
import 'parent_dashboard_body.dart';
import 'student_dashboard_body.dart';
import 'teacher_dashboard_body.dart';
import '../no_internet_view.dart';

class NativeDashboard extends StatefulWidget {
  final UserSession session;
  const NativeDashboard({super.key, required this.session});

  @override
  State<NativeDashboard> createState() => NativeDashboardState();
}

class NativeDashboardState extends State<NativeDashboard> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardService.fetchSummary(widget.session);
  }

  /// Exposed so the Home tab's refresh button can trigger a reload.
  Future<void> reload() async {
    final next = DashboardService.fetchSummary(widget.session);
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is NoConnectionException) {
            return NoInternetView(onRetry: () => reload());
          }
          final message = error is ApiException ? error.message : 'Something went wrong loading your dashboard.';
          return DashboardErrorView(message: message, onRetry: () => reload());
        }

        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: reload,
          child: switch (widget.session.userType) {
            'admin' => AdminDashboardBody(data: data),
            'teacher' => TeacherDashboardBody(data: data),
            'parent' => ParentDashboardBody(data: data),
            _ => StudentDashboardBody(data: data),
          },
        );
      },
    );
  }
}
