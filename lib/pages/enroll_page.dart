import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScanQrToJoinGroupPage extends StatefulWidget {
  const ScanQrToJoinGroupPage({super.key});

  @override
  State<ScanQrToJoinGroupPage> createState() => _ScanQrToJoinGroupPageState();
}

class _ScanQrToJoinGroupPageState extends State<ScanQrToJoinGroupPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;

  @override
  void dispose() {
    // ignore: deprecated_member_use
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (!isScanned) {
        isScanned = true; // prevent multiple scans

        final uuid = scanData.code ?? '';
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null && uuid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({'linked_uuid': uuid}, SetOptions(merge: true));

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('UUID linked: $uuid')),
            );
            Navigator.pop(context); // close after success
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
}
