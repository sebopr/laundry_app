// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/pages/onboarding_page.dart';
import 'package:lavaplan/services/household/household_service.dart';

// Kept for re-scanning from Settings (e.g. moving buildings).
// Handles both building: and household: prefixes.
class ScanQrToJoinGroupPage extends StatefulWidget {
  const ScanQrToJoinGroupPage({super.key});

  @override
  State<ScanQrToJoinGroupPage> createState() =>
      _ScanQrToJoinGroupPageState();
}

class _ScanQrToJoinGroupPageState extends State<ScanQrToJoinGroupPage> {
  bool _processing = false;

  Future<void> _handleScan(String code) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      if (code.startsWith('building:')) {
        final linkedUuid = code.substring('building:'.length);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'linked_uuid': linkedUuid});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Building joined successfully.')));
          Navigator.pop(context);
        }
      } else if (code.startsWith('household:')) {
        await HouseholdService.join(code.substring('household:'.length));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Household joined successfully.')));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unrecognised QR code.')));
          setState(() => _processing = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return QrScanPage(onScanned: _handleScan);
  }
}
