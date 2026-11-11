/// The Programmes row above the programme cards: four separate glass cards
/// that rotate on their own, sideways.
///
/// Each card is the same glass tile the Zen home has always used for its
/// programme doors: its OWN [GlassWrap], a tall portrait photo on the left
/// and two smaller rounded photo tiles beside it, 8 px of glass around them,
/// 176 px of picture. Same wrapper, same size, same height on every card.
///
/// It moves every 5 s over 600 ms (easeInOutCubic), holds while a finger is
/// on it and carries on 5 s after the finger lifts. Reduced motion: it stays
/// where it is.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/coins/coins_screen.dart';
import '../features/programs/program_router.dart';
import '../screens/subscription.dart';
import '../theme/tokens.dart';
import 'glass_wrap.dart';
import 'word_fit_text.dart';

bool get _kTest => WidgetsBinding.instance.runtimeType.toString().contains('Test');

/// Where "Coins" opens, shared with the cards below.
void openCoinsPage(BuildContext c) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const CoinsScreen()));

void _openPlans(BuildContext c) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));

class _Tile {
  const _Tile(this.art, this.label, this.open, {this.id = ''});
  final String art;
  final String label;
  final void Function(BuildContext) open;
  final String id;
}

class _Card {
  const _Card(this.id, this.tall, this.a, this.b);
  final String id;
  final _Tile tall;
  final _Tile a;
  final _Tile b;
}

// Dark, quiet, people-free meditation stills (assets/rails/subj-*), none of
// them used anywhere else on the home.
final _cards = <_Card>[
  _Card(
    'earn',
    _Tile('assets/rails/subj-dawn.jpg', 'Earn coins', (c) => Programmes.open(c, Programme.earn)),
    _Tile('assets/rails/subj-soul.jpg', 'Daily coins', (c) => Programmes.open(c, Programme.earn)),
    _Tile('assets/rails/subj-forest.jpg', 'Bonuses', (c) => Programmes.open(c, Programme.earn, tab: 'targets')),
  ),
  _Card(
    'reference',
    _Tile('assets/rails/subj-harmony.jpg', 'Reference', (c) => Programmes.open(c, Programme.reference)),
    _Tile('assets/rails/subj-river.jpg', 'Your links', (c) => Programmes.open(c, Programme.reference)),
    _Tile('assets/rails/subj-star.jpg', 'Invite friends', (c) => Programmes.open(c, Programme.reference)),
  ),
  _Card(
    'coins',
    _Tile('assets/rails/subj-calm.jpg', 'Coins', openCoinsPage),
    _Tile('assets/rails/subj-moon.jpg', 'Your wallet', openCoinsPage),
    _Tile('assets/rails/subj-prayer.jpg', 'Earned today', openCoinsPage),
  ),
  _Card(
    'plus',
    _Tile('assets/rails/subj-grace.jpg', 'Zen Plus', _openPlans),
    _Tile('assets/rails/subj-love.jpg', 'Full library', _openPlans),
    _Tile('assets/rails/subj-ocean.jpg', 'Go deeper', _openPlans),
  ),
];

/// Every picture the row uses (for the "no repeats" test).
List<String> get glassTileRowArt => [
      for (final c in _cards) ...[c.tall.art, c.a.art, c.b.art],
    ];

class GlassTileRow extends StatefulWidget {
  const GlassTileRow({super.key, this.onOpen});

  /// Tests: let the timer run (it stands still under the test binding).
  static bool debugLive = false;

  /// Tests / shots: start on this card.
  static int? debugPage;

  /// Tests: called instead of opening a page, with `card:tile` ids.
  final void Function(String id)? onOpen;

  static const rotate = Duration(seconds: 5);
  static const glide = Duration(milliseconds: 600);

  /// Picture height inside the glass (the old reference tile's 176).
  static const photo = 176.0;

  @override
  State<GlassTileRow> createState() => _GlassTileRowState();
}

class _GlassTileRowState extends State<GlassTileRow> {
  static final _base = 1000 * _cards.length;
  late final PageController _pager = PageController(initialPage: _base + (GlassTileRow.debugPage ?? 0));
  Timer? _timer;
  late int _index = GlassTileRow.debugPage ?? 0;
  bool _still = false;

  bool get _frozen => _kTest && !GlassTileRow.debugLive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still || _frozen) {
      _timer?.cancel();
    } else if (_timer == null) {
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pager.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted || _still || _frozen) return;
    _timer = Timer(GlassTileRow.rotate, _advance);
  }

  Future<void> _advance() async {
    if (!mounted || !_pager.hasClients) return;
    await _pager.animateToPage((_pager.page ?? _base.toDouble()).round() + 1,
        duration: GlassTileRow.glide, curve: Curves.easeInOutCubic);
    _schedule();
  }

  void _hold() => _timer?.cancel();

  @override
  Widget build(BuildContext context) {
    const h = GlassTileRow.photo + 16 + 2 + 16; // picture, padding, hairline, margin
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: h,
        child: Listener(
          onPointerDown: (_) => _hold(),
          onPointerUp: (_) => _schedule(),
          onPointerCancel: (_) => _schedule(),
          child: PageView.builder(
            key: const ValueKey('prog-tile-pager'),
            controller: _pager,
            onPageChanged: (i) => setState(() => _index = i % _cards.length),
            itemBuilder: (context, abs) => _CardView(card: _cards[abs % _cards.length], onOpen: widget.onOpen),
          ),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < _cards.length; i++)
          AnimatedContainer(
            key: ValueKey('prog-dot-$i'),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == _index ? 18 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: i == _index ? NwsbColors.goldLight : const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ]),
    ]);
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card, this.onOpen});
  final _Card card;
  final void Function(String id)? onOpen;

  void _tap(BuildContext context, _Tile t, String slot) {
    HapticFeedback.selectionClick();
    if (onOpen != null) {
      onOpen!('${card.id}:$slot');
    } else {
      t.open(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: GlassTileRow.photo,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          GestureDetector(
            key: ValueKey('prog-tile-${card.id}:tall'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tap(context, card.tall, 'tall'),
            child: _Photo(tile: card.tall, width: 112, height: GlassTileRow.photo, big: true),
          ),
          const SizedBox(width: 8),
          for (final (i, t) in [(0, card.a), (1, card.b)]) ...[
            if (i == 1) const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                key: ValueKey('prog-tile-${card.id}:${i == 0 ? 'a' : 'b'}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _tap(context, t, i == 0 ? 'a' : 'b'),
                child: _Photo(tile: t, height: 122),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.tile, this.width, required this.height, this.big = false});
  final _Tile tile;
  final double? width;
  final double height;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Colors.black),
          Image(
            image: AssetImage(tile.art),
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.05),
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1.0],
                colors: [Color(0x00000000), Color(0xDD000000)],
              ),
            ),
          ),
          Positioned(
            left: 9,
            right: 9,
            bottom: 9,
            child: WordFitText(
              tile.label,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: big ? 15 : 13, height: 1.12),
            ),
          ),
        ]),
      ),
    );
  }
}
