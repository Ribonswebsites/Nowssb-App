/// The banner slot just above 'Your essentials' — one design per home.
///
/// Both homes open the same six programme doors the old three-card rail
/// ([TrioRail]) did, with the same pictures. Only the shape differs:
/// * Normal home: a raised neumorphic console of soft buttons.
/// * Fashion home: a wide editorial poster with the doors as glass pills
///   along its foot.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../features/economy/economy_api.dart';
import '../features/programs/program_router.dart';
import '../theme/tokens.dart';
import 'neumorphic.dart';

/// Opens a programme door. Tests swap it to record taps.
typedef HomeDoorOpener = void Function(BuildContext context, Programme p, String? tab);

void _defaultOpen(BuildContext context, Programme p, String? tab) => Programmes.open(context, p, tab: tab);

class HomeDoor {
  const HomeDoor(this.label, this.image, this.tint, this.programme, [this.tab]);
  final String label;
  final String image;
  final Color tint;
  final Programme programme;
  final String? tab;

  /// The coin ledger door shows the live balance.
  bool get isCoins => tab == 'wallet';

  /// The label without the brand prefix, for the tight Normal list.
  String get short {
    final t = label.startsWith('NowssB ') ? label.substring(7) : label;
    return t.isEmpty ? label : '${t[0].toUpperCase()}${t.substring(1)}';
  }
}

/// Same doors, pictures and destinations as [TrioRail].
const homeDoors = <HomeDoor>[
  HomeDoor('NowssB Gifts', 'assets/banners/earn/sit-dark.png', Color(0xFF6A1B4D), Programme.gifts),
  HomeDoor('NowssB Rewards', 'assets/banners/earn/yoga-light.png', Color(0xFF1E3A8A), Programme.rewards),
  HomeDoor('Your Earning', 'assets/banners/earn/man-light.png', Color(0xFF8A5A12), Programme.earnings),
  HomeDoor('NowssB coins earned', 'assets/banners/earn/yoga-dark.png', Color(0xFF0F6E56), Programme.rewards, 'wallet'),
  HomeDoor('NowssB Coupons', 'assets/banners/earn/hands-light.png', Color(0xFF7A1F4F), Programme.coupons),
  HomeDoor('NowssB Reference', 'assets/banners/earn/sit-light.png', Color(0xFF1F4E7A), Programme.reference),
];

const _portrait = 'assets/banners/earn/hands-raise.png';

Widget _coins(Widget Function(int coins) build) => ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (_, __) => build(EconomyMirror.instance.coins),
    );

Widget _tinted(HomeDoor d, {Alignment alignment = const Alignment(0, -0.2)}) => Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: d.tint),
        Image(
          image: AssetImage(d.image),
          fit: BoxFit.cover,
          alignment: alignment,
          color: d.tint.withValues(alpha: 0.30),
          colorBlendMode: BlendMode.srcATop,
        ),
      ],
    );

// ---------------------------------------------------------------- Normal

const _nmBg = NwsbColors.surface;

/// Soft inset: darker on the top-left, lighter on the bottom-right, as if
/// pressed into the surface (Flutter has no inner box-shadow).
BoxDecoration _inset(BorderRadius r) => BoxDecoration(
      borderRadius: r,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD9DCE4), Color(0xFFEDEFF4), Color(0xFFFAFBFD)],
        stops: [0, 0.45, 1],
      ),
      border: Border.all(color: const Color(0x0F000000)),
    );

BoxDecoration _raised(BorderRadius r, List<BoxShadow> s) => BoxDecoration(color: _nmBg, borderRadius: r, boxShadow: s);

/// Normal home: one raised neumorphic console. A wide inset coin readout on
/// top, then the other five doors as raised soft buttons with inset wells.
/// A pressed button sinks into the surface.
class NormalHomeBannerSlot extends StatelessWidget {
  const NormalHomeBannerSlot({super.key, this.onOpen = _defaultOpen});
  final HomeDoorOpener onOpen;

  @override
  Widget build(BuildContext context) {
    final coins = homeDoors.firstWhere((d) => d.isCoins);
    final rest = homeDoors.where((d) => !d.isCoins).toList();
    Widget btn(HomeDoor d) => Expanded(child: _NeuDoor(door: d, onOpen: onOpen));
    const gap = SizedBox(width: 14);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _raised(BorderRadius.circular(28), NwsbShadows.raised),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NeuDoor(door: coins, onOpen: onOpen, readout: true),
          const SizedBox(height: 14),
          IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [btn(rest[0]), gap, btn(rest[1]), gap, btn(rest[3])])),
          const SizedBox(height: 14),
          Row(children: [btn(rest[2]), gap, btn(rest[4])]),
        ],
      ),
    );
  }
}

class _NeuDoor extends StatefulWidget {
  const _NeuDoor({required this.door, required this.onOpen, this.readout = false});
  final HomeDoor door;
  final HomeDoorOpener onOpen;
  final bool readout;

  @override
  State<_NeuDoor> createState() => _NeuDoorState();
}

class _NeuDoorState extends State<_NeuDoor> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  Widget _well(double size) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: _inset(BorderRadius.circular(size)),
        child: ClipOval(child: _tinted(widget.door)),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.door;
    final r = BorderRadius.circular(widget.readout ? 20 : 18);
    const ink = Color(0xFF2A2D3A);
    final Widget body;
    if (widget.readout) {
      body = Row(children: [
        _well(44),
        const SizedBox(width: 12),
        Expanded(
          child: Text(d.short,
              maxLines: 2, style: const TextStyle(color: Color(0xFF6B6F7D), fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: _inset(BorderRadius.circular(14)),
          child: _coins((c) => Text('$c',
              style: TextStyle(
                  color: d.tint,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()]))),
        ),
      ]);
    } else {
      body = Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        _well(42),
        const SizedBox(height: 8),
        // One line, never broken mid-word: shrinks a touch when very tight.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(d.short,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]);
    }
    return Semantics(
      button: true,
      label: d.label,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('normal-door-${d.label}'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: () => widget.onOpen(context, d.programme, d.tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: widget.readout
              ? const EdgeInsets.fromLTRB(10, 10, 12, 10)
              : const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: _down ? _inset(r) : _raised(r, NwsbShadows.raisedXs),
          child: body,
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- Fashion

/// Fashion home: a wide editorial poster, the doors as glass pills on it.
class FashionHomeBannerSlot extends StatelessWidget {
  const FashionHomeBannerSlot({super.key, this.onOpen = _defaultOpen});
  final HomeDoorOpener onOpen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: NwsbColors.deep),
            const Image(
              image: AssetImage(_portrait),
              fit: BoxFit.cover,
              alignment: Alignment(0, -0.35),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [Color(0x00060C18), Color(0x33060C18), Color(0xF2060C18)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 74,
              child: Text(
                'Words, rewards, and what you have earned.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 25,
                  height: 1.05,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: homeDoors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _FashionPill(door: homeDoors[i], onOpen: onOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FashionPill extends StatelessWidget {
  const _FashionPill({required this.door, required this.onOpen});
  final HomeDoor door;
  final HomeDoorOpener onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('fashion-door-${door.label}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpen(context, door.programme, door.tab),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(dimension: 36, child: ClipOval(child: _tinted(door))),
                const SizedBox(width: 9),
                Text(
                  door.label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (door.isCoins)
                  _coins((c) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '$c',
                          style: const TextStyle(color: Color(0xFFE4C56A), fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
