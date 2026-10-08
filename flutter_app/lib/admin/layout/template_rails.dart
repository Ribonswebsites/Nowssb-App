/// Side rails for the Sections drawer: fifteen scroll rows and stacks,
/// and fifteen vertical pill columns that sit on the left or the right.
/// Black, gold, white, glass. NowssB marks only. Every word is a field.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';
import 'template_more.dart';
import 'template_motion.dart';

const kRailKinds = <String>[
  'sideShelf', 'wordLane', 'priceLane', 'soundLane', 'couponLane',
  'rankLane', 'posterLane', 'dealLane', 'storyStack', 'stepStack',
  'noteStack', 'offerStack', 'wordStack', 'priceStack', 'nightStack',
  'sidePills', 'doorPills', 'shopPills', 'soundPills', 'earnPills',
  'giftPills', 'wordPills', 'nightPills', 'calmPills', 'storePills',
  'markPills', 'goldPills', 'coinPills', 'bookPills', 'pathPills',
];

const kRailTemplates = <String, (String, String, String)>{
  'sideShelf': ('Side shelf', 'Posters you can swipe', 'Cards'),
  'wordLane': ('Word lane', 'Words in a sideways row', 'Words'),
  'priceLane': ('Price lane', 'Prices you swipe', 'Numbers'),
  'soundLane': ('Sound lane', 'Sounds in a sideways row', 'Cards'),
  'couponLane': ('Coupon lane', 'Coupons you swipe', 'Offers & coupons'),
  'rankLane': ('Rank lane', 'Ranks in a sideways row', 'Numbers'),
  'posterLane': ('Poster lane', 'Tall posters you swipe', 'Top banners'),
  'dealLane': ('Deal lane', 'Deals you swipe', 'Offers & coupons'),
  'storyStack': ('Story stack', 'Stories you scroll down', 'Cards'),
  'stepStack': ('Step stack', 'Steps you scroll down', 'Features'),
  'noteStack': ('Note stack', 'Notes you scroll down', 'Words'),
  'offerStack': ('Offer stack', 'Offers you scroll down', 'Offers & coupons'),
  'wordStack': ('Word stack', 'A tall list of words', 'Words'),
  'priceStack': ('Price stack', 'Prices you scroll down', 'Numbers'),
  'nightStack': ('Night stack', 'Night cards you scroll down', 'Top banners'),
  'sidePills': ('Side pills', 'Black pills down the side', 'Buttons & banners'),
  'doorPills': ('Door pills', 'Doors as black pills', 'Buttons & banners'),
  'shopPills': ('Shop pills', 'Store, player and earn as pills', 'Buttons & banners'),
  'soundPills': ('Sound pills', 'Sound actions as pills', 'Buttons & banners'),
  'earnPills': ('Earn pills', 'Rank actions as pills', 'Buttons & banners'),
  'giftPills': ('Gift pills', 'Gift actions as pills', 'Offers & coupons'),
  'wordPills': ('Word pills', 'Word actions as pills', 'Words'),
  'nightPills': ('Night pills', 'Night actions as pills', 'Buttons & banners'),
  'calmPills': ('Calm pills', 'Calm actions as pills', 'Features'),
  'storePills': ('Store pills', 'Departments as pills', 'Cards'),
  'markPills': ('Mark pills', 'Marks you can tap', 'Features'),
  'goldPills': ('Gold pills', 'Gold-edged black pills', 'Buttons & banners'),
  'coinPills': ('Coin pills', 'Coin actions as pills', 'Offers & coupons'),
  'bookPills': ('Book pills', 'Reading actions as pills', 'Words'),
  'pathPills': ('Path pills', 'A path of black pills', 'Features'),
};

const _lib = 'assets/hero-curve/banner-library.webp';
const _shop = 'assets/hero-curve/banner-store.webp';
const _earn = 'assets/banners/programs/earn.png';
const _ticket = 'assets/gifts/coupon-hero.png';

const _marks = <String>[
  NwsbMarks.bag,
  NwsbMarks.sound,
  NwsbMarks.earn,
  NwsbMarks.book,
  NwsbMarks.word,
  NwsbMarks.coupon,
  NwsbMarks.rewards,
  NwsbMarks.flame,
  NwsbMarks.house,
  NwsbMarks.crown,
  NwsbMarks.reader,
  NwsbMarks.hourglass,
  NwsbMarks.user,
  NwsbMarks.signature,
  NwsbMarks.arrow,
];

