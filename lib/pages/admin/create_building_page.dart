import 'dart:ui' show ImageByteFormat;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateBuildingPage extends StatefulWidget {
  // Called after building is created. If provided the page doesn't pop itself —
  // the caller decides what to do next (e.g. onboarding moves to next step).
  final VoidCallback? onCreated;

  const CreateBuildingPage({super.key, this.onCreated});

  @override
  State<CreateBuildingPage> createState() => _CreateBuildingPageState();
}

class _CreateBuildingPageState extends State<CreateBuildingPage> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _createdUuid;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final uuid = const Uuid().v4();

    // Create building document
    await FirebaseFirestore.instance.collection('buildings').doc(uuid).set({
      'name': name,
      'created_by': uid,
      'created_at': FieldValue.serverTimestamp(),
      'machines': {'1': 'active', '2': 'active', '3': 'active'},
    });

    // Add to admin's managed_buildings
    // Also set linked_uuid if this is the admin's first building and
    // they're also a resident (isResidentAdmin = true)
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final isResidentAdmin =
        userDoc.data()?['isResidentAdmin'] as bool? ?? false;
    final hasLinkedUuid =
        userDoc.data()?['linked_uuid'] != null;

    final updates = <String, dynamic>{
      'managed_buildings': FieldValue.arrayUnion([uuid]),
    };
    if (isResidentAdmin && !hasLinkedUuid) {
      updates['linked_uuid'] = uuid;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(updates);

    setState(() {
      _createdUuid = uuid;
      _loading = false;
    });
  }

  Future<void> _print() async {
    final qrData = 'building:$_createdUuid';
    final doc = pw.Document();
    final qrImage = await _buildPdfQr(qrData);
    doc.addPage(pw.Page(
      build: (ctx) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(_nameController.text,
              style: const pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 8),
          pw.Text('Scan to join the laundry booking system',
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
    return Scaffold(
      appBar: AppBar(title: const Text('New building')),
      body: _createdUuid != null
          ? _QrView(
              buildingName: _nameController.text,
              uuid: _createdUuid!,
              onPrint: _print,
              onDone: () {
                if (widget.onCreated != null) {
                  widget.onCreated!();
                } else {
                  Navigator.pop(context);
                }
              },
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Building name or address',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'e.g. Bahnhofstrasse 12',
                    filled: true,
                    fillColor: theme.colorScheme.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _create(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _create,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Create building'),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.check_circle,
                color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(buildingName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Building created. Post this QR in the laundry room.',
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
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onDone,
                    child: const Text('Continue'),
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
