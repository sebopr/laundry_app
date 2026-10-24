import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/services/building/building_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows the one-time code that hands this building over to another admin.
/// Opening the page creates the code, or shows the one that's still open.
class HandOverPage extends StatefulWidget {
  final String buildingUuid;
  final String buildingName;

  const HandOverPage({
    super.key,
    required this.buildingUuid,
    required this.buildingName,
  });

  @override
  State<HandOverPage> createState() => _HandOverPageState();
}

class _HandOverPageState extends State<HandOverPage> {
  late final Future<({String code, DateTime expiresAt})> _transfer =
      BuildingService.createTransfer(widget.buildingUuid);
  bool _cancelling = false;

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _cancelling = true);
    try {
      await BuildingService.cancelTransfer(widget.buildingUuid);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.handOverCancelled)));
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Cancel handover failed: $e');
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.handOverBuilding)),
      body: FutureBuilder<({String code, DateTime expiresAt})>(
        future: _transfer,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(l10n.errorGeneric));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final code = snap.data!.code;
          // Shown as XXXX-XXXX; the server ignores the dash.
          final shown = '${code.substring(0, 4)}-${code.substring(4)}';
          final validUntil = DateFormat.yMMMd(
                  Localizations.localeOf(context).toLanguageTag())
              .add_Hm()
              .format(snap.data!.expiresAt);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(widget.buildingName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(l10n.handOverExplain,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: QrImageView(
                      data: 'transfer:$code',
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SelectableText(shown,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  const SizedBox(height: 4),
                  Text(l10n.handOverValidUntil(validUntil),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _cancelling ? null : _cancel,
                    icon: const Icon(LucideIcons.x),
                    label: Text(l10n.handOverCancel),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
