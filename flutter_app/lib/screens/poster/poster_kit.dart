/// POSTER language kit — the shared vocabulary of the Drop Studio pieces Ribon
/// loved (word-poster + drop-flow): giant Anton poster type, real NowssB cut-outs,
/// black meaning tags, gold pills, torn photo tiles.
///
/// Only primitives live here. Every page composes them its OWN way
/// (see BUILDER-HANDOFF → POSTER PAGES); no page copies another's layout.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/template/editable.dart';
import '../../widgets/concept/stillwater.dart';
import '../../data/store_prices.dart';
import '../../data/entitlements.dart';
import '../../features/economy/money.dart';
import '../../features/economy/play_billing.dart';

/// The live store price for a word (admin default / Deal of the Day applied).
num wordPrice(String word) => StorePrices.instance.priceFor('word:${word.toLowerCase()}');

/// Store prices are rupees (config/store, Google Play INR points). Every
/// poster price goes through the app's region money path: Play's own
/// localized price when it is cached for [sku], else FxBook (₹ for India).
/// Whole amounts print without decimals (₹99); paise show only when the
/// price really has them (a Play label like ₹99.50 is kept as sent).
String inr(num v, {String? sku}) {
  if (v <= 0) return 'Included';
  final play = sku == null ? null : PlayCheckout.cachedPrice(sku);
  return play != null ? FxBook.wholeLabel(play) : FxBook.instance.formatPrice(v, whole: true);
}

/// Price label for a bag item id (word:/signature:/meaning:/ebook:) or null
/// when it is already owned or in the user's plan — then NO price shows.
String? priceOrNull(String itemId, num price) => Entitlements.instance.ownsOrIncluded(itemId, price: price) ? null : inr(price, sku: itemId);

/// What to print instead of a price for an owned / included item.
String ownedLabel(String itemId) => Entitlements.instance.ownsItem(itemId) ? 'Owned' : 'In your plan';

/// Price text, or the owned / in-plan label.
String priceText(String itemId, num price) => priceOrNull(itemId, price) ?? ownedLabel(itemId);

const kPGold = Color(0xFFC8A96E);
const kPGoldSoft = Color(0xFFE8D5A3);
const kPViolet = Color(0xFF7C4DDB);
const kPDeep = Color(0xFF060C18);
const kPInk = Color(0xFF14101C);
const kPPaper = Color(0xFFF1EADB);
const kPPlum = Color(0xFF241638);

/// The real cut-outs and photos (all bundled; admin can override per slot).
class PosterAssets {
  static const cleopatra = 'assets/hero-curve/cleopatra.webp';
  static const pointer = 'assets/hero-curve/pointer.webp';
  static const redhead = 'assets/hero-curve/subject.webp';
  static const blonde = 'assets/hero-curve/tab-subject.webp';
  static const listen = 'assets/hero-curve/listen.webp';

  // Bundled photos only (assets/rails/store/* is NOT in pubspec's bundle).
  static const _photos = [
    // TEXT-FREE stills only (Hunter: never reuse posters with printed words).
    'assets/hero-curve/tab-forest.webp', 'assets/hero-curve/tab-rain.webp', 'assets/hero-curve/tab-beach.webp',
    'assets/hero-curve/tab-desert.webp', 'assets/hero-curve/tab-window.webp', 'assets/hero-curve/listen.webp',
    'assets/hero-curve/tab-stool.webp',
  ];
  static const _named = {
    'word': 'assets/hero-curve/tab-desert.webp',
    'ebooks': 'assets/hero-curve/tab-window.webp',
  };

  /// A real bundled photo for a catalogue category id / page (stable per id;
  /// [index] spreads a list of categories across distinct photos).
  static String rail(String id, [int? index]) => _named[id] ?? _photos[(index ?? id.codeUnits.fold<int>(0, (a, c) => a + c)) % _photos.length];
}