Map<String, dynamic> railStarter(String kind) => switch (kind) {
      'sideShelf' => {'title': 'Side shelf', 't1': 'Library', 't2': 'Store', 't3': 'Earn', 'image': _lib, 'image2': _shop, 'image3': _earn},
      'wordLane' => {'title': 'Word lane', 'w1': 'Prana', 'w2': 'Soma', 'w3': 'Aura', 'w4': 'Pitta', 'w5': 'Calm'},
      'priceLane' => {'title': 'Price lane', 'n1': '₹199', 'l1': 'Word card', 'n2': '₹499', 'l2': 'Meaning pack', 'n3': '₹1499', 'l3': 'Signature'},
      'soundLane' => {'title': 'Sound lane', 't1': 'Morning', 't2': 'Night', 't3': 'Rain', 'image': _lib, 'image2': _earn, 'image3': _shop},
      'couponLane' => {'title': 'Coupon lane', 'c1': 'NOW10', 'a1': '10% off', 'c2': 'NOW20', 'a2': '20% off', 'c3': 'NOW50', 'a3': '50 coins'},
      'rankLane' => {'title': 'Rank lane', 'r1': 'Officer', 'p1': '22%', 'r2': 'Exec I', 'p2': '30%', 'r3': 'Diamond', 'p3': '50%'},
      'posterLane' => {'title': 'Poster lane', 't1': 'Sounds', 't2': 'Words', 't3': 'Coupons', 'image': _lib, 'image2': _shop, 'image3': _ticket},
      'dealLane' => {'title': 'Deal lane', 't1': 'Word week', 'p1': '₹299', 't2': 'Sound week', 'p2': '₹199', 't3': 'Both', 'p3': '₹449'},
      'storyStack' => {'title': 'Story stack', 'h1': 'Morning line', 's1': 'Five quiet minutes', 'h2': 'Night sound', 's2': 'Let the day go', 'h3': 'Word card', 's3': 'One word, spoken'},
      'stepStack' => {'title': 'Step stack', 'h1': 'Pick a feeling', 's1': 'Tell the day how you are', 'h2': 'Press play', 's2': 'A short practice starts', 'h3': 'Come back', 's3': 'Tomorrow is enough'},
      'noteStack' => {'title': 'Note stack', 'h1': 'Keep it short', 's1': 'One line is enough', 'h2': 'Keep it kind', 's2': 'No rush in the words', 'h3': 'Keep it yours', 's3': 'Only this account sees it'},
      'offerStack' => {'title': 'Offer stack', 'h1': 'First order', 's1': '10% off the catalogue', 'h2': 'Coin rate', 's2': '10 coins = ₹1', 'h3': 'Not cash', 's3': 'Catalogue prizes only'},
      'wordStack' => {'title': 'Word stack', 'h1': 'Prana', 's1': 'Breath', 'h2': 'Soma', 's2': 'Rest', 'h3': 'Aura', 's3': 'The field around you'},
      'priceStack' => {'title': 'Price stack', 'h1': 'Word card', 's1': '₹199', 'h2': 'Meaning pack', 's2': '₹499', 'h3': 'Signature set', 's3': '₹1,499'},
      'nightStack' => {'title': 'Night stack', 'h1': 'Soft rain', 's1': '12 minutes', 'h2': 'Low drum', 's2': '8 minutes', 'h3': 'Night words', 's3': 'Read aloud'},
      'sidePills' => {'title': 'Side pills', 'a': 'Store', 'b': 'Player', 'c': 'Earn', 'd': 'Words'},
      'doorPills' => {'title': 'Door pills', 'a': 'Words', 'b': 'Sounds', 'c': 'Practice', 'd': 'Gifts'},
      'shopPills' => {'title': 'Shop pills', 'a': 'Store', 'b': 'Player', 'c': 'Earn', 'd': 'Bag'},
      'soundPills' => {'title': 'Sound pills', 'a': 'Morning', 'b': 'Rain', 'c': 'Night', 'd': 'Library'},
      'earnPills' => {'title': 'Earn pills', 'a': 'Ranks', 'b': 'Coins', 'c': 'Code', 'd': 'Team'},
      'giftPills' => {'title': 'Gift pills', 'a': 'Open', 'b': 'Scratch', 'c': 'Spin', 'd': 'Keep'},
      'wordPills' => {'title': 'Word pills', 'a': 'Read', 'b': 'Hear', 'c': 'Save', 'd': 'Own'},
      'nightPills' => {'title': 'Night pills', 'a': 'Rest', 'b': 'Rain', 'c': 'Quiet', 'd': 'Sleep'},
      'calmPills' => {'title': 'Calm pills', 'a': 'Breathe', 'b': 'Listen', 'c': 'Sit', 'd': 'Stay'},
      'storePills' => {'title': 'Store pills', 'a': 'Words', 'b': 'Meanings', 'c': 'Books', 'd': 'Plans'},
      'markPills' => {'title': 'Mark pills', 'a': 'Bag', 'b': 'Sound', 'c': 'Book', 'd': 'Coin'},
      'goldPills' => {'title': 'Gold pills', 'a': 'Offer', 'b': 'Code', 'c': 'Save', 'd': 'Go'},
      'coinPills' => {'title': 'Coin pills', 'a': '10', 'b': '20', 'c': '50', 'd': '100'},
      'bookPills' => {'title': 'Book pills', 'a': 'Read', 'b': 'Mark', 'c': 'Share', 'd': 'Shelf'},
      'pathPills' => {'title': 'Path pills', 'a': 'Start', 'b': 'Today', 'c': 'Again', 'd': 'Done'},
      _ => const {},
    };

