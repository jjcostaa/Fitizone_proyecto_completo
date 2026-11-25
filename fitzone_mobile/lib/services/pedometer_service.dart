import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de Podómetro en tiempo real aislado por cuenta de usuario.
/// Guarda pasos diarios y meta diaria de forma independiente para cada usuarioId.
class PedometerService extends ChangeNotifier {
  static const String _kStepsPrefix = 'fitzone_steps_';
  static const String _kGoalPrefix = 'fitzone_steps_goal_';

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  String _userId = '';
  int _stepsToday = 0;
  int _dailyGoal = 6000;
  bool _isTracking = false;
  bool _sensorAvailable = true;
  double _lastMagnitude = 0.0;
  DateTime _lastStepTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _goalNotifiedToday = false;

  VoidCallback? onGoalReached;

  String get userId => _userId;
  int get stepsToday => _stepsToday;
  int get dailyGoal => _dailyGoal;
  bool get isTracking => _isTracking;
  bool get sensorAvailable => _sensorAvailable;
  double get progress => (_stepsToday / (_dailyGoal > 0 ? _dailyGoal : 1)).clamp(0.0, 1.0);
  double get distanceKm => _stepsToday * 0.00075;
  double get caloriesKcal => _stepsToday * 0.042;

  String get _todayKey {
    final now = DateTime.now();
    return '$_kStepsPrefix${_userId}_${now.year}_${now.month}_${now.day}';
  }

  String get _goalKey => '$_kGoalPrefix$_userId';

  Future<void> initForUser(String userId) async {
    stopTracking();
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    _stepsToday = userId.isEmpty ? 0 : (prefs.getInt(_todayKey) ?? 0);
    _dailyGoal = userId.isEmpty ? 6000 : (prefs.getInt(_goalKey) ?? 6000);
    _goalNotifiedToday = _stepsToday >= _dailyGoal;
    notifyListeners();
  }

  void resetSession() {
    stopTracking();
    _userId = '';
    _stepsToday = 0;
    _dailyGoal = 6000;
    _goalNotifiedToday = false;
    notifyListeners();
  }

  void startTracking() {
    if (_isTracking || _userId.isEmpty) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _sensorAvailable = false;
      _isTracking = true;
      notifyListeners();
      return;
    }

    try {
      _subscription = userAccelerometerEventStream().listen(
        (event) {
          final magnitude = math.sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final now = DateTime.now();
          if (magnitude > 2.2 &&
              _lastMagnitude <= 2.2 &&
              now.difference(_lastStepTime).inMilliseconds > 320) {
            _lastStepTime = now;
            _incrementSteps(1);
          }
          _lastMagnitude = magnitude;
        },
        onError: (_) {
          _sensorAvailable = false;
          notifyListeners();
        },
      );
      _sensorAvailable = true;
      _isTracking = true;
      notifyListeners();
    } catch (_) {
      _sensorAvailable = false;
      _isTracking = false;
      notifyListeners();
    }
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _isTracking = false;
    notifyListeners();
  }

  Future<void> addSimulatedSteps(int count) async {
    await _incrementSteps(count);
  }

  Future<void> resetToday() async {
    _stepsToday = 0;
    _goalNotifiedToday = false;
    if (_userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_todayKey, 0);
    }
    notifyListeners();
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal.clamp(1000, 30000);
    _goalNotifiedToday = _stepsToday >= _dailyGoal;
    if (_userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_goalKey, _dailyGoal);
    }
    notifyListeners();
  }

  Future<void> _incrementSteps(int delta) async {
    _stepsToday += delta;
    if (_userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_todayKey, _stepsToday);
    }

    if (!_goalNotifiedToday && _stepsToday >= _dailyGoal) {
      _goalNotifiedToday = true;
      onGoalReached?.call();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
