/// DOOR SCREENS — Store checkout (CheckoutPage).
/// Signature move: THE POSTER STACK — every item in the bag is its own
/// word-poster (giant serif title, its art cut in, black meaning tag,
/// status sticker) dealt into a fanned stack; tap a poster to bring it
/// forward. The "how you pay" copy becomes three torn PAY / UNLOCK / KEEP
/// tiles. The dock carries the serif total and the gold Place-order pill.
/// Writes nothing; Builder keeps CheckoutPage's Google Play flow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../admin/template/editable.dart';
import 'door_kit.dart';

const _slot = 'concept.Doors.Checkout';

class DoorLine {
  const DoorLine({
    required this.id,
    required this.title,
    required this.kind,
    required this.priceLabel,
    required this.image,
    this.meaning,
    this.status,
    this.included = false,
  });
  /// In the user's plan: shows 'Included', never a price.
  final bool included;
  String get priceText => included ? 'Included' : priceLabel;
  final String id, title, kind, priceLabel, image;
  final String? meaning; // tag line
  final String? status; // e.g. "In your plan", "Owned"
}

class DoorCheckout extends StatefulWidget {
  const DoorCheckout({
    super.key,
    required this.items,
    required this.totalLabel,
    this.cartCount = 0,
    this.message,
    this.onPlaceOrder,
    this.onAddToLibrary,
    this.onOpenItem,
    this.onRemove,
    this.onOpenCart,
    this.onOpenWishlist,
    this.onBack,
    this.debugPhase,
    this.debugFront,
  });
  final List<DoorLine> items;
  final String totalLabel;
  final int cartCount;
  final String? message; // CheckoutPage._message (errors / done)
  final VoidCallback? onPlaceOrder;
  /// All-in-plan bag: the dock says 'Add to library' and calls this.
  final VoidCallback? onAddToLibrary;
  bool get allInPlan => items.isNotEmpty && items.every((i) => i.included);
  final void Function(String id)? onOpenItem;
  final void Function(String id)? onRemove;
  final VoidCallback? onOpenCart, onOpenWishlist, onBack;
  final double? debugPhase;
  final int? debugFront;

  @override
  State<DoorCheckout> createState() => _S();
}

class _S extends State<DoorCheckout> with TickerProviderStateMixin, DoorPhase {
  late int _front = widget.debugFront ?? 0;

  @override
  double? get debugPhaseValue => widget.debugPhase;

