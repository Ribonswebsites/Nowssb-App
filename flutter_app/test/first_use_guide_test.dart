import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/shell/first_use_guide.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('welcome shows once, then each tab mark shows once', () async {
    expect(await FirstUseGuide.next(0), 'welcome');
    await FirstUseGuide.markDone('welcome');
    expect(await FirstUseGuide.next(0), '0');
    await FirstUseGuide.markDone('0');
    expect(await FirstUseGuide.next(0), isNull);
    expect(await FirstUseGuide.next(2), '2');
  });

  test('Skip guide stops every mark for this install', () async {
    await FirstUseGuide.skipAll();
    for (var i = 0; i < FirstUseGuide.tabCount; i++) {
      expect(await FirstUseGuide.next(i), isNull);
    }
  });
}
