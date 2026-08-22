import 'package:flutter/widgets.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A preset icon+message quick-send, e.g. "you forgot your laundry", sent as
/// a distinct chat bubble instead of typed text. Keeps neighbour-to-neighbour
/// nudges about shared-machine etiquette low-key and non-confrontational.
class Nudge {
  final String id;
  final IconData icon;
  final String Function(AppLocalizations l10n) label;
  final String Function(AppLocalizations l10n) message;

  const Nudge({
    required this.id,
    required this.icon,
    required this.label,
    required this.message,
  });
}

const kNudges = [
  Nudge(
    id: 'forgot_laundry',
    icon: LucideIcons.shirt,
    label: _forgotLaundryLabel,
    message: _forgotLaundryMessage,
  ),
  Nudge(
    id: 'clean_detergent_bay',
    icon: LucideIcons.droplets,
    label: _cleanDetergentLabel,
    message: _cleanDetergentMessage,
  ),
];

String _forgotLaundryLabel(AppLocalizations l10n) => l10n.nudgeForgotLaundryLabel;
String _forgotLaundryMessage(AppLocalizations l10n) => l10n.nudgeForgotLaundryMessage;
String _cleanDetergentLabel(AppLocalizations l10n) => l10n.nudgeCleanDetergentLabel;
String _cleanDetergentMessage(AppLocalizations l10n) => l10n.nudgeCleanDetergentMessage;

Nudge? nudgeById(String? id) {
  if (id == null) return null;
  for (final n in kNudges) {
    if (n.id == id) return n;
  }
  return null;
}
