import 'package:flutter/material.dart';

class BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const bracketLength = 30.0;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), const Offset(bracketLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, bracketLength), paint);

    // Top-right corner
    canvas.drawLine(
        Offset(size.width - bracketLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, bracketLength), paint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - bracketLength), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(bracketLength, size.height), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - bracketLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - bracketLength), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
