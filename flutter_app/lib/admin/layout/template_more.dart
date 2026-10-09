/// More ready-to-fill sections and banners for the UI Editor (item 8):
/// top banners, cards, features, reviews, buttons & banners, offers &
/// coupons, picture + words and numbers. Like the first ones they draw
/// from the entry's props only, and every word and picture in them is a
/// template field (`tpl.<page>.<entry>.<field>`), so a tap edits it.
library;

import 'package:flutter/material.dart';

import 'template_fresh.dart';
import 'template_motion.dart';
import 'template_rails.dart';

/// The helpers a template draws with (from TemplateSection), so words and
/// pictures here are editable exactly like in the first templates.
class TplKit {
  const TplKit({
    required this.props,
    required this.label,
    required this.picture,
    required this.button,
    required this.corner,
    required this.shadow,
  });

  final Map<String, dynamic> props;

  /// Words from prop [id] (a tap edits them in the editor).
  final Widget Function(String id, TextStyle style, {int? maxLines, TextAlign? align}) label;

  /// A picture from prop [id] (a tap replaces it), filling its box.
  final Widget Function(String id) picture;

  /// The section's button (prop 'cta', goes to 'route').
  final Widget Function({bool light, Color? color}) button;

  final double corner;
  final List<BoxShadow>? shadow;

  String s(String k) => '${props[k] ?? ''}';
  bool has(String k) => s(k).isNotEmpty;
  Color color(String k, int def) => Color(props[k] is num ? (props[k] as num).toInt() : def);
  double num_(String k, double def) => props[k] is num ? (props[k] as num).toDouble() : def;
}

// ── Look ─────────────────────────────────────────────────────────────

const _navy = 0xFF0B1120;
const _ink = 0xFF1B2437;
const _gold = Color(0xFFE8D5A3);
const _cream = 0xFFF5F2EC;
const _dark = Color(0xFF14161C);

TextStyle _h1(bool light, [double size = 26]) => TextStyle(
    color: light ? _dark : Colors.white, fontSize: size, fontWeight: FontWeight.w800, height: 1.1);
TextStyle _h2(bool light, [double size = 17]) =>
    TextStyle(color: light ? _dark : Colors.white, fontSize: size, fontWeight: FontWeight.w800, height: 1.15);
TextStyle _p(bool light, [double size = 13.5]) =>
    TextStyle(color: light ? const Color(0xFF4A4F5C) : const Color(0xCCFFFFFF), fontSize: size, height: 1.35);
TextStyle _eyebrow(Color c) => TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.4);

bool _isLight(int bg) => Color(bg).computeLuminance() > 0.5;

Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

Widget _card(TplKit k, Widget child, {int? bg, int? bg2, EdgeInsets padding = const EdgeInsets.all(18), double? height}) {
  final b = k.color('bg', bg ?? _ink);
  final b2 = k.props['bg2'] is num ? Color((k.props['bg2'] as num).toInt()) : (bg2 == null ? null : Color(bg2));
  return Container(
    height: height,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: b2 == null ? b : null,
      gradient: b2 == null ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [b, b2]),
      borderRadius: BorderRadius.circular(k.corner),
      boxShadow: k.shadow,
    ),
    child: child,
  );
}

Widget _pic(TplKit k, String id, {double radius = 16, double? height, double? width, double aspect = 0}) {
  Widget w = ClipRRect(borderRadius: BorderRadius.circular(radius), child: k.picture(id));
  if (aspect > 0) return AspectRatio(aspectRatio: aspect, child: w);
  return SizedBox(height: height, width: width, child: w);
}

/// Words in a fixed-height box: shrunk to fit when they are longer.
Widget _fit(Widget column) => LayoutBuilder(
      builder: (context, box) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(width: box.maxWidth, child: column),
      ),
    );

Widget _chip(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );

Widget _icon(IconData i, Color c, {double size = 22, Color? bg}) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg ?? c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
      child: Icon(i, color: c, size: size),
    );

Widget _stars(int n, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 5; i++) Icon(i < n ? Icons.star_rounded : Icons.star_outline_rounded, color: c, size: 16),
    ]);

/// A ticket edge: semicircle notches on both sides at [at] (0..1 down).
class _TicketClip extends CustomClipper<Path> {
  const _TicketClip({this.at = 0.5, this.r = 12, this.vertical = false, this.radius = 18});
  final double at, r, radius;
  final bool vertical;

  @override
  Path getClip(Size s) {
    final p = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius)));
    final n = Path();
    if (vertical) {
      final x = s.width * at;
      n
        ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: r))
        ..addOval(Rect.fromCircle(center: Offset(x, s.height), radius: r));
    } else {
      final y = s.height * at;
      n
        ..addOval(Rect.fromCircle(center: Offset(0, y), radius: r))
        ..addOval(Rect.fromCircle(center: Offset(s.width, y), radius: r));
    }
    return Path.combine(PathOperation.difference, p, n);
  }

  @override
  bool shouldReclip(_TicketClip old) => old.at != at || old.r != r || old.vertical != vertical || old.radius != radius;
}

class _Dashes extends StatelessWidget {
  const _Dashes({required this.color, this.vertical = false});
  final Color color;
  final bool vertical;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final len = vertical ? box.maxHeight : box.maxWidth;
        final n = len.isFinite ? (len / 9).floor() : 20;
        final dash = SizedBox(
          width: vertical ? 1.5 : 5,
          height: vertical ? 5 : 1.5,
          child: DecoratedBox(decoration: BoxDecoration(color: color)),
        );
        return Flex(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (var i = 0; i < n; i++) dash],
        );
      });
}

// ── The templates ────────────────────────────────────────────────────

