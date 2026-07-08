import 'package:flutter/material.dart';
import '../models/school.dart';
import '../models/user_session.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../services/web_session_service.dart';
import 'web_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final School school;
  final String roleGroup; // 'staff' or 'student'

  const LoginScreen({super.key, required this.school, required this.roleGroup});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  bool get _isStudent => widget.roleGroup == 'student';

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both fields.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Primary: log into the real website so we get a real session
      // cookie — this is what the WebView dashboard runs on.
      final cookies = await WebSessionService.login(
        school: widget.school,
        identifier: identifier,
        password: password,
      );

      // Secondary, best-effort: also grab an API token for the offline-
      // capable native screens (attendance/scores, Phase 3). If this
      // fails, the WebView experience still works fine — offline features
      // just won't sync until the next successful login.
      var session = UserSession(
        token: '',
        userType: _isStudent ? 'student' : 'staff',
        userId: 0,
        name: null,
        schoolName: widget.school.name,
        subdomain: widget.school.subdomain,
      );
      try {
        session = await AuthService.login(
          school: widget.school,
          role: _isStudent ? 'student' : '',
          identifier: identifier,
          password: password,
        );
      } catch (_) {
        // non-fatal
      }

      await SessionStore.save(session);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => WebDashboardScreen(session: session, sessionCookies: cookies),
        ),
        (route) => false,
      );
    } on NoConnectionException catch (e) {
      setState(() => _errorMessage = e.message);
    } on WebLoginException catch (e) {
      setState(() => _errorMessage = e.message);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.school.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isStudent ? 'Student Login' : 'Admin / Teacher Login',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _identifierController,
              keyboardType: _isStudent ? TextInputType.text : TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: _isStudent ? 'Registration Number (Reg No)' : 'Email Address',
                prefixIcon: Icon(_isStudent ? Icons.badge_outlined : Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
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
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
