import 'package:flutter/material.dart';

/// Shown whenever a screen needs data from the server but the request
/// couldn't reach it (see NoConnectionException in api_client.dart).
/// Any screen that needs live data drops this in when that happens,
/// with a Retry button that re-runs the fetch.
class NoInternetView extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const NoInternetView({
    super.key,
    required this.onRetry,
    this.message = "No internet connection.\nCheck your network and try again.",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
