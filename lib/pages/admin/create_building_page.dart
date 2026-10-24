import 'dart:async';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:lavaplan/components/admin_declaration_checkbox.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/services/building/building_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CreateBuildingPage extends StatefulWidget {
  const CreateBuildingPage({super.key});

  @override
  State<CreateBuildingPage> createState() => _CreateBuildingPageState();
}

class _CreateBuildingPageState extends State<CreateBuildingPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = [];
  bool _searching = false;
  String? _searchError;
  AddressSuggestion? _selected;
  bool _declared = false;
  bool _loading = false;
  String? _createdUuid;
  String? _createdName;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    setState(() {
      _selected = null;
      _searchError = null;
    });
    final query = text.trim();
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await BuildingService.searchAddresses(query);
      // Ignore results for a query the user has since typed past.
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _suggestions = results;
        _searchError = results.isEmpty
            ? AppLocalizations.of(context)!.buildingAddressNoResults
            : null;
      });
    } catch (e) {
      debugPrint('Address search failed: $e');
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _searchError = AppLocalizations.of(context)!.buildingAddressSearchFailed;
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _select(AddressSuggestion s) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = s;
      _suggestions = [];
      _searchController.text = s.label;
    });
  }

  Future<void> _create() async {
    final selected = _selected;
    if (selected == null || !_declared || _loading) return;
    setState(() => _loading = true);

    final l10n = AppLocalizations.of(context)!;
    try {
      final building = await BuildingService.createBuilding(selected.featureId);
      if (!mounted) return;
      setState(() {
        _createdUuid = building.id;
        _createdName = building.name;
        _loading = false;
      });
    } on BuildingException catch (e) {
      debugPrint('Create building failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      final message = switch (e.code) {
        'already-exists' => l10n.errorBuildingExists,
        'resource-exhausted' => l10n.errorBuildingLimit,
        _ => l10n.errorGeneric,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('Create building failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  Future<void> _print() async {
    final scanToJoin = AppLocalizations.of(context)!.scanToJoin;
    final qrData = 'building:$_createdUuid';
    final doc = pw.Document();
    final qrImage = await _buildPdfQr(qrData);
    doc.addPage(pw.Page(
      build: (ctx) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(_createdName ?? '',
              style: const pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 8),
          pw.Text(scanToJoin,
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 24),
          pw.Center(child: qrImage),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  Future<pw.Widget> _buildPdfQr(String data) async {
    final image = await QrPainter(
            data: data, version: QrVersions.auto, gapless: true)
        .toImage(200);
    final bytes =
        (await image.toByteData(format: ImageByteFormat.png))!
            .buffer
            .asUint8List();
    return pw.Image(pw.MemoryImage(bytes), width: 200, height: 200);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canCreate = _selected != null && _declared && !_loading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newBuilding)),
      body: _createdUuid != null
          ? _QrView(
              buildingName: _createdName ?? '',
              uuid: _createdUuid!,
              onPrint: _print,
              onDone: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(l10n.buildingAddressLabel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.buildingAddressHint,
                    prefixIcon: const Icon(LucideIcons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)))
                        : _selected != null
                            ? const Icon(LucideIcons.circleCheck,
                                color: Colors.green)
                            : null,
                    filled: true,
                    fillColor: theme.colorScheme.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_searchError!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.orange.shade800)),
                  ),
                ..._suggestions.map((s) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(LucideIcons.mapPin, size: 18),
                      title: Text(s.label),
                      onTap: () => _select(s),
                    )),
                const SizedBox(height: 24),
                AdminDeclarationCheckbox(
                  value: _declared,
                  onChanged: (v) => setState(() => _declared = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canCreate ? _create : null,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(l10n.createBuilding),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QrView extends StatelessWidget {
  final String buildingName;
  final String uuid;
  final VoidCallback onPrint;
  final VoidCallback onDone;

  const _QrView({
    required this.buildingName,
    required this.uuid,
    required this.onPrint,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(LucideIcons.circleCheck,
                color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(buildingName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(l10n.buildingCreatedMsg,
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
                data: 'building:$uuid',
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(LucideIcons.printer),
                    label: Text(l10n.btnPrint),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onDone,
                    child: Text(l10n.btnContinue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
