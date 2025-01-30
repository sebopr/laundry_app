import 'package:flutter/material.dart';

class EnrollPage extends StatelessWidget {
  const EnrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enroll Page"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text("Enroll Page"),
      ),
    );
  }
}