bool isRailKind(String kind) => kRailKinds.contains(kind);

Widget buildRailBanner(String kind, TplKit k) {
  if (kind.endsWith('Pills')) return _pills(k, kind);
  if (kind.endsWith('Stack')) return _stack(k, kind);
  return _lane(k, kind);
}

Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

TextStyle _w(double s) => TextStyle(color: Colors.white, fontSize: s, fontWeight: FontWeight.w800);
TextStyle _g(double s) => TextStyle(color: const Color(0xFFE8D5A3), fontSize: s, fontWeight: FontWeight.w800);
TextStyle _d(double s) => TextStyle(color: const Color(0xB3FFFFFF), fontSize: s, fontWeight: FontWeight.w600);

Widget _lane(TplKit k, String kind) {
  final cards = switch (kind) {
    'wordLane' => [
        for (final id in ['w1', 'w2', 'w3', 'w4', 'w5'])
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
              k.label(id, _w(28)),
              const SizedBox(height: 6),
              Container(width: 36, height: 2, color: const Color(0xFFE8D5A3)),
            ]),
          ),
      ],
    'priceLane' => [
        for (final pair in [('n1', 'l1'), ('n2', 'l2'), ('n3', 'l3')])
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 120, height: 120, alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE8D5A3), width: 1.4)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                k.label(pair.$1, _g(16)),
                k.label(pair.$2, _d(11), maxLines: 2, align: TextAlign.center),
              ]),
            ),
          ),
      ],
    'couponLane' => [
        _couponCard(k, 'c1', 'a1'),
        _couponCard(k, 'c2', 'a2'),
        _couponCard(k, 'c3', 'a3'),
      ],
    'rankLane' => [
        _priceCard(k, 'r1', 'p1'),
        _priceCard(k, 'r2', 'p2'),
        _priceCard(k, 'r3', 'p3'),
      ],
    'dealLane' => [
        _priceCard(k, 't1', 'p1'),
        _priceCard(k, 't2', 'p2'),
        _priceCard(k, 't3', 'p3'),
      ],
    'soundLane' => [
        _poster(k, 'image', 't1', 132, 140),
        _poster(k, 'image2', 't2', 132, 140),
        _poster(k, 'image3', 't3', 132, 140),
      ],
    'posterLane' => [
        _poster(k, 'image', 't1', 150, 180),
        _poster(k, 'image2', 't2', 150, 180),
        _poster(k, 'image3', 't3', 150, 180),
      ],
    _ => [
        _poster(k, 'image', 't1', 140, 140),
        _poster(k, 'image2', 't2', 140, 140),
        _poster(k, 'image3', 't3', 140, 140),
      ],
  };
  final tall = kind == 'posterLane' ? 196.0 : 156.0;
  return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    k.label('title', _w(18)),
    const SizedBox(height: 10),
    SizedBox(
      height: tall,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: cards),
      ),
    ),
  ]));
}

