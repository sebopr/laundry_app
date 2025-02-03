import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

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
            ],
          ),
        ),
      ),
    );
  }
}
