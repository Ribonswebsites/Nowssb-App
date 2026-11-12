/// Root reward overlay: every win plays here, on the root navigator, so the
/// reveal and the coin flight never depend on the widget that asked for them
/// (a card that scrolls away, a sheet that pops, a list that reloads).
///
/// Order is always: "You won X" reveal → coins fly into the balance pill.
/// Plays are queued, so two wins never fight over the screen.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/template/editable.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/swipe_away.dart';
import 'coin_collect.dart' show CoinDay;

class RewardOverlay {
  RewardOverlay._();

  /// The app's root navigator (MaterialApp.navigatorKey).
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> _chain = Future<void>.value();

  /// Tests: let plays run (they are skipped under the test binding).
  static bool debugPlayInTests = false;

  static bool get _quiet =>
      !debugPlayInTests && WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// True when plays are switched off (widget tests), so nothing should
  /// keep retrying.
  static bool get quiet => _quiet;

  static DateTime? _busySince;

  /// Longest a single play may hold the queue. A flight takes ~3 s and a
  /// card waits for a tap, so anything past this is a play that never ended
  /// (its route was removed, its navigator rebuilt): the queue moves on
  /// instead of keeping every later reward, the Collect card included,
  /// waiting behind it forever.
  static const _stuckAfter = Duration(seconds: 45);

  /// Tests: forget any play still queued from an earlier test.
  @visibleForTesting
  static void debugReset() {
    _chain = Future<void>.value();
    _busySince = null;
  }

  /// Whether a play could start right now (a navigator is on screen).
  static bool get canPlay {
    final nav = navigatorKey.currentState;
    return nav != null && nav.mounted && !_quiet;
  }

  /// Queue a play. Returns when this play has finished.
  static Future<void> enqueue(Future<void> Function(NavigatorState nav) play) {
    final done = Completer<void>();
    final since = _busySince;
    if (since != null && DateTime.now().difference(since) > _stuckAfter) {
      _chain = Future<void>.value();
    }
    _chain = _chain.then((_) async {
      final nav = navigatorKey.currentState;
      if (nav == null || !nav.mounted || _quiet) return;
      _busySince = DateTime.now();
      try {
        await play(nav);
      } catch (e) {
        debugPrint('NowssB reward overlay: $e');
      } finally {
        _busySince = null;
      }
    }).whenComplete(() {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  /// "You won X" for any list of prize items (coins, passes, coupons, tokens…).
  static Future<void> reveal({
    required String title,
    required List<Map<String, dynamic>> items,
    String? rarity,
  }) {
    if (items.isEmpty) return Future<void>.value();
    return enqueue((nav) => nav.push<void>(RawDialogRoute<void>(
          barrierDismissible: true,
          barrierLabel: 'close',
          barrierColor: const Color(0xCC03060C),
          transitionDuration: const Duration(milliseconds: 360),
          transitionBuilder: (context, a, _, child) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween(begin: 0.86, end: 1.0)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
              child: child,
            ),
          ),
          // Swipe the card away (any direction) as well as tap-outside/back.
          pageBuilder: (context, _, __) => SwipeAway(
            onDismissed: () => Navigator.of(context).maybePop(),
            child: YouWonCard(title: title, items: items, rarity: rarity),
          ),
        )));
  }

  /// Coins flying into the balance pill with a count-up. [immediate] skips
  /// the queue: the flight starts now, even if another play is on screen
  /// (the Collect card's own tap uses it, so the top bar never waits).
  static Future<void> coins(int gained, {required int from, required int to, CoinDay? day, bool immediate = false}) {
    if (gained <= 0) return Future<void>.value();
    Future<void> fly(NavigatorState nav) {
      final ctx = nav.overlay?.context ?? nav.context;
      return NwsbCoinFly.show(ctx, coins: gained, from: from, to: to, day: day);
    }
    if (immediate) {
      final nav = navigatorKey.currentState;
      if (nav == null || !nav.mounted || _quiet) return Future<void>.value();
      return fly(nav);
    }
    return enqueue(fly);
  }
}

/// Where the coins land: the balance pill registers itself here.
class CoinPillAnchor {
  CoinPillAnchor._();
  static final List<GlobalKey> _keys = [];
  static void add(GlobalKey k) => _keys.add(k);
  static void remove(GlobalKey k) => _keys.remove(k);

  /// Centre of the most recently mounted, visible pill (global coordinates).
  static Offset? target() {
    for (final k in _keys.reversed) {
      final box = k.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        final c = box.localToGlobal(box.size.center(Offset.zero));
        if (c.dx.isFinite && c.dy.isFinite && c.dy >= 0) return c;
      }
    }
    return null;
  }
}

/// The "You won" card: the NowssB Store black card look (liked pages),
/// a white badge for the prize and a white Collect pill.
class YouWonCard extends StatefulWidget {
  const YouWonCard({super.key, required this.title, required this.items, this.rarity});
  final String title;
  final List<Map<String, dynamic>> items;
  final String? rarity;

  @override
  State<YouWonCard> createState() => _YouWonCardState();
}

class _YouWonCardState extends State<YouWonCard> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  bool get _nothing => widget.items.every((i) => '${i['type']}' == 'none');

  String get _headline {
    if (_nothing) return 'Not this time';
    final first = widget.items.first;
    if (widget.items.length == 1) return '${first['label'] ?? 'A prize'}';
    return '${widget.items.length} prizes';
  }

  @override
  Widget build(BuildContext context) {
    final rarity = (widget.rarity ?? '').trim();
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF0111114),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 12))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EditableLabel('reward_overlay.YouWonCard', _nothing ? 'NO PRIZE' : 'YOU WON',
                            style: const TextStyle(color: Color(0xB3FFFFFF), letterSpacing: 2.4, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _Medal(items: widget.items),
                        const SizedBox(height: 14),
                        Text(_headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: 6),
                        EditableLabel('reward_overlay.YouWonCard', widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
                        if (rarity.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(rarity.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                        ],
                        if (widget.items.length > 1) ...[
                          const SizedBox(height: 12),
                          for (final i in widget.items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(children: [
                                _ItemMark(item: i, size: 26),
                                const SizedBox(width: 10),
                                Expanded(child: Text('${i['label'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                              ]),
                            ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0B0B10),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: EditableLabel('reward_overlay.YouWonCard', _nothing ? 'Okay' : 'Collect',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0B0B10))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: 0.4 + 0.6 * v, child: child),
      child: SizedBox(width: 96, height: 96, child: Center(child: _ItemMark(item: items.first, size: 72))),
    );
  }
}

class _ItemMark extends StatelessWidget {
  const _ItemMark({required this.item, required this.size});
  final Map<String, dynamic> item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final type = '${item['type'] ?? ''}';
    if (type == 'coins') return NwsbCoinDisc(size: size);
    final mark = switch (type) {
      'percentOff' => NwsbMarks.bag,
      'pass' => NwsbMarks.crown,
      'giftbox' || 'scratch' => NwsbMarks.gift,
      'token' => NwsbMarks.stages,
      'badge' || 'cosmetic' => NwsbMarks.verified,
      'none' => NwsbMarks.word,
      _ => NwsbMarks.gift,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: NwsbIcon(mark, size: size * 0.5, color: Colors.black),
    );
  }
}
