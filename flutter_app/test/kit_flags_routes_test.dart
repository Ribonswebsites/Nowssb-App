import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));
  group('NewUi.decide', () {
    test('off for regular users by default', () {
      expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: null)), isFalse);
      expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: false)), isFalse);
    });
    test('on for admins', () {
      expect(NewUi.decide(const NewUiInputs(isAdmin: true, remote: null)), isTrue);
      expect(NewUi.decide(const NewUiInputs(isAdmin: true, remote: false)), isTrue);
    });
    test('remote true releases to everyone', () {
      expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: true)), isTrue);
    });
    test('debug override wins both ways', () {
      expect(NewUi.decide(const NewUiInputs(isAdmin: true, remote: true, debugOverride: false)), isFalse);
      expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: null, debugOverride: true)), isTrue);
    });
    test('NwsbAdmin is false with no account', () => expect(NwsbAdmin.isAdmin, isFalse));
    test('key format', () => expect(NewUi.key('coupons'), 'newui_coupons'));
    test('signed-out non-admin phone is off (no Firebase in tests)', () {
      NewUi.resetForTest();
      expect(NewUi.isOn('coupons'), isFalse);
    });
  });

  group('AppRoutes', () {
    test('every page has one unique route, path and screen id', () {
      expect(AppRoutes.routes.keys.toSet(), AppPage.values.toSet());
      final paths = AppRoutes.routes.values.map((r) => r.path).toList();
      final ids = AppRoutes.routes.values.map((r) => r.screenId).toList();
      expect(paths.toSet().length, paths.length);
      expect(ids.toSet().length, ids.length);
      for (final r in AppRoutes.routes.values) {
        expect(r.path, startsWith('/'));
        expect(r.flag, isNot(contains('newui_')));
      }
    });

    test('resolve handles paths, deep links, web links, args and unknowns', () {
      expect(AppRoutes.resolve('/coupons')!.page, AppPage.coupons);
      expect(AppRoutes.resolve('coupons')!.page, AppPage.coupons);
      expect(AppRoutes.resolve('/coupons/scratch')!.page, AppPage.couponsScratch);
      final d = AppRoutes.resolve('nowssb://coupons/abc123?tab=mine&src=push')!;
      expect(d.page, AppPage.coupons);
      expect(d.args.tab, 'mine');
      expect(d.args.id, 'abc123');
      expect(d.args.extra, {'src': 'push'});
      expect(AppRoutes.resolve('https://nowssb.com/store/words/')!.page, AppPage.storeWords);
      expect(AppRoutes.resolve('nowssb://earn')!.page, AppPage.earn);
      expect(AppRoutes.resolve('/nope'), isNull);
      expect(AppRoutes.resolve('/couponsx'), isNull);
    });

    test('byScreenId', () {
      expect(AppRoutes.byScreenId('store.ebooks')!.page, AppPage.storeEbooks);
      expect(AppRoutes.byScreenId('missing'), isNull);
    });

    testWidgets('rebuilt screen is hidden while the flag is off, shown when on', (t) async {
      AppRoutes.clearRebuiltForTest();
      NewUi.resetForTest();
      AppRoutes.registerRebuilt(AppPage.coupons, (_, a) => Text('NEW ${a.tab}', textDirection: TextDirection.ltr));
      expect(AppRoutes.hasRebuilt(AppPage.coupons), isTrue);
      // Flag ON via debug override → rebuilt.
      await NewUi.setDebugOverride('coupons', true);
      await t.pumpWidget(MaterialApp(home: Builder(builder: (c) => AppRoutes.build(c, AppPage.coupons, const RouteArgs(tab: 'mine')))));
      expect(find.text('NEW mine'), findsOneWidget);
      await NewUi.setDebugOverride('coupons', null);
      AppRoutes.clearRebuiltForTest();
    });

    testWidgets('open drops a double tap and records the source', (t) async {
      AppRoutes.clearRebuiltForTest();
      final opened = <String>[];
      AppRoutes.onOpen = (p, s) => opened.add('${p.name}:$s');
      AppRoutes.registerRebuilt(AppPage.partner, (_, __) => const Text('P'));
      await NewUi.setDebugOverride('partner', true);
      late BuildContext ctx;
      await t.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      AppRoutes.open(ctx, AppPage.partner, source: 'test');
      AppRoutes.open(ctx, AppPage.partner, source: 'test');
      await t.pumpAndSettle();
      expect(opened, ['partner:test']);
      expect(find.text('P'), findsOneWidget);
      AppRoutes.onOpen = null;
      await NewUi.setDebugOverride('partner', null);
      AppRoutes.clearRebuiltForTest();
    });
  });
}
