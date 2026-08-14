/// A small readout of what the video pool is doing, for the debug build.
///
/// The whole claim of this port is "a hundred clips exist, four decode". That
/// is not something anyone should have to take on trust, so it is on screen:
/// scroll the app and watch `live` sit at or under four while `leases` climbs
/// into the hundreds.
///
/// Compiled out of release builds — [kDebugMode] is a const, so the branch
/// below is removed entirely rather than merely skipped.
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
    if (!kDebugMode) return const SizedBox.shrink();

    final live = VideoPool.instance.liveCount;
    final leases = VideoPool.instance.leaseCount;
    final over = live > VideoPool.maxLive;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: over ? const Color(0xCCB00020) : const Color(0xCC000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'decoders $live/${VideoPool.maxLive}   clips $leases',
          style: const TextStyle(
            fontSize: 10,
            height: 1.2,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
