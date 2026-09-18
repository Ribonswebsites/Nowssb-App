import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tab switches do not pop a center destination pill', () {
    final src = File('lib/shell/nav_shell.dart').readAsStringSync();
    expect(src, isNot(contains('_tabTransitioning')));
    expect(src, isNot(contains('_transitionTarget')));
    expect(src, isNot(contains('_tabTransitionTimer')));
    expect(src, isNot(contains('Icons.auto_awesome')));
    expect(src, isNot(contains("'Opening'")));
  });
}
