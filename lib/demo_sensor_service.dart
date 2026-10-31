
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

class DemoSensorService extends ChangeNotifier {
  final Random _random = Random();
  Timer? _timer;

  bool isRunning = false;

  // Dữ liệu mô phỏng, không phải dữ liệu đo thật.
  int leftSensorValue = 50;
  int rightSensorValue = 50;
  int heartRate = 72;

  DateTime? lastUpdated;

  void start() {
    if (isRunning) return;

    isRunning = true;
    lastUpdated = DateTime.now();
    notifyListeners();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        leftSensorValue = 45 + _random.nextInt(16);
        rightSensorValue = 45 + _random.nextInt(16);
        heartRate = 65 + _random.nextInt(26);
        lastUpdated = DateTime.now();

        notifyListeners();
      },
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
