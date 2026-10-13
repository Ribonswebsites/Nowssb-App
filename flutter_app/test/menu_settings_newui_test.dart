import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/menu_settings/glass_menu_settings_page.dart';
import 'package:nowssb/pages/menu_settings/menu_settings_model.dart';
import 'package:nowssb/pages/menu_settings/newui_flag.dart';

List<SettingSection> _sections({void Function()? onAbout, ValueChanged<bool>? onWake, bool wake = false}) => [
      SettingSection('Comfort', [
        SettingItem(id: 'wake', title: 'Screen awake', icon: Icons.light_mode_outlined, kind: SettingKind.toggle, value: wake, onChanged: onWake),
      ]),
      SettingSection('About', [
        SettingItem(id: 'about', title: 'About', icon: Icons.info_outline, onTap: onAbout),
        const SettingItem(id: 'terms', title: 'Terms', icon: Icons.description_outlined),
      ]),
    ];

Widget _app(GlassMenuSettingsPage p) => MaterialApp(home: p);

void main() {
  group('flag', () {
    tearDown(() => NewUiMenuSettingsFlag.debugOverride = null);
    test('on for everyone by default, remote false kills', () {
      expect(NewUiMenuSettingsFlag.resolve(isAdmin: false), isTrue);
      expect(NewUiMenuSettingsFlag.resolve(isAdmin: true, remote: false), isFalse);
      expect(NewUiMenuSettingsFlag.resolve(isAdmin: false, remote: true), isTrue);
      expect(NewUiMenuSettingsFlag.resolve(isAdmin: true), isTrue);
      NewUiMenuSettingsFlag.debugOverride = false;
      expect(NewUiMenuSettingsFlag.resolve(isAdmin: true), isFalse);
    });
  });

  test('filterSections drops empty sections', () {
    final f = filterSections(_sections(), 'ter');
    expect(f.length, 1);
    expect(f.single.items.single.id, 'terms');
  });

  testWidgets('loading then ready', (t) async {
    await t.pumpWidget(_app(GlassMenuSettingsPage(
        background: const ColoredBox(color: Colors.black),
        reduceEffects: true,
        load: () => Future.delayed(const Duration(milliseconds: 50), _sections))));
    expect(find.byKey(const Key('ms_loading')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 60));
    expect(find.text('About'), findsWidgets);
    expect(find.byKey(const Key('ms_offline')), findsNothing);
  });

  testWidgets('error state retries', (t) async {
    var calls = 0;
    await t.pumpWidget(_app(GlassMenuSettingsPage(
        background: const ColoredBox(color: Colors.black),
        reduceEffects: true,
        load: () async {
          calls++;
          if (calls == 1) throw Exception('x');
          return _sections();
        })));
    await t.pump();
    expect(find.byKey(const Key('ms_error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pump();
    expect(find.byKey(const Key('ms_item_about')), findsOneWidget);
  });

  testWidgets('empty and search-empty states', (t) async {
    await t.pumpWidget(_app(GlassMenuSettingsPage(background: const ColoredBox(color: Colors.black), reduceEffects: true, load: () async => const [])));
    await t.pump();
    expect(find.byKey(const Key('ms_empty')), findsOneWidget);
  });

  testWidgets('offline banner', (t) async {
    await t.pumpWidget(_app(GlassMenuSettingsPage(
        background: const ColoredBox(color: Colors.black),
        reduceEffects: true, load: () async => _sections(), isOnline: () async => false)));
    await t.pump();
    expect(find.byKey(const Key('ms_offline')), findsOneWidget);
    expect(find.byKey(const Key('ms_item_about')), findsOneWidget);
  });

  testWidgets('search, tap and toggle flows', (t) async {
    var about = 0;
    bool? wake;
    await t.pumpWidget(_app(GlassMenuSettingsPage(
        background: const ColoredBox(color: Colors.black),
        reduceEffects: true,
        load: () async => _sections(onAbout: () => about++, onWake: (v) => wake = v))));
    await t.pump();
    await t.tap(find.byKey(const Key('ms_item_about')));
    expect(about, 1);
    await t.tap(find.byType(Switch));
    expect(wake, isTrue);
    await t.enterText(find.byKey(const Key('ms_search')), 'zzz');
    await t.pump();
    expect(find.byKey(const Key('ms_empty')), findsOneWidget);
    await t.enterText(find.byKey(const Key('ms_search')), 'term');
    await t.pump();
    expect(find.byKey(const Key('ms_item_terms')), findsOneWidget);
    expect(find.byKey(const Key('ms_item_about')), findsNothing);
  });
}
