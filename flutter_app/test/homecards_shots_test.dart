// Shots + checks for the Zen Plus, eBooks, Meaning Store offers and Sound
// Library cards on the Normal home (Ribon 11-11). 390 wide.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/widgets/concept/normal/ebooks.dart';
import 'package:nowssb/widgets/concept/normal/fashion_plus_entry.dart';
import 'package:nowssb/widgets/sound_glass.dart';

import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

class _FakePlayer extends ChangeNotifier implements SlPlayer {
  _FakePlayer({this.active = false, this.playing = false, this.word});
  @override
  bool active;
  @override
  bool playing;
  @override
  Word? word;
  int toggles = 0;
  @override
  Future<void> toggle() async {
    toggles++;
    playing = !playing;
    notifyListeners();
  }
}

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: Scaffold(
            backgroundColor: const Color(0xFFEDEFF3),
            body: SingleChildScrollView(child: RepaintBoundary(key: const ValueKey('shot'), child: child)),
          ),
        ),
      ),
    );

Future<void> _shot(WidgetTester t, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 300));
  final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await t.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    final dir = Directory('/workspace/team-plan/shots/homecards');
    if (dir.existsSync()) File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _size(WidgetTester t, double w) async {
  t.view.physicalSize = Size(w * 3, 1400 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

List<Word> _words() {
  final j = jsonDecode(File('assets/content/library.json').readAsStringSync()) as Map<String, dynamic>;
  return [for (final e in j["items"] as List) Word.from(e as Map<String, dynamic>)!];
}

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    if (!homeFontsReady) {
      for (final fam in ['DM Sans', 'Roboto']) {
        await (FontLoader(fam)..addFont(Future.value(ByteData.sublistView(File('assets/fonts/NotoSans-PIE.ttf').readAsBytesSync())))).load();
      }
    }
  });

  testWidgets('Zen Plus shot', (t) async {
    await _size(t, 390);
    await t.pumpWidget(_app(NFashionPlusEntry(onEnter: () {})));
    await _shot(t, 'zenplus');
    expect(t.takeException(), isNull);
  });

  testWidgets('eBooks shot', (t) async {
    await _size(t, 390);
    await t.pumpWidget(_app(NEbooks(onBrowse: () {}, books: [for (final b in kEbBooks) (b.key, b.title)])));
    await _shot(t, 'ebooks');
    expect(t.takeException(), isNull);
  });

  testWidgets('Meaning Store offers shot', (t) async {
    await _size(t, 390);
    await t.pumpWidget(_app(V4StoreEarn(onStore: () {})));
    await _shot(t, 'offers');
    expect(t.takeException(), isNull);
  });

  testWidgets('Sound Library shots: idle, playing, empty', (t) async {
    await _size(t, 390);
    final words = _words();
    final idle = _FakePlayer();
    var opened = <String>[];
    await t.pumpWidget(_app(V4SoundLibrary(
      onTap: () => opened.add('library'),
      onPlay: (w, title) => opened.add('play:${w.length}:$title'),
      words: words,
      player: idle,
      day: 3,
    )));
    await _shot(t, 'sound-idle');
    await t.tap(find.byKey(const ValueKey('v4-sound-listen')));
    await t.pump();
    expect(opened.last, startsWith('play:4:'));
    await t.tap(find.byKey(const ValueKey('v4-sound-row-0')));
    await t.pump();
    expect(opened.last, startsWith('play:1:'));
    expect(idle.toggles, 0);

    final live = _FakePlayer(active: true, playing: true, word: words[5]);
    await t.pumpWidget(_app(V4SoundLibrary(onTap: () {}, onPlay: (_, __) {}, words: words, player: live, day: 3)));
    await _shot(t, 'sound-playing');
    expect(find.text('NOW PLAYING'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('v4-sound-play')));
    await t.pump();
    expect(live.toggles, 1);
    expect(find.text('PAUSED'), findsOneWidget);

    await t.pumpWidget(_app(V4SoundLibrary(onTap: () => opened.add('lib2'), words: const [], player: _FakePlayer())));
    await _shot(t, 'sound-empty');
    await t.tap(find.byKey(const ValueKey('v4-sound-listen')));
    expect(opened.last, 'lib2');
    expect(t.takeException(), isNull);
  });

  for (final (w, s) in const [(320.0, 1.0), (360.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
    testWidgets('no overflow at $w@$s', (t) async {
      await _size(t, w);
      final words = _words();
      await t.pumpWidget(_app(
        Column(children: [
          NFashionPlusEntry(onEnter: () {}),
          NEbooks(onBrowse: () {}, books: [for (final b in kEbBooks) (b.key, b.title)]),
          V4StoreEarn(onStore: () {}),
          V4SoundLibrary(onTap: () {}, words: words, player: _FakePlayer(), day: 1),
        ]),
        scale: s,
      ));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull);
    }, skip: !homeFontsReady);
  }
}