/// kind → (name, what it is, drawer category).
const kMoreTemplates = <String, (String, String, String)>{
  // Top banners
  'heroCentered': ('Centred top banner', 'A big centred headline over a picture', 'Top banners'),
  'heroSideImage': ('Top banner, picture right', 'Words left, a tall picture right', 'Top banners'),
  'heroGlow': ('Glowing top banner', 'A soft gold glow behind big words', 'Top banners'),
  'heroCard': ('Card top banner', 'A picture card with words under it', 'Top banners'),
  'heroLight': ('Light top banner', 'Dark words on cream, picture to the side', 'Top banners'),
  'heroBadge': ('Top banner with badge', 'A badge, a headline and two buttons', 'Top banners'),
  // Cards
  'cardsGrid': ('Two-by-two cards', 'Four picture cards in a grid', 'Cards'),
  'cardsTall': ('Tall picture cards', 'Two tall cards side by side', 'Cards'),
  'cardsList': ('Card list', 'Three rows: picture, title, a line', 'Cards'),
  'cardsPricing': ('Price cards', 'Three plans with a price each', 'Cards'),
  'cardsProfile': ('Profile card', 'A round photo, a name and a line', 'Cards'),
  'cardsOverlap': ('Stacked cards', 'Fanned cards with a title', 'Cards'),
  // Features
  'featureGrid': ('Feature grid', 'Four features with icons', 'Features'),
  'featureRow': ('Feature row', 'Three icons in a row', 'Features'),
  'featureChecks': ('Checklist', 'A heading and ticked points', 'Features'),
  'featureSteps': ('Steps', 'Numbered steps, one under the other', 'Features'),
  'featureLight': ('Light features', 'Features on cream', 'Features'),
  // Reviews
  'quoteBig': ('Big quote', 'One quote in large words', 'Reviews'),
  'quoteCards': ('Review cards', 'Two reviews with stars', 'Reviews'),
  'quoteAvatar': ('Review with photo', 'A photo, stars and a review', 'Reviews'),
  'quoteLight': ('Light quote', 'A quote on cream with a gold mark', 'Reviews'),
  // Buttons & banners
  'ctaGradient': ('Colour button banner', 'A colourful banner with a button', 'Buttons & banners'),
  'ctaDark': ('Dark button banner', 'A gold-edged dark banner', 'Buttons & banners'),
  'ctaLight': ('Light button banner', 'A cream banner with a dark button', 'Buttons & banners'),
  'ctaTwo': ('Two buttons', 'A line of words and two buttons', 'Buttons & banners'),
  'ctaNewsletter': ('Sign-up banner', 'Invite people to join', 'Buttons & banners'),
  'ctaPicture': ('Picture button banner', 'A small picture, words and a button', 'Buttons & banners'),
  // Offers & coupons
  'couponGold': ('Gold coupon (dark)', 'A gold ticket on navy with a code', 'Offers & coupons'),
  'couponStub': ('Coupon with stub (light)', 'A white ticket with a tear-off stub', 'Offers & coupons'),
  'couponNeon': ('Neon coupon (dark)', 'A glowing-edge coupon', 'Offers & coupons'),
  'couponRound': ('Round badge coupon (light)', 'A round amount badge and a code', 'Offers & coupons'),
  'couponStrip': ('Coupon strip (dark)', 'A slim ticket across the page', 'Offers & coupons'),
  'couponPastel': ('Pastel coupons (light)', 'Two soft-coloured coupons', 'Offers & coupons'),
  'offerFlash': ('Flash offer', 'A bold red offer with a time line', 'Offers & coupons'),
  'offerBundle': ('Bundle offer', 'Two pictures, one price', 'Offers & coupons'),
  'offerPrice': ('Price tag offer', 'Old price, new price and a button', 'Offers & coupons'),
  // Picture + words
  'splitLeft': ('Picture left, words right', 'A rounded picture beside words', 'Picture + words'),
  'splitRight': ('Words left, picture right', 'Words beside a rounded picture', 'Picture + words'),
  'splitOverlap': ('Picture with words card', 'A words card over a picture', 'Picture + words'),
  'splitLight': ('Light picture + words', 'On cream, picture and words', 'Picture + words'),
  // Numbers
  'statsRow': ('Numbers row', 'Three big numbers with labels', 'Numbers'),
  'statsCards': ('Number cards', 'Four numbers in cards', 'Numbers'),
  'statsProgress': ('Progress bars', 'Three bars that show how far', 'Numbers'),
  'statsBig': ('One big number', 'A huge number and a line', 'Numbers'),
  'offerTwins': ('Twin offer cards', 'Two gold-edged offer cards, side by side', 'Top banners'),
  'savedShelf': ('Saved for you', 'Chips and cards of things you saved', 'Cards'),
  'goldRibbon': ('Gold ribbon', 'A shining gold ribbon with doors under it', 'Top banners'),
  'doorChips': ('Door chips', 'A row of doors you can tap', 'Cards'),
  'codeBand': ('Code band', 'A slim band with an offer code', 'Offers & coupons'),
  'giftOpen': ('Opening gift', 'A gift card whose flap lifts', 'Offers & coupons'),
  'stayCard': ('Stay card', 'A curved card that asks you to stay', 'Buttons & banners'),
  'threeDeals': ('Three deals', 'Three steps, then the deals they unlock', 'Offers & coupons'),
  'savingLine': ('Saving line', 'A bar that fills with what you saved', 'Numbers'),
  'bagItem': ('Bag item', 'One item in the bag, with its price', 'Cards'),
  'coinPicks': ('Coin amounts', 'Five coin amounts in a row', 'Offers & coupons'),
  'metalPass': ('Metal membership', 'A metal card with a slow shine', 'Cards'),
  'rankTrack': ('Rank track', 'Dots for each rank and how far you are', 'Numbers'),
  'benefitSplit': ('This rank, next rank', 'What you have, and what the next rank adds', 'Features'),
  'dropShelf': ('Dropped prices', 'Cards with the old price and the new one', 'Cards'),
  'peekShelf': ('Peeking posters', 'Posters in a row, the next one peeking in', 'Top banners'),
  'lovedRow': ('Loved row', 'Cards you marked, with a heart', 'Cards'),
  'shineLine': ('Moving offer line', 'One line of an offer that travels', 'Top banners'),
  'pulseCta': ('Pulsing button', 'A banner whose button breathes', 'Buttons & banners'),
  'litSteps': ('Lit steps', 'Steps that light up one after another', 'Features'),
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
  ...kFreshTemplates,
};

