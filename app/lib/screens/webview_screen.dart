import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_session.dart';
import '../widgets/no_internet_view.dart';
import '../widgets/full_page_loader.dart';

/// Opens a single page of the full Scholivax website inside the app.
///
/// [path] is appended to the logged-in school's base URL, e.g.
/// `/admin/hrm` -> `https://greenfield.scholivax.top/admin/hrm`.
///
/// Uses flutter_inappwebview — the same engine used for the dashboard's
/// own embedded pages — so it shares that engine's native CookieManager
/// cookie store. The `ci_session` cookie set at login time (see
/// WebCookieBridge) is already present here, so this page loads straight
/// in, already logged in, with no query-param bridging needed.
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

  // Hides the website's own page-title/breadcrumb/"Visit Website" header
  // block (application/views/backend/page_info.php, class `.bg-title`) —
  // the app already shows the page title in its own AppBar, so this row
  // is redundant inside the WebView and just wastes vertical space.
  static const _hideChromeJs = '''
    (function() {
      if (document.getElementById('scholivax-app-hide-chrome')) return;
      var style = document.createElement('style');
      style.id = 'scholivax-app-hide-chrome';
      style.innerHTML = '.bg-title { display: none !important; }';
      document.head.appendChild(style);
    })();
  ''';

  Future<void> _checkConnectionThenLoad() async {
    final result = await Connectivity().checkConnectivity();
    final offline = result.contains(ConnectivityResult.none) || result.isEmpty;
    if (!mounted) return;
    setState(() {
      _noConnection = offline;
      if (!offline) _loading = true;
    });
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
                  onPermissionRequest: (controller, request) async {
                    // Needed for pages like /teacher/attendance_scan, which
                    // use the browser's own camera access (getUserMedia) for
                    // barcode scanning. Without this, flutter_inappwebview
                    // denies every permission request by default, which is
                    // exactly the "Permission denied" error this fixes.
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() => _progress = progress / 100);
                  },
                  onLoadStop: (controller, url) {
                    controller.evaluateJavascript(source: _hideChromeJs);
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
                Positioned.fill(
                  child: FullPageLoader(visible: _loading, label: 'Loading ${widget.title}…'),
                ),
              ],
            ),
    );
  }
}
