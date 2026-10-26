/// The Widgets & features page: every text wraps (no ellipsis, no overflow)
/// on small phones and large type, every card and button does something,
/// and the Fashion background dim updates live and persists.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/fashion_bg_dim.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/concept/doors/film_dial.dart';
import 'package:nowssb/screens/widgets_page.dart';

import 'fake_video_platform.dart';

class _Pushes extends NavigatorObserver {
  final names = <String>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is MaterialPageRoute && navigator != null) {
      names.add(route.builder(navigator!.context).runtimeType.toString());
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    FashionBgDim.debugDialPhase = 0.25; // frozen sparks: stable renders
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<_Pushes> pump(WidgetTester tester,
      {double width = 390, double height = 3200, double scale = 1}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final obs = _Pushes();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [obs],
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (c) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(c).push(
                  MaterialPageRoute<void>(builder: (_) => const WidgetsPage())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    obs.names.clear();
    return obs;
  }

  Future<void> tapAndSee(WidgetTester tester, _Pushes obs, Finder f, String screen) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
    expect(obs.names, contains(screen), reason: '$f should open $screen');
    expect(tester.takeException(), isNull);
    obs.names.clear();
  }

  Future<void> reopen(WidgetTester tester, _Pushes obs) async {
    Navigator.of(tester.element(find.byType(Scaffold).first)).popUntil((r) => r.isFirst);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    obs.names.clear();
  }

  group('no truncation', () {
    for (final (w, sc) in [(360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
      testWidgets('${w.toInt()}@$sc: no ellipsis, no clipped lines, no overflow', (tester) async {
        await Settings.instance.setFashionPlus(true);
        await Settings.instance.setFashionHome(true);
        await pump(tester, width: w, scale: sc);
        expect(tester.takeException(), isNull);
        final paras = tester.renderObjectList<RenderParagraph>(
            find.descendant(of: find.byType(WidgetsPage), matching: find.byType(RichText)));
        expect(paras, isNotEmpty);
        for (final p in paras) {
          final t = p.text.toPlainText();
          expect(p.overflow == TextOverflow.ellipsis && p.maxLines != null, isFalse, reason: '"$t" can ellipsize');
          expect(p.didExceedMaxLines, isFalse, reason: '"$t" is cut');
        }
        for (final t in ['On the television', 'Full screen', 'Plain header', 'Apply now',
            'Personalised Healing', 'Notifications', 'What you have missed']) {
          expect(find.text(t), findsWidgets, reason: t);
        }
      });
    }
  });

  group('every card and button works', () {
    testWidgets('Hero header Apply changes the hero style', (tester) async {
      await Settings.instance.setHeroStyle('tv');
      await pump(tester);
      final apply = find.byKey(const ValueKey('hero-apply-full'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(Settings.instance.heroStyle, 'full');
      expect(find.byKey(const ValueKey('hero-apply-full')), findsNothing, reason: 'now "In use"');
      await Settings.instance.setHeroStyle('tv');
    });

    testWidgets('Jump to cards open their screens', (tester) async {
      final obs = await pump(tester);
      for (final (title, screen) in [
        ('Practice', 'PracticeScreen'),
        ('Sound Library', 'SoundLibraryScreen'),
        ('Progress', 'PracticeProgressScreen'),
        ('Store', 'StoreScreen'),
        ('Meaning', 'MeaningStoreScreen'),
        ('Notifications', 'NotificationsSettingsPage'),
      ]) {
        await tapAndSee(tester, obs, find.byKey(ValueKey('go-card-$title')), screen);
        await reopen(tester, obs);
      }
      await tapAndSee(tester, obs, find.byKey(const ValueKey('go-card-Profile')).first, 'ProfileScreen');
    });

    testWidgets('Connect goes back to the app', (tester) async {
      await pump(tester);
      final f = find.byKey(const ValueKey('go-card-Connect'));
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
      expect(find.byType(WidgetsPage), findsNothing);
    });

    testWidgets('Make it yours cards open their screens', (tester) async {
      final obs = await pump(tester);
      for (final (title, screen) in [
        ('Fashion Plus', 'FashionPlusScreen'),
        ('Player Settings', 'PlayerSettingsScreen'),
        ('Home buttons', 'QuickAccessScreen'),
        ('Personalised Healing', 'HealingPathScreen'),
      ]) {
        await tapAndSee(tester, obs, find.byKey(ValueKey('go-card-$title')), screen);
        await reopen(tester, obs);
      }
      await tapAndSee(tester, obs, find.byKey(const ValueKey('go-card-Profile')).last, 'ProfileScreen');
    });

    testWidgets('Make it yours switches and the Fashion home card toggle', (tester) async {
      await Settings.instance.setFashionPlus(false);
      await Settings.instance.setFashionHome(false);
      await Settings.instance.setShowHealing(false);
      await pump(tester);
      Finder sw(String title) =>
          find.descendant(of: find.byKey(ValueKey('go-card-$title')), matching: find.byType(Switch));
      for (final (title, read) in [
        ('Fashion Plus', () => Settings.instance.fashionPlus),
        ('Fashion home', () => Settings.instance.fashionHome),
        ('Personalised Healing', () => Settings.instance.showHealing),
      ]) {
        await tester.ensureVisible(sw(title));
        await tester.tap(sw(title));
        await tester.pumpAndSettle();
        expect(read(), isTrue, reason: '$title switch');
      }
      final home = find.byKey(const ValueKey('go-card-Fashion home'));
      await tester.ensureVisible(home);
      await tester.tapAt(tester.getBottomLeft(home) + const Offset(20, -10));
      await tester.pumpAndSettle();
      expect(Settings.instance.fashionHome, isFalse, reason: 'tapping the card toggles too');
      await Settings.instance.setFashionPlus(false);
      await Settings.instance.setShowHealing(false);
    });

    testWidgets('streak card: Practise opens practice; Add to home answers', (tester) async {
      final obs = await pump(tester);
      await tapAndSee(tester, obs, find.byKey(const ValueKey('home-widget-practise')), 'PracticeScreen');
      Navigator.of(tester.element(find.byType(WidgetsPage))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-widget-add')));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget, reason: 'off Android it explains how to add it');
    });
  });

  group('background dim (FilmDial)', () {
    final dial = find.byKey(const ValueKey('fashion-bg-dim-dial'));
    Color overlay(WidgetTester t) => t.widget<ColoredBox>(find.byKey(const ValueKey('fashion-bg-dim'))).color;

    /// Screen point on the dial arc for [v] (0..1), 270° from bottom-left.
    Offset at(WidgetTester t, double v) {
      final box = t.getRect(find.descendant(of: dial, matching: find.byType(LayoutBuilder)).first);
      final a = math.pi * .75 + math.pi * 1.5 * v;
      return box.center + Offset(math.cos(a), math.sin(a)) * (box.width / 2 - 18);
    }

    Future<SharedPreferences> start(WidgetTester tester, Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', ...prefs});
      await FashionBgDim.instance.set(FashionBgDim.defaultDim, persist: false);
      await FashionBgDim.instance.load();
      await Settings.instance.setFashionPlus(true);
      await Settings.instance.setFashionHome(true);
      addTearDown(() async {
        await FashionBgDim.instance.set(FashionBgDim.defaultDim, persist: false);
        await Settings.instance.setFashionPlus(false);
        await Settings.instance.setFashionHome(false);
      });
      await pump(tester);
      if (!FashionBgDim.useSlider) {
        await tester.ensureVisible(dial);
        await tester.pumpAndSettle();
      }
      return SharedPreferences.getInstance();
    }

    testWidgets('the dial shows film (1 - dim): default dim 0.45 opens at 55%', (tester) async {
      await start(tester, {});
      expect(dial, findsOneWidget);
      expect(find.byKey(const ValueKey('fashion-bg-dim-slider')), findsNothing);
      expect(tester.widget<FilmDial>(dial).value, closeTo(.55, 1e-9));
      expect(find.text('55'), findsOneWidget);
      expect(overlay(tester).a, closeTo(.45, .01));
    });

    testWidgets('dragging to 30% film dims live to 0.7; release saves dim 0.7', (tester) async {
      final prefs = await start(tester, {});
      final seen = <double>[];
      FashionBgDim.onDimChanged.add(seen.add);
      addTearDown(() => FashionBgDim.onDimChanged.remove(seen.add));

      final g = await tester.startGesture(at(tester, .55));
      // Sideways first so the dial's pan wins the arena over the page scroll.
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      for (final film in [.45, .2, .3]) {
        await g.moveTo(at(tester, film));
        await tester.pump();
        expect(overlay(tester).a, closeTo(1 - film, .02), reason: 'live at $film film');
        expect(prefs.getDouble(FashionBgDim.prefKey), isNull, reason: 'not saved mid-drag');
      }
      expect(find.text('30'), findsOneWidget);
      expect(seen.length, greaterThanOrEqualTo(3));
      await g.up();
      await tester.pump();
      expect(prefs.getDouble(FashionBgDim.prefKey), closeTo(.7, .02), reason: 'saved on release');
    });

    for (final (dim, film, label) in [(0.0, '100', 'Full film'), (0.45, '55', 'Soft glow'), (0.7, '30', 'Soft glow')]) {
      testWidgets('stored dim $dim shows $film% film ($label) and overlay alpha $dim', (tester) async {
        await start(tester, {FashionBgDim.prefKey: dim});
        expect(FashionBgDim.instance.value, dim);
        expect(tester.widget<FilmDial>(dial).value, closeTo(1 - dim, 1e-9));
        expect(find.descendant(of: dial, matching: find.text(film)), findsOneWidget);
        expect(find.descendant(of: dial, matching: find.text(label)), findsOneWidget);
        expect(overlay(tester).a, closeTo(dim, .005));
      });
    }

    testWidgets('a restart restores the saved dim', (tester) async {
      await start(tester, {FashionBgDim.prefKey: 0.2});
      expect(FashionBgDim.instance.value, .2);
      expect(tester.widget<FilmDial>(dial).value, closeTo(.8, 1e-9));
      expect(find.text('80'), findsOneWidget);
      expect(overlay(tester).a, closeTo(.2, .01));
    });

    testWidgets('a11y steps go in film direction and save (increase = more film = less dim)', (tester) async {
      final h = tester.ensureSemantics();
      final prefs = await start(tester, {});
      final node = find.semantics.byLabel(RegExp('Film visibility'));
      tester.semantics.performAction(node, SemanticsAction.increase);
      await tester.pump();
      expect(FashionBgDim.instance.value, closeTo(.35, .001));
      expect(prefs.getDouble(FashionBgDim.prefKey), closeTo(.35, .001));
      tester.semantics.performAction(node, SemanticsAction.decrease);
      tester.semantics.performAction(node, SemanticsAction.decrease);
      await tester.pump();
      expect(prefs.getDouble(FashionBgDim.prefKey), closeTo(.55, .001));
      expect(overlay(tester).a, closeTo(.55, .01));
      h.dispose();
    });

    for (final (w, sc) in [(360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
      testWidgets('dial lays out at ${w.toInt()}@$sc with no overflow', (tester) async {
        SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
        await Settings.instance.setFashionPlus(true);
        await Settings.instance.setFashionHome(true);
        addTearDown(() async {
          await Settings.instance.setFashionPlus(false);
          await Settings.instance.setFashionHome(false);
        });
        await pump(tester, width: w, scale: sc);
        await tester.ensureVisible(dial);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final r = tester.getRect(dial);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(w));
      });
    }

    testWidgets('slider fallback shows film % too: dragged to 0% film saves dim 1', (tester) async {
      FashionBgDim.useSlider = true;
      addTearDown(() => FashionBgDim.useSlider = false);
      final prefs = await start(tester, {});
      final slider = find.byKey(const ValueKey('fashion-bg-dim-slider'));
      expect(dial, findsNothing);
      expect(find.byKey(const ValueKey('fashion-bg-dim-value')), findsOneWidget);
      expect(find.text('55%'), findsOneWidget);
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      final g = await tester.startGesture(tester.getCenter(slider));
      await g.moveTo(Offset(tester.getTopLeft(slider).dx - 40, tester.getCenter(slider).dy));
      await tester.pump();
      expect(overlay(tester).a, closeTo(1, .01));
      await g.up();
      await tester.pumpAndSettle();
      expect(prefs.getDouble(FashionBgDim.prefKey), 1.0);
    });

    test('defaults to 0.45 and clamps', () async {
      SharedPreferences.setMockInitialValues({});
      await FashionBgDim.instance.load();
      expect(FashionBgDim.instance.value, 0.45);
      await FashionBgDim.instance.set(3);
      expect(FashionBgDim.instance.value, 1.0);
      await FashionBgDim.instance.set(FashionBgDim.defaultDim);
    });
  });
}