Widget _stack(TplKit k, String kind) {
  final rows = [('h1', 's1'), ('h2', 's2'), ('h3', 's3')];
  Widget row(int i) {
    final (h, s) = rows[i];
    switch (kind) {
      case 'stepStack':
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 28, height: 28, alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFE8D5A3), shape: BoxShape.circle),
                child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF16181E), fontWeight: FontWeight.w900)),
              ),
              if (i < 2) Container(width: 2, height: 28, color: const Color(0x55E8D5A3)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              k.label(h, _w(16)),
              k.label(s, _d(12), maxLines: 2),
            ])),
          ]),
        );
      case 'noteStack':
        return Padding(
          padding: EdgeInsets.only(bottom: 8, left: i * 8),
          child: Transform.rotate(
            angle: (i - 1) * 0.03,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF4EFE4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                k.label(h, const TextStyle(color: Color(0xFF1A140C), fontSize: 15, fontWeight: FontWeight.w800)),
                k.label(s, const TextStyle(color: Color(0xFF5C5348), fontSize: 12)),
              ]),
            ),
          ),
        );
      case 'offerStack':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 92, child: k.label(h, _g(18), maxLines: 2)),
            Expanded(child: k.label(s, _w(14), maxLines: 2)),
          ]),
        );
      case 'wordStack':
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: k.label(h, _w(26), maxLines: 1)),
            k.label(s, _d(13), maxLines: 1),
          ]),
        );
      case 'priceStack':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            k.label(h, _w(14)),
            const Expanded(child: Text('  · · · · · · · · ', maxLines: 1, style: TextStyle(color: Color(0x44FFFFFF), letterSpacing: 2))),
            k.label(s, _g(14)),
          ]),
        );
      case 'nightStack':
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF0C0C10), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(child: k.label(h, _w(16))),
            k.label(s, _g(12)),
          ]),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: const Color(0xFFE8D5A3), width: 3)),
              color: const Color(0xFF14161C),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              k.label(h, _w(15)),
              k.label(s, _d(12)),
            ]),
          ),
        );
    }
  }

  return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    k.label('title', _w(18)),
    const SizedBox(height: 8),
    SizedBox(height: 240, child: SingleChildScrollView(child: Column(children: [for (var i = 0; i < 3; i++) row(i)]))),
  ]));
}

Widget _row(TplKit k, String head, String sub) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x33E8D5A3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          k.label(head, _w(15)),
          const SizedBox(height: 2),
          k.label(sub, _d(12)),
        ]),
      ),
    );

Widget _chipCard(TplKit k, String id) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 108,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x55E8D5A3)),
        ),
        child: k.label(id, _w(14), align: TextAlign.center),
      ),
    );

Widget _priceCard(TplKit k, String top, String bottom) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 132,
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x44E8D5A3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          k.label(top, _w(16), maxLines: 1),
          const SizedBox(height: 6),
          k.label(bottom, _g(13), maxLines: 2),
        ]),
      ),
    );

Widget _couponCard(TplKit k, String code, String amount) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 140,
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A140C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x88E8D5A3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          k.label(code, _g(16), maxLines: 1),
          const SizedBox(height: 6),
          k.label(amount, _w(13), maxLines: 2),
        ]),
      ),
    );

Widget _poster(TplKit k, String image, String title, double width, double height) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            k.picture(image),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xE0000000)],
                ),
              ),
            ),
            Positioned(left: 10, right: 10, bottom: 10, child: k.label(title, _w(14), maxLines: 1)),
          ]),
        ),
      ),
    );

