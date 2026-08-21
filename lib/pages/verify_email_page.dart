import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/services/auth/auth_service.dart';

// ─── Email confirmation page ──────────────────────────────────────────────────
//
// Shown by AuthGate between signing up and reaching the app, for email +
// password accounts only. Firebase never pushes the confirmation back to the
// client, so this page polls: every few seconds it reloads the account and
// asks whether the link has been opened yet.

class VerifyEmailPage extends StatefulWidget {
  final User user;
  const VerifyEmailPage({super.key, required this.user});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const _pollInterval = Duration(seconds: 3);

  final _auth = AuthService();
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _secondsUntilResend = 0;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A link was already sent when the account was created, so pick up
    // whatever is left of that cooldown instead of starting a fresh one.
    _tickCooldown(AuthService.remainingResendCooldown);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // Runs the resend button's countdown down to zero.
  void _tickCooldown(Duration remaining) {
    _cooldownTimer?.cancel();
    _secondsUntilResend = remaining.inSeconds;
    if (_secondsUntilResend <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsUntilResend--);
      if (_secondsUntilResend <= 0) timer.cancel();
    });
  }

  // Returns to AuthGate by way of userChanges() once the address is confirmed.
  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    if (!silent) setState(() { _checking = true; _error = null; });
    try {
      final confirmed = await _auth.refreshEmailConfirmed();
      if (!mounted) return;
      if (!confirmed && !silent) {
        setState(() => _error = 'Not confirmed yet. Open the link we emailed '
            'you, then try again.');
      }
    } catch (e) {
      // A reload can fail if the account was deleted or the session expired;
      // in both cases signing out puts the user back on a working screen.
      if (mounted && !silent) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await _auth.sendEmailConfirmation();
      if (!mounted) return;
      setState(() => _tickCooldown(AuthService.resendCooldown));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirmation email sent.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    }
  }

  String _message(Object e) {
    final code = e.toString();
    if (code.contains('too-many-requests')) {
      return 'Too many attempts. Wait a few minutes before trying again.';
    }
    if (code.contains('user-token-expired') || code.contains('user-not-found')) {
      return 'Your session expired. Please sign in again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = widget.user.email ?? 'your address';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text('Confirm your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'We sent a confirmation link to '),
                    TextSpan(
                        text: email,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const TextSpan(
                        text: '. Open it to finish setting up your account — '
                            'this screen continues on its own.'),
                  ]),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: theme.colorScheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _checking ? null : _check,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('I have confirmed my email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _secondsUntilResend > 0 ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_secondsUntilResend > 0
                      ? 'Resend email (${_secondsUntilResend}s)'
                      : 'Resend email'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => AuthService().signOut(),
                  child: const Text('Use a different account'),
                ),
                const SizedBox(height: 8),
                Text('Check your spam folder if it has not arrived.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
