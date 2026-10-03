/// The three NowssB gift boxes: a still, premium showcase with tap motion
/// (no endless wobble), the gift-card grid and the reveal. The Daily Spin
/// lives in spin_wheel.dart.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/reward_fx.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import 'gifts_screen.dart';
export 'spin_wheel.dart';
import '../../admin/template/editable.dart';

class GiftBox {
  const GiftBox(this.asset, this.title, this.line);
  final String asset;
  final String title;
  final String line;
}

const kGiftBoxes = <GiftBox>[
  GiftBox('assets/gifts/box-red.webp', 'Word gift', 'Red ribbon. A word, a stage, or a 7-day pass.'),
  GiftBox('assets/gifts/box-gold.webp', 'Subscription gift', 'Gold ribbon. Basic, Standard, or Premium.'),
  GiftBox('assets/gifts/box-black.webp', 'Signature gift', 'Black ribbon. The high tier. Rare on the wheel.'),
];



class GiftShowcase extends StatelessWidget {
  const GiftShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    // Stacked, not a sideways strip: the hero picture on top, the three gift
    // boxes below it. Nothing here scrolls on its own, so the page scroll
    // always wins.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              EditableImage.asset(
                'assets/gifts/gift-hero.png',
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox(height: 210),
                slot: 'gift_show.GiftShowcase',
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x00000000), Color(0xCC000000)],
                        stops: [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                right: 18,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditableLabel('gift_show.GiftShowcase', 'THE GIFT SHOP',
                        style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 2.6, fontSize: 11, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    EditableLabel('gift_show.GiftShowcase', 'Three ribbons. One real purchase, sent as a code.',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.25)),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0x66E4C56A)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const GiftGallery(),
      ],
    );
  }
}

class GiftGallery extends StatelessWidget {
  const GiftGallery({super.key});

