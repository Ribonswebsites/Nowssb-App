/// The app's own switches, remembered between launches.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings._();
  static final Settings instance = Settings._();

  static const _kPlus = 'nwsb_fashplus_v2';
  static const _kHome = 'nwsb_home_mode';
  static const _kVoice = 'nwsb_pw_voice';
  static const _kLoop = 'nwsb_pw_loop';
  static const _kReps = 'nwsb_pw_reps';
  static const _kSpeed = 'nwsb_pw_speed';
  static const _kVol = 'nwsb_pw_volume';
  static const _kEq = 'nwsb_pw_eq';

  bool _fashionPlus = true;
  bool _fashionHome = false;
  String _voice = 'female';
  String _loop = 'off';
  int _reps = 7;
  double _speed = 1;
  double _volume = 0.85;
  String _eq = 'flat';
  List<double> _bands = List<double>.filled(7, 0);
  String _output = 'speaker';
  bool _qualityHigh = true;
  bool _animation = true;
  bool _notify = true;

  static const Map<String, List<double>> _eqPresets = {
    'flat': [0, 0, 0, 0, 0, 0, 0],
    'focus': [-2, -1, 1, 4, 5, 1, -2],
    'deep': [6, 5, 2, 0, -1, -3, -4],
    'bright': [-3, -2, 0, 1, 3, 6, 7],
  };

  bool get fashionPlus => _fashionPlus;
  bool get fashionHome => _fashionHome;
  String get voice => _voice;
  String get loop => _loop;
  int get reps => _reps;
  double get speed => _speed;
  double get volume => _volume;
  String get eq => _eq;
  List<double> get bands => List.unmodifiable(_bands);
  String get output => _output;
  bool get qualityHigh => _qualityHigh;
  bool get animationOn => _animation;
  bool get notifyOn => _notify;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _fashionPlus = p.getBool(_kPlus) ?? true;
      _fashionHome = p.getBool(_kHome) ?? false;
      _voice = p.getString(_kVoice) ?? 'female';
      _loop = p.getString(_kLoop) ?? 'off';
      _reps = p.getInt(_kReps) ?? 7;
      _speed = p.getDouble(_kSpeed) ?? 1;
      _volume = p.getDouble(_kVol) ?? 0.85;
      _eq = p.getString(_kEq) ?? 'flat';
      _bands = List<double>.from(_eqPresets[_eq] ?? _eqPresets['flat']!);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setFashionPlus(bool on) async {
    if (_fashionPlus == on) return;
    _fashionPlus = on;
    notifyListeners();
    await _saveBool(_kPlus, on);
  }

  Future<void> setFashionHome(bool on) async {
    if (_fashionHome == on) return;
    _fashionHome = on;
    notifyListeners();
    await _saveBool(_kHome, on);
  }

  void setVoice(String v) {
    _voice = v;
    notifyListeners();
    _saveStr(_kVoice, v);
  }

  String cycleLoop() {
    _loop = _loop == 'off' ? 'once' : _loop == 'once' ? 'infinite' : 'off';
    notifyListeners();
    _saveStr(_kLoop, _loop);
    return _loop;
  }

  void setReps(int n) {
    _reps = n.clamp(1, 99);
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_kReps, _reps))
        .catchError((_) {});
  }

  void setSpeed(double v) {
    _speed = v.clamp(0.7, 1.5);
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setDouble(_kSpeed, _speed))
        .catchError((_) {});
  }

  void setVolume(double v) {
    _volume = v.clamp(0, 1);
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setDouble(_kVol, _volume))
        .catchError((_) {});
  }

  void setEq(String name, [List<double>? bands]) {
    _eq = name;
    if (name != 'custom') {
      _bands = List<double>.from(_eqPresets[name] ?? _eqPresets['flat']!);
    } else if (bands != null) {
      _bands = bands;
    }
    notifyListeners();
    _saveStr(_kEq, name);
  }

  void setBand(int i, double v) {
    _bands = List<double>.from(_bands);
    _bands[i] = v.clamp(-12, 12);
    _eq = 'custom';
    notifyListeners();
  }

  void setOutput(String v) {
    _output = v;
    notifyListeners();
  }

  void toggleQuality() {
    _qualityHigh = !_qualityHigh;
    notifyListeners();
  }

  void toggleAnimation() {
    _animation = !_animation;
    notifyListeners();
  }

  void toggleNotify() {
    _notify = !_notify;
    notifyListeners();
  }

  Future<void> _saveBool(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }

  Future<void> _saveStr(String k, String v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(k, v);
    } catch (_) {}
  }
}
