import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'database/app_database.dart';

/// Shared simulated sensor stream used by Dashboard, Alerts and Reports.
/// All readings and alerts generated here are DEMO data, not medical measurements.
class DemoSensorService extends ChangeNotifier {
  DemoSensorService._();

  static final DemoSensorService instance = DemoSensorService._();

  final Random _random = Random();
  final Map<String, DateTime> _lastAlertAt = {};

  Timer? _timer;
  bool isRunning = false;

  int leftSensorValue = 50;
  int rightSensorValue = 50;
  int heartRate = 72;
  int _tickCount = 0;

  DateTime? lastUpdated;

  Future<void> _saveMeasurement() async {
    if (lastUpdated == null) return;

    try {
      await AppDatabase.instance.insertMeasurement(
        leftSensorValue: leftSensorValue,
        rightSensorValue: rightSensorValue,
        heartRate: heartRate,
        measuredAt: lastUpdated!,
      );
    } catch (e) {
      debugPrint('Failed to save demo measurement: $e');
    }
  }

  Future<void> _evaluateAlerts() async {
    final now = lastUpdated ?? DateTime.now();
    final difference = (leftSensorValue - rightSensorValue).abs();

    String? key;
    String? title;
    String? message;
    String severity = 'Medium';

    if (difference >= 35) {
      key = 'arm_difference';
      title = 'Demo alert: Arm sensor difference';
      message =
          'The simulated left/right sensor difference reached $difference units. This is a deliberately generated demo event, not a real assessment of arm strength.';
      severity = 'High';
    } else if (heartRate >= 120) {
      key = 'heart_rate';
      title = 'Demo alert: Elevated simulated heart rate';
      message =
          'The simulated heart-rate value reached $heartRate BPM. This value is generated for testing the alert workflow and is not a real heart-rate measurement.';
      severity = 'High';
    } else if (difference >= 20 || heartRate >= 100) {
      key = difference >= 20 ? 'arm_difference_medium' : 'heart_rate_medium';
      title = difference >= 20
          ? 'Demo notice: Arm sensor values differ'
          : 'Demo notice: Simulated heart rate changed';
      message = difference >= 20
          ? 'The simulated left/right sensor difference is $difference units.'
          : 'The simulated heart-rate value is $heartRate BPM.';
      severity = 'Medium';
    }

    if (key == null) return;

    final previous = _lastAlertAt[key];
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 45)) {
      return;
    }

    _lastAlertAt[key] = now;
    try {
      await AppDatabase.instance.insertAlert(
        title: title!,
        message: '$message This is demo-only data; it is not a medical alert.',
        severity: severity,
        createdAt: now,
      );
    } catch (e) {
      debugPrint('Failed to save demo alert: $e');
    }
  }

  Future<void> _saveAndEvaluate() async {
    await _saveMeasurement();
    await _evaluateAlerts();
    notifyListeners();
  }

  void _generateReading() {
    _tickCount++;

    // One clearly abnormal simulated event every third update makes the
    // alert workflow easy to demonstrate. Other updates return to normal-ish
    // values so the charts show visible movement rather than a flat line.
    if (_tickCount % 3 == 0) {
      final leftIsLower = _tickCount % 2 == 0;
      leftSensorValue = leftIsLower
          ? 8 + _random.nextInt(13)
          : 80 + _random.nextInt(19);
      rightSensorValue = leftIsLower
          ? 80 + _random.nextInt(19)
          : 8 + _random.nextInt(13);
      heartRate = 118 + _random.nextInt(29);
    } else {
      leftSensorValue = 32 + _random.nextInt(37);
      rightSensorValue = 32 + _random.nextInt(37);
      heartRate = 65 + _random.nextInt(36);
    }

    lastUpdated = DateTime.now();
  }

  void start() {
    if (isRunning) return;

    isRunning = true;
    _tickCount = 0;

    // Trigger a visible event immediately when the user presses Start Demo.
    leftSensorValue = 12 + _random.nextInt(8);
    rightSensorValue = 84 + _random.nextInt(12);
    heartRate = 126 + _random.nextInt(16);
    lastUpdated = DateTime.now();

    unawaited(_saveAndEvaluate());

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isRunning) return;
      _generateReading();
      unawaited(_saveAndEvaluate());
    });

    notifyListeners();
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