  static const _ribbon = <Color>[Color(0xFFB8322E), Color(0xFFE4C56A), Color(0xFF2A2A2A)];

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < kGiftBoxes.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _boxCell(context, kGiftBoxes[i], _ribbon[i])),
          ],
        ],
      ),
    );
  }

  Widget _boxCell(BuildContext context, GiftBox box, Color ribbon) {
    return GiftPedestal(
      tone: ribbon,
      onTap: () => showGiftCardSheet(context, giftCardFor(box.title)),
      child: Column(
        children: [
          EditableImage.asset(box.asset, height: 96, fit: BoxFit.contain, slot: 'gift_show.GiftGallery'),
          const SizedBox(height: 8),
          Text(box.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 3),
          Text(box.line, textAlign: TextAlign.center, maxLines: 3, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 10.5, height: 1.25)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x88E4C56A))),
            child: const EditableLabel('gift_show.GiftGallery', 'Send', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// A still gift on a lit glass pedestal. Tap: it dips, lifts and a gold
/// shine sweeps across it once — then it rests. No looping motion.
class GiftPedestal extends StatefulWidget {
  const GiftPedestal({super.key, required this.child, required this.onTap, this.tone = const Color(0xFFE4C56A)});
  final Widget child;
  final VoidCallback onTap;
  final Color tone;

  @override
  State<GiftPedestal> createState() => _GiftPedestalState();
}

class _GiftPedestalState extends State<GiftPedestal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  var _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    HapticFeedback.selectionClick();
    await _c.forward(from: 0);
    if (mounted) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: _tap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            final lift = sin(t * pi) * 8;
            return Transform.translate(
              offset: Offset(0, -lift),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [const Color(0x14FFFFFF), widget.tone.withValues(alpha: 0.10)],
                  ),
                  border: Border.all(color: widget.tone.withValues(alpha: 0.35 + 0.4 * sin(t * pi))),
                  boxShadow: [BoxShadow(color: widget.tone.withValues(alpha: 0.12 + 0.25 * sin(t * pi)), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (r) => LinearGradient(
                    begin: Alignment(-1.6 + 3.2 * t, -1),
                    end: Alignment(-0.6 + 3.2 * t, 1),
                    colors: t == 0 || t == 1
                        ? const [Color(0x00FFFFFF), Color(0x00FFFFFF)]
                        : const [Color(0x00FFFFFF), Color(0x55FFF3C9), Color(0x00FFFFFF)],
                    stops: t == 0 || t == 1 ? const [0, 1] : const [0.35, 0.5, 0.65],
                  ).createShader(r),
                  child: child,
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shows a gift that the server has already put on this account (or a
/// gift card code Play has just paid for). Nothing is minted here.
Future<void> openGiftBox(
  BuildContext context, {
  required GiftBox box,
  required String prize,
  required String itemId,
  String? code,
}) async {
  if (!context.mounted) return;
  RewardHaptics.big();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Gift',
    barrierColor: const Color(0xC0000000),
    pageBuilder: (context, _, __) => Stack(children: [
      const Positioned.fill(child: ConfettiBurst(color: Color(0xFFE4C56A), count: 70)),
      _Reveal(box: box, prize: prize, code: code ?? ''),
    ]),
  );
}

GiftBox giftBoxFor(String cardId) => switch (cardId) {
      'bundle' || 'signature3' => kGiftBoxes[2],
      'basic7' || 'ebook7' || 'standard30' || 'premium30' || 'ebook30' => kGiftBoxes[1],
      _ => kGiftBoxes[0],
    };

class GiftPlanGrid extends StatelessWidget {
  const GiftPlanGrid({super.key});

  static const _items = <(String, String, String, String)>[
    ('Stage card', 'One locked stage.', 'assets/gifts/box-red.webp', 'stage'),
    ('Word card', 'One full word.', 'assets/gifts/box-red.webp', 'word'),
    ('Bundle card', 'Ten words.', 'assets/gifts/box-black.webp', 'bundle'),
    ('7-day Basic', 'No rank credit.', 'assets/gifts/box-gold.webp', 'basic'),
    ('7-day ebook', 'After the trial.', 'assets/gifts/box-gold.webp', 'ebook'),
    ('30-day Standard', 'Gifted is not a rate.', 'assets/gifts/box-gold.webp', 'standard'),
    ('30-day Premium', 'Higher tier.', 'assets/gifts/box-gold.webp', 'premium'),
    ('3-day Signature', 'Does not unlock Partner.', 'assets/gifts/box-black.webp', 'signature'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          for (var r = 0; r < _items.length; r += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _cell(context, _items[r])),
                  Expanded(child: _cell(context, _items[r + 1])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, (String, String, String, String) item) {
    final (title, line, asset, id) = item;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GiftPedestal(
        onTap: () => showGiftCardSheet(context, giftCardFor(id)),
        child: Column(
          children: [
            EditableImage.asset(asset, height: 80, fit: BoxFit.contain, slot: 'gift_show.GiftPlanGrid'),
            const SizedBox(height: 8),
            EditableLabel('gift_show.GiftPlanGrid', title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            Text(line, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.box, required this.prize, required this.code});
  final GiftBox box;
  final String prize;
  final String code;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with TickerProviderStateMixin {
  late final AnimationController _open;
  late final AnimationController _sway;

  @override
  void initState() {
    super.initState();
    _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
    _open.forward();
  }

  @override
  void dispose() {
    _open.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_open, _sway]),
            builder: (context, _) {
              final intro = Curves.easeOutCubic.transform(_open.value.clamp(0.0, 1.0));
              const sway = 0.0;
              final yaw = (1 - intro) * 1.45 + intro * sway;
              final spin = Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(0.2)
                ..rotateY(yaw);
              return Opacity(
                opacity: intro.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.9 + 0.1 * intro,
                  child: Container(
                    width: 300,
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE4C56A)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                          child: ColoredBox(
                            color: Colors.black,
                            child: SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: Transform(
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.medium,
                                transform: spin,
                                child: EditableImage.asset(widget.box.asset, fit: BoxFit.contain, slot: 'gift_show.Reveal'),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            children: [
                              Text(widget.prize, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                              const SizedBox(height: 6),
                              if (widget.code.isNotEmpty)
                                Text(widget.code, style: const TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 4),
                              const EditableLabel('gift_show.Reveal', 'On this account. Not cash. Not a rank key.', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () async {
                                  if (widget.code.isNotEmpty) await Clipboard.setData(ClipboardData(text: widget.code));
                                  if (context.mounted) Navigator.of(context).pop();
                                },
                                child: widget.code.isEmpty
                                    ? const EditableLabel('gift_show.Reveal', 'Lovely', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800))
                                    : const EditableLabel('gift_show.Reveal', 'Copy code', style: TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Weighted open. Higher subscription tiers are on the table, not the default.
class RandomGiftButton extends StatelessWidget {
  const RandomGiftButton({super.key});


  @override
  Widget build(BuildContext context) {
    return GoldButton(
      label: 'Open a random gift',
      filled: false,
      // Today's free gift box, drawn by the server from the published
      // contents (Gifts → Rules). One a day; minutes in the app pick the box.
      onTap: () => runReward(context, () => EconomyApi.call('openDailyBox', {}), title: 'Today\u2019s gift'),
    );
  }
}