TextStyle anton(double size, {Color color = kPInk, FontWeight w = FontWeight.w700, double height = .86, bool italic = false, double ls = -1}) => TextStyle(
      // Ribon 2:13 AM: poster words are Anton (condensed sans) — no serif anywhere.
      fontFamily: 'Anton',
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: height < 1 ? 1.0 : height,
      letterSpacing: ls * .25,
      color: color,
      fontStyle: FontStyle.normal, // Ribon: never italic display type
    );

/// GREETING TYPE — every non-poster text copies NmGreeting (normal home):
/// 'Good Evening' 19/w300 soft grey, 'Healer' 26/w800 h1.1 ink, subline
/// 12.5/w400 faint grey. Same DM Sans theme font. `dark` = on a dark ground
/// (light tints, AA contrast); otherwise on paper/gold (opaque ink tints).
TextStyle gHello({bool dark = true, Color? color}) => TextStyle(
    fontSize: 19, fontWeight: FontWeight.w300, fontFamilyFallback: kPieFallback, color: color ?? (dark ? const Color(0xFFC9C5D3) : const Color(0xFF4E4A57)));
TextStyle gTitle({bool dark = true, Color? color}) => TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800, height: 1.1, fontFamilyFallback: kPieFallback, color: color ?? (dark ? Colors.white : const Color(0xFF1A1A2E)));
TextStyle gSub({bool dark = true, Color? color}) => TextStyle(
    fontSize: 12.5, fontWeight: FontWeight.w400, fontFamilyFallback: kPieFallback, color: color ?? (dark ? const Color(0xFFB9B4C6) : const Color(0xFF4A4652)));

/// DM Sans lacks PIE glyphs (₂ ḗ ʰ ̥ ǣ ǵ): fall back to bundled Noto Sans.
const kPieFallback = ['NotoSansPIE'];

/// Kept for call sites: the greeting subline.
final kSans = gSub();

/// Page frame: deep violet liquid backdrop, scroll body, frosted top bar,
/// optional pinned dock with a fade behind it (content never sits under it).
class PosterScaffold extends StatefulWidget {
  const PosterScaffold({
    super.key,
    required this.slot,
    required this.kicker,
    required this.children,
    this.onBack,
    this.onOpenStores,
    this.onOpenBag,
    this.dock,
    this.controller,
    this.tint = kPViolet,
  });
  final String slot;
  final String kicker;
  final List<Widget> children;
  final VoidCallback? onBack, onOpenStores, onOpenBag;
  final Widget? dock;
  final ScrollController? controller;
  final Color tint;
  @override
  State<PosterScaffold> createState() => _PosterScaffoldState();
}

class _PosterScaffoldState extends State<PosterScaffold> {
  late final ScrollController _c = widget.controller ?? ScrollController();
  double _y = 0;
  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() => _y = _c.offset));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _c.hasClients) setState(() => _y = _c.offset);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final dockH = widget.dock == null ? 0.0 : 68 + 22 + mq.padding.bottom;
    return Scaffold(
      backgroundColor: kPDeep,
      body: Stack(children: [
        Positioned.fill(
          child: Breath(
            builder: (_, ph) => CustomPaint(painter: _Liquid(ph, widget.tint, _y)),
          ),
        ),
        ListView(
          controller: _c,
          padding: EdgeInsets.only(bottom: dockH + 36),
          children: [
            // an invisible twin of the top bar reserves EXACTLY its height
            // (it grows when the kicker wraps at 320 / large text)
            ExcludeSemantics(child: IgnorePointer(child: Opacity(opacity: 0, child: _TopBar(widget: widget, frost: 0)))),
            const SizedBox(height: 14),
            ...widget.children,
          ],
        ),
        Positioned(left: 0, right: 0, top: 0, child: _TopBar(widget: widget, frost: (_y / 120).clamp(0.0, 1.0))),
        if (widget.dock != null) ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: dockH + 70,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00060C18), Color(0xEB060C18), kPDeep],
                    stops: [0, .55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 16, right: 16, bottom: 22 + mq.padding.bottom, child: widget.dock!),
        ],
      ]),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.widget, required this.frost});
  final PosterScaffold widget;
  final double frost;
  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context).top;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18 * frost, sigmaY: 18 * frost),
        child: Container(
          padding: EdgeInsets.fromLTRB(14, pad + 10, 14, 10),
          color: Color.lerp(const Color(0x00060C18), const Color(0xCC0B0816), frost),
          child: Row(children: [
            RoundIcon(icon: Icons.arrow_back_rounded, label: 'Back', onTap: widget.onBack),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                // Three round icons leave little room at 320@1.3: shrink, never clip.
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('NowssB', maxLines: 1, style: gTitle())),
                EditableLabel(widget.slot, widget.kicker.toUpperCase(), id: 'kicker', maxLines: 3, style: gSub(color: kPGoldSoft)),
              ]),
            ),
            if (widget.onOpenStores != null) ...[
              RoundIcon(icon: Icons.storefront_outlined, label: 'All stores', onTap: widget.onOpenStores),
              const SizedBox(width: 8),
            ],
            RoundIcon(icon: Icons.shopping_bag_outlined, label: 'Bag', onTap: widget.onOpenBag),
          ]),
        ),
      ),
    );
  }
}

