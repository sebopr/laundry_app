// lib/widgets/global_overlay_wrapper.dart
import 'package:flutter/material.dart';
import 'package:lavaplan/services/conectivity/conectivity_service.dart';

class GlobalOverlayWrapper extends StatefulWidget {
  final Widget child;

  const GlobalOverlayWrapper({super.key, required this.child});

  @override
  State<GlobalOverlayWrapper> createState() => _GlobalOverlayWrapperState();
}

class _GlobalOverlayWrapperState extends State<GlobalOverlayWrapper> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    ConnectivityService().connectionStream.listen((status) {
      setState(() {
        _hasInternet = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_hasInternet)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red,
              child: const SafeArea(
                child: Text(
                  'No Internet Connection',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
