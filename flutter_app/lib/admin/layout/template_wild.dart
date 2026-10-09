/// Fifty more sections for Admin → Templates.
///
/// Each one is a different layout: a shelf you swipe, a bill, a stair of
/// type, a meter, a seal, a ledger. Black, white, cream. Every word is a
/// field, so a tap edits it. Nothing turns by itself.
library;

import 'package:flutter/material.dart';

import 'anims/effects.dart';
import 'template_more.dart';

const kWildTemplates = <String, (String, String, String)>{
  'glassShelf': ('Glass shelf', 'Three glass cards you swipe', 'Cards'),
  'neoPair': ('Soft pair', 'Two soft cards, black and white', 'Cards'),
  'blackBill': ('Black bill', 'A black bill with a gold line', 'Offers & coupons'),
  'whiteBill': ('White bill', 'A white bill with a black line', 'Offers & coupons'),
  'stairType': ('Stair type', 'Three words stepping down', 'Words'),
  'priceRail': ('Price rail', 'Prices you swipe', 'Numbers'),
  'stampRing': ('Stamp ring', 'A round stamp on a line', 'Buttons & banners'),
  'slantSplit': ('Slant split', 'A diagonal cut between two tones', 'Picture + words'),
  'captionBar': ('Caption bar', 'A thin bar under a big word', 'Top banners'),
  'meterStack': ('Three meters', 'Three bars that fill', 'Numbers'),
  'wordPoster': ('Word poster', 'One word, set like a poster', 'Words'),
  'notchCoupon': ('Notched coupon', 'A coupon with a notch', 'Offers & coupons'),
  'hourRow': ('Hour row', 'Morning, noon, night', 'Features'),
  'markQuote': ('Mark quote', 'A quote between two rules', 'Reviews'),
  'tickList': ('Tick list', 'A short list with ticks', 'Features'),
  'countRun': ('Count run', 'A huge figure and a caption', 'Numbers'),
  'cornerSeal': ('Corner seal', 'A seal in the corner', 'Cards'),
  'offerBand': ('Offer band', 'A full-width offer band', 'Offers & coupons'),
  'pillSwipe': ('Pill swipe', 'Pills you swipe', 'Buttons & banners'),
  'frameSwipe': ('Frame swipe', 'Frames you swipe', 'Cards'),
  'inkCard': ('Ink card', 'White type on black', 'Cards'),
  'ruleSheet': ('Rule sheet', 'Lines and short notes', 'Words'),
  'bigSmall': ('Big and small', 'A huge word and a quiet line', 'Words'),
  'edgeLabel': ('Edge label', 'A label down the edge', 'Top banners'),
  'threeDiscs': ('Three discs', 'Three round marks', 'Features'),
  'dashSteps': ('Dash steps', 'A dashed path of steps', 'Features'),
  'foldTicket': ('Fold ticket', 'A ticket with a folded corner', 'Offers & coupons'),
  'inkClose': ('Ink close', 'A black closing line', 'Top banners'),
  'creamClose': ('Cream close', 'A cream closing line', 'Top banners'),
  'spotWord': ('Spot word', 'One word in a ring', 'Words'),
  'twoDoors': ('Two doors', 'Two ways in', 'Buttons & banners'),
  'priceCol': ('Price column', 'A column of prices', 'Numbers'),
  'plainNote': ('Plain note', 'A note on warm paper', 'Words'),
  'badgeSwipe': ('Badge swipe', 'Badges you swipe', 'Features'),
  'sideIndex': ('Side index', 'A numbered index', 'Words'),
  'barWave': ('Bar wave', 'Bars of different heights', 'Numbers'),
  'crossPanel': ('Cross panel', 'A cross on a dark panel', 'Buttons & banners'),
  'haloType': ('Halo type', 'Type inside a soft ring', 'Words'),
  'codeTicket': ('Code ticket', 'A code on a ticket', 'Offers & coupons'),
  'stepSwipe': ('Step swipe', 'Steps you swipe', 'Features'),
  'darkQuote': ('Dark quote', 'A quote on black', 'Reviews'),
  'lightQuote': ('Cream quote', 'A quote on cream', 'Reviews'),
  'coinSwipe': ('Coin swipe', 'Coins you swipe', 'Offers & coupons'),
  'waxSeal': ('Wax seal', 'A seal over a short line', 'Cards'),
  'splitStat': ('Split stat', 'A figure and a sentence', 'Numbers'),
  'glassRun': ('Glass run', 'A line that travels on glass', 'Top banners'),
  'tightStack': ('Tight stack', 'Words stacked tight', 'Words'),
  'lineButton': ('Line button', 'An outline button', 'Buttons & banners'),
  'darkLedger': ('Dark ledger', 'A dark list of prices', 'Numbers'),
  'posterRule': ('Poster rule', 'A poster with one rule', 'Top banners'),
};