Widget _pills(TplKit k, String kind) {
  const ids = ['a', 'b', 'c', 'd'];
  final seed = kind.hashCode.abs();
  Widget one(int i, double t) {
    final id = ids[i];
    final mark = _marks[(seed + i) % _marks.length];
    final on = (t * 4).floor() % 4 == i;
    switch (kind) {
      case 'doorPills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF101114),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(color: on ? const Color(0xFFE8D5A3) : const Color(0x33FFFFFF)),
            ),
            child: k.label(id, _w(15)),
          ),
        );
      case 'shopPills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              NwsbIcon(mark, size: 18, color: const Color(0xFF16181E)),
              const SizedBox(height: 4),
              k.label(id, const TextStyle(color: Color(0xFF16181E), fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ),
        );
      case 'soundPills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF16181E), border: Border.fromBorderSide(BorderSide(color: Color(0xFFE8D5A3)))), child: NwsbIcon(mark, size: 16, color: Colors.white)),
            const SizedBox(width: 8),
            Expanded(child: k.label(id, _w(16))),
          ]),
        );
      case 'earnPills':
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8D5A3)), borderRadius: BorderRadius.circular(6)),
          child: k.label(id, _g(14)),
        );
      case 'giftPills':
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF1A140C), borderRadius: BorderRadius.circular(4)),
          child: Row(children: [
            Expanded(child: k.label(id, _w(14))),
            const Text('····', style: TextStyle(color: Color(0xFFE8D5A3))),
          ]),
        );
      case 'nightPills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: ColoredBox(
            color: const Color(0xFF07080C),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: k.label(id, _w(22))),
          ),
        );
      case 'calmPills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white)),
            child: k.label(id, _w(13)),
          ),
        );
      case 'storePills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(children: [
            Container(width: 48, height: 48, alignment: Alignment.center, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: NwsbIcon(mark, size: 20, color: const Color(0xFF16181E))),
            const SizedBox(height: 4),
            k.label(id, _d(12), align: TextAlign.center),
          ]),
        );
      case 'markPills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 36, height: 36, alignment: Alignment.center, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: NwsbIcon(mark, size: 16, color: const Color(0xFF16181E))),
            const SizedBox(width: 8),
            k.label(id, _w(13)),
          ]),
        );
      case 'goldPills':
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: on ? const Color(0xFFE8D5A3) : const Color(0xFF3A3018), borderRadius: BorderRadius.circular(20)),
          child: k.label(id, TextStyle(color: on ? const Color(0xFF16181E) : const Color(0xFFE8D5A3), fontWeight: FontWeight.w800, fontSize: 14)),
        );
      case 'coinPills':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: 72, height: 72, alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE8D5A3), width: 2), color: const Color(0xFF1A140C)),
            child: k.label(id, _g(16)),
          ),
        );
      case 'bookPills':
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
          decoration: const BoxDecoration(color: Color(0xFFF6F1E6), border: Border(left: BorderSide(color: Color(0xFF8A6A32), width: 6))),
          child: k.label(id, const TextStyle(color: Color(0xFF1A140C), fontWeight: FontWeight.w800, fontSize: 15)),
        );
      case 'pathPills':
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? const Color(0xFFE8D5A3) : const Color(0xFF2A2A2A), border: Border.all(color: const Color(0xFFE8D5A3)))),
            if (i < 3) Container(width: 2, height: 36, color: const Color(0x55E8D5A3)),
          ]),
          const SizedBox(width: 10),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: k.label(id, _w(15)))),
        ]);
      case 'wordPills':
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: const BoxDecoration(
            color: Color(0xFF12141A),
            border: Border(left: BorderSide(color: Color(0xFFE8D5A3), width: 4)),
          ),
          child: k.label(id, _w(16)),
        );
      default:
        return _pill(k, id, mark, on, 0.8);
    }
  }

  return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    k.label('title', _w(16)),
    const SizedBox(height: 8),
    Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: MotionLoop(
          milliseconds: 2800,
          builder: (t) => Column(children: [for (var i = 0; i < 4; i++) one(i, t)]),
        ),
      ),
    ),
  ]));
}

Widget _pill(TplKit k, String id, String mark, bool on, double pulse) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF012141A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: on ? Color.lerp(const Color(0xFFE8D5A3), Colors.white, pulse)! : const Color(0x33FFFFFF),
          width: on ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: NwsbIcon(mark, size: 18, color: const Color(0xFF16181E)),
          ),
          const SizedBox(width: 10),
          Expanded(child: k.label(id, _w(14), maxLines: 1)),
        ]),
      ),
    ),
  );
}
