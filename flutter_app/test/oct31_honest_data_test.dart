import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Connect chats never invent a canned reply', () {
    final src = File('lib/features/social/connect_screen.dart').readAsStringSync();
    expect(src.contains('_replies'), isFalse);
    expect(src.contains('Frequency received'), isFalse);
  });
  test('Shared rails show no UPI / India-only payout wording', () {
    final src = File('lib/widgets/hub_rails.dart').readAsStringSync();
    expect(src.contains("'UPI'"), isFalse);
    expect(src.contains('Add UPI'), isFalse);
    expect(src.contains('India rail'), isFalse);
  });
}