const kWildKinds = <String>[
  'glassShelf',
  'neoPair',
  'blackBill',
  'whiteBill',
  'stairType',
  'priceRail',
  'stampRing',
  'slantSplit',
  'captionBar',
  'meterStack',
  'wordPoster',
  'notchCoupon',
  'hourRow',
  'markQuote',
  'tickList',
  'countRun',
  'cornerSeal',
  'offerBand',
  'pillSwipe',
  'frameSwipe',
  'inkCard',
  'ruleSheet',
  'bigSmall',
  'edgeLabel',
  'threeDiscs',
  'dashSteps',
  'foldTicket',
  'inkClose',
  'creamClose',
  'spotWord',
  'twoDoors',
  'priceCol',
  'plainNote',
  'badgeSwipe',
  'sideIndex',
  'barWave',
  'crossPanel',
  'haloType',
  'codeTicket',
  'stepSwipe',
  'darkQuote',
  'lightQuote',
  'coinSwipe',
  'waxSeal',
  'splitStat',
  'glassRun',
  'tightStack',
  'lineButton',
  'darkLedger',
  'posterRule',
];

bool isWildKind(String kind) => kWildKinds.contains(kind);

Map<String, dynamic> wildStarter(String kind) => switch (kind) {
      'glassShelf' => {'title': 'Glass shelf', 'line': 'Swipe the glass', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'neoPair' => {'title': 'Soft pair', 'line': 'Black beside white', 'a': 'Black', 'b': 'White'},
      'blackBill' => {'title': 'Black bill', 'line': 'Pay once', 'a': 'Item', 'b': '₹199'},
      'whiteBill' => {'title': 'White bill', 'line': 'Pay once', 'a': 'Item', 'b': '₹199'},
      'stairType' => {'title': 'Stair', 'line': 'Step down the line', 'a': 'Read', 'b': 'Hear', 'c': 'Keep'},
      'priceRail' => {'title': 'Prices', 'line': 'Swipe the figures', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'stampRing' => {'title': 'Owned', 'line': 'Never restocked', 'a': 'Once'},
      'slantSplit' => {'title': 'Today', 'line': 'Leave the noise', 'a': 'Keep', 'b': 'Drop'},
      'captionBar' => {'title': 'Caption', 'line': 'Under the word', 'a': 'NowssB'},
      'meterStack' => {'title': 'Meters', 'line': 'How the week went', 'a': 'Breath', 'b': 'Read', 'c': 'Rest'},
      'wordPoster' => {'title': 'STILL', 'line': 'Set large', 'a': 'Own it'},
      'notchCoupon' => {'title': 'Coupon', 'line': 'Tear and keep', 'a': '₹150', 'b': 'PAPER'},
      'hourRow' => {'title': 'The day', 'line': 'Three hours', 'a': 'Morning', 'b': 'Noon', 'c': 'Night'},
      'markQuote' => {'title': 'A note', 'line': 'Between the rules', 'a': 'Healing is a return.'},
      'tickList' => {'title': 'Included', 'line': 'What you get', 'a': 'Spoken', 'b': 'Offline', 'c': 'Private'},
      'countRun' => {'title': '1200', 'line': 'Words on the shelf', 'a': 'On the shelf'},
      'cornerSeal' => {'title': 'Seal', 'line': 'In the corner', 'a': 'NS'},
      'offerBand' => {'title': 'This week', 'line': 'Across the page', 'a': 'Half off'},
      'pillSwipe' => {'title': 'Go', 'line': 'Swipe, do not wait', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'frameSwipe' => {'title': 'Frames', 'line': 'Swipe the frames', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'inkCard' => {'title': 'Ink', 'line': 'White on black', 'a': 'White type'},
      'ruleSheet' => {'title': 'Notes', 'line': 'Short lines', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'bigSmall' => {'title': 'QUIET', 'line': 'Said softly', 'a': 'soft'},
      'edgeLabel' => {'title': 'EDGE', 'line': 'Down the side', 'a': 'Side'},
      'threeDiscs' => {'title': 'Marks', 'line': 'Three marks', 'a': 'I', 'b': 'II', 'c': 'III'},
      'dashSteps' => {'title': 'Path', 'line': 'Follow the dashes', 'a': 'Start', 'b': 'Today', 'c': 'Stay'},
      'foldTicket' => {'title': 'Ticket', 'line': 'Folded once', 'a': 'Admit', 'b': 'One'},
      'inkClose' => {'title': 'Close', 'line': 'On black', 'a': 'End'},
      'creamClose' => {'title': 'Close', 'line': 'On cream', 'a': 'End'},
      'spotWord' => {'title': 'HERE', 'line': 'In the ring', 'a': 'Now'},
      'twoDoors' => {'title': 'Doors', 'line': 'Pick one', 'a': 'Store', 'b': 'Player'},
      'priceCol' => {'title': 'Prices', 'line': 'Read down', 'a': '₹199', 'b': '₹499', 'c': '₹1499'},
      'plainNote' => {'title': 'Note', 'line': 'Come back', 'a': 'Tomorrow'},
      'badgeSwipe' => {'title': 'Badges', 'line': 'Swipe the badges', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'sideIndex' => {'title': 'Index', 'line': 'Numbered', 'a': '01 Prana', 'b': '02 Soma', 'c': '03 Aura'},
      'barWave' => {'title': 'Bars', 'line': 'Rising and falling', 'a': 'Low', 'b': 'Mid', 'c': 'High'},
      'crossPanel' => {'title': 'Here', 'line': 'You are here', 'a': 'Open'},
      'haloType' => {'title': 'HALO', 'line': 'Inside the ring', 'a': 'Still'},
      'codeTicket' => {'title': 'Code', 'line': 'Show this', 'a': 'QUIET10'},
      'stepSwipe' => {'title': 'Steps', 'line': 'Swipe the steps', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'darkQuote' => {'title': 'Dark', 'line': 'On black', 'a': 'Healing is a return.'},
      'lightQuote' => {'title': 'Light', 'line': 'On cream', 'a': 'Healing is a return.'},
      'coinSwipe' => {'title': 'Coins', 'line': 'Swipe the coins', 'a': 'One', 'b': 'Two', 'c': 'Three'},
      'waxSeal' => {'title': 'Wax', 'line': 'Pressed once', 'a': 'Once'},
      'splitStat' => {'title': '48', 'line': 'Minutes today', 'a': 'On the shelf'},
      'glassRun' => {'title': 'NowssB', 'line': 'It travels', 'a': 'Words', 'b': 'Sounds', 'c': 'Practice'},
      'tightStack' => {'title': 'Stack', 'line': 'Tight type', 'a': 'Read', 'b': 'Hear', 'c': 'Keep'},
      'lineButton' => {'title': 'Open', 'line': 'An outline', 'a': 'Begin'},
      'darkLedger' => {'title': 'Ledger', 'line': 'Name and figure', 'a': 'Word', 'b': 'Meaning', 'c': 'Plan'},
      'posterRule' => {'title': 'POSTER', 'line': 'One rule', 'a': 'Own it'},
      _ => const {},
    };


const _ink = Color(0xFF14120E);
const _cream = Color(0xFFF6F1E6);
const _paper = Color(0xFFF3EFE6);

TextStyle _t(Color c, double s, {FontWeight w = FontWeight.w800}) =>
    TextStyle(color: c, fontSize: s, fontWeight: w, height: 1.05, letterSpacing: -0.2);

Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: child);

Widget _fx(TplKit k, String id, Widget child) {
  final fx = k.s('fx_$id');
  if (fx.isEmpty || fx == 'none') return child;
  return LoopFx(kind: fx, child: child);
}

Widget _card(Color bg, Color fg, TplKit k, String id) => _fx(
      k,
      id,
      Container(
        width: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: k.label(id, _t(fg, 16)),
      ),
    );

Widget buildWildTemplate(String kind, TplKit k) {
  final layout = _layout[kind] ?? 'poster';
  final dark = _dark.contains(kind);
  final bg = dark ? _ink : _paper;
  final fg = dark ? _cream : _ink;
  final title = k.label('title', _t(fg, layout == 'poster' || layout == 'bigsmall' ? 36 : 20));
  final line = k.has('line') ? k.label('line', _t(fg.withValues(alpha: 0.7), 13, w: FontWeight.w600)) : const SizedBox.shrink();
  Widget body;
  switch (layout) {
    case 'scroll':
      body = SizedBox(
        height: 92,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final id in ['a', 'b', 'c'])
              if (k.has(id)) Padding(padding: const EdgeInsets.only(right: 8), child: _card(dark ? const Color(0xFF2A261F) : Colors.white, fg, k, id)),
          ],
        ),
      );
    case 'pair':
      body = Row(children: [
        Expanded(child: _card(_ink, _cream, k, 'a')),
        const SizedBox(width: 8),
        Expanded(child: _card(Colors.white, _ink, k, 'b')),
      ]);
    case 'stairs':
    case 'stack':
    case 'index':
    case 'prices':
    case 'ticks':
    case 'rules':
    case 'ledger':
    case 'hours':
    case 'dash':
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final id in ['a', 'b', 'c'])
            if (k.has(id))
              Padding(
                padding: EdgeInsets.only(left: layout == 'stairs' ? (id == 'a' ? 0 : id == 'b' ? 18 : 36) : 0, bottom: 6),
                child: _fx(k, id, k.label(id, _t(fg, layout == 'prices' ? 22 : 16))),
              ),
        ],
      );
    case 'meters':
    case 'bars':
      body = Column(children: [
        for (final (id, f) in [('a', 0.45), ('b', 0.7), ('c', 0.9)])
          if (k.has(id))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                SizedBox(width: 64, child: k.label(id, _t(fg, 12, w: FontWeight.w700))),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: layout == 'bars' ? f : f * 0.8, minHeight: layout == 'bars' ? 18 : 8, backgroundColor: fg.withValues(alpha: 0.12), color: fg))),
              ]),
            ),
      ]);
    case 'quote':
      body = Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: fg, width: 2))),
        child: Padding(padding: const EdgeInsets.only(left: 12), child: k.label('a', _t(fg, 18, w: FontWeight.w600))),
      );
    case 'stamp':
    case 'seal':
    case 'spot':
    case 'halo':
      body = Row(children: [
        Container(
          width: 64, height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: fg, width: 1.4)),
          child: k.label('a', _t(fg, 12), align: TextAlign.center, maxLines: 2),
        ),
        const SizedBox(width: 12),
        Expanded(child: line),
      ]);
    case 'marquee':
      body = ClipRect(child: Row(children: [
        for (final id in ['a', 'b', 'c'])
          if (k.has(id)) Padding(padding: const EdgeInsets.only(right: 16), child: k.label(id, _t(fg, 16))),
      ]));
    case 'doors':
      body = Row(children: [
        for (final id in ['a', 'b'])
          if (k.has(id))
            Expanded(child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: fg)),
              child: k.label(id, _t(fg, 16)),
            )),
      ]);
    case 'notch':
    case 'fold':
    case 'code':
    case 'bill':
      body = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: dark ? const Color(0xFF1C1914) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: fg.withValues(alpha: 0.3))),
        child: Row(children: [
          for (final id in ['a', 'b'])
            if (k.has(id)) Expanded(child: k.label(id, _t(fg, 16))),
        ]),
      );
    case 'count':
      body = k.label('a', _t(fg, 14, w: FontWeight.w600));
    case 'button':
      body = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: fg, width: 1.4)),
        child: k.label('a', _t(fg, 14)),
      );
    case 'cross':
      body = SizedBox(height: 64, child: Stack(alignment: Alignment.center, children: [
        Container(width: 1.4, height: 64, color: fg),
        Container(width: 64, height: 1.4, color: fg),
        k.label('a', _t(fg, 13)),
      ]));
    case 'edge':
      body = Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        RotatedBox(quarterTurns: 3, child: k.label('a', _t(fg, 12, w: FontWeight.w700))),
        const SizedBox(width: 10),
        Expanded(child: line),
      ]);
    default:
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final id in ['a', 'b', 'c'])
            if (k.has(id)) Padding(padding: const EdgeInsets.only(bottom: 4), child: k.label(id, _t(fg, 16))),
        ],
      );
  }
  final showLine = layout != 'stamp' && layout != 'seal' && layout != 'spot' && layout != 'halo' && layout != 'edge';
  return _pad(Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      boxShadow: dark ? null : const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title,
      if (k.has('line') && showLine) ...[const SizedBox(height: 4), line],
      const SizedBox(height: 10),
      body,
    ]),
  ));
}

