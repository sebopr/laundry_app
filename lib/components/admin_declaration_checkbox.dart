import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/constants/legal.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// The admin's declaration of authority. Creating or taking over a building
/// is blocked until it's ticked; the server stores when it was accepted.
class AdminDeclarationCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminDeclarationCheckbox(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final linkStyle = TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline);

    TextSpan link(String text, String url) => TextSpan(
          text: text,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication),
        );

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall,
                  children: [
                    TextSpan(text: l10n.adminDeclarationText),
                    TextSpan(text: ' ${l10n.adminDeclarationLegal} '),
                    link(l10n.privacyPolicy, privacyPolicyUrl),
                    const TextSpan(text: ', '),
                    link(l10n.termsOfUse, termsOfUseUrl),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
