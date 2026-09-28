import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

PageLayout _l(List<SectionEntry> s) => PageLayout(page: 'p', sections: s);
List<String> _ids(List<SectionEntry> e) => [for (final s in e) s.id];

void main() {
  const bundled = ['a', 'b', 'c', 'd'];

  test('no saved layout = bundled order, default-off stays off', () {
    final m = mergeLayout(bundled, null, hiddenByDefault: {'c'});
    expect(_ids(m), bundled);
    expect(m.where((e) => !e.visible).map((e) => e.id), ['c']);
  });

  test('saved order wins; sections shipped later slot in after their neighbour', () {
    final m = mergeLayout(bundled, _l(const [SectionEntry(id: 'c'), SectionEntry(id: 'a')]));
    // b follows a (its bundled predecessor), d follows c.
    expect(_ids(m), ['c', 'd', 'a', 'b']);
  });

  test('templates and duplicates survive; unknown builtins are dropped', () {
    final m = mergeLayout(
      bundled,
      _l(const [
        SectionEntry(id: 'tpl1', kind: 'textBlock'),
        SectionEntry(id: 'a'),
        SectionEntry(id: 'a~2', src: 'a'),
        SectionEntry(id: 'gone'),
        SectionEntry(id: 'b', visible: false),
        SectionEntry(id: 'c', deleted: true),
        SectionEntry(id: 'd'),
      ]),
    );
    expect(_ids(m), ['tpl1', 'a', 'a~2', 'b', 'c', 'd']);
    expect(m.firstWhere((e) => e.id == 'b').showsNow, isFalse);
    expect(m.firstWhere((e) => e.id == 'c').showsNow, isFalse);
  });

  test('layout json round trip', () {
    const l = PageLayout(page: 'home.normal', version: 3, sections: [
      SectionEntry(id: 'a', props: {'padTop': 12, 'transition': 'cube'}),
      SectionEntry(id: 'x', kind: 'imageBanner', props: {'url': 'https://e/x.webp'}, start: 1, end: 2),
    ]);
    final back = PageLayout.from('home.normal', l.toJson())!;
    expect(back.version, 3);
    expect(_ids(back.sections), ['a', 'x']);
    expect(back.sections[0].props['transition'], 'cube');
    expect(back.sections[1].kind, 'imageBanner');
    expect(back.sections[1].start, 1);
  });
}
