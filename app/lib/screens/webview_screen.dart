import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/no_internet_view.dart';

/// Opens a single page of the full Scholivax website inside the app.
///
/// [path] is appended to the logged-in school's base URL, e.g.
/// `/admin/hrm` -> `https://greenfield.scholivax.top/admin/hrm`.
///
/// The user's API [session] token is passed along as `app_token` /
/// `app_uid` query params so the backend can — once a small session-bridge
/// endpoint is added there — recognise the app user and skip the web
/// login form. Until that bridge exists, the site will simply show its
/// own login page the first time, which still works fine.
class WebViewScreen extends StatefulWidget {
  final String title;
  final String path;
  final UserSession session;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.path,
    required this.session,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _noConnection = false;

  String get _url {
    final session = widget.session;
    final uri = Uri.parse('${session.baseUrl}${widget.path}');
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'app_token': session.token,
      'app_uid': session.userId.toString(),
    }).toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    final result = await Connectivity().checkConnectivity();
    final offline = result.contains(ConnectivityResult.none) || result.isEmpty;
    if (offline) {
      setState(() => _noConnection = true);
      return;
    }
    setState(() => _noConnection = false);
    await _controller.loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Back to dashboard',
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: _load,
          ),
        ],
      ),
      body: _noConnection
          ? NoInternetView(onRetry: _load)
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.navy),
                  ),
              ],
            ),
    );
  }
}
