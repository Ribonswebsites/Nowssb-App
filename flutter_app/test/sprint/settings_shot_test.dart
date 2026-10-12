import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/screens/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Settings page renders without promo banner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadRoboto);
    await tester.binding.setSurfaceSize(const Size(412, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
      home: const RepaintBoundary(key: ValueKey('shot'), child: AppSettingsScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('settings_calm.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });
}

Future<void> _loadRoboto() async {
  final dir = Directory('/home/box/flutter/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      loader.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
  final icons = File('/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
  }
}
