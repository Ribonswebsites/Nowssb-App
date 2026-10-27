import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nowssb/data/billing_config.dart';
import 'package:nowssb/data/play_subscriptions.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings persistence', () {
    test('Now Playing View and Playlist View are separate and both persist', () async {
      SharedPreferences.setMockInitialValues({});
      final s = Settings.instance;
      await s.setPlaylist('Compact');
      await s.setNowView('Minimal');
      expect(s.playlist, 'Compact');
      expect(s.nowView, 'Minimal');
      final p = await SharedPreferences.getInstance();
      expect(p.getString('nwsb_player_playlist'), 'Compact');
      expect(p.getString('nwsb_player_now_view'), 'Minimal');
    });

    test('player options persist to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final s = Settings.instance;
      await s.setQuality('High');
      await s.setCrossfade('5 Sec');
      await s.setSleepTimer('30 Min');
      await s.setNowPlaying('Off');
      await s.setEq('deep');
      await s.load();
      expect(s.quality, 'High');
      expect(s.crossfade, '5 Sec');
      expect(s.sleepTimer, '30 Min');
      expect(s.nowPlaying, 'Off');
      expect(s.eq, 'deep');
    });
  });

  group('Subscriptions (mocked Play)', () {
    test('buy / restore off Android say why instead of breaking', () async {
      final b = PlaySubscriptions.instance;
      final r = await b.buy('frequency', yearly: false);
      expect(r.ok, isFalse);
      expect(r.message, isNotEmpty);
      final rr = await b.restore();
      expect(rr.ok, isFalse);
      expect(b.busy, isFalse);
    });

    test('local-currency Play price is what the card shows', () {
      final id = playPlanFor('frequency', yearly: false)!.productId;
      PlaySubscriptions.instance.debugSetProducts([
        ProductDetails(id: id, title: 'Frequency', description: '', price: '₹499.00', rawPrice: 499, currencyCode: 'INR'),
      ]);
      expect(PlaySubscriptions.instance.priceFor(id), '₹499.00');
    });
  });

  group('Player logic', () {
    test('Next/Prev end the current run so the new word starts', () {
      final src = File('lib/screens/practice_player.dart').readAsStringSync();
      final move = src.substring(src.indexOf('Future<void> _move(int direction)'));
      expect(move.substring(0, 1400), contains('_playGen++'));
      expect(move.substring(0, 1800), contains('_playing = false'));
    });

    test('sleep timer is only re-armed when its own choice changes', () {
      final src = File('lib/screens/practice_player.dart').readAsStringSync();
      expect(src, contains('Settings.instance.sleepTimer != _armedSleep'));
    });

    test('mini player: a paused run cannot restart on Loop or flip the next run', () {
      final src = File('lib/data/playback_session.dart').readAsStringSync();
      expect(src, contains('if (_loop && _active && alive())'));
      expect(src, contains('if (_gen == gen && _playing)'));
    });
  });

  test('a bought word shows as owned (server doc id matches the app)', () {
    final e = Entitlements.instance;
    e.debugSet(uid: 'u1', owned: {});
    expect(e.ownsOrIncluded('word:aarogya'), isFalse);
    e.debugSet(uid: 'u1', owned: {ownedDocId(Entitlements.wordItemId('AAROGYA'))});
    expect(e.ownsOrIncluded('word:aarogya'), isTrue);
    expect(e.ownsItem('word:aarogya'), isTrue);
  });
}