class RoundIcon extends StatelessWidget {
  const RoundIcon({super.key, required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Tap(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1FFFFFFF),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      );
}

/// Press = scale .96 + light haptic. Every tappable piece uses this.
class Tap extends StatefulWidget {
  const Tap({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(scale: _down ? .96 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
      );
}

class _Liquid extends CustomPainter {
  _Liquid(this.ph, this.tint, this.y);
  final double ph, y;
  final Color tint;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = kPDeep);
    final a = ph * math.pi * 2;
    void blob(double x, double yy, double r, Color col) {
      final o = Offset(x * s.width, yy * s.height - y * .08);
      c.drawCircle(o, r, Paint()..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)));
    }

    blob(.85 + .05 * math.sin(a), .22, s.width * .9, tint.withValues(alpha: .42));
    blob(.1, .62 + .03 * math.cos(a), s.width * .8, kPPlum.withValues(alpha: .9));
    blob(.7, 1.0, s.width * .7, tint.withValues(alpha: .28));
    blob(.2 + .04 * math.cos(a), .05, s.width * .45, kPGold.withValues(alpha: .10));
  }

  @override
  bool shouldRepaint(_Liquid o) => o.ph != ph || o.y != y;
}

/// Section kicker: "—— HOW THE DROP FLOWS".
class Kicker extends StatelessWidget {
  const Kicker(this.slot, this.text, {super.key, this.pad = const EdgeInsets.fromLTRB(20, 30, 20, 14)});
  final String slot, text;
  final EdgeInsets pad;
  @override
  Widget build(BuildContext context) => Padding(
        padding: pad,
        child: Row(children: [
          Container(width: 22, height: 1.4, color: kPGold),
          const SizedBox(width: 10),
          Expanded(child: EditableLabel(slot, text, maxLines: 2, style: gHello())),
        ]),
      );
}

/// Black meaning strip (white type, 15.7:1).
class InkTag extends StatelessWidget {
  const InkTag(this.text, {super.key, this.size = 14.5, this.maxLines = 4});
  final String text;
  final double size;
  final int maxLines;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        color: const Color(0xF20A0A0D),
        child: Text(text, maxLines: maxLines, style: gSub(color: Colors.white).copyWith(height: 1.3)),
      );
}

/// Gold sticker label (ink type on gold, 8.9:1).
class GoldTag extends StatelessWidget {
  const GoldTag(this.text, {super.key, this.size = 10.5});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        color: kPGold,
        child: Text(text, style: gSub(color: kPInk)),
      );
}

/// The gold "Own this word" pill — ink on gold, white rim, soft drop.
class GoldPill extends StatelessWidget {
  const GoldPill({super.key, required this.label, required this.onTap, this.arrow = false, this.dark = false});
  final String label;
  final VoidCallback? onTap;
  final bool arrow, dark;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Tap(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: dark ? kPInk : kPGold,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: dark ? kPGold : Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(label, style: gHello(color: dark ? kPGoldSoft : kPInk)),
              ),
              if (arrow) ...[const SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 18, color: dark ? kPGoldSoft : kPInk)],
            ]),
          ),
        ),
      );
}

