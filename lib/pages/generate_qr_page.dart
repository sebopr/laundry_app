import 'dart:ui' show ImageByteFormat;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class GenerateQrPage extends StatefulWidget {
  // When provided, shows the QR for a specific building (admin use).
  // When null, loads or creates the QR for the current user's building.
  final String? buildingUuid;

  const GenerateQrPage({super.key, this.buildingUuid});

  @override
  State<GenerateQrPage> createState() => _GenerateQrPageState();
}

class _GenerateQrPageState extends State<GenerateQrPage> {
  String? _linkedUuid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrCreate();
  }

  Future<void> _loadOrCreate() async {
    // Admin viewing a specific building's QR directly
    if (widget.buildingUuid != null) {
      setState(() {
        _linkedUuid = widget.buildingUuid;
        _loading = false;
      });
      return;
    }

    // Default: load or create the current user's building UUID
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final existing = doc.data()?['linked_uuid'] as String?;

    if (existing != null) {
      setState(() {
        _linkedUuid = existing;
        _loading = false;
      });
      return;
    }

    // First time: generate and persist
    final newUuid = const Uuid().v4();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'linked_uuid': newUuid});

    setState(() {
      _linkedUuid = newUuid;
      _loading = false;
    });
  }

  // QR payload — prefixed so the scanner knows what it's scanning
  String get _qrData => 'building:$_linkedUuid';

  Future<void> _print() async {
    final doc = pw.Document();
    final qrWidget = await _buildPdfQr(_qrData);
    doc.addPage(pw.Page(
      build: (ctx) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('Laundry Room — Scan to join',
              style: const pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 24),
          pw.Center(child: qrWidget),
          pw.SizedBox(height: 12),
          pw.Text('Scan with the Laundry app to book machines.',
              style: const pw.TextStyle(fontSize: 12)),
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
      appBar: AppBar(title: const Text('Building QR Code')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text('Post this in your laundry room',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Residents scan it to join the booking system.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
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
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _print,
                      icon: const Icon(Icons.print),
                      label: const Text('Print QR'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
