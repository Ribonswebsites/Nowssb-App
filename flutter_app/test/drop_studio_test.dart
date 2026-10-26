import 'package:nowssb/screens/concept/drop_v5.dart';
import 'package:nowssb/screens/concept/drop_v4_concepts.dart' show DoorHooks;
import 'package:nowssb/data/day_part.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/drop_studio.dart';
import 'package:nowssb/screens/fashion/sections_mid.dart';
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/quick_access.dart';
import 'package:nowssb/screens/store/cart_pages.dart';
import 'package:nowssb/screens/widgets_page.dart';
import 'package:nowssb/screens/word_detail.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/enter_curve_stage.dart';
import 'fake_video_platform.dart';
import 'support/home_render.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  final tabs = <int>[];
  final fixed = DateTime(2026, 10, 26, 16, 20);

  Future<void> boot(WidgetTester t, Widget home, {double w = 390, double s = 1}) async {
    t.view.physicalSize = Size(w * s * 2, 844 * s * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await CartBag.instance.load();
    });
    tabs.clear();
    await t.pumpWidget(MediaQuery(
      data: MediaQueryData(size: Size(w, 844), textScaler: TextScaler.linear(s)),
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        home: NavScope(go: tabs.add, child: home),
      ),
    ));
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> settle(WidgetTester t, [int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> reach(WidgetTester t, Finder f) async {
    for (var i = 0; i < 40 && f.hitTestable().evaluate().isEmpty; i++) {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -220));
      await t.pump(const Duration(milliseconds: 120));
    }
    expect(f.hitTestable(), findsWidgets);
  }

  Future<void> openDoor(WidgetTester t, String label) async {
    await boot(t, const DropStudioScreen());
    // v4 prism: the tab turns the prism, a tap on the front face opens it
    final tab = find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w.key is ValueKey<String> && '${(w.key as ValueKey<String>).value}'.startsWith('drop-prism-tab-')));
    final prism = find.byKey(const ValueKey('drop-prism'));
    for (var i = 0; i < 40 && prism.evaluate().isEmpty; i++) {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -220));
      await t.pump(const Duration(milliseconds: 120));
    }
    await t.ensureVisible(prism);
    await t.pump();
    await t.ensureVisible(tab.first);
    await t.pump();
    await t.tap(tab.hitTestable().first);
    await settle(t);
    await t.ensureVisible(find.byKey(const ValueKey('drop-prism')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('drop-prism')));
    await settle(t);
  }

  Future<void> reachIn(WidgetTester t, Finder f, Type screen) async {
    final scroll = find.descendant(of: find.byType(screen), matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down));
    final enter = find.text('ENTER FASHION PLUS').hitTestable();
    if (enter.evaluate().isNotEmpty) {
      await t.tap(enter.first);
      await settle(t, 10);
    }
    for (var i = 0; i < 40 && f.hitTestable().evaluate().isEmpty; i++) {
      await t.drag(scroll.first, const Offset(0, -200), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 120));
    }
    expect(f.hitTestable(), findsWidgets);
  }

  Future<void> finish(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
    while (t.takeException() != null) {}
  }

  Future<SharedPreferences> prefs(WidgetTester t) async =>
      (await t.runAsync(SharedPreferences.getInstance))!;

  group('customize doors use the home\'s real state', () {
    testWidgets('Themes → WidgetsPage, hero style saved and reloaded', (t) async {
      await openDoor(t, 'Themes');
      expect(find.byType(WidgetsPage), findsOneWidget);
      final next = Settings.instance.heroStyle == 'full' ? 'tv' : 'full';
      final title = next == 'full' ? 'Full screen' : 'On the television';
      final card = find.byWidgetPredicate((w) =>
          w.runtimeType.toString() == '_HeroCard' && (w as dynamic).title == title);
      expect(card, findsOneWidget);
      await t.runAsync(() async => ((t.widget(card) as dynamic).onApply as VoidCallback)());
      await settle(t, 2);
      expect(Settings.instance.heroStyle, next);
      expect((await prefs(t)).getString('nwsb_hero_style'), next);
      await t.runAsync(Settings.instance.load);
      expect(Settings.instance.heroStyle, next);
    });

    testWidgets('Background → FashionPlusScreen, backdrop film saved', (t) async {
      await t.runAsync(() => Settings.instance.setFashionPlus(true));
      await openDoor(t, 'Background');
      expect(find.byType(FashionPlusScreen), findsOneWidget);
      expect((t.widget(find.byType(FashionPlusScreen)) as FashionPlusScreen).mode, FashionPlusMode.background);
      expect(find.text(Settings.fashionImageName(0)), findsNothing);
      final i = Settings.instance.fashionVideoIndex == 0 ? 2 : 0;
      final label = find.text(Settings.fashionVideoNames[i]);
      await reachIn(t, label, FashionPlusScreen);
      await t.runAsync(() async {
        await t.tap(label.hitTestable().first);
      });
      await settle(t, 2);
      expect(Settings.instance.fashionVideoIndex, i);
      expect((await prefs(t)).getInt('nwsb_fashplus_video'), i);
      await t.runAsync(Settings.instance.load);
      expect(Settings.instance.fashionVideoIndex, i);
    });

    testWidgets('Start art → FashionPlusScreen start-art mode, still saved', (t) async {
      // Even with motion on, the Start art door opens the stills, not the films.
      await t.runAsync(() => Settings.instance.setFashionPlus(true));
      await openDoor(t, 'Start art');
      expect(find.byType(FashionPlusScreen), findsOneWidget);
      expect((t.widget(find.byType(FashionPlusScreen)) as FashionPlusScreen).mode, FashionPlusMode.startArt);
      expect(find.text(Settings.fashionVideoNames[0]), findsNothing);
      final label = find.text(Settings.fashionImageName(0));
      await reachIn(t, label, FashionPlusScreen);
      await t.runAsync(() async {
        await t.tap(label.hitTestable().first);
      });
      await settle(t, 2);
      expect(Settings.instance.fashionImageIndex, 0);
      expect((await prefs(t)).getInt('nwsb_fashplus_image'), 0);
      await t.runAsync(Settings.instance.load);
      expect(Settings.instance.fashionImageIndex, 0);
      await t.runAsync(() => Settings.instance.setFashionPlus(true));
    });

    testWidgets('Access → QuickAccessScreen, nav saved', (t) async {
      await openDoor(t, 'Access');
      expect(find.byType(QuickAccessScreen), findsOneWidget);
      final apply = find.text('Apply Changes');
      await reachIn(t, apply, QuickAccessScreen);
      await t.runAsync(() async {
        await t.tap(apply.hitTestable().first);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await settle(t, 2);
      expect((await prefs(t)).getStringList('nwsb_nav_slots') ?? (await prefs(t)).getString('nwsb_nav_slots'),
          isNotNull);
    });
  });

  group('offers → cart → order', () {
    testWidgets('hero opens the Store tab (the old Today\'s offers tap)', (t) async {
      await boot(t, const DropStudioScreen());
      final hero = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_DropHero');
      await t.tap(hero, warnIfMissed: false);
      await settle(t, 2);
      expect(tabs, contains(3));
    });

    testWidgets('Own the drop → real word item in cart → Checkout', (t) async {
      await boot(t, DropStudioScreen(clock: () => fixed));
      final first = dropWordsFor(ContentStore.instance.library, fixed).first;
      await t.runAsync(() async {
        await t.tap(find.text('Own the drop'));
        await Future<void>.delayed(const Duration(milliseconds: 1400));
      });
      await settle(t, 30);
      final got = CartBag.instance.cart.where((b) => b.id == 'word:${first.word.toLowerCase()}');
      expect(got, hasLength(1));
      expect(got.single.image, dropCutoutFor(first), reason: 'the bag shows the word\'s own cut-out');
      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('bag opens Cart, a word opens WordDetail', (t) async {
      await boot(t, const DropStudioScreen());
      await t.tap(find.byIcon(Icons.shopping_bag_outlined));
      await settle(t);
      expect(find.byType(CartPage), findsOneWidget);
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await settle(t);
      final deck = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_WordPoster').hitTestable();
      await reach(t, deck);
      await t.tap(deck.first);
      await settle(t);
      expect(find.byType(WordDetail), findsOneWidget);
    });
  });

  group('drop logic', () {
    Future<void> clearCart(WidgetTester t) async => t.runAsync(() async {
          for (final b in CartBag.instance.cart.toList()) {
            await CartBag.instance.removeCart(b.id);
          }
        });

    testWidgets('double-tap Own adds once and opens one checkout', (t) async {
      await boot(t, DropStudioScreen(clock: () => fixed));
      await clearCart(t);
      final first = dropWordsFor(ContentStore.instance.library, fixed).first;
      await t.runAsync(() async {
        await t.tap(find.text('Own the drop'));
        await t.tap(find.text('Own the drop'), warnIfMissed: false);
        await Future<void>.delayed(const Duration(milliseconds: 1400));
      });
      await settle(t, 30);
      expect(CartBag.instance.cart.where((b) => b.id == 'word:${first.word.toLowerCase()}'), hasLength(1));
      expect(find.byType(CheckoutPage), findsOneWidget);
    });

    testWidgets('the bar follows the deck: word, price and buy', (t) async {
      await boot(t, DropStudioScreen(clock: () => fixed));
      await clearCart(t);
      final drop = dropWordsFor(ContentStore.instance.library, fixed);
      Text dock() => t.widget<Text>(find.byKey(const ValueKey('drop-dock-word')));
      expect(dock().data, drop[0].word);
      final deck = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_WordPoster').hitTestable();
      await reach(t, deck);
      await t.drag(deck.first, const Offset(-200, 0));
      await settle(t);
      expect(dock().data, drop[1].word);
      expect(find.text('02 / ${drop.length.toString().padLeft(2, '0')}'), findsWidgets);
      final price = t.widget<Text>(find.byKey(const ValueKey('drop-dock-price'))).data;
      expect(price, isNotEmpty);
      await t.runAsync(() async {
        await t.tap(find.text('Own the drop'));
        await Future<void>.delayed(const Duration(milliseconds: 1400));
      });
      await settle(t, 30);
      expect(CartBag.instance.cart.map((b) => b.id), contains('word:${drop[1].word.toLowerCase()}'));
    });

    testWidgets('a debug page past the end is clamped (no 06 / 05)', (t) async {
      await boot(t, DropStudioScreen(clock: () => fixed, debugPage: 9));
      final n = dropWordsFor(ContentStore.instance.library, fixed).length;
      final nn = n.toString().padLeft(2, '0');
      expect(find.text('$nn / $nn'), findsWidgets);
      expect(find.textContaining(RegExp(r'^(0[6-9]|1\d) / ')), findsNothing);
      await finish(t);
    });

    test('words rotate by the hour, deterministically', () {
      final all = ContentStore.instance.library;
      final pool = all.where((w) => w.meaning.isNotEmpty).toList();
      final a = dropWordsFor(all, fixed);
      expect(dropWordsFor(all, fixed.add(const Duration(minutes: 39))).map((w) => w.key), a.map((w) => w.key));
      expect(dropWordsFor(<Word>[], fixed), isEmpty);
      if (pool.length > kDropSize) {
        final b = dropWordsFor(all, fixed.add(const Duration(hours: 1)));
        expect(a, hasLength(kDropSize));
        expect(pool.indexOf(b.first), (pool.indexOf(a.first) + kDropSize) % pool.length);
      }
    });

    testWidgets('a new drop lands at the top of the hour (injected clock)', (t) async {
      var now = DateTime(2026, 10, 26, 15, 58);
      DayClock.clock = () => now;
      addTearDown(() => DayClock.clock = null);
      await boot(t, DropStudioScreen(clock: () => now));
      final all = ContentStore.instance.library;
      final before = dropWordsFor(all, now).first.word;
      Text dock() => t.widget<Text>(find.byKey(const ValueKey('drop-dock-word')));
      expect(dock().data, before);
      final after = dropWordsFor(all, DateTime(2026, 10, 26, 16)).first.word;
      now = DateTime(2026, 10, 26, 16, 0, 1);
      await t.pump(const Duration(minutes: 2, seconds: 1));
      await t.pump();
      expect(dock().data, after);
      if (all.where((w) => w.meaning.isNotEmpty).length > kDropSize) expect(after, isNot(before));
      await finish(t);
    });
    testWidgets('home entry turns over on the hour with Drop Studio (shared ticker)', (t) async {
      var now = DateTime(2026, 10, 26, 11, 58);
      DayClock.clock = () => now;
      addTearDown(() => DayClock.clock = null);
      await boot(t, Scaffold(body: ListView(children: [DropStudioEntry(onTap: () {}, clock: () => now)])));
      final all = ContentStore.instance.library;
      String word() => t.widget<Text>(find.byKey(const ValueKey('drop-studio-entry-word'))).data!;
      String chip() => t.widget<Text>(find.byKey(const ValueKey('drop-entry-when'))).data!;
      expect(word(), dropWordsFor(all, now).first.word.toUpperCase());
      expect(chip(), startsWith('This morning'));
      expect(DayClock.running, isTrue);
      now = DateTime(2026, 10, 26, 12, 0, 1);
      await t.pump(const Duration(minutes: 2, seconds: 1));
      await t.pump();
      expect(word(), dropWordsFor(all, now).first.word.toUpperCase());
      expect(chip(), startsWith('This afternoon'));
      await t.pumpWidget(const SizedBox());
      expect(DayClock.running, isFalse, reason: 'last listener gone: the timer is cancelled');
    });
  });

  group('Drop entry v4 (peel poster)', () {
    testWidgets('01:00 and 01:17 local read night (Tonight), not morning', (t) async {
      for (final now in [DateTime(2026, 10, 27, 1), DateTime(2026, 10, 27, 1, 17)]) {
        DayClock.clock = () => now;
        await boot(t, Scaffold(body: ListView(children: [DropStudioEntry(onTap: () {})])));
        expect(t.widget<Text>(find.byKey(const ValueKey('drop-entry-when'))).data, 'Tonight, 1 AM');
        expect(dayPartFor(now), DayPart.night);
        await t.pumpWidget(const SizedBox());
      }
      DayClock.clock = null;
    });
    testWidgets('tap opens the studio; peel drag springs back (instant under reduced motion)', (t) async {
      DayClock.clock = () => DateTime(2026, 10, 27, 9);
      addTearDown(() => DayClock.clock = null);
      var opened = 0;
      await boot(
          t,
          MediaQuery(
              data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
              child: Scaffold(body: ListView(children: [DropStudioEntry(onTap: () => opened++)]))));
      await t.tap(find.byKey(const ValueKey('drop-studio-entry-word')));
      await t.pump();
      expect(opened, 1);
      final entry = t.getRect(find.byKey(const ValueKey('drop-studio-entry')));
      await t.dragFrom(entry.bottomRight - const Offset(30, 30), const Offset(-60, -60));
      expect(await t.pumpAndSettle(), lessThanOrEqualTo(6), reason: 'reduced motion: the peel snaps back, no spring');
      await t.pumpWidget(const SizedBox());
    });
    for (final w in [320.0, 360.0, 390.0, 412.0]) {
      for (final s in [1.0, 1.3]) {
        testWidgets('entry word whole, no overflow at $w x$s', (t) async {
          DayClock.clock = () => DateTime(2026, 10, 27, 1, 17);
          addTearDown(() => DayClock.clock = null);
          await boot(t, Scaffold(body: ListView(children: [DropStudioEntry(onTap: () {})])), w: w, s: s);
          final card = t.getRect(find.byKey(const ValueKey('drop-studio-entry')));
          final r = t.getRect(find.ancestor(of: find.byKey(const ValueKey('drop-studio-entry-word')), matching: find.byType(FittedBox)).first);
          expect(r.left >= card.left && r.right <= card.right && r.top >= card.top && r.bottom <= card.bottom, isTrue,
              reason: 'word $r inside $card');
          expect(t.takeException(), isNull);
          for (final e in find.byType(Text).evaluate()) {
            expect((e.widget as Text).overflow, isNot(TextOverflow.ellipsis));
          }
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  });

  group('Drop doors v4 (prism)', () {
    for (final (i, label) in [(0, 'Themes'), (1, 'Background'), (2, 'Start art'), (3, 'Access')]) {
      testWidgets('tab $label turns the prism; front tap fires its hook', (t) async {
        final hits = <String>[];
        await boot(
            t,
            Scaffold(
                body: ListView(children: [
              DoorsPrismV5(
                  hooks: DoorHooks(
                onOpenThemes: () => hits.add('Themes'),
                onOpenBackground: () => hits.add('Background'),
                onOpenStartArt: () => hits.add('Start art'),
                onOpenAccess: () => hits.add('Access'),
              ))
            ])));
        await t.ensureVisible(find.byKey(ValueKey('drop-prism-tab-$i')));
        await t.pump();
        await t.tap(find.byKey(ValueKey('drop-prism-tab-$i')));
        await settle(t, 4);
        await t.tap(find.byKey(const ValueKey('drop-prism')));
        await t.pump();
        expect(hits, [label]);
        await t.pumpWidget(const SizedBox());
      });
    }
    for (final w in [320.0, 360.0, 390.0, 412.0]) {
      for (final s in [1.0, 1.3]) {
        testWidgets('prism: no overflow at $w x$s', (t) async {
          await boot(t, const Scaffold(body: SingleChildScrollView(child: DoorsPrismV5())), w: w, s: s);
          expect(t.takeException(), isNull);
          for (final e in find.byType(Text).evaluate()) {
            expect((e.widget as Text).overflow, isNot(TextOverflow.ellipsis));
          }
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  });

  group('Fashion home', () {
    testWidgets('entry opens Drop Studio; old sections are gone', (t) async {
      await boot(t, const HomeFashion());
      var sawOld = false;
      for (var i = 0; i < 60; i++) {
        if (find.byType(FashCustomize).evaluate().isNotEmpty ||
            find.byWidgetPredicate((w) => w is EnterCurveStage && !w.embedded).evaluate().isNotEmpty ||
            find.text('A featured drop for this hour').evaluate().isNotEmpty) {
          sawOld = true;
        }
        if (find.byKey(const ValueKey('drop-studio-entry')).hitTestable().evaluate().isNotEmpty) break;
        await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(sawOld, isFalse);
      expect(find.byKey(const ValueKey('drop-studio-entry')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('drop-studio-entry')));
      await settle(t);
      expect(find.byType(DropStudioScreen), findsOneWidget);
      await finish(t);
    });

    testWidgets('whole home has no Make this home yours / Today\'s offers', (t) async {
      await boot(t, const HomeFashion());
      for (var i = 0; i < 80; i++) {
        expect(find.byType(FashCustomize), findsNothing);
        expect(find.byWidgetPredicate((w) => w is EnterCurveStage && !w.embedded), findsNothing);
        expect(find.text('Customized\nyou app experience'), findsNothing);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await t.pump(const Duration(milliseconds: 120));
      }
      await finish(t);
    });
  });

  for (final (w, s) in const [(360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
    testWidgets('no overflow / ellipsis at ${w.toInt()}@$s', (t) async {
      final errors = <String>[];
      final cut = <String>{};
      void check() {
        final e = t.takeException();
        if (e != null) errors.add('$e');
        for (final el in find.byType(RichText).evaluate()) {
          final p = el.renderObject;
          if (p is RenderParagraph && p.hasSize && p.didExceedMaxLines) {
            cut.add(p.text.toPlainText());
          }
        }
      }

      await boot(t, const Column(children: [
        DropStudioEntry(),
        Expanded(child: DropStudioScreen()),
      ]), w: w, s: s);
      check();
      for (var i = 0; i < 30; i++) {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -250));
        await t.pump(const Duration(milliseconds: 120));
        check();
      }
      expect(errors.where((e) => e.contains('overflow')), isEmpty);
      expect(cut, isEmpty);
    }, skip: !homeFontsReady);
  }
}
