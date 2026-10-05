import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/section_editor/section_focal_pad.dart';
import 'package:nowssb/widgets/sections/section_config.dart';
import 'package:nowssb/admin/section_editor/section_editor_shell.dart';

void main() {
  test('focalAfterPan maps drag to −1…1 and clamps', () {
    final (x, y) = focalAfterPan(
      focalX: 0,
      focalY: 0,
      dx: 50,
      dy: -25,
      size: const Size(100, 100),
    );
    expect(x, -1.0); // 50 / 50 = 1 → focalX = 0 - 1
    expect(y, 0.5);
    final clamped = focalAfterPan(
      focalX: 0.9,
      focalY: -0.9,
      dx: -100,
      dy: 100,
      size: const Size(100, 100),
    );
    expect(clamped.$1, 1.0);
    expect(clamped.$2, -1.0);
  });

  test('zoomAfterPinch scales and clamps 1…8', () {
    expect(zoomAfterPinch(startZoom: 1, startDist: 100, dist: 200), 2.0);
    expect(zoomAfterPinch(startZoom: 4, startDist: 100, dist: 300), 8.0);
    expect(zoomAfterPinch(startZoom: 2, startDist: 100, dist: 10), 1.0);
  });

  test('ensureEditableItems seeds two cards when empty', () {
    final cfg = SectionConfig(id: 'hero', type: SectionTypeId.glassyCarousel);
    final items = ensureEditableItems(cfg);
    expect(items.length, 2);
    expect(items.first.id, 'hero.a');
    expect(ensureEditableItems(cfg.copyWith(items: items)), items);
  });
}
