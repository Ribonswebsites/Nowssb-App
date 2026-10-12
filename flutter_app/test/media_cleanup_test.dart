import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/editor/media_cleanup.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/admin/template/slot_keys.dart';
import 'package:nowssb/admin/template/ui_overrides.dart';

const m = 'https://media.nowssb.com/';

void main() {
  test('isAdminMedia only accepts our upload prefixes', () {
    expect(isAdminMedia('${m}ui/a/1.webp'), isTrue);
    expect(isAdminMedia('${m}assets/logo.png'), isFalse);
    expect(isAdminMedia('assets/anim/x.json'), isFalse);
    expect(isAdminMedia('https://other.com/ui/a.webp'), isFalse);
  });

  test('replaced slot media is planned for delete; unchanged is not', () {
    final plan = planMedia(
      liveOverrides: {
        'home.hero': UiOverride(slot: 'home.hero', type: SlotType.video, url: '${m}ui/h/old.mp4'),
        'home.same': UiOverride(slot: 'home.same', type: SlotType.image, url: '${m}ui/s/1.webp'),
      },
      draftOverrides: {
        'home.hero': UiOverride(slot: 'home.hero', type: SlotType.video, url: '${m}ui/h/new.mp4'),
        'home.same': UiOverride(slot: 'home.same', type: SlotType.image, url: '${m}ui/s/1.webp', text: 'x'),
      },
      liveLayouts: const {},
      draftLayouts: const {},
    );
    expect(plan.oldUrls, {'${m}ui/h/old.mp4'});
    expect(plan.targets, {'home.hero'});
    expect(plan.hasVideo, isTrue);
  });

  test('deleted section, removed template and reset page are planned', () {
    const live = PageLayout(page: 'p', sections: [
      SectionEntry(id: 'a'),
      SectionEntry(id: 't1', kind: 'imageBanner', props: {'image': '${m}ui/t/1.webp'}),
      SectionEntry(id: 't2', kind: 'imageBanner', props: {'image': '${m}ui/t/2.webp'}),
    ]);
    const next = PageLayout(page: 'p', sections: [
      SectionEntry(id: 'a', deleted: true),
      SectionEntry(id: 't1', kind: 'imageBanner', props: {'image': '${m}ui/t/1b.webp'}),
    ]);
    final plan = planMedia(
      liveOverrides: const {},
      draftOverrides: const {},
      liveLayouts: {'p': live, 'q': live},
      draftLayouts: {'p': next, 'q': null},
    );
    expect(plan.deletedSections, [('p', 'a')]);
    expect(plan.resetPages, {'q'});
    expect(plan.oldUrls, containsAll(['${m}ui/t/1.webp', '${m}ui/t/2.webp']));
    expect(plan.oldUrls.contains('${m}ui/t/1b.webp'), isFalse);
  });
}
