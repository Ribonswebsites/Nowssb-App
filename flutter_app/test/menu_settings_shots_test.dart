import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/menu_settings/glass_menu_settings_page.dart';
import 'package:nowssb/pages/menu_settings/menu_settings_model.dart';

List<SettingSection> _s({bool admin = false}) => [
      const SettingSection('Your app', [
        SettingItem(id: 'n', title: 'Notifications', icon: Icons.notifications_none_rounded),
        SettingItem(id: 'p', title: 'Player', icon: Icons.tune_rounded),
        SettingItem(id: 'q', title: 'Quick access', icon: Icons.dashboard_customize_outlined),
        SettingItem(id: 'quote', title: "Today's quote", icon: Icons.format_quote_rounded),
      ]),
      const SettingSection('Comfort', [
        SettingItem(id: 'w', title: 'Screen awake', icon: Icons.light_mode_outlined, kind: SettingKind.toggle, value: true),
        SettingItem(id: 'nav', title: 'Nav bar', subtitle: 'glass', icon: Icons.space_dashboard_outlined),
        SettingItem(id: 'd', title: 'Appear in Discover', icon: Icons.travel_explore, kind: SettingKind.toggle),
      ]),
      if (admin)
        const SettingSection('Admin', [
          SettingItem(id: 'admin', title: 'Admin', icon: Icons.admin_panel_settings_outlined),
        ]),
      const SettingSection('Account', [
        SettingItem(id: 'so', title: 'Sign out', icon: Icons.logout_rounded),
        SettingItem(id: 'del', title: 'Delete account', icon: Icons.person_remove_outlined, destructive: true),
      ]),
    ];

Future<void> _fonts() async {
  for (final base in ['/workspace/flutter', '/home/box/flutter']) {
    final dir = Directory('$base/bin/cache/artifacts/material_fonts');
    if (!dir.existsSync()) continue;
    final l = FontLoader('Roboto');
    for (final f in dir.listSync().whereType<File>()) {
      final n = f.uri.pathSegments.last;
      if (n.startsWith('Roboto-') && n.endsWith('.ttf')) l.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
    await l.load();
    final icons = File('${dir.path}/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
    }
    return;
  }
}

Future<void> _shot(WidgetTester t, String name, GlassMenuSettingsPage page, {String? search}) async {
  await t.runAsync(_fonts);
  await t.binding.setSurfaceSize(const Size(412, 892));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
    home: RepaintBoundary(key: const ValueKey('shot'), child: page),
  ));
  await t.runAsync(() async {
    await precacheImage(const AssetImage('assets/fashion/fp-intro.webp'), t.element(find.byType(Scaffold)));
  });
  await t.pump();
  await t.pump(const Duration(milliseconds: 100));
  if (search != null) {
    await t.enterText(find.byKey(const Key('ms_search')), search);
    await t.pump();
  }
  await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('goldens/menu_settings/$name.png'));
}

// Goldens can't play video: use the Fashion Plus poster still instead.
const Widget _poster = Image(image: AssetImage('assets/fashion/fp-intro.webp'), fit: BoxFit.cover);

void main() {
  testWidgets('1 main', (t) => _shot(t, 'menu-settings-1', GlassMenuSettingsPage(background: _poster, reduceEffects: false, displayName: 'Ribon', load: () async => _s())));
  testWidgets('2 search', (t) => _shot(t, 'menu-settings-2', GlassMenuSettingsPage(background: _poster, reduceEffects: false, load: () async => _s()), search: 'scr'));
  testWidgets('3 admin', (t) => _shot(t, 'menu-settings-3', GlassMenuSettingsPage(background: _poster, reduceEffects: false, displayName: 'Admin', load: () async => _s(admin: true))));
  testWidgets('4 offline', (t) => _shot(t, 'menu-settings-4', GlassMenuSettingsPage(background: _poster, reduceEffects: false, isOnline: () async => false, load: () async => _s())));
  testWidgets('5 error', (t) => _shot(t, 'menu-settings-5', GlassMenuSettingsPage(background: _poster, reduceEffects: false, load: () async => throw Exception('x'))));
  testWidgets('6 no results', (t) => _shot(t, 'menu-settings-6', GlassMenuSettingsPage(background: _poster, reduceEffects: false, load: () async => _s()), search: 'zzz'));
}
