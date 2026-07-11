import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/parent_service.dart';
import '../services/session_store.dart';
import 'dashboard_screen.dart';

/// Shown once, right after a parent logs in with the default password
/// ('parent123') — blocks the way into the dashboard until they set a
/// password of their own.
class SetNewPasswordScreen extends StatefulWidget {
  final UserSession session;
  const SetNewPasswordScreen({super.key, required this.session});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    final newPassword = _newController.text;
    final confirm = _confirmController.text;

    if (newPassword.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both fields.');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (newPassword == 'parent123') {
      setState(() => _errorMessage = 'Please choose a password other than the default.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ParentService.changePassword(widget.session, newPassword);
      final updatedSession = widget.session.copyWith(mustChangePassword: false);
      await SessionStore.save(updatedSession);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => DashboardScreen(session: updatedSession)),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorMessage = 'Could not set your new password. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(title: const Text('Set a New Password'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "You're signed in with the default password. Please set your own before continuing.",
              style: TextStyle(fontSize: 14.5, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _newController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: _obscure,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Set Password & Continue'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
