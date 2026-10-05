import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/sections/section_config.dart';
import 'package:nowssb/widgets/sections/section_configs.dart';

void main() {
  test('resolve prefers slot override over fallback', () {
    final store = SectionConfigs.instance;
    final fallback = SectionConfig(id: 'glassy', type: SectionTypeId.glassyCarousel);
    final live = SectionConfig(
      id: 'glassy',
      type: SectionTypeId.glassyCarousel,
      version: 3,
      layout: const SectionLayout(height: 300),
    );
    store.applyLocal('section.store.atelier.glassy', live);
    final r = store.resolve(
      pageId: 'store.atelier',
      sectionId: 'glassy',
      fallback: fallback,
    );
    expect(r.version, 3);
    expect(r.layout.height, 300);
    store.applyLocal('section.store.atelier.glassy', null);
    final back = store.resolve(
      pageId: 'store.atelier',
      sectionId: 'glassy',
      fallback: fallback,
    );
    expect(back.version, 0);
  });
}
