// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lavaplan/services/auth/session_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ─── Login page ───────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegisterTap;
  const LoginPage({super.key, this.onRegisterTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  bool _obscurePw = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (SessionService.instance.consumeKickedFlag()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.signedOutElsewhere)),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signInWithEmailPassword(
          _emailController.text.trim(), _pwController.text);
      TextInput.finishAutofillContext();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(AppLocalizations.of(context)!, e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(AppLocalizations.of(context)!, e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _appleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signInWithApple();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(AppLocalizations.of(context)!, e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              _AuthHeader(tagline: l10n.appTagline),
              const SizedBox(height: 48),
              Text(l10n.loginTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(l10n.loginSubtitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade500)),
              const SizedBox(height: 24),
              AutofillGroup(
                child: Column(children: [
                  _InputField(
                    controller: _emailController,
                    label: l10n.fieldEmail,
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _pwController,
                    label: l10n.fieldPassword,
                    icon: LucideIcons.lock,
                    obscureText: _obscurePw,
                    onToggleObscure: () =>
                        setState(() => _obscurePw = !_obscurePw),
                    onSubmitted: (_) => _signIn(),
                    autofillHints: const [AutofillHints.password],
                  ),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: TextStyle(
                        color: theme.colorScheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              _PrimaryButton(
                label: l10n.btnSignIn,
                loading: _loading,
                onPressed: _signIn,
              ),
              const SizedBox(height: 28),
              _OrDivider(),
              const SizedBox(height: 20),
              _SocialButton(
                label: l10n.btnContinueGoogle,
                icon: const _GoogleIcon(),
                onPressed: _loading ? null : _googleSignIn,
              ),
              const SizedBox(height: 10),
              _SocialButton(
                label: l10n.btnContinueApple,
                icon: const Icon(Icons.apple, size: 20),
                onPressed: _loading ? null : _appleSignIn,
                dark: true,
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(l10n.loginNoAccount,
                    style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: widget.onRegisterTap,
                  child: Text(l10n.btnSignUp),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Register page ────────────────────────────────────────────────────────────

class RegisterPage extends StatefulWidget {
  final VoidCallback? onLoginTap;
  const RegisterPage({super.key, this.onLoginTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pwController.text != _confirmPwController.text) {
      setState(() => _error = l10n.errorPasswordMismatch);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signUpWithEmailPassword(
          _emailController.text.trim(), _pwController.text);
      TextInput.finishAutofillContext();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(l10n, e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(AppLocalizations.of(context)!, e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _appleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signInWithApple();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(AppLocalizations.of(context)!, e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              _AuthHeader(tagline: l10n.appTagline),
              const SizedBox(height: 48),
              Text(l10n.registerTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(l10n.registerSubtitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade500)),
              const SizedBox(height: 24),
              AutofillGroup(
                child: Column(children: [
                  _InputField(
                    controller: _emailController,
                    label: l10n.fieldEmail,
                    icon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.newUsername],
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _pwController,
                    label: l10n.fieldPassword,
                    icon: LucideIcons.lock,
                    obscureText: _obscurePw,
                    onToggleObscure: () =>
                        setState(() => _obscurePw = !_obscurePw),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _confirmPwController,
                    label: l10n.fieldConfirmPassword,
                    icon: LucideIcons.lock,
                    obscureText: _obscureConfirm,
                    onToggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onSubmitted: (_) => _register(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: TextStyle(
                        color: theme.colorScheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              _PrimaryButton(
                label: l10n.btnCreateAccount,
                loading: _loading,
                onPressed: _register,
              ),
              const SizedBox(height: 28),
              _OrDivider(),
              const SizedBox(height: 20),
              _SocialButton(
                label: l10n.btnContinueGoogle,
                icon: const _GoogleIcon(),
                onPressed: _loading ? null : _googleSignIn,
              ),
              const SizedBox(height: 10),
              _SocialButton(
                label: l10n.btnContinueApple,
                icon: const Icon(Icons.apple, size: 20),
                onPressed: _loading ? null : _appleSignIn,
                dark: true,
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(l10n.registerHaveAccount,
                    style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: widget.onLoginTap,
                  child: Text(l10n.btnSignIn),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _AuthHeader extends StatelessWidget {
  final String tagline;
  const _AuthHeader({required this.tagline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Image.asset('assets/branding/lavaplan_mark.png', height: 56),
      const SizedBox(height: 10),
      Text('Lavaplan',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(tagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: Colors.grey.shade500)),
    ]);
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.autocorrect = true,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(obscureText
                    ? LucideIcons.eye
                    : LucideIcons.eyeOff),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(AppLocalizations.of(context)!.orDivider,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade500)),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool dark;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );

    if (dark) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black54,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.1,
      ),
    );
  }
}

String _friendlyError(AppLocalizations l10n, Object e) {
  final msg = e.toString().toLowerCase();
  if (msg.contains('wrong-password') ||
      msg.contains('invalid-credential') ||
      msg.contains('user-not-found')) {
    return l10n.errorWrongCredentials;
  }
  if (msg.contains('invalid-email')) return l10n.errorInvalidEmail;
  if (msg.contains('email-already-in-use')) {
    return l10n.errorEmailInUse;
  }
  if (msg.contains('weak-password')) {
    return l10n.errorWeakPassword;
  }
  if (msg.contains('network-request-failed')) {
    return l10n.errorNoInternet;
  }
  if (msg.contains('too-many-requests')) {
    return l10n.errorTooManyRequests;
  }
  return l10n.errorGeneric;
}