const kMoreKinds = <String>[
  'heroCentered', 'heroSideImage', 'heroGlow', 'heroCard', 'heroLight', 'heroBadge', //
  'cardsGrid', 'cardsTall', 'cardsList', 'cardsPricing', 'cardsProfile', 'cardsOverlap',
  'featureGrid', 'featureRow', 'featureChecks', 'featureSteps', 'featureLight',
  'quoteBig', 'quoteCards', 'quoteAvatar', 'quoteLight',
  'ctaGradient', 'ctaDark', 'ctaLight', 'ctaTwo', 'ctaNewsletter', 'ctaPicture',
  'couponGold', 'couponStub', 'couponNeon', 'couponRound', 'couponStrip', 'couponPastel',
  'offerFlash', 'offerBundle', 'offerPrice',
  'splitLeft', 'splitRight', 'splitOverlap', 'splitLight',
  'statsRow', 'statsCards', 'statsProgress', 'statsBig',
  'offerTwins', 'savedShelf', 'goldRibbon', 'doorChips', 'codeBand',
  'giftOpen', 'stayCard', 'threeDeals', 'savingLine', 'bagItem',
  'coinPicks', 'metalPass', 'rankTrack', 'benefitSplit', 'dropShelf',
  'peekShelf', 'lovedRow', 'shineLine', 'pulseCta', 'litSteps',
  'sideShelf', 'wordLane', 'priceLane', 'soundLane', 'couponLane',
  'rankLane', 'posterLane', 'dealLane', 'storyStack', 'stepStack',
  'noteStack', 'offerStack', 'wordStack', 'priceStack', 'nightStack',
  'sidePills', 'doorPills', 'shopPills', 'soundPills', 'earnPills',
  'giftPills', 'wordPills', 'nightPills', 'calmPills', 'storePills',
  'markPills', 'goldPills', 'coinPills', 'bookPills', 'pathPills',
  ...kFreshKinds,
];

const _a = 'assets/banners/stories/aura.png';
const _b = 'assets/banners/stories/prana.png';
const _c = 'assets/banners/stories/soma.png';
const _d = 'assets/banners/stories/pitta.png';
const _e = 'assets/store/collections/cosmos.webp';
const _f = 'assets/store/collections/nature.webp';
const _g = 'assets/store/collections/peace.webp';
const _h = 'assets/store/collections/sacred.webp';

