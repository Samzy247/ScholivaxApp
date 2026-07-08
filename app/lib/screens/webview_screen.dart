import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/no_internet_view.dart';

/// Opens a single page of the full Scholivax website inside the app.
///
/// [path] is appended to the logged-in school's base URL, e.g.
/// `/admin/hrm` -> `https://greenfield.scholivax.top/admin/hrm`.
///
/// Uses flutter_inappwebview — the SAME engine as [WebDashboardScreen] —
/// so it shares that engine's native CookieManager cookie store. The
/// `ci_session` cookie set at login time (see WebCookieBridge) is already
/// present here, so this page loads straight in, already logged in, with
/// no query-param bridging needed.
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
  InAppWebViewController? _controller;
  bool _loading = true;
  bool _noConnection = false;
  double _progress = 0;

  String get _url => '${widget.session.baseUrl}${widget.path}';

  Future<void> _checkConnectionThenLoad() async {
    final result = await Connectivity().checkConnectivity();
    final offline = result.contains(ConnectivityResult.none) || result.isEmpty;
    if (!mounted) return;
    setState(() => _noConnection = offline);
    if (!offline) {
      await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(_url)));
    }
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
            onPressed: _checkConnectionThenLoad,
          ),
        ],
        bottom: _progress > 0 && _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress, minHeight: 2),
              )
            : null,
      ),
      body: _noConnection
          ? NoInternetView(onRetry: _checkConnectionThenLoad)
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_url)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useOnLoadResource: false,
                    supportZoom: false,
                    domStorageEnabled: true,
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
                  onProgressChanged: (controller, progress) {
                    setState(() => _progress = progress / 100);
                  },
                  onLoadStop: (controller, url) {
                    if (mounted) setState(() => _loading = false);
                  },
                  onReceivedError: (controller, request, error) {
                    if (mounted && (request.isForMainFrame ?? true)) {
                      setState(() {
                        _loading = false;
                        _noConnection = true;
                      });
                    }
                  },
                ),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.navy),
                  ),
              ],
            ),
    );
  }
}
