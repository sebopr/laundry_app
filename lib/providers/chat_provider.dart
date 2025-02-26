import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  bool _isChatPageActive = false;

  bool get isChatPageActive => _isChatPageActive;

  void setChatPageActive(bool isActive) {
    _isChatPageActive = isActive;
    notifyListeners();
  }
}
