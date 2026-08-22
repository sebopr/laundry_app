import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ─── Email confirmation page ──────────────────────────────────────────────────
//
// Shown by AuthGate between signing up and reaching the app, for email +
// password accounts only. A 6-digit code was emailed when the account was
// created (see AuthService.sendVerificationCode); this page collects it and
// submits it to the verifyEmailCode Cloud Function.

class VerifyEmailPage extends StatefulWidget {
  final User user;
  const VerifyEmailPage({super.key, required this.user});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _auth = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _cooldownTimer;
  int _secondsUntilResend = 0;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A code was already sent when the account was created, so pick up
    // whatever is left of that cooldown instead of starting a fresh one.
    _tickCooldown(AuthService.remainingResendCooldown);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

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

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Pasted content — spread it across the remaining boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < digits.length && index + i < 6; i++) {
        _controllers[index + i].text = digits[i];
      }
      final next = (index + digits.length).clamp(0, 5);
      _focusNodes[next].requestFocus();
      setState(() {});
      if (_code.length == 6) _verify();
      return;
    }
    setState(() {});
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_code.length == 6) _verify();
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _code;
    if (code.length != 6) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await _auth.verifyEmailCode(code);
      // AuthGate picks this up via FirebaseAuth.userChanges() once the ID
      // token refresh above lands — nothing else to do here.
    } catch (e) {
      if (mounted) {
        setState(() => _error = _message(AppLocalizations.of(context)!, e));
        _clearCode();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _error = null);
    try {
      await _auth.sendVerificationCode();
      if (!mounted) return;
      _clearCode();
      setState(() => _tickCooldown(AuthService.resendCooldown));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.codeSentSnackbar)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = _message(l10n, e));
    }
  }

  String _message(AppLocalizations l10n, Object e) {
    var msg = e.toString();
    if (msg.startsWith('Exception: ')) msg = msg.substring('Exception: '.length);
    if (msg.contains('too-many-requests')) {
      return l10n.errorTooManyRequests;
    }
    if (msg.contains('user-token-expired') || msg.contains('user-not-found')) {
      return l10n.sessionExpired;
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final email = widget.user.email ?? 'your address';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(LucideIcons.mailWarning,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text(l10n.verifyEmailTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: l10n.verifyEmailBodyPrefix),
                    TextSpan(
                        text: email,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: l10n.verifyEmailBodySuffix),
                  ]),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => _digitBox(theme, i)),
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
                  onPressed: (_verifying || _code.length != 6) ? null : _verify,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n.btnVerify,
                          style: const TextStyle(
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
                      ? l10n.btnResendCodeCooldown(_secondsUntilResend)
                      : l10n.btnResendCode),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => AuthService().signOut(),
                  child: Text(l10n.useDifferentAccount),
                ),
                const SizedBox(height: 8),
                Text(l10n.checkSpamFolder,
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

  Widget _digitBox(ThemeData theme, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 44,
        height: 54,
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6, // allows paste of the full code into any box
          showCursor: false,
          style: (theme.textTheme.headlineSmall ?? const TextStyle(fontSize: 24))
              .copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: theme.colorScheme.secondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
          ),
          onChanged: (value) => _onDigitChanged(index, value),
          onTap: () {
            // Tapping a filled box selects its content so typing replaces it.
            _controllers[index].selection = TextSelection(
                baseOffset: 0, extentOffset: _controllers[index].text.length);
          },
        ),
      ),
    );
  }
}
