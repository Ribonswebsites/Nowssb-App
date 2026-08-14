/// The little black readout in the corner of a debug build.
///
/// WHAT IT SAYS. "decoders 2/4" is how many videos are being decoded right
/// now, out of the ceiling this app enforces; "clips 9" is how many exist on
/// the page. The distance between those two numbers is the whole reason the
/// Flutter app can be smooth where the website could not — the website was
/// running the equivalent of 106/4.
///
/// It is a development tool and nothing else. TAP IT TO HIDE IT, and it is
/// compiled out of a release build entirely: kDebugMode is a const, so the
/// branch below is removed rather than merely skipped and a Play build never
/// contains it.
///
/// It also reports trouble, because a phone in someone's hand cannot be read
/// with debugPrint:
///
///   near N   how many clips say they are on screen. Zero here while clips
///            are plainly visible means the MEASURING is broken.
///   err …    the last clip that refused to open, and what the platform said
///            about it. Present means the measuring is fine and the OPENING
///            is what failed. Two bugs that look identical from outside.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../media/video_pool.dart';

class PoolHud extends StatefulWidget {
  const PoolHud({super.key});

  @override
  State<PoolHud> createState() => _PoolHudState();
}

class _PoolHudState extends State<PoolHud> {
  Timer? _t;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _t = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => mounted ? setState(() {}) : null,
      );
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || _hidden) return const SizedBox.shrink();

    final pool = VideoPool.instance;
    final live = pool.liveCount;
    final near = pool.nearCount;
    final err = pool.lastError;

    // Red when something is actually wrong: over the ceiling, or clips on
    // screen with nothing decoding at all.
    final bad = live > VideoPool.maxLive || (near > 0 && live == 0);

    return GestureDetector(
      onTap: () => setState(() => _hidden = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: bad ? const Color(0xE6B00020) : const Color(0xCC000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'decoders $live/${VideoPool.maxLive}   '
              'clips ${pool.leaseCount}   near $near',
              style: const TextStyle(
                fontSize: 10,
                height: 1.2,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (err != null)
              Text(
                err,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.25,
                  color: Color(0xFFFFD9DD),
                ),
              ),
            const Text(
              'tap to hide · debug only',
              style: TextStyle(fontSize: 8, color: Color(0x8CFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}