Map<String, dynamic> moreStarter(String kind) {
  final fresh = freshStarter(kind);
  if (fresh.isNotEmpty) return fresh;
  final rail = railStarter(kind);
  if (rail.isNotEmpty) return rail;
  return switch (kind) {
      'heroCentered' => {'eyebrow': 'NEW TODAY', 'title': 'Find your calm in five minutes', 'subtitle': 'Short practices for busy days', 'cta': 'Start now', 'route': 'tab:1', 'image': _b},
      'heroSideImage' => {'eyebrow': 'FOR YOU', 'title': 'Breathe. Listen. Heal.', 'subtitle': 'A new path every morning', 'cta': 'Begin', 'route': 'tab:1', 'image': _a},
      'heroGlow' => {'title': 'Words that heal', 'subtitle': 'Over 1,000 healing words, read aloud for you', 'cta': 'Explore words', 'route': 'tab:3'},
      'heroCard' => {'title': 'Tonight’s sleep story', 'subtitle': '12 minutes · Soft rain', 'cta': 'Play', 'route': 'tab:1', 'image': _c},
      'heroLight' => {'eyebrow': 'SPRING EDITION', 'title': 'Light for the body and mind', 'cta': 'See more', 'route': 'tab:3', 'image': _d},
      'heroBadge' => {'badge': 'Most loved', 'title': 'The 21-day healing journey', 'subtitle': 'Join 40,000 people', 'cta': 'Join', 'cta2': 'Learn more', 'route': 'tab:1'},
      'cardsGrid' => {'title': 'Browse by mood', 'image': _a, 't1': 'Calm', 'image2': _b, 't2': 'Focus', 'image3': _c, 't3': 'Sleep', 'image4': _d, 't4': 'Energy'},
      'cardsTall' => {'title': 'This week', 'image': _e, 't1': 'The cosmos within', 'image2': _f, 't2': 'Back to nature'},
      'cardsList' => {'title': 'Keep going', 'image': _a, 't1': 'Morning breath', 's1': '5 min · Day 3', 'image2': _b, 't2': 'Healing words', 's2': '8 min · New', 'image3': _c, 't3': 'Deep rest', 's3': '15 min'},
      'cardsPricing' => {'title': 'Choose your plan', 't1': 'Monthly', 'p1': '₹199', 't2': 'Yearly', 'p2': '₹1,499', 't3': 'Lifetime', 'p3': '₹3,999', 'cta': 'Choose', 'route': 'tab:4'},
      'cardsProfile' => {'image': _d, 'title': 'Meera Rao', 'subtitle': 'Breath coach · 12 years', 'cta': 'Follow', 'route': 'tab:2'},
      'cardsOverlap' => {'title': 'Collections', 'subtitle': 'Hand-picked sets of practices', 'image': _g, 'image2': _h, 'image3': _e, 'cta': 'Open', 'route': 'tab:3'},
      'featureGrid' => {'title': 'Why people stay', 't1': 'Read aloud', 's1': 'Every word, spoken', 't2': 'Offline', 's2': 'Works anywhere', 't3': 'Daily', 's3': 'New each day', 't4': 'Private', 's4': 'Only for you'},
      'featureRow' => {'t1': 'Breathe', 't2': 'Listen', 't3': 'Rest'},
      'featureChecks' => {'title': 'What you get', 't1': 'Guided practices every day', 't2': 'Healing words with meanings', 't3': 'Sleep sounds and stories', 't4': 'No ads, ever'},
      'featureSteps' => {'title': 'How it works', 't1': 'Pick a feeling', 's1': 'Tell us how you are today', 't2': 'Press play', 's2': 'A short practice starts', 't3': 'Feel better', 's3': 'Come back tomorrow'},
      'featureLight' => {'title': 'Made for real life', 't1': 'Two minutes', 's1': 'Even on busy days', 't2': 'Any place', 's2': 'Bus, bed or break', 't3': 'Your pace', 's3': 'No streak pressure'},
      'quoteBig' => {'body': '“The words found me on the hardest week of my year.”', 'title': 'Anika, Pune'},
      'quoteCards' => {'b1': 'I sleep better than I have in years.', 'n1': 'Rahul', 'b2': 'Five minutes every morning changed my days.', 'n2': 'Sara'},
      'quoteAvatar' => {'image': _a, 'body': 'Calm, kind and beautifully made. I use it every day.', 'title': 'Priya S.', 'subtitle': 'Member since 2024'},
      'quoteLight' => {'body': 'Healing is not a race. It is a return.', 'title': 'NowssB'},
      'ctaGradient' => {'title': 'Start your free week', 'subtitle': 'Cancel any time', 'cta': 'Try free', 'route': 'tab:4'},
      'ctaDark' => {'title': 'Ready when you are', 'subtitle': 'One tap to your first practice', 'cta': 'Start', 'route': 'tab:1'},
      'ctaLight' => {'title': 'Share NowssB', 'subtitle': 'Give a friend a calm week', 'cta': 'Invite', 'route': 'tab:2'},
      'ctaTwo' => {'title': 'Pick how you want to begin', 'cta': 'Practise', 'cta2': 'Read', 'route': 'tab:1'},
      'ctaNewsletter' => {'title': 'A calm note each Sunday', 'subtitle': 'Short, kind and never spam', 'cta': 'Join the list', 'route': 'tab:2'},
      'ctaPicture' => {'image': _c, 'title': 'New: sleep sounds', 'subtitle': 'Rain, waves, forest', 'cta': 'Listen', 'route': 'tab:1'},
      'couponGold' => {'amount': '30%', 'title': 'OFF your first year', 'code': 'CALM30', 'subtitle': 'Valid till 31 Dec', 'route': 'tab:4'},
      'couponStub' => {'amount': '₹200', 'title': 'Off any course', 'code': 'HEAL200', 'subtitle': 'One use per person', 'route': 'tab:4'},
      'couponNeon' => {'amount': '50%', 'title': 'Weekend offer', 'code': 'GLOW50', 'route': 'tab:4'},
      'couponRound' => {'amount': '25', 'title': 'Percent off the store', 'code': 'STORE25', 'subtitle': 'Ends Sunday', 'route': 'tab:4'},
      'couponStrip' => {'amount': '₹99', 'title': 'First month', 'code': 'FIRST99', 'route': 'tab:4'},
      'couponPastel' => {'a1': '15%', 't1': 'Books', 'c1': 'READ15', 'a2': '20%', 't2': 'Courses', 'c2': 'LEARN20', 'route': 'tab:4'},
      'offerFlash' => {'eyebrow': 'FLASH SALE', 'title': 'Everything 40% off', 'subtitle': 'Today only · ends at midnight', 'cta': 'Shop now', 'route': 'tab:4'},
      'offerBundle' => {'title': 'Calm + Sleep bundle', 'image': _b, 'image2': _c, 'price': '₹499', 'subtitle': 'Save ₹300', 'cta': 'Get both', 'route': 'tab:4'},
      'offerPrice' => {'title': 'Premium, for a year', 'old': '₹2,399', 'price': '₹1,499', 'cta': 'Upgrade', 'route': 'tab:4', 'image': _e},
      'splitLeft' => {'image': _a, 'title': 'Words that listen', 'body': 'Each healing word comes with its meaning and a voice.', 'cta': 'Read', 'route': 'tab:3'},
      'splitRight' => {'image': _d, 'title': 'Rest is a practice', 'body': 'Short evening sessions to let the day go.', 'cta': 'Try one', 'route': 'tab:1'},
      'splitOverlap' => {'image': _f, 'title': 'Back to nature', 'body': 'Sounds recorded in forests and hills.', 'cta': 'Listen', 'route': 'tab:1'},
      'splitLight' => {'image': _g, 'eyebrow': 'GUIDE', 'title': 'A gentle start', 'body': 'Three minutes, one breath at a time.', 'cta': 'Begin', 'route': 'tab:1'},
      'statsRow' => {'n1': '40K', 'l1': 'members', 'n2': '1,200', 'l2': 'healing words', 'n3': '4.9 / 5', 'l3': 'rating'},
      'statsCards' => {'title': 'Your month', 'n1': '18', 'l1': 'days', 'n2': '214', 'l2': 'minutes', 'n3': '36', 'l3': 'words', 'n4': '7', 'l4': 'streak'},
      'statsProgress' => {'title': 'This week', 't1': 'Breath', 'v1': 0.8, 't2': 'Reading', 'v2': 0.55, 't3': 'Sleep', 'v3': 0.35},
      'statsBig' => {'title': '1,000,000', 'subtitle': 'minutes of calm, together', 'cta': 'Add yours', 'route': 'tab:1'},
      _ => motionStarter(kind),
    };
}

