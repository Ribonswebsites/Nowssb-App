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
import '../../theme/tokens.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import 'reward_fx.dart' show ConfettiBurst;

class RewardOverlay {
  RewardOverlay._();

  /// The app's root navigator (MaterialApp.navigatorKey).
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> _chain = Future<void>.value();

  static bool get _quiet =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Queue a play. Returns when this play has finished.
  static Future<void> enqueue(Future<void> Function(NavigatorState nav) play) {
    final done = Completer<void>();
    _chain = _chain.then((_) async {
      final nav = navigatorKey.currentState;
      if (nav == null || !nav.mounted || _quiet) return;
      try {
        await play(nav);
      } catch (e) {
        debugPrint('NowssB reward overlay: $e');
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
          pageBuilder: (context, _, __) =>
              YouWonCard(title: title, items: items, rarity: rarity),
        )));
  }

  /// Coins flying into the balance pill with a count-up.
  static Future<void> coins(int gained, {required int from, required int to}) {
    if (gained <= 0) return Future<void>.value();
    return enqueue((nav) {
      final ctx = nav.overlay?.context ?? nav.context;
      return NwsbCoinFly.show(ctx, coins: gained, from: from, to: to);
    });
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

/// The premium glass "You won" card.
class YouWonCard extends StatefulWidget {
  const YouWonCard({super.key, required this.title, required this.items, this.rarity});
  final String title;
  final List<Map<String, dynamic>> items;
  final String? rarity;

  @override
  State<YouWonCard> createState() => _YouWonCardState();
}

class _YouWonCardState extends State<YouWonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  bool get _nothing => widget.items.every((i) => '${i['type']}' == 'none');

  String get _headline {
    if (_nothing) return 'Not this time';
    final first = widget.items.first;
    if (widget.items.length == 1) return '${first['label'] ?? 'A prize'}';
    return '${widget.items.length} prizes';
  }

  Color get _tone => switch ((widget.rarity ?? '').toLowerCase()) {
        'rare' => const Color(0xFF7FB7FF),
        'epic' => const Color(0xFFC08BFF),
        'legendary' => const Color(0xFFFFC857),
        'mythic' => const Color(0xFFFF6FA8),
        _ => NwsbColors.gold,
      };

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        if (!_nothing) Positioned.fill(child: ConfettiBurst(color: tone, count: 80)),
        Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (context, child) {
                    final t = _glow.value;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment(-1 + 2 * t, -1),
                          end: Alignment(1 + 2 * t, 1),
                          colors: [
                            const Color(0x33FFFFFF),
                            tone.withValues(alpha: 0.16),
                            const Color(0x14FFFFFF),
                          ],
                        ),
                        border: Border.all(color: tone.withValues(alpha: 0.55), width: 1.2),
                        boxShadow: [BoxShadow(color: tone.withValues(alpha: 0.28), blurRadius: 40)],
                      ),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EditableLabel('reward_overlay.YouWonCard', _nothing ? 'NO PRIZE' : 'YOU WON',
                            style: TextStyle(color: tone, letterSpacing: 3.2, fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        _Medal(tone: tone, items: widget.items),
                        const SizedBox(height: 14),
                        Text(_headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: 6),
                        EditableLabel('reward_overlay.YouWonCard', widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
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
                              backgroundColor: tone,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: EditableLabel('reward_overlay.YouWonCard', _nothing ? 'Okay' : 'Collect',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)),
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
      ]),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.tone, required this.items});
  final Color tone;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: 0.4 + 0.6 * v, child: child),
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [tone.withValues(alpha: 0.55), tone.withValues(alpha: 0.05)]),
        ),
        child: _ItemMark(item: items.first, size: 64),
      ),
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
