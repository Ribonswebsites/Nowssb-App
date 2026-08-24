/// The app's own switches, remembered between launches.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings._();
  static final Settings instance = Settings._();

  static const _kPlus = 'nwsb_fashplus_v2';
  static const _kHome = 'nwsb_home_mode';
  static const _kFashionHeroFix = 'nwsb_fashion_hero_fix_v1';
  static const _kVoice = 'nwsb_pw_voice';
  static const _kLoop = 'nwsb_pw_loop';
  static const _kReps = 'nwsb_pw_reps';
  static const _kSpeed = 'nwsb_pw_speed';
  static const _kVol = 'nwsb_pw_volume';
  static const _kEq = 'nwsb_pw_eq';
  static const _kQuality = 'nwsb_pw_quality';
  static const _kBass = 'nwsb_pw_bass';
  static const _kCrossfade = 'nwsb_pw_crossfade';
  static const _kSleep = 'nwsb_pw_sleep';
  static const _kDownload = 'nwsb_pw_download';
  static const _kPlaylist = 'nwsb_pw_playlist';
  static const _kNowPlaying = 'nwsb_pw_nowplaying';

  bool _fashionPlus = true;
  bool _fashionHome = true;
  String _voice = 'female';
  String _loop = 'off';
  int _reps = 7;
  double _speed = 1;
  double _volume = 0.85;
  String _eq = 'flat';
  List<double> _bands = List<double>.filled(7, 0);
  String _output = 'speaker';
  bool _qualityHigh = true;
  String _quality = 'High';
  bool _bass = true;
  String _crossfade = '5 Sec';
  String _sleep = 'Off';
  bool _download = true;
  String _playlist = 'Classic';
  String _nowPlaying = 'On';
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
  String get quality => _quality;
  bool get bassBoost => _bass;
  String get crossfade => _crossfade;
  String get sleepTimer => _sleep;
  bool get downloadOnly => _download;
  String get playlist => _playlist;
  String get nowPlaying => _nowPlaying;
  bool get animationOn => _animation;
  bool get notifyOn => _notify;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _fashionPlus = p.getBool(_kPlus) ?? true;
      _fashionHome = p.getBool(_kHome) ?? true;
      // Existing 9.6.8 installs persisted Normal Home, which hid the
      // August 15 TV Hero. Move them to the corrected Fashion Hero once;
      // afterward the user’s explicit Normal/Fashion choice is respected.
      final heroFixApplied = p.getBool(_kFashionHeroFix) ?? false;
      if (!heroFixApplied) {
        _fashionHome = true;
        await p.setBool(_kHome, true);
        await p.setBool(_kFashionHeroFix, true);
      }
      _voice = p.getString(_kVoice) ?? 'female';
      _loop = p.getString(_kLoop) ?? 'off';
      _reps = p.getInt(_kReps) ?? 7;
      _speed = p.getDouble(_kSpeed) ?? 1;
      _volume = p.getDouble(_kVol) ?? 0.85;
      _eq = p.getString(_kEq) ?? 'flat';
      _quality = p.getString(_kQuality) ?? (p.getBool('nwsb_pw_quality_high') == false ? 'Normal' : 'High');
      _qualityHigh = _quality == 'High' || _quality == 'Lossless';
      _bass = p.getBool(_kBass) ?? true;
      _crossfade = p.getString(_kCrossfade) ?? '5 Sec';
      _sleep = p.getString(_kSleep) ?? 'Off';
      _download = p.getBool(_kDownload) ?? true;
      _playlist = p.getString(_kPlaylist) ?? 'Classic';
      _nowPlaying = p.getString(_kNowPlaying) ?? 'On';
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
    _saveInt(_kReps, _reps);
  }

  void setSpeed(double v) {
    _speed = v.clamp(0.5, 2.0);
    notifyListeners();
    _saveDouble(_kSpeed, _speed);
  }

  void setVolume(double v) {
    _volume = v.clamp(0, 1);
    notifyListeners();
    _saveDouble(_kVol, _volume);
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

  String cycleOutput() {
    _output = _output == 'speaker'
        ? 'earpiece'
        : _output == 'earpiece'
            ? 'bluetooth'
            : 'speaker';
    notifyListeners();
    return _output;
  }

  void setQuality(String v) {
    _quality = v;
    _qualityHigh = v == 'High' || v == 'Lossless';
    notifyListeners();
    _saveStr(_kQuality, v);
  }

  void toggleBass() {
    _bass = !_bass;
    notifyListeners();
    _saveBool(_kBass, _bass);
  }

  void setCrossfade(String v) {
    _crossfade = v;
    notifyListeners();
    _saveStr(_kCrossfade, v);
  }

  void setSleepTimer(String v) {
    _sleep = v;
    notifyListeners();
    _saveStr(_kSleep, v);
  }

  void toggleDownloadOnly() {
    _download = !_download;
    notifyListeners();
    _saveBool(_kDownload, _download);
  }

  void setPlaylist(String v) {
    _playlist = v;
    notifyListeners();
    _saveStr(_kPlaylist, v);
  }

  void setNowPlaying(String v) {
    _nowPlaying = v;
    notifyListeners();
    _saveStr(_kNowPlaying, v);
  }

  void toggleQuality() {
    setQuality(_qualityHigh ? 'Normal' : 'High');
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

  Future<void> _saveInt(String k, int v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(k, v);
    } catch (_) {}
  }

  Future<void> _saveDouble(String k, double v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(k, v);
    } catch (_) {}
  }
}