Widget buildMoreTemplate(String kind, TplKit k) {
  if (isFreshKind(kind)) return buildFreshTemplate(kind, k);
  if (isRailKind(kind)) return buildRailBanner(kind, k);
  if (kMotionKinds.contains(kind)) return buildMotionBanner(kind, k);
  final L = k.label;
  switch (kind) {
    // ── Top banners ──
    case 'heroCentered':
      return _pad(ClipRRect(
        borderRadius: BorderRadius.circular(k.corner),
        child: SizedBox(
          height: k.num_('height', 300),
          child: Stack(fit: StackFit.expand, children: [
            k.picture('image'),
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0xDD000000)]))),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (k.has('eyebrow')) L('eyebrow', _eyebrow(_gold), align: TextAlign.center),
                const SizedBox(height: 8),
                L('title', _h1(false, 28), maxLines: 3, align: TextAlign.center),
                const SizedBox(height: 8),
                L('subtitle', _p(false, 14), maxLines: 2, align: TextAlign.center),
                const SizedBox(height: 16),
                k.button(),
              ]),
            ),
          ]),
        ),
      ));
    case 'heroSideImage':
      return _pad(_card(
        k,
        padding: EdgeInsets.zero,
        bg: _navy,
        bg2: _ink,
        SizedBox(
          height: k.num_('height', 240),
          child: Row(children: [
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
                child: _fit(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  L('eyebrow', _eyebrow(_gold)),
                  const SizedBox(height: 8),
                  L('title', _h1(false, 25), maxLines: 3),
                  const SizedBox(height: 8),
                  L('subtitle', _p(false), maxLines: 2),
                  const SizedBox(height: 14),
                  k.button(),
                ])),
              ),
            ),
            Expanded(flex: 9, child: k.picture('image')),
          ]),
        ),
      ));
    case 'heroGlow':
      return _pad(Container(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(k.corner),
          boxShadow: k.shadow,
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.1,
            colors: [k.color('bg2', 0xFF5A4A22), k.color('bg', _navy)],
          ),
        ),
        child: Column(children: [
          const Icon(Icons.auto_awesome_rounded, color: _gold, size: 30),
          const SizedBox(height: 12),
          L('title', _h1(false, 32), maxLines: 2, align: TextAlign.center),
          const SizedBox(height: 10),
          L('subtitle', _p(false, 14.5), maxLines: 3, align: TextAlign.center),
          const SizedBox(height: 20),
          k.button(),
        ]),
      ));
    case 'heroCard':
      return _pad(_card(
        k,
        padding: const EdgeInsets.all(10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pic(k, 'image', aspect: 16 / 10, radius: k.corner - 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  L('title', _h2(false, 19), maxLines: 2),
                  const SizedBox(height: 4),
                  L('subtitle', _p(false), maxLines: 1),
                ]),
              ),
              const SizedBox(width: 10),
              k.button(),
            ]),
          ),
        ]),
      ));
    case 'heroLight':
      return _pad(_card(
        k,
        bg: _cream,
        padding: EdgeInsets.zero,
        SizedBox(
          height: k.num_('height', 230),
          child: Row(children: [
            Expanded(child: k.picture('image')),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _fit(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  L('eyebrow', _eyebrow(const Color(0xFFB07D1A))),
                  const SizedBox(height: 8),
                  L('title', _h1(true, 23), maxLines: 4),
                  const SizedBox(height: 14),
                  k.button(color: _dark),
                ])),
              ),
            ),
          ]),
        ),
      ));
    case 'heroBadge':
      return _pad(_card(
        k,
        bg: 0xFF1E1638,
        bg2: 0xFF0B1120,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: _gold.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(99), border: Border.all(color: _gold.withValues(alpha: 0.6))),
            child: L('badge', const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 14),
          L('title', _h1(false, 27), maxLines: 3),
          const SizedBox(height: 8),
          L('subtitle', _p(false), maxLines: 2),
          const SizedBox(height: 18),
          Row(children: [
            k.button(),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white54)),
              child: L('cta2', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ]),
        ]),
      ));
    // ── Cards ──
    case 'cardsGrid':
      Widget tile(String img, String t) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: Stack(fit: StackFit.expand, children: [
                k.picture(img),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xBB000000)]))),
                Positioned(left: 12, bottom: 10, right: 12, child: L(t, _h2(false, 15), maxLines: 1)),
              ]),
            ),
          );
      return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        L('title', _h2(false, 19)),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: tile('image', 't1')), const SizedBox(width: 10), Expanded(child: tile('image2', 't2'))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: tile('image3', 't3')), const SizedBox(width: 10), Expanded(child: tile('image4', 't4'))]),
      ]));
    case 'cardsTall':
      Widget tall(String img, String t) => Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 0.7,
                child: Stack(fit: StackFit.expand, children: [
                  k.picture(img),
                  const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.center, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC000000)]))),
                  Positioned(left: 14, right: 14, bottom: 14, child: L(t, _h2(false, 17), maxLines: 2)),
                ]),
              ),
            ),
          );
      return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        L('title', _h2(false, 19)),
        const SizedBox(height: 12),
        Row(children: [tall('image', 't1'), const SizedBox(width: 12), tall('image2', 't2')]),
      ]));
    case 'cardsList':
      Widget row(int i, String img) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _card(
              k,
              padding: const EdgeInsets.all(10),
              Row(children: [
                _pic(k, img, width: 64, height: 64, radius: 12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    L('t$i', _h2(false, 15.5), maxLines: 1),
                    const SizedBox(height: 4),
                    L('s$i', _p(false, 12.5), maxLines: 1),
                  ]),
                ),
                const Icon(Icons.play_circle_fill_rounded, color: _gold, size: 34),
              ]),
            ),
          );
      return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        L('title', _h2(false, 19)),
        row(1, 'image'),
        row(2, 'image2'),
        row(3, 'image3'),
      ]));
    case 'cardsPricing':
      Widget plan(int i, bool best) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: best ? _gold : const Color(0xFF1B2437),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: best ? _gold : Colors.white12),
              ),
              child: Column(children: [
                L('t$i', TextStyle(color: best ? _dark : Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700), maxLines: 1),
                const SizedBox(height: 8),
                FittedBox(child: L('p$i', TextStyle(color: best ? _dark : Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
                if (best) ...[const SizedBox(height: 6), _chip('BEST', _dark, _gold)],
              ]),
            ),
          );
      return _pad(Column(children: [
        L('title', _h2(false, 19), align: TextAlign.center),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          plan(1, false),
          const SizedBox(width: 8),
          plan(2, true),
          const SizedBox(width: 8),
          plan(3, false),
        ]),
        const SizedBox(height: 14),
        k.button(),
      ]));
    case 'cardsProfile':
      return _pad(_card(
        k,
        bg: _ink,
        bg2: 0xFF26324A,
        Row(children: [
          ClipOval(child: SizedBox(width: 76, height: 76, child: k.picture('image'))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(false, 18), maxLines: 1),
              const SizedBox(height: 4),
              L('subtitle', _p(false, 12.5), maxLines: 2),
              const SizedBox(height: 10),
              k.button(),
            ]),
          ),
        ]),
      ));
    case 'cardsOverlap':
      return _pad(_card(
        k,
        bg: 0xFF15233A,
        Row(children: [
          SizedBox(
            width: 150,
            height: 130,
            child: Stack(children: [
              Positioned(left: 0, top: 18, child: Transform.rotate(angle: -0.18, child: _pic(k, 'image3', width: 80, height: 100, radius: 12))),
              Positioned(left: 64, top: 18, child: Transform.rotate(angle: 0.18, child: _pic(k, 'image2', width: 80, height: 100, radius: 12))),
              Positioned(left: 32, top: 6, child: _pic(k, 'image', width: 84, height: 110, radius: 12)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(false, 18), maxLines: 2),
              const SizedBox(height: 6),
              L('subtitle', _p(false, 12.5), maxLines: 3),
              const SizedBox(height: 10),
              k.button(),
            ]),
          ),
        ]),
      ));
    // ── Features ──
    case 'featureGrid':
      const icons = [Icons.record_voice_over_rounded, Icons.cloud_off_rounded, Icons.wb_sunny_rounded, Icons.lock_rounded];
      const tints = [Color(0xFFE8D5A3), Color(0xFF7DD3FC), Color(0xFFFDBA74), Color(0xFFA78BFA)];
      Widget f(int i) => Expanded(
            child: _card(
              k,
              padding: const EdgeInsets.all(14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _icon(icons[i - 1], tints[i - 1]),
                const SizedBox(height: 10),
                L('t$i', _h2(false, 15), maxLines: 1),
                const SizedBox(height: 3),
                L('s$i', _p(false, 12), maxLines: 2),
              ]),
            ),
          );
      return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        L('title', _h2(false, 19)),
        const SizedBox(height: 12),
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [f(1), const SizedBox(width: 10), f(2)])),
        const SizedBox(height: 10),
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [f(3), const SizedBox(width: 10), f(4)])),
      ]));
    case 'featureRow':
      const icons = [Icons.air_rounded, Icons.headphones_rounded, Icons.bedtime_rounded];
      return _pad(_card(
        k,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        Row(children: [
          for (var i = 1; i <= 3; i++)
            Expanded(
              child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFE8D5A3), Color(0xFFB8955A)])),
                  child: Icon(icons[i - 1], color: _dark, size: 26),
                ),
                const SizedBox(height: 8),
                L('t$i', _h2(false, 14), maxLines: 1, align: TextAlign.center),
              ]),
            ),
        ]),
      ));
    case 'featureChecks':
      return _pad(_card(
        k,
        bg: _ink,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _h2(false, 19)),
          const SizedBox(height: 10),
          for (var i = 1; i <= 4; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 22),
                const SizedBox(width: 10),
                Expanded(child: L('t$i', _p(false, 14.5), maxLines: 2)),
              ]),
            ),
        ]),
      ));
    case 'featureSteps':
      return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        L('title', _h2(false, 19)),
        for (var i = 1; i <= 3; i++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2)),
                child: Text('$i', style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  L('t$i', _h2(false, 15.5), maxLines: 1),
                  const SizedBox(height: 2),
                  L('s$i', _p(false, 13), maxLines: 2),
                ]),
              ),
            ]),
          ),
      ]));
    case 'featureLight':
      const icons = [Icons.timer_rounded, Icons.place_rounded, Icons.spa_rounded];
      return _pad(_card(
        k,
        bg: _cream,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _h2(true, 19)),
          for (var i = 1; i <= 3; i++)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                _icon(icons[i - 1], const Color(0xFFB07D1A), bg: const Color(0xFFEDE3CC)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    L('t$i', _h2(true, 15), maxLines: 1),
                    L('s$i', _p(true, 12.5), maxLines: 1),
                  ]),
                ),
              ]),
            ),
        ]),
      ));
    // ── Reviews ──
    case 'quoteBig':
      return _pad(_card(
        k,
        bg: _navy,
        bg2: 0xFF1E2A44,
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('“', style: TextStyle(color: _gold, fontSize: 64, height: 1, fontWeight: FontWeight.w900)),
          L('body', const TextStyle(color: Colors.white, fontSize: 21, height: 1.3, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic), maxLines: 5),
          const SizedBox(height: 14),
          Row(children: [
            Container(width: 26, height: 2, color: _gold),
            const SizedBox(width: 10),
            L('title', const TextStyle(color: _gold, fontWeight: FontWeight.w700, fontSize: 13.5)),
          ]),
        ]),
      ));
    case 'quoteCards':
      Widget q(int i) => Expanded(
            child: _card(
              k,
              padding: const EdgeInsets.all(14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _stars(5, _gold),
                const SizedBox(height: 8),
                L('b$i', _p(false, 13.5), maxLines: 5),
                const SizedBox(height: 10),
                L('n$i', const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            ),
          );
      return _pad(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [q(1), const SizedBox(width: 10), q(2)])));
    case 'quoteAvatar':
      return _pad(_card(
        k,
        Column(children: [
          ClipOval(child: SizedBox(width: 64, height: 64, child: k.picture('image'))),
          const SizedBox(height: 10),
          _stars(5, _gold),
          const SizedBox(height: 10),
          L('body', _p(false, 15), maxLines: 4, align: TextAlign.center),
          const SizedBox(height: 10),
          L('title', _h2(false, 14.5), align: TextAlign.center),
          L('subtitle', _p(false, 12), align: TextAlign.center),
        ]),
      ));
    case 'quoteLight':
      return _pad(_card(
        k,
        bg: _cream,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 4, height: 70, decoration: BoxDecoration(color: const Color(0xFFB07D1A), borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('body', const TextStyle(color: _dark, fontSize: 20, height: 1.3, fontWeight: FontWeight.w700), maxLines: 4),
              const SizedBox(height: 10),
              L('title', const TextStyle(color: Color(0xFFB07D1A), fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ),
        ]),
      ));
    // ── Buttons & banners ──
    case 'ctaGradient':
      return _pad(_card(
        k,
        bg: 0xFF7C3AED,
        bg2: 0xFFEC4899,
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(false, 20), maxLines: 2),
              const SizedBox(height: 4),
              L('subtitle', const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13), maxLines: 1),
            ]),
          ),
          const SizedBox(width: 12),
          k.button(light: true),
        ]),
      ));
    case 'ctaDark':
      return _pad(Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: k.color('bg', _navy),
          borderRadius: BorderRadius.circular(k.corner),
          border: Border.all(color: _gold.withValues(alpha: 0.7), width: 1.5),
          boxShadow: k.shadow,
        ),
        child: Column(children: [
          L('title', _h2(false, 21), align: TextAlign.center, maxLines: 2),
          const SizedBox(height: 6),
          L('subtitle', _p(false), align: TextAlign.center, maxLines: 2),
          const SizedBox(height: 16),
          k.button(),
        ]),
      ));
    case 'ctaLight':
      return _pad(_card(
        k,
        bg: _cream,
        Row(children: [
          _icon(Icons.card_giftcard_rounded, const Color(0xFFB07D1A), bg: const Color(0xFFEDE3CC)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(true, 17), maxLines: 1),
              L('subtitle', _p(true, 12.5), maxLines: 2),
            ]),
          ),
          const SizedBox(width: 8),
          k.button(color: _dark),
        ]),
      ));
    case 'ctaTwo':
      return _pad(Column(children: [
        L('title', _h2(false, 18), align: TextAlign.center, maxLines: 2),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          k.button(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: _gold)),
            child: L('cta2', const TextStyle(color: _gold, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ]),
      ]));
    case 'ctaNewsletter':
      return _pad(_card(
        k,
        bg: 0xFF0F2A2A,
        bg2: 0xFF0B1120,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.mail_rounded, color: Color(0xFF5EEAD4), size: 28),
          const SizedBox(height: 10),
          L('title', _h2(false, 19), maxLines: 2),
          const SizedBox(height: 4),
          L('subtitle', _p(false), maxLines: 2),
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: 16, right: 4),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(99)),
            child: Row(children: [
              const Expanded(child: Text('your@email.com', style: TextStyle(color: Colors.white38, fontSize: 14))),
              k.button(),
            ]),
          ),
        ]),
      ));
    case 'ctaPicture':
      return _pad(_card(
        k,
        padding: const EdgeInsets.all(12),
        Row(children: [
          _pic(k, 'image', width: 84, height: 84, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(false, 16), maxLines: 2),
              const SizedBox(height: 3),
              L('subtitle', _p(false, 12.5), maxLines: 1),
            ]),
          ),
          k.button(),
        ]),
      ));
    // ── Offers & coupons ──
    case 'couponGold':
      return _pad(ClipPath(
        clipper: _TicketClip(at: 0.68, vertical: true, radius: k.corner),
        child: Container(
          height: 130,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF3E2B0), Color(0xFFC9A45C)])),
          child: Row(children: [
            Expanded(
              flex: 68,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  FittedBox(child: L('amount', const TextStyle(color: _dark, fontSize: 42, fontWeight: FontWeight.w900, height: 1))),
                  L('title', const TextStyle(color: _dark, fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1),
                  const SizedBox(height: 4),
                  L('subtitle', const TextStyle(color: Color(0xAA14161C), fontSize: 11.5), maxLines: 1),
                ]),
              ),
            ),
            const SizedBox(width: 2, child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: _Dashes(color: Color(0x6614161C), vertical: true))),
            Expanded(
              flex: 32,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('CODE', style: TextStyle(color: Color(0xAA14161C), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                FittedBox(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: L('code', const TextStyle(color: _dark, fontSize: 16, fontWeight: FontWeight.w900)))),
              ]),
            ),
          ]),
        ),
      ));
    case 'couponStub':
      return _pad(ClipPath(
        clipper: _TicketClip(at: 0.72, radius: k.corner),
        child: Container(
          color: Colors.white,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(child: L('amount', const TextStyle(color: Color(0xFFDC2626), fontSize: 40, fontWeight: FontWeight.w900, height: 1))),
                    const SizedBox(height: 4),
                    L('title', _h2(true, 15), maxLines: 1),
                    L('subtitle', _p(true, 12), maxLines: 1),
                  ]),
                ),
                const Icon(Icons.local_offer_rounded, color: Color(0xFFDC2626), size: 40),
              ]),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(height: 2, child: _Dashes(color: Color(0x33000000)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Row(children: [
                const Text('Use code ', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                L('code', const TextStyle(color: _dark, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ]),
            ),
          ]),
        ),
      ));
    case 'couponNeon':
      return _pad(Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1F),
          borderRadius: BorderRadius.circular(k.corner),
          border: Border.all(color: const Color(0xFF22D3EE), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x8822D3EE), blurRadius: 18)],
        ),
        child: Row(children: [
          FittedBox(child: L('amount', const TextStyle(color: Color(0xFF22D3EE), fontSize: 44, fontWeight: FontWeight.w900, height: 1, shadows: [Shadow(color: Color(0xFF22D3EE), blurRadius: 14)]))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(false, 16), maxLines: 1),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF0ABFC))),
                child: L('code', const TextStyle(color: Color(0xFFF0ABFC), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
              ),
            ]),
          ),
        ]),
      ));
    case 'couponRound':
      return _pad(_card(
        k,
        bg: 0xFFFFF7ED,
        Row(children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF97316)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              L('amount', const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
              const Text('% OFF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(true, 16), maxLines: 2),
              L('subtitle', _p(true, 12), maxLines: 1),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF97316), width: 1.5)),
                child: L('code', const TextStyle(color: Color(0xFFC2410C), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ]),
          ),
        ]),
      ));
    case 'couponStrip':
      return _pad(ClipPath(
        clipper: _TicketClip(at: 0.3, vertical: true, r: 9, radius: k.corner),
        child: Container(
          height: 72,
          color: const Color(0xFF1F2937),
          child: Row(children: [
            Expanded(
              flex: 30,
              child: Container(
                color: const Color(0xFF34D399),
                alignment: Alignment.center,
                child: FittedBox(child: Padding(padding: const EdgeInsets.all(6), child: L('amount', const TextStyle(color: _dark, fontSize: 24, fontWeight: FontWeight.w900)))),
              ),
            ),
            Expanded(
              flex: 70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: L('title', _h2(false, 15), maxLines: 1)),
                  L('code', const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ]),
              ),
            ),
          ]),
        ),
      ));
    case 'couponPastel':
      Widget one(int i, Color bg, Color fg) => Expanded(
            child: ClipPath(
              clipper: _TicketClip(at: 0.62, r: 10, radius: k.corner),
              child: Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FittedBox(child: L('a$i', TextStyle(color: fg, fontSize: 32, fontWeight: FontWeight.w900, height: 1))),
                  L('t$i', _h2(true, 14), maxLines: 1),
                  const SizedBox(height: 16),
                  L('c$i', TextStyle(color: fg, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
                ]),
              ),
            ),
          );
      return _pad(Row(children: [
        one(1, const Color(0xFFFCE7F3), const Color(0xFFBE185D)),
        const SizedBox(width: 10),
        one(2, const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
      ]));
    case 'offerFlash':
      return _pad(_card(
        k,
        bg: 0xFFB91C1C,
        bg2: 0xFF7F1D1D,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 22),
            const SizedBox(width: 4),
            L('eyebrow', _eyebrow(const Color(0xFFFDE047))),
          ]),
          const SizedBox(height: 8),
          L('title', _h1(false, 26), maxLines: 2),
          const SizedBox(height: 6),
          L('subtitle', const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13), maxLines: 1),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(value: 0.7, minHeight: 6, color: Color(0xFFFDE047), backgroundColor: Color(0x33FFFFFF)),
          ),
          const SizedBox(height: 14),
          k.button(light: true),
        ]),
      ));
    case 'offerBundle':
      return _pad(_card(
        k,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _h2(false, 18), maxLines: 1),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _pic(k, 'image', aspect: 1.2, radius: 14)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.add_circle_rounded, color: _gold, size: 28)),
            Expanded(child: _pic(k, 'image2', aspect: 1.2, radius: 14)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            L('price', const TextStyle(color: _gold, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            Expanded(child: L('subtitle', const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1)),
            k.button(),
          ]),
        ]),
      ));
    case 'offerPrice':
      return _pad(_card(
        k,
        padding: const EdgeInsets.all(12),
        Row(children: [
          _pic(k, 'image', width: 100, height: 110, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('title', _h2(false, 16), maxLines: 2),
              const SizedBox(height: 6),
              L('old', const TextStyle(color: Colors.white54, fontSize: 13, decoration: TextDecoration.lineThrough)),
              L('price', const TextStyle(color: _gold, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              k.button(),
            ]),
          ),
        ]),
      ));
    // ── Picture + words ──
    case 'splitLeft' || 'splitRight':
      final pic = Expanded(child: _pic(k, 'image', aspect: 0.85, radius: 18));
      final words = Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: kind == 'splitLeft' ? 14 : 0, right: kind == 'splitLeft' ? 0 : 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            L('title', _h2(false, 19), maxLines: 3),
            const SizedBox(height: 6),
            L('body', _p(false), maxLines: 4),
            const SizedBox(height: 12),
            k.button(),
          ]),
        ),
      );
      return _pad(Row(children: kind == 'splitLeft' ? [pic, words] : [words, pic]));
    case 'splitOverlap':
      return _pad(Column(children: [
        _pic(k, 'image', aspect: 16 / 9, radius: k.corner),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _card(
              k,
              bg: 0xF21B2437,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                L('title', _h2(false, 18), maxLines: 2),
                const SizedBox(height: 4),
                L('body', _p(false, 13), maxLines: 2),
                const SizedBox(height: 10),
                k.button(),
              ]),
            ),
          ),
        ),
      ]));
    case 'splitLight':
      return _pad(_card(
        k,
        bg: _cream,
        padding: const EdgeInsets.all(12),
        Row(children: [
          Expanded(child: _pic(k, 'image', aspect: 0.9, radius: 14)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              L('eyebrow', _eyebrow(const Color(0xFFB07D1A))),
              const SizedBox(height: 6),
              L('title', _h2(true, 18), maxLines: 2),
              const SizedBox(height: 6),
              L('body', _p(true, 13), maxLines: 3),
              const SizedBox(height: 10),
              k.button(color: _dark),
            ]),
          ),
        ]),
      ));
    // ── Numbers ──
    case 'statsRow':
      return _pad(_card(
        k,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
        Row(children: [
          for (var i = 1; i <= 3; i++) ...[
            if (i > 1) Container(width: 1, height: 40, color: Colors.white12),
            Expanded(
              child: Column(children: [
                FittedBox(child: L('n$i', const TextStyle(color: _gold, fontSize: 26, fontWeight: FontWeight.w900))),
                L('l$i', _p(false, 12), maxLines: 1, align: TextAlign.center),
              ]),
            ),
          ],
        ]),
      ));
    case 'statsCards':
      const tints = [Color(0xFFE8D5A3), Color(0xFF7DD3FC), Color(0xFF34D399), Color(0xFFFDBA74)];
      Widget s(int i) => Expanded(
            child: _card(
              k,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              Column(children: [
                FittedBox(child: L('n$i', TextStyle(color: tints[i - 1], fontSize: 24, fontWeight: FontWeight.w900))),
                L('l$i', _p(false, 11.5), maxLines: 1, align: TextAlign.center),
              ]),
            ),
          );
      return _pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        L('title', _h2(false, 19)),
        const SizedBox(height: 12),
        Row(children: [s(1), const SizedBox(width: 8), s(2), const SizedBox(width: 8), s(3), const SizedBox(width: 8), s(4)]),
      ]));
    case 'statsProgress':
      const tints = [Color(0xFFE8D5A3), Color(0xFF7DD3FC), Color(0xFFA78BFA)];
      return _pad(_card(
        k,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          L('title', _h2(false, 18)),
          for (var i = 1; i <= 3; i++) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: L('t$i', _p(false, 13.5), maxLines: 1)),
              Text('${(k.num_('v$i', 0.5).clamp(0.0, 1.0) * 100).round()}%', style: TextStyle(color: tints[i - 1], fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: k.num_('v$i', 0.5).clamp(0.0, 1.0), minHeight: 8, color: tints[i - 1], backgroundColor: Colors.white10),
            ),
          ],
        ]),
      ));
    case 'statsBig':
      return _pad(_card(
        k,
        bg: _navy,
        bg2: 0xFF2A2214,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
        Column(children: [
          FittedBox(child: L('title', const TextStyle(color: _gold, fontSize: 48, fontWeight: FontWeight.w900, height: 1))),
          const SizedBox(height: 8),
          L('subtitle', _p(false, 15), align: TextAlign.center, maxLines: 2),
          const SizedBox(height: 16),
          k.button(),
        ]),
      ));
  }
  return const SizedBox.shrink();
}

/// Is [bg] a light card (dark words)? For callers that recolour.
bool moreIsLight(int bg) => _isLight(bg);
