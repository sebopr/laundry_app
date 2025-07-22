// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _monitorConnection();
  }

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  void _monitorConnection() {
    Connectivity().onConnectivityChanged.listen((_) async {
      final current =
          await InternetConnectionChecker.createInstance().hasConnection;
      _emitIfChanged(current);
    });

    // Initial check
    InternetConnectionChecker.createInstance().hasConnection.then((value) {
      _emitIfChanged(value);
    });

    // Background check every 5 seconds (optional but useful)
    Timer.periodic(const Duration(seconds: 5), (_) async {
      final current =
          await InternetConnectionChecker.createInstance().hasConnection;
      _emitIfChanged(current);
    });
  }

  void _emitIfChanged(bool newStatus) {
    if (_hasConnection != newStatus) {
      _hasConnection = newStatus;
      _connectionController.sink.add(newStatus);
    }
  }

  void dispose() {
    _connectionController.close();
  }
}
