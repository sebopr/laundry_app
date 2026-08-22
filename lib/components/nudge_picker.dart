import 'package:flutter/material.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/models/nudge.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A "+" button that fans out into a small stack of round preset-nudge
/// buttons when tapped, Waze-report-button style. Picking one collapses the
/// menu and reports the chosen [Nudge] via [onSelected].
class NudgePicker extends StatefulWidget {
  final void Function(Nudge nudge) onSelected;

  const NudgePicker({super.key, required this.onSelected});

  @override
  State<NudgePicker> createState() => _NudgePickerState();
}

class _NudgePickerState extends State<NudgePicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  bool _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  void _select(Nudge nudge) {
    widget.onSelected(nudge);
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = kNudges.length - 1; i >= 0; i--)
          _buildOption(theme, l10n, kNudges[i], i),
        _buildMainButton(theme, l10n),
      ],
    );
  }

  Widget _buildOption(
      ThemeData theme, AppLocalizations l10n, Nudge nudge, int index) {
    final delay = (index * 0.08).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: animation,
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: _controller,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  nudge.label(l10n),
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _select(nudge),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(nudge.icon,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: l10n.nudgeButtonTooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _toggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF22C6C6), Color(0xFF12A3A8)],
                ),
              ),
              child: AnimatedRotation(
                turns: _open ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(LucideIcons.plus,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
