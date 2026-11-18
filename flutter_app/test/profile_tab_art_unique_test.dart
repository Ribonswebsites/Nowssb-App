// Each Profile tab (coins, cart, wishlist, orders) has its own render, used
// nowhere else, and none of them is the avatar.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile tab cards each own a unique, unshared render', () {
    final src = File('lib/screens/profile.dart').readAsStringSync();
    final arts = RegExp(r"assets/profile/tabs/[a-z_]+\.webp")
        .allMatches(src)
        .map((m) => m.group(0)!)
        .toList();
    expect(arts.length, 4);
    expect(arts.toSet().length, 4, reason: 'no tab may reuse another tab\'s art');
    final bytes = <String>{};
    for (final a in arts) {
      final f = File(a);
      expect(f.existsSync(), isTrue, reason: a);
      expect(f.lengthSync(), lessThan(120 * 1024), reason: '$a should stay small');
      bytes.add(f.readAsBytesSync().join(','));
    }
    expect(bytes.length, 4, reason: 'every tab render is a different picture');
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('screens/profile.dart')) continue;
      final s = f.readAsStringSync();
      for (final a in arts) {
        expect(s.contains(a), isFalse, reason: '$a is reused in ${f.path}');
      }
    }
  });
}
