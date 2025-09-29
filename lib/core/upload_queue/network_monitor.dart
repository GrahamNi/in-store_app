// Network and Battery Monitoring for Upload Queue
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'upload_models.dart';

// =============================================================================
// NETWORK AWARENESS SYSTEM
// =============================================================================

class NetworkMonitor {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkConditions> _controller = StreamController.broadcast();
  
  Stream<NetworkConditions> get conditionsStream => _controller.stream;
  NetworkConditions _currentConditions = const NetworkConditions(
    type: NetworkType.none,
    isConnected: false,
  );

  NetworkConditions get current => _currentConditions;

  void start() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConditions(results);
    });
    
    // Initial check
    _connectivity.checkConnectivity().then(_updateConditions);
  }

  void _updateConditions(List<ConnectivityResult> results) {
    NetworkType type = NetworkType.none;
    bool isConnected = false;
    bool isMetered = false;

    if (results.contains(ConnectivityResult.wifi)) {
      type = NetworkType.wifi;
      isConnected = true;
      isMetered = false;
    } else if (results.contains(ConnectivityResult.mobile)) {
      type = NetworkType.cellular;
      isConnected = true;
      isMetered = true;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      type = NetworkType.other;
      isConnected = true;
      isMetered = false;
    }

    _currentConditions = NetworkConditions(
      type: type,
      isConnected: isConnected,
      isMetered: isMetered,
    );

    _controller.add(_currentConditions);
    debugPrint('Network changed: ${type.name}, connected: $isConnected');
  }

  void dispose() {
    _controller.close();
  }
}

// =============================================================================
// BATTERY AWARENESS SYSTEM
// =============================================================================

class BatteryMonitor {
  final Battery _battery = Battery();
  final StreamController<int> _levelController = StreamController.broadcast();
  Timer? _pollTimer;

  Stream<int> get batteryLevelStream => _levelController.stream;
  int _currentLevel = 100;

  int get currentLevel => _currentLevel;
  bool get isBatteryLow => _currentLevel < 20;

  void start() {
    // Poll battery level every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkBatteryLevel();
    });
    
    // Initial check
    _checkBatteryLevel();
  }

  void _checkBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (level != _currentLevel) {
        _currentLevel = level;
        _levelController.add(level);
        debugPrint('Battery level: $level%');
      }
    } catch (e) {
      debugPrint('Battery check error: $e');
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _levelController.close();
  }
}
