/// The app's own switches, remembered between launches.
///
/// Two of them matter and both are real behaviour rather than decoration:
///
///   fashionPlus  Motion mode. Off, a page background is the clip's own
///                first frame — a still, costing nothing. On, it plays.
///                This is the switch the website calls Fashion Plus and it
///                is the one that trades battery for movement, so it is off
///                by default and the page that turns it on says so.
///
///   fashionHome  Which home. The dark one or the pale neumorphic one.
///
/// Written through [ChangeNotifier] so a screen rebuilds the moment the
/// switch moves, and through SharedPreferences so it survives a relaunch.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings._();
  static final Settings instance = Settings._();

  static const _kPlus = 'nwsb_fashplus';
  static const _kHome = 'nwsb_home_mode';
  static const _kVideo = 'nwsb_fashplus_video';
  static const _kImage = 'nwsb_fashplus_image';
  static const _kEq = 'nwsb_player_eq';
  static const _kQuality = 'nwsb_player_quality';
  static const _kBass = 'nwsb_player_bass';
  static const _kSpeed = 'nwsb_player_speed';
  static const _kCrossfade = 'nwsb_player_crossfade';
  static const _kSleep = 'nwsb_player_sleep';
  static const _kDownload = 'nwsb_player_download';
  static const _kPlaylist = 'nwsb_player_playlist';
  static const _kNowPlaying = 'nwsb_player_now_playing';

  /// One selected Fashion Plus film plays behind every primary page while
  /// motion mode is enabled.
  static const fashionVideos = <String>[
    'assets/video/fashion-plus-bg-5.mp4',
    'assets/video/fashion-plus-bg-6.mp4',
  ];
  static const fashionVideoNames = <String>[
    'Falling Diamonds',
    'Violet Silk',
  ];

  /// A saved still is used only while Fashion Plus is off. With no saved
  /// image, the normal NowssB black background is intentionally shown.
  static const fashionImages = <String>[
    'assets/fashion/fp-intro.webp',
    'assets/store/intro-store.webp',
    'assets/store/intro-words.webp',
    'assets/store/intro-meanings.webp',
    'assets/store/intro-ebooks.webp',
  ];
  static const fashionImageNames = <String>[
    'Fashion',
    'Store',
    'Word Atelier',
    'Meanings',
    'eBooks',
  ];

  bool _fashionPlus = false;
  bool _fashionHome = false;
  int _fashionVideo = 1;
  int _fashionImage = -1;
  int _backgroundTransition = 0;
  String _eq = 'flat';
  String _quality = 'Normal';
  bool _bassBoost = false;
  double _speed = 1.0;
  String _crossfade = 'Off';
  String _sleepTimer = 'Off';
  bool _downloadOnly = false;
  String _playlist = 'Classic';
  String _nowPlaying = 'On';

  /// Motion mode: do page backgrounds play, or hold their first frame?
  bool get fashionPlus => _fashionPlus;

  /// Which home is behind the Connect tab.
  bool get fashionHome => _fashionHome;

  int get fashionVideoIndex => _fashionVideo;
  int get fashionImageIndex => _fashionImage;
  String get fashionVideoAsset => fashionVideos[_fashionVideo];
  String? get fashionImageAsset =>
      _fashionImage < 0 ? null : fashionImages[_fashionImage];
  int get backgroundTransition => _backgroundTransition;
  String get eq => _eq;
  String get quality => _quality;
  bool get bassBoost => _bassBoost;
  double get speed => _speed;
  String get crossfade => _crossfade;
  String get sleepTimer => _sleepTimer;
  bool get downloadOnly => _downloadOnly;
  String get playlist => _playlist;
  String get nowPlaying => _nowPlaying;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _fashionPlus = p.getBool(_kPlus) ?? false;
      _fashionHome = p.getBool(_kHome) ?? false;
      _fashionVideo = _validIndex(
        p.getInt(_kVideo) ?? _fashionVideo,
        fashionVideos.length,
        fallback: 1,
      );
      _fashionImage = _validImageIndex(p.getInt(_kImage) ?? _fashionImage);
      _eq = p.getString(_kEq) ?? _eq;
      _quality = p.getString(_kQuality) ?? _quality;
      _bassBoost = p.getBool(_kBass) ?? _bassBoost;
      _speed = p.getDouble(_kSpeed) ?? _speed;
      _crossfade = p.getString(_kCrossfade) ?? _crossfade;
      _sleepTimer = p.getString(_kSleep) ?? _sleepTimer;
      _downloadOnly = p.getBool(_kDownload) ?? _downloadOnly;
      _playlist = p.getString(_kPlaylist) ?? _playlist;
      _nowPlaying = p.getString(_kNowPlaying) ?? _nowPlaying;
      notifyListeners();
    } catch (_) {
      // A platform that refuses storage is not a reason to fail to start.
      // The defaults are the safe ones: still backgrounds, pale home.
    }
  }

  Future<void> setFashionPlus(bool on) async {
    if (_fashionPlus == on) return;
    _fashionPlus = on;
    _advanceBackgroundTransition();
    await _save(_kPlus, on);
  }

  Future<void> setFashionHome(bool on) async {
    if (_fashionHome == on) return;
    _fashionHome = on;
    _advanceBackgroundTransition();
    await _save(_kHome, on);
  }

  Future<void> setFashionVideo(int index) async {
    final next = _validIndex(index, fashionVideos.length, fallback: 1);
    if (_fashionVideo == next) return;
    _fashionVideo = next;
    _advanceBackgroundTransition();
    await _saveInt(_kVideo, next);
  }

  Future<void> setFashionImage(int? index) async {
    final next = index == null ? -1 : _validImageIndex(index);
    if (_fashionImage == next) return;
    _fashionImage = next;
    _advanceBackgroundTransition();
    await _saveInt(_kImage, next);
  }

  static int _validIndex(int index, int length, {required int fallback}) =>
      index >= 0 && index < length ? index : fallback;

  static int _validImageIndex(int index) =>
      index >= 0 && index < fashionImages.length ? index : -1;

  Future<void> setEq(String value) async { _eq = value; await _save(_kEq, value); notifyListeners(); }
  Future<void> setQuality(String value) async { _quality = value; await _save(_kQuality, value); notifyListeners(); }
  Future<void> toggleBass() async { _bassBoost = !_bassBoost; await _save(_kBass, _bassBoost); notifyListeners(); }
  Future<void> setSpeed(double value) async { _speed = value; await _saveDouble(_kSpeed, value); notifyListeners(); }
  Future<void> setCrossfade(String value) async { _crossfade = value; await _save(_kCrossfade, value); notifyListeners(); }
  Future<void> setSleepTimer(String value) async { _sleepTimer = value; await _save(_kSleep, value); notifyListeners(); }
  Future<void> toggleDownloadOnly() async { _downloadOnly = !_downloadOnly; await _save(_kDownload, _downloadOnly); notifyListeners(); }
  Future<void> setPlaylist(String value) async { _playlist = value; await _save(_kPlaylist, value); notifyListeners(); }
  Future<void> setNowPlaying(String value) async { _nowPlaying = value; await _save(_kNowPlaying, value); notifyListeners(); }

  /// A tab does not change the selected asset, but it should still make the
  /// background arrive gently rather than appearing as a hard cut.
  void fadeBackgroundForNavigation() => _advanceBackgroundTransition();

  void _advanceBackgroundTransition() {
    _backgroundTransition++;
    notifyListeners();
  }

  Future<void> _save(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }

  Future<void> _saveDouble(String k, double v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(k, v);
    } catch (_) {}
  }

  Future<void> _saveInt(String k, int v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(k, v);
    } catch (_) {}
  }
}