/// A real NowssB cut-out (transparent webp), admin-editable.
class Cutout extends StatelessWidget {
  const Cutout(this.asset, {super.key, required this.slot, required this.id, this.flip = false, this.fadeBottom = 0, this.align = Alignment.bottomCenter});
  final String asset, slot, id;
  final bool flip;
  final double fadeBottom;
  final Alignment align;
  @override
  Widget build(BuildContext context) {
    Widget img = EditableImage.asset(asset, slot: slot, id: id, fit: BoxFit.contain, alignment: align);
    if (flip) img = Transform.flip(flipX: true, child: img);
    if (fadeBottom > 0) {
      img = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
          stops: [0, 1 - fadeBottom, 1],
        ).createShader(r),
        child: img,
      );
    }
    return IgnorePointer(child: img);
  }
}

/// Torn paper edge (top jagged small, bottom ragged deeper).
class TornClipper extends CustomClipper<Path> {
  const TornClipper(this.seed, {this.depth = 1});
  final int seed;
  final double depth;
  @override
  Path getClip(Size s) {
    final r = math.Random(seed);
    final p = Path()..moveTo(0, r.nextDouble() * 5 * depth);
    for (var x = 0.0; x < s.width; x += 13) {
      p.lineTo(x, r.nextDouble() * 6 * depth);
    }
    p.lineTo(s.width, 0);
    for (var y = 0.0; y < s.height; y += 15) {
      p.lineTo(s.width - r.nextDouble() * 5 * depth, y);
    }
    p.lineTo(s.width, s.height);
    for (var x = s.width; x > 0; x -= 11) {
      p.lineTo(x, s.height - r.nextDouble() * 9 * depth);
    }
    p.lineTo(0, s.height);
    for (var y = s.height; y > 0; y -= 17) {
      p.lineTo(r.nextDouble() * 4 * depth, y);
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(TornClipper o) => o.seed != seed;
}

/// Giant Anton poster word that always fits its box width (never overflows at any
/// text scale): scales DOWN only, cropped at the right edge if [bleed].
class GiantWord extends StatelessWidget {
  const GiantWord(this.text, {super.key, required this.style, this.bleed = false, this.align = Alignment.centerLeft, this.outline});
  final String text;
  final TextStyle style;
  final bool bleed;
  final Alignment align;
  final Color? outline;
  @override
  Widget build(BuildContext context) {
    final s = outline == null
        ? style
        : style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = outline!,
            color: null);
    final t = Text(text, maxLines: 1, softWrap: false, textScaler: TextScaler.noScaling, style: s);
    if (bleed) {
      return ClipRect(child: OverflowBox(alignment: align, maxWidth: double.infinity, child: t));
    }
    return FittedBox(fit: BoxFit.scaleDown, alignment: align, child: t);
  }
}

/// Breath-driven gentle sway: rotates [base] ± [amp] rad and bobs [bob] px.
class Sway extends StatelessWidget {
  const Sway({super.key, required this.child, this.base = 0, this.amp = .012, this.bob = 3, this.offset = 0});
  final Widget child;
  final double base, amp, bob, offset;
  @override
  Widget build(BuildContext context) => Breath(builder: (_, ph) {
        final l = Stillwater.lungs((ph + offset) % 1);
        return Transform.translate(
          offset: Offset(0, -bob * l),
          child: Transform.rotate(angle: base + amp * (l - .5) * 2, child: child),
        );
      });
}

/// Photo filling its box (cover), admin-editable.
class Photo extends StatelessWidget {
  const Photo(this.asset, {super.key, required this.slot, required this.id, this.align = Alignment.center});
  final String asset, slot, id;
  final Alignment align;
  @override
  Widget build(BuildContext context) => EditableImage.asset(asset, slot: slot, id: id, fit: BoxFit.cover, alignment: align);
}
