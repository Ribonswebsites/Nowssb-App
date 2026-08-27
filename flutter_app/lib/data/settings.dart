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

  /// One selected Fashion Plus film plays behind every primary page while
  /// motion mode is enabled.
  static const fashionVideos = <String>[
    'assets/video/fashion-plus-bg.mp4',
    'assets/video/fashion-plus-bg-1.mp4',
    'assets/video/fashion-plus-bg-2.mp4',
    'assets/video/fashion-plus-bg-3.mp4',
    'assets/video/fashion-plus-bg-5.mp4',
    'assets/video/fashion-plus-bg-6.mp4',
  ];
  static const fashionVideoNames = <String>[
    'Shattered Glass',
    'Background Two',
    'Background Three',
    'Background Four',
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
  int _fashionVideo = 5;
  int _fashionImage = -1;

  /// Motion mode: do page backgrounds play, or hold their first frame?
  bool get fashionPlus => _fashionPlus;

  /// Which home is behind the Connect tab.
  bool get fashionHome => _fashionHome;

  int get fashionVideoIndex => _fashionVideo;
  int get fashionImageIndex => _fashionImage;
  String get fashionVideoAsset => fashionVideos[_fashionVideo];
  String? get fashionImageAsset =>
      _fashionImage < 0 ? null : fashionImages[_fashionImage];

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _fashionPlus = p.getBool(_kPlus) ?? false;
      _fashionHome = p.getBool(_kHome) ?? false;
      _fashionVideo = _validIndex(
        p.getInt(_kVideo) ?? _fashionVideo,
        fashionVideos.length,
        fallback: 5,
      );
      _fashionImage = _validImageIndex(p.getInt(_kImage) ?? _fashionImage);
      notifyListeners();
    } catch (_) {
      // A platform that refuses storage is not a reason to fail to start.
      // The defaults are the safe ones: still backgrounds, pale home.
    }
  }

  Future<void> setFashionPlus(bool on) async {
    if (_fashionPlus == on) return;
    _fashionPlus = on;
    notifyListeners();
    await _save(_kPlus, on);
  }

  Future<void> setFashionHome(bool on) async {
    if (_fashionHome == on) return;
    _fashionHome = on;
    notifyListeners();
    await _save(_kHome, on);
  }

  Future<void> setFashionVideo(int index) async {
    final next = _validIndex(index, fashionVideos.length, fallback: 5);
    if (_fashionVideo == next) return;
    _fashionVideo = next;
    notifyListeners();
    await _saveInt(_kVideo, next);
  }

  Future<void> setFashionImage(int? index) async {
    final next = index == null ? -1 : _validImageIndex(index);
    if (_fashionImage == next) return;
    _fashionImage = next;
    notifyListeners();
    await _saveInt(_kImage, next);
  }

  static int _validIndex(int index, int length, {required int fallback}) =>
      index >= 0 && index < length ? index : fallback;

  static int _validImageIndex(int index) =>
      index >= 0 && index < fashionImages.length ? index : -1;

  Future<void> _save(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }

  Future<void> _saveInt(String k, int v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(k, v);
    } catch (_) {}
  }
}
