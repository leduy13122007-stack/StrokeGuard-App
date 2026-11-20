
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'database/app_database.dart';

class DemoSensorService extends ChangeNotifier {
  final Random _random = Random();
  Timer? _timer;

  bool isRunning = false;

  int leftSensorValue = 50;
  int rightSensorValue = 50;
  int heartRate = 72;

  DateTime? lastUpdated;

  Future<void> _saveMeasurement() async {
  if (lastUpdated == null) return;

  try {
    final id = await AppDatabase.instance.insertMeasurement(
      leftSensorValue: leftSensorValue,
      rightSensorValue: rightSensorValue,
      heartRate: heartRate,
      measuredAt: lastUpdated!,
    );

    debugPrint('Measurement saved successfully. ID: $id');
  } catch (e) {
    debugPrint('Failed to save measurement: $e');
  }
}

  void start() {
    if (isRunning) return;

    isRunning = true;
    lastUpdated = DateTime.now();

    _saveMeasurement();
    notifyListeners();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        leftSensorValue = 45 + _random.nextInt(16);
        rightSensorValue = 45 + _random.nextInt(16);
        heartRate = 65 + _random.nextInt(26);
        lastUpdated = DateTime.now();

        _saveMeasurement();
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
