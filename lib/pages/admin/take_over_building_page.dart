import 'package:flutter/material.dart';
import 'package:lavaplan/components/admin_declaration_checkbox.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/pages/onboarding_page.dart';
import 'package:lavaplan/services/building/building_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Where the new admin enters (or scans) the handover code from the
/// building's current admin. See HandOverPage for the other side.
class TakeOverBuildingPage extends StatefulWidget {
  const TakeOverBuildingPage({super.key});

  @override
  State<TakeOverBuildingPage> createState() => _TakeOverBuildingPageState();
}

class _TakeOverBuildingPageState extends State<TakeOverBuildingPage> {
  final _codeController = TextEditingController();
  bool _declared = false;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (result == null || !mounted) return;
    setState(() => _codeController.text =
        result.replaceFirst(RegExp('^transfer:', caseSensitive: false), ''));
  }

  Future<void> _takeOver() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || !_declared || _loading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);
    try {
      final name = await BuildingService.acceptTransfer(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.takeOverDone(name))));
      Navigator.pop(context);
    } on BuildingException catch (e) {
      debugPrint('Take over failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      final message = switch (e.code) {
        'not-found' || 'invalid-argument' => l10n.errorTransferInvalid,
        'already-exists' => l10n.errorTransferOwn,
        'resource-exhausted' => l10n.errorBuildingLimit,
        _ => l10n.errorGeneric,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('Take over failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canSubmit =
        _codeController.text.trim().isNotEmpty && _declared && !_loading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.takeOverBuilding)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.takeOverExplain,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.takeOverCodeHint,
              filled: true,
              fillColor: theme.colorScheme.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.scanLine),
                tooltip: l10n.scanQrCode,
                onPressed: _scan,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AdminDeclarationCheckbox(
            value: _declared,
            onChanged: (v) => setState(() => _declared = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSubmit ? _takeOver : null,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(l10n.btnTakeOver),
            ),
          ),
        ],
      ),
    );
  }
}