  @override
  void initState() {
    super.initState();
    startPhase();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Scaffold(
      backgroundColor: doorDeep,
      body: AnimatedBuilder(
        animation: phase,
        builder: (context, _) {
          final t = phase.value;
          return Stack(fit: StackFit.expand, children: [
            DoorLiquid(t: t),
            SafeArea(
              child: Column(children: [
                DoorTopBar(
                  slot: _slot,
                  sub: 'Checkout',
                  onBack: widget.onBack,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    DoorRoundButton(icon: Icons.favorite_border_rounded, onTap: widget.onOpenWishlist, semantic: 'Wishlist'),
                    const SizedBox(width: 8),
                    Stack(clipBehavior: Clip.none, children: [
                      DoorRoundButton(icon: Icons.shopping_bag_outlined, onTap: widget.onOpenCart, semantic: 'Cart'),
                      if (widget.cartCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(color: doorGold, shape: BoxShape.circle),
                            child: Text('${widget.cartCount}', style: doorBody(10, color: doorInk, w: FontWeight.w800)),
                          ),
                        ),
                    ]),
                  ]),
                ),
                // Total dock stays docked at the bottom.
                Expanded(
                  child: ListView( padding: const EdgeInsets.only(bottom: 16), children: [
                    DoorTicker(items: [for (final i in items) i.title, 'Pay on Google Play', 'Unlock on every phone'], t: t),
                    DoorKicker('$_slot.k1', items.length == 1 ? 'In your bag · 1 piece' : 'In your bag · ${items.length} pieces'),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Your bag is empty.', style: doorTitle()),
                      )
                    else
                      LayoutBuilder(builder: (context, c) => _stack(c.maxWidth, t)),
                    if (widget.message != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.black,
                          child: Text(widget.message!, style: doorBody(14)),
                        ),
                      ),
                    DoorKicker('$_slot.k2', widget.allInPlan ? 'How it unlocks' : 'How you pay'),
                    _HowYouPay(t: t, allInPlan: widget.allInPlan),
                  ]),
                ),
                DoorDock(
                  slot: _slot,
                  // 320@1.3 has no room for the long kicker: just "TOTAL".
                  kicker: _narrow(context)
                      ? (widget.allInPlan ? 'In your plan' : 'Total')
                      : (widget.allInPlan ? 'All in your plan' : 'Total · Google Play'),
                  line: widget.allInPlan ? 'Included' : widget.totalLabel,
                  action: widget.allInPlan ? 'Add to library' : 'Place order',
                  onTap: items.isEmpty
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          widget.allInPlan ? widget.onAddToLibrary?.call() : widget.onPlaceOrder?.call();
                        },
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  /// 320@1.3 (or big text): short dock kickers that fit one line.
  static bool _narrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 || MediaQuery.textScalerOf(context).scale(10) > 12;

  Widget _stack(double w, double t) {
    final items = widget.items;
    final cardW = w - 44;
    final cardH = cardW * .74;
    final peek = 46.0;
    final back = math.min(items.length - 1, 3);
    final order = [
      for (var k = 0; k < items.length; k++)
        if (k != _front) k,
      _front,
    ].reversed.take(back + 1).toList().reversed.toList();
    return SizedBox(
      height: cardH + back * peek + 24,
      child: Stack(clipBehavior: Clip.none, children: [
        for (var j = 0; j < order.length; j++)
          () {
            final k = order[j];
            final depth = order.length - 1 - j; // 0 = front
            return AnimatedPositioned(
              key: ValueKey(items[k].id),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              left: 22 + depth * 6.0,
              right: 22 - depth * 6.0,
              top: (back - depth) * peek,
              height: cardH,
              child: Transform.rotate(
                angle: depth == 0 ? math.sin(t * math.pi * 2) * .008 : (depth.isEven ? .035 : -.04),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (depth == 0) {
                      widget.onOpenItem?.call(items[k].id);
                    } else {
                      setState(() => _front = k);
                    }
                  },
                  child: _ItemPoster(
                    line: items[k],
                    t: t,
                    front: depth == 0,
                    onRemove: widget.onRemove == null ? null : () => widget.onRemove!(items[k].id),
                  ),
                ),
              ),
            );
          }(),
      ]),
    );
  }
}

class _ItemPoster extends StatelessWidget {
  const _ItemPoster({required this.line, required this.t, required this.front, this.onRemove});
  final DoorLine line;
  final double t;
  final bool front;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) {
    final a = math.sin(t * math.pi * 2);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 22, offset: Offset(0, 12))],
      ),
      padding: const EdgeInsets.all(5),
      child: ClipRect(
        child: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: doorPaper),
          if (!front)
            // back posters: opaque paper + the title strip only (no type bleed)
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(line.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: doorTitle(color: doorInk)),
              ),
            )
          else ...[
            EditableImage.asset(line.image,
                slot: '$_slot.item.${line.id}', fit: BoxFit.cover, alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const ColoredBox(color: doorDeep)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, .4, 1],
                    colors: [Color(0x00000000), Color(0x22000000), Color(0xF2000000)]),
              ),
            ),
            Positioned(
              left: 12,
              right: 60,
              bottom: 104,
              child: Transform.translate(
                offset: Offset(0, a * 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(line.title.toUpperCase(), textScaler: TextScaler.noScaling, style: doorDisplay(64, ls: 0)),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 56,
              right: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: const Color(0xF0181818),
                  child: Text(line.meaning ?? line.kind,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: doorBody(13)),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: doorGold, borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: doorInk.withValues(alpha: .2))),
                child: Text('${line.kind} · ${line.priceText}', style: doorBody(14, color: doorInk, w: FontWeight.w800)),
              ),
            ),
            if (line.status != null) Positioned(right: 10, top: 10, child: DoorSticker(line.status!, angle: .05, size: 10)),
            if (onRemove != null)
              Positioned(
                right: 8,
                bottom: 10,
                child: DoorRoundButton(icon: Icons.close_rounded, onTap: onRemove, semantic: 'Remove ${line.title}', size: 36),
              ),
          ],
        ]),
      ),
    );
  }
}

class _HowYouPay extends StatelessWidget {
  const _HowYouPay({required this.t, this.allInPlan = false});
  final double t;
  final bool allInPlan;
  @override
  Widget build(BuildContext context) {
    Widget tile(String w, String sticker, String line, String asset, int seed, double angle, bool right) {
      return Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: .78,
          child: Transform.rotate(
            angle: angle,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                height: 132,
                child: DoorTornTile(slot: '$_slot.pay.$w', asset: asset, word: w, seed: seed, t: t, sticker: sticker, wordSize: 56),
              ),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                child: EditableLabel('$_slot.pay.$w.line', line, style: doorBody(13, color: Colors.white)),
              ),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        if (allInPlan)
          tile('INCLUDED', 'Your plan', 'Every piece here is already in your plan. Nothing to pay.',
              'assets/video/earth-evening-poster.webp', 21, -.03, false)
        else
          tile('PAY', 'Google Play', 'Securely, in your own currency. Coupons and coins lower the price.',
              'assets/video/earth-evening-poster.webp', 21, -.03, false),
        const SizedBox(height: 10),
        tile('UNLOCK', 'Digital', 'Words, meanings and eBooks are digital. Nothing is shipped.',
            'assets/video/nm-calm-clouds-poster.webp', 22, .03, true),
        const SizedBox(height: 10),
        tile('KEEP', 'Every phone', 'Unlocks on every phone you sign in to, once Google confirms.',
            'assets/video/player-box-rings-poster.webp', 23, -.02, false),
      ]),
    );
  }
}
