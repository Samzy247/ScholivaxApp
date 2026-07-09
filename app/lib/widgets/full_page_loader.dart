import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fully covers the screen while content loads underneath (a WebView, in
/// particular), so the person never sees a flash of blank/unstyled page —
/// then fades out once loading finishes.
class FullPageLoader extends StatelessWidget {
  final bool visible;
  final String label;

  const FullPageLoader({super.key, required this.visible, this.label = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.navy),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
