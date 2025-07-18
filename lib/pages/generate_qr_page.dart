import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class GenerateQrPage extends StatefulWidget {
  const GenerateQrPage({super.key});

  @override
  State<GenerateQrPage> createState() => _GenerateQrPageState();
}

class _GenerateQrPageState extends State<GenerateQrPage> {
  //generate uuid
  String uuid = '';
  @override
  void initState() {
    super.initState();
    uuid = const Uuid().v4();
  }

  void generateUUID() {
    var uuidGenerator = const Uuid();
    setState(() {
      uuid = uuidGenerator.v4(); // Generates a new random UUID (version 4)
    });
  }

  Future<void> _printQrCode() async {
    final doc = pw.Document();

    final qrImage = await wrapFlutterQrAsPdfWidget(uuid);

    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('QR Code', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.Center(child: qrImage),
            pw.SizedBox(height: 20),
            pw.Text('UUID: $uuid', style: const pw.TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  Future<pw.Widget> wrapFlutterQrAsPdfWidget(String data) async {
    final image = await QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    ).toImage(200);

    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final imageBytes = byteData!.buffer.asUint8List();

    final pdfImage = pw.MemoryImage(imageBytes);

    return pw.Image(pdfImage, width: 200, height: 200);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate QR Code"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 45),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              QrImageView(
                data: uuid,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 40),
              Text(uuid),
              const SizedBox(height: 99),
              IconButton(
                icon: const Icon(Icons.print, size: 66),
                onPressed: _printQrCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