const _layout = <String, String>{
  'glassShelf': 'scroll',
  'neoPair': 'pair',
  'blackBill': 'bill',
  'whiteBill': 'bill',
  'stairType': 'stairs',
  'priceRail': 'scroll',
  'stampRing': 'stamp',
  'slantSplit': 'slant',
  'captionBar': 'bar',
  'meterStack': 'meters',
  'wordPoster': 'poster',
  'notchCoupon': 'notch',
  'hourRow': 'hours',
  'markQuote': 'quote',
  'tickList': 'ticks',
  'countRun': 'count',
  'cornerSeal': 'seal',
  'offerBand': 'band',
  'pillSwipe': 'scroll',
  'frameSwipe': 'scroll',
  'inkCard': 'ink',
  'ruleSheet': 'rules',
  'bigSmall': 'bigsmall',
  'edgeLabel': 'edge',
  'threeDiscs': 'discs',
  'dashSteps': 'dash',
  'foldTicket': 'fold',
  'inkClose': 'close',
  'creamClose': 'close',
  'spotWord': 'spot',
  'twoDoors': 'doors',
  'priceCol': 'prices',
  'plainNote': 'note',
  'badgeSwipe': 'scroll',
  'sideIndex': 'index',
  'barWave': 'bars',
  'crossPanel': 'cross',
  'haloType': 'halo',
  'codeTicket': 'code',
  'stepSwipe': 'scroll',
  'darkQuote': 'quote',
  'lightQuote': 'quote',
  'coinSwipe': 'scroll',
  'waxSeal': 'stamp',
  'splitStat': 'count',
  'glassRun': 'marquee',
  'tightStack': 'stack',
  'lineButton': 'button',
  'darkLedger': 'ledger',
  'posterRule': 'poster',
};

const _dark = <String>{
  'blackBill',
  'stampRing',
  'notchCoupon',
  'inkCard',
  'inkClose',
  'crossPanel',
  'codeTicket',
  'darkQuote',
  'waxSeal',
  'glassRun',
  'darkLedger',
};
