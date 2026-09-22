from pathlib import Path
root=Path('/tmp/nowssb-app')
# Flutter shared widget: add a fourth, matching spread preset.
p=root/'flutter_app/lib/widgets/editorial_banner.dart'
s=p.read_text(encoding='utf-8')
needle="""  const EditorialBanner.healing({super.key})
      : eyebrow = 'NOWSSB / THE DAILY RITUAL',
        title = 'HEALING\\nIN A\\nNEW FORM',
        body =
            'Pronunciation, sound and stillness — carried with you wherever you are.',
        note = 'LISTEN · PRACTICE · HEAL',
        images = const [
          'assets/editorial/reader.png',
          'assets/editorial/store.png',
          'assets/editorial/subscribe.png',
        ],
        background = const Color(0xFFEAD8D1);
"""
addition=needle+"""
  const EditorialBanner.stories({super.key})
      : eyebrow = 'NOWSSB / EDITORIAL DISCOVERY',
        title = 'STORIES\\nTHAT\\nFIND YOU',
        body =
            'A living collection of words, images and rituals that meet you at exactly the right moment.',
        note = 'READ · LISTEN · DISCOVER',
        images = const [
          'assets/editorial/connect.png',
          'assets/editorial/science.png',
          'assets/editorial/healing.png',
        ],
        background = const Color(0xFFF0E5DE);
"""
if needle not in s: raise SystemExit('Flutter healing preset not found')
p.write_text(s.replace(needle,addition,1),encoding='utf-8')
# Flutter home modes: keep registry keys stable and add the new spread into the existing editorial slot.
for rel,old,new in [
('flutter_app/lib/screens/home_normal.dart',"('editorialA', const EditorialBanner.science()),","""('editorialA',
          const Column(
            children: [
              EditorialBanner.science(),
              EditorialBanner.stories(),
            ],
          )),"""),
('flutter_app/lib/screens/home_fashion.dart',"('editorialA', const EditorialBanner.healing()),","""('editorialA',
          const Column(
            children: [
              EditorialBanner.healing(),
              EditorialBanner.stories(),
            ],
          )),"""),
]:
    p=root/rel; s=p.read_text(encoding='utf-8')
    if old not in s: raise SystemExit(f'Flutter insertion point not found: {rel}')
    p.write_text(s.replace(old,new,1),encoding='utf-8')
# Web banner list: add a matching fourth card and update the count label.
p=root/'app/js/editorial-banners.js'; s=p.read_text(encoding='utf-8')
needle="""    {
      key: 'healing',
      eyebrow: 'NOWSSB / THE DAILY RITUAL',
      title: 'HEALING\\nIN A\\nNEW FORM',
      body: 'Pronunciation, sound and stillness — carried with you wherever you are.',
      note: 'LISTEN · PRACTICE · HEAL',
      tint: 'rose',
      images: [
        'file_000000005f8881f48b6867d03c79a021.png',
        'file_0000000019a0820ca12b3d08e77712e0.png',
        'file_00000000fdd48246890602f65eafaab8.png'
      ]
    }
"""
addition=needle+""",
    {
      key: 'stories',
      eyebrow: 'NOWSSB / EDITORIAL DISCOVERY',
      title: 'STORIES\\nTHAT\\nFIND YOU',
      body: 'A living collection of words, images and rituals that meet you at exactly the right moment.',
      note: 'READ · LISTEN · DISCOVER',
      tint: 'paper',
      images: [
        'file_00000000156082109bcff739c6d80a7a.png',
        'file_00000000b77c82119c4127cc603420a8.png',
        'file_000000005f8881f48b6867d03c79a021.png'
      ]
    }
"""
if needle not in s: raise SystemExit('Web healing banner not found')
s=s.replace(needle,addition,1).replace("'0' + (index + 1) + ' / 03'","'0' + (index + 1) + ' / 04'",1)
old_mount="""    place('#home-nm .nmh-supplied-essentials', '.nmh-trend-wrap', banners[2], 2);"""
# Existing placement is on the home wrapper, so insert Stories after the normal essentials anchor.
if old_mount in s:
    s=s.replace(old_mount,"""    place('#home-nm .nmh-wrap', '.nmh-supplied-essentials', banners[3], 3);
    place('#home-nm .nmh-wrap', '.nmh-trend-wrap', banners[2], 2);""",1)
else:
    marker="    place('#home-nm .nmh-wrap', '.nmh-supplied-essentials', banners[1], 1);"
    if marker not in s: raise SystemExit('Normal web placement anchor not found')
    s=s.replace(marker,marker+"\n    place('#home-nm .nmh-wrap', '.nmh-supplied-essentials', banners[3], 3);",1)
marker="    place('#home .home-body', '.fash-plyr-wrap', banners[2], 2);"
if marker not in s: raise SystemExit('Fashion web placement anchor not found')
s=s.replace(marker,marker+"\n    place('#home .home-body', '.fash-plyr-wrap', banners[3], 3);",1)
p.write_text(s,encoding='utf-8')
print('Stories banner added to Flutter and web normal/fashion homes')
