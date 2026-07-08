import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_session.dart';
import '../services/session_store.dart';
import '../widgets/no_internet_view.dart';
import 'school_select_screen.dart';

/// This is the app's main screen after login — an embedded WebView showing
/// the ACTUAL website (same one you use in a browser), authenticated via
/// the same session cookie a browser login would get. Every feature that
/// exists on the website automatically exists here too, with no per-page
/// rebuilding. The only screens built natively are the offline-capable
/// ones (attendance scanning, score entry — Phase 3), which live outside
/// this WebView entirely.
class WebDashboardScreen extends StatefulWidget {
  final UserSession session;
  final List<Cookie> sessionCookies;

  const WebDashboardScreen({
    super.key,
    required this.session,
    required this.sessionCookies,
  });

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefresh;
  bool _cookiesReady = false;
  bool _noConnection = false;
  double _progress = 0;

  // Injects Poppins across the site's pages, on top of whatever font
  // the website's own CSS specifies.
  static const _fontInjectionJs = '''
    (function() {
      if (document.getElementById('scholivax-app-font')) return;
      var link = document.createElement('link');
      link.id = 'scholivax-app-font';
      link.rel = 'stylesheet';
      link.href = 'https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap';
      document.head.appendChild(link);
      var style = document.createElement('style');
      style.innerHTML = "*:not(.material-icons):not([class*='icon']):not([class*='fa-']) { font-family: 'Poppins', sans-serif !important; }";
      document.head.appendChild(style);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _pullToRefresh = PullToRefreshController(
      settings: PullToRefreshSettings(color: const Color(0xFF1A2E45)),
      onRefresh: () async {
        if (Platform.isAndroid) {
          _controller?.reload();
        } else {
          final url = await _controller?.getUrl();
          if (url != null) _controller?.loadUrl(urlRequest: URLRequest(url: url));
        }
      },
    );
    _prepare();
  }

  Future<void> _prepare() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasConnection = !connectivity.contains(ConnectivityResult.none);

    if (!hasConnection) {
      setState(() {
        _noConnection = true;
        _cookiesReady = false;
      });
      return;
    }

    final host = Uri.parse(widget.session.baseUrl).host;
    final cookieManager = CookieManager.instance();
    for (final cookie in widget.sessionCookies) {
      await cookieManager.setCookie(
        url: WebUri(widget.session.baseUrl),
        name: cookie.name,
        value: cookie.value,
        domain: host,
        path: '/',
        isSecure: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _noConnection = false;
      _cookiesReady = true;
    });
  }

  Future<void> _logout() async {
    await CookieManager.instance().deleteAllCookies();
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SchoolSelectScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.schoolName),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
        bottom: _progress > 0 && _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress, minHeight: 2),
              )
            : null,
      ),
      body: _noConnection
          ? NoInternetView(onRetry: _prepare)
          : !_cookiesReady
              ? const Center(child: CircularProgressIndicator())
              : InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.session.baseUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useOnLoadResource: false,
                    supportZoom: false,
                    domStorageEnabled: true,
                  ),
                  pullToRefreshController: _pullToRefresh,
                  onWebViewCreated: (controller) => _controller = controller,
                  onProgressChanged: (controller, progress) {
                    setState(() => _progress = progress / 100);
                  },
                  onLoadStop: (controller, url) async {
                    _pullToRefresh?.endRefreshing();
                    await controller.evaluateJavascript(source: _fontInjectionJs);
                  },
                  onReceivedError: (controller, request, error) {
                    _pullToRefresh?.endRefreshing();
                    if (request.isForMainFrame ?? true) {
                      setState(() => _noConnection = true);
                    }
                  },
                ),
    );
  }
}
