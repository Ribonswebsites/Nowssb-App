import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/menu_settings/ms_widgets.dart';
import 'package:nowssb/pages/menu_settings/ms_guide.dart';
import 'package:nowssb/pages/menu_settings/ms_menu_page.dart';
import 'package:nowssb/pages/menu_settings/ms_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake {
  final calls = <String>[];
  bool awake = true, motion = false, nav = true, discover = true;
  MsSettingsActions get actions => MsSettingsActions(
        openPlayer: () => calls.add('player'),
        openNotifications: () => calls.add('notifications'),
        screenAwake: () => awake,
        setScreenAwake: (v) => awake = v,
        motionBackground: () => motion,
        setMotionBackground: (v) => motion = v,
        navGlass: () => nav,
        setNavGlass: (v) => nav = v,
        openBackgroundPicker: () => calls.add('bg'),
        appearInDiscover: () => discover,
        setAppearInDiscover: (v) => discover = v,
        openProfile: () => calls.add('profile'),
        openPrivacy: () => calls.add('privacy'),
        openTerms: () => calls.add('terms'),
        signOut: () => calls.add('signout'),
        deleteAccount: () => calls.add('delete'),
        clearCache: () => calls.add('cache'),
        clearHistory: () => calls.add('history'),
        openPlayerGuide: () => calls.add('pguide'),
        requestWords: () => calls.add('request'),
        openAbout: () => calls.add('about'),
        isAdmin: true,
        openAdmin: () => calls.add('admin'),
        version: 'v9.5.0',
      );
}

const _poster = Image(image: AssetImage('assets/fashion/fp-intro.webp'), fit: BoxFit.cover);

Widget _wrap(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
      builder: (_, c) => MsBackground(background: _poster, child: c!),
      home: child,
    );

Future<void> _fonts() async {
  final dir = Directory('/workspace/flutter/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final l = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf')) l.addFont(f.readAsBytes().then(ByteData.sublistView));
  }
  await l.load();
  final icons = File('${dir.path}/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
}

Future<void> _tap(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> _shot(WidgetTester t, String n) async {
  await t.runAsync(() => precacheImage(const AssetImage('assets/fashion/fp-intro.webp'), t.element(find.byType(Scaffold).last)));
  await t.pump();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/menu_settings/menu-settings-$n.png'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await (await SharedPreferences.getInstance()).setBool('ms_guide_seen_v1', true);
  });
  tearDown(() => MenuSettingsFlag.debugOverride = null);

  test('flag on by default, debug override wins', () {
    expect(MenuSettingsFlag.isOn, isTrue);
    MenuSettingsFlag.debugOverride = false;
    expect(MenuSettingsFlag.isOn, isFalse);
  });

  testWidgets('every settings row calls its action', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 892));
    final f = _Fake();
    await t.pumpWidget(_wrap(MsSettingsPage(actions: f.actions, showGuide: false)));
    for (final k in ['ms_player', 'ms_notifications', 'ms_profile', 'ms_privacy', 'ms_terms', 'ms_signout', 'ms_delete', 'ms_player_guide', 'ms_request', 'ms_about', 'ms_admin']) {
      await _tap(t, k);
    }
    expect(f.calls, ['player', 'notifications', 'profile', 'privacy', 'terms', 'signout', 'delete', 'pguide', 'request', 'about', 'admin']);
    await _tap(t, 'ms_awake');
    expect(f.awake, isFalse);
    await _tap(t, 'ms_discover');
    expect(f.discover, isFalse);
  });

  testWidgets('look and storage sub-pages work', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 892));
    final f = _Fake();
    await t.pumpWidget(_wrap(MsSettingsPage(actions: f.actions, showGuide: false)));
    await _tap(t, 'ms_look');
    await _tap(t, 'ms_motion');
    await _tap(t, 'ms_nav');
    await _tap(t, 'ms_pick_bg');
    expect([f.motion, f.nav], [true, false]);
    await t.pageBack();
    await t.pumpAndSettle();
    await _tap(t, 'ms_data');
    await _tap(t, 'ms_cache');
    await _tap(t, 'ms_history');
    expect(f.calls, ['bg', 'cache', 'history']);
  });

  testWidgets('guide shows once, steps through and replays', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.binding.setSurfaceSize(const Size(412, 892));
    await t.pumpWidget(_wrap(MsSettingsPage(actions: _Fake().actions)));
    await t.pump();
    await t.pump();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ms_guide')), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pump();
    await t.tap(find.text('Next'));
    await t.pump();
    await t.tap(find.text('Begin'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ms_guide')), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('ms_guide_seen_v1'), isTrue);
    await _tap(t, 'ms_guide_row');
    expect(find.byKey(const Key('ms_guide')), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();
  });

  testWidgets('menu entries and hubs open', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 892));
    final hits = <String>[];
    MsEntry e(String id) => MsEntry(id, Icons.circle, id, 'sub', () => hits.add(id));
    await t.pumpWidget(_wrap(MsMenuPage(groups: [MsGroup('Practice', [e('home'), e('library')]), MsGroup('You', [e('settings')])])));
    await _tap(t, 'ms_menu_home');
    await _tap(t, 'ms_menu_settings');
    expect(hits, ['home', 'settings']);
  });

  group('screenshots', () {
    setUp(() async {});
    Future<void> settings(WidgetTester t) async {
      await t.runAsync(_fonts);
      await t.binding.setSurfaceSize(const Size(412, 892));
      await t.pumpWidget(_wrap(MsSettingsPage(actions: _Fake().actions, showGuide: false)));
    }

    testWidgets('1 menu', (t) async {
      await t.runAsync(_fonts);
      await t.binding.setSurfaceSize(const Size(412, 892));
      MsEntry e(String id, IconData i, String s) => MsEntry(id, i, id, s, () {});
      await t.pumpWidget(_wrap(MsMenuPage(groups: [
        MsGroup('Practice', [e('Home', Icons.home_outlined, 'Your daily start'), e('Daily practice', Icons.self_improvement_rounded, 'Morning ritual and routines'), e('Sound library', Icons.graphic_eq_rounded, 'Root frequencies'), e('My progress', Icons.spa_outlined, 'Your healing journey')]),
        MsGroup('Learn', [e('Word science', Icons.auto_stories_outlined, 'How NowssB works'), e('Shabdapathy reader', Icons.menu_book_outlined, 'Foundations'), e('Store', Icons.shopping_bag_outlined, 'Words, meanings, plans')]),
        MsGroup('Rewards', [e('Rewards & gifts', Icons.card_giftcard_rounded, 'Coins, gifts, coupons'), e('Earn & payouts', Icons.volunteer_activism_outlined, 'Agents, codes, earnings')]),
      ])));
      await _shot(t, '1');
    });
    testWidgets('2 settings', (t) async {
      await settings(t);
      await _shot(t, '2');
    });
    testWidgets('3 settings privacy', (t) async {
      await settings(t);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await t.pumpAndSettle();
      await _shot(t, '3');
    });
    testWidgets('4 look', (t) async {
      await settings(t);
      await _tap(t, 'ms_look');
      await _shot(t, '4');
    });
    testWidgets('5 storage', (t) async {
      await settings(t);
      await _tap(t, 'ms_data');
      await _shot(t, '5');
    });
    testWidgets('6 guide', (t) async {
      await t.runAsync(_fonts);
      await t.binding.setSurfaceSize(const Size(412, 892));
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(_wrap(MsSettingsPage(actions: _Fake().actions)));
      await t.pumpAndSettle();
      await _shot(t, '6');
    });
  });
}
