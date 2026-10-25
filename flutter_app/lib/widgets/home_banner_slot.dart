/// The Fashion home's banner slot just above its routine cards.
///
/// The Fashion home opens the same six programme doors the three-card rail
/// ([TrioRail]) does, with the same pictures, as a wide editorial poster
/// with the doors as glass pills along its foot. The Normal home keeps the
/// original [TrioRail] itself.
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
