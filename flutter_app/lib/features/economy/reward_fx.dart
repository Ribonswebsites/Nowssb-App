/// Reward moments: coin burst + count-up, gift-box opening, chest opening,
/// rarity confetti and haptics. Purely visual — every number shown comes
/// from the server response that triggered it (nothing here adds coins).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/template/editable.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import 'economy_api.dart';

/// Rarity palette (Common → Mythic).
Color rarityColor(String? rarity) => switch ((rarity ?? '').toLowerCase()) {
      'rare' => const Color(0xFF7FB7FF),
      'epic' => const Color(0xFFC08BFF),
      'legendary' => const Color(0xFFFFC857),
      'mythic' => const Color(0xFFFF6FA8),
      _ => const Color(0xFFE4E4E4),
    };

String rarityTitle(String? r) {
  final s = (r ?? 'common').toLowerCase();
  return s.isEmpty ? 'Common' : s[0].toUpperCase() + s.substring(1);
}

bool rarityParty(String? r) => ['epic', 'legendary', 'mythic'].contains((r ?? '').toLowerCase());

class RewardHaptics {
  static void tick() => HapticFeedback.selectionClick();
  static void pop() => HapticFeedback.mediumImpact();
  static void big() => HapticFeedback.heavyImpact();
  static Future<void> rarity(String? r) async {
    switch ((r ?? '').toLowerCase()) {
      case 'mythic':
      case 'legendary':
        HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 90));
        HapticFeedback.heavyImpact();
      case 'epic':
        HapticFeedback.heavyImpact();
      case 'rare':
        HapticFeedback.mediumImpact();
      default:
        HapticFeedback.lightImpact();
    }
  }
}

/// Coins from a server response: burst + flight + count-up into the wallet.
Future<void> playCoins(BuildContext context, int gained, {int? balanceAfter}) async {
  if (gained <= 0 || !context.mounted) return;
  final after = balanceAfter ?? EconomyMirror.instance.coins;
  final before = math.max(0, after - gained);
  await NwsbCoinFly.show(context, coins: gained, from: before, to: after);
}

/// Sum of coins in a server response (effects / items / coins).
int coinsIn(Map<String, dynamic> r) {
  var n = 0;
  final effects = r['effects'];
  if (effects is List) {
    for (final e in effects) {
      if (e is Map && e['kind'] == 'coins') n += (e['coins'] as num?)?.toInt() ?? 0;
    }
    if (n > 0) return n;
  }
  return (r['coins'] as num?)?.toInt() ?? 0;
}

int? balanceIn(Map<String, dynamic> r) {
  final effects = r['effects'];
  if (effects is List) {
    for (final e in effects.reversed) {
      if (e is Map && e['kind'] == 'coins' && e['balance'] is num) return (e['balance'] as num).toInt();
    }
  }
  return null;
}

/// Plays whatever the server says happened: gift box / chest opening,
/// prize sheet, badge toast, then the coin flight with count-up.
Future<void> celebrate(BuildContext context, Map<String, dynamic> r, {String? title}) async {
  if (!context.mounted) return;
  List<Map<String, dynamic>> asItems(Object? v) =>
      (v as List?)?.whereType<Map>().map((m) => m.map((k, v) => MapEntry('$k', v))).toList() ?? <Map<String, dynamic>>[];
  var items = asItems(r['items']);
  final effects = (r['effects'] as List?)?.whereType<Map>().toList() ?? const [];
  Map? find(String kind) {
    for (final e in effects) {
      if (e['kind'] == kind) return e;
    }
    return null;
  }

  final box = find('giftbox');
  final chest = find('chest');
  final reveal = find('reveal');
  if (box != null) {
    if (items.isEmpty) items = asItems(box['items']);
    await GiftBoxOpening.show(context, box: '${box['box'] ?? r['box'] ?? 'gold'}', title: '${r['title'] ?? title ?? 'Gift box'}', items: items);
  } else if (chest != null) {
    await GiftBoxOpening.show(context, box: 'weekly', title: title ?? 'Weekly chest', items: items.isEmpty ? [{'type': 'coins', 'label': '${chest['coins'] ?? 0} coins'}] : items, chest: true);
  } else if (items.isNotEmpty) {
    await RewardItemsSheet.show(context, title: title ?? 'On your account', items: items);
  } else if (reveal == null && r['granted'] is Map && (r['granted'] as Map)['type'] != 'coins') {
    await RewardItemsSheet.show(context, title: title ?? 'On your account', items: [Map<String, dynamic>.from(r['granted'] as Map)]);
  }
  if (!context.mounted) return;
  for (final b in effects.where((e) => e['kind'] == 'badge')) {
    RewardHaptics.pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Badge earned: ${b['title'] ?? ''}')));
  }
  await playCoins(context, coinsIn(r), balanceAfter: balanceIn(r));
}

/// Shows an economy error calmly ("switching on" instead of raw errors).
void showEconomyError(BuildContext context, Object e) {
  if (!context.mounted) return;
  final text = e is EconomyException ? e.message : 'That did not go through. Try again.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: EditableLabel('reward_fx.shared', text)));
}

/// Runs a server action, then celebrates the result.
Future<Map<String, dynamic>?> runReward(BuildContext context, Future<Map<String, dynamic>> Function() action, {String? title}) async {
  try {
    final r = await action();
    if (context.mounted) await celebrate(context, r, title: title);
    return r;
  } catch (e) {
    showEconomyError(context, e);
    return null;
  }
}

/* ── confetti ── */
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.color = NwsbColors.gold, this.count = 90, this.duration = const Duration(milliseconds: 2200)});
  final Color color;
  final int count;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    final palette = [widget.color, NwsbColors.goldLight, Colors.white, widget.color.withValues(alpha: 0.7)];
    _bits = List.generate(widget.count, (i) {
      final a = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.4;
      final v = 380 + r.nextDouble() * 520;
      return _Bit(math.cos(a) * v, math.sin(a) * v, r.nextDouble() * math.pi, (r.nextDouble() - 0.5) * 14, palette[i % palette.length], 4 + r.nextDouble() * 6, r.nextBool());
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_bits, _c.value * widget.duration.inMilliseconds / 1000), size: Size.infinite),
      ),
    );
  }
}

class _Bit {
  _Bit(this.vx, this.vy, this.rot, this.spin, this.color, this.size, this.round);
  final double vx, vy, rot, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Bit> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.42);
    for (final b in bits) {
      final x = origin.dx + b.vx * t * 0.9;
      final y = origin.dy + b.vy * t + 640 * t * t;
      final fade = (1 - t / 2.2).clamp(0.0, 1.0);
      final p = Paint()..color = b.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.rot + b.spin * t);
      if (b.round) {
        canvas.drawCircle(Offset.zero, b.size / 2, p);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * 1.8), const Radius.circular(1.5)), p);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/* ── item tiles ── */
class RewardItemTile extends StatelessWidget {
  const RewardItemTile({super.key, required this.item, this.delayMs = 0});
  final Map<String, dynamic> item;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final type = '${item['type'] ?? ''}';
    final rarity = '${item['rarity'] ?? ''}';
    final mark = switch (type) {
      'coins' => null,
      'scratch' => NwsbMarks.gift,
      'percentOff' => NwsbMarks.bag,
      'pass' => NwsbMarks.word,
      'giftbox' => NwsbMarks.gift,
      'token' => NwsbMarks.stages,
      _ => NwsbMarks.word,
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delayMs),
      curve: Interval(delayMs / (520 + delayMs), 1, curve: Curves.easeOutBack),
      builder: (context, v, child) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * v, child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rarity.isEmpty ? const Color(0x33FFFFFF) : rarityColor(rarity), width: 1.2),
          boxShadow: rarity.isEmpty ? null : [BoxShadow(color: rarityColor(rarity).withValues(alpha: 0.35), blurRadius: 18)],
        ),
        child: Row(
          children: [
            if (mark == null)
              const NwsbCoinDisc(size: 34)
            else
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: NwsbIcon(mark, size: 18, color: Colors.black),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${item['label'] ?? 'Prize'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            if (rarity.isNotEmpty)
              Text(rarityTitle(rarity), style: TextStyle(color: rarityColor(rarity), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class RewardItemsSheet {
  static Future<void> show(BuildContext context, {required String title, required List<Map<String, dynamic>> items}) {
    RewardHaptics.pop();
    final party = items.any((i) => rarityParty('${i['rarity'] ?? ''}'));
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: const Color(0xC8000000),
      pageBuilder: (context, _, __) => Stack(
        children: [
          if (party) const Positioned.fill(child: ConfettiBurst(color: Color(0xFFC08BFF))),
          Center(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: GlassWrap(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EditableLabel('reward_fx.RewardItemsSheet', title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      for (var i = 0; i < items.length; i++) RewardItemTile(item: items[i], delayMs: i * 140),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const EditableLabel('reward_fx.RewardItemsSheet', 'Lovely', style: TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ── gift box / chest opening ── */
class GiftBoxOpening extends StatefulWidget {
  const GiftBoxOpening({super.key, required this.box, required this.title, required this.items, this.chest = false});
  final String box;
  final String title;
  final List<Map<String, dynamic>> items;
  final bool chest;

  static Future<void> show(BuildContext context, {required String box, required String title, required List<Map<String, dynamic>> items, bool chest = false}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xE0000000),
      pageBuilder: (context, _, __) => GiftBoxOpening(box: box, title: title, items: items, chest: chest),
    );
  }

  @override
  State<GiftBoxOpening> createState() => _GiftBoxOpeningState();
}

class _GiftBoxOpeningState extends State<GiftBoxOpening> with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _rays = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  bool _opened = false;

  Color get _tone => switch (widget.box) {
        'bronze' => const Color(0xFFCD8B54),
        'silver' => const Color(0xFFD9DDE3),
        'diamond' => const Color(0xFF9EE7FF),
        'weekly' => const Color(0xFF7FB7FF),
        'monthly' => const Color(0xFFC08BFF),
        _ => NwsbColors.gold,
      };

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (var i = 0; i < 3 && mounted; i++) {
      RewardHaptics.tick();
      await _shake.forward(from: 0);
    }
    if (!mounted) return;
    RewardHaptics.big();
    setState(() => _opened = true);
    await _open.forward();
  }

  @override
  void dispose() {
    _shake.dispose();
    _open.dispose();
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_rays, _open]),
            builder: (context, _) => Opacity(
              opacity: _open.value,
              child: Transform.rotate(angle: _rays.value * 2 * math.pi, child: CustomPaint(size: const Size(520, 520), painter: _RaysPainter(_tone))),
            ),
          ),
          if (_opened) Positioned.fill(child: ConfettiBurst(color: _tone, count: 70)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_shake, _open]),
                builder: (context, _) {
                  final s = math.sin(_shake.value * math.pi * 6) * 0.08 * (1 - _shake.value);
                  final lift = Curves.easeOutBack.transform(_open.value);
                  return Transform.rotate(
                    angle: s,
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // body
                          Container(
                            width: 140,
                            height: 104,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_tone, Color.lerp(_tone, Colors.black, 0.45)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(widget.chest ? 14 : 10),
                              boxShadow: [BoxShadow(color: _tone.withValues(alpha: 0.5 * _open.value + 0.15), blurRadius: 40)],
                            ),
                            child: Center(child: Container(width: widget.chest ? 140 : 20, height: widget.chest ? 14 : 104, color: Colors.black.withValues(alpha: 0.25))),
                          ),
                          // lid
                          Positioned(
                            bottom: 96 + 60 * lift,
                            child: Transform.rotate(
                              angle: -0.5 * lift,
                              child: Container(
                                width: 156,
                                height: 30,
                                decoration: BoxDecoration(color: Color.lerp(_tone, Colors.white, 0.2), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Container(width: widget.chest ? 30 : 20, height: 30, color: Colors.black.withValues(alpha: 0.25))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              EditableLabel('reward_fx.GiftBoxOpening', widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _opened ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        if (_opened)
                          for (var i = 0; i < widget.items.length; i++) RewardItemTile(item: widget.items[i], delayMs: 300 + i * 160),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _opened ? () => Navigator.of(context).pop() : null,
                          child: const EditableLabel('reward_fx.GiftBoxOpening', 'Collect', style: TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: size.width / 2));
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi * 2 / 14;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.09) * size.width / 2, c.dy + math.sin(a - 0.09) * size.width / 2)
        ..lineTo(c.dx + math.cos(a + 0.09) * size.width / 2, c.dy + math.sin(a + 0.09) * size.width / 2)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}

/// A calm card for when the server is not switched on yet.
class SwitchingOnCard extends StatelessWidget {
  const SwitchingOnCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: EconomyApi.switchingOn,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();
        return GlassWrap(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: const [
              NwsbIcon(NwsbMarks.word, color: NwsbColors.gold, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: EditableLabel(
                  'reward_fx.SwitchingOnCard',
                  'Rewards are switching on. Nothing was lost — coins, cards and gifts start counting as soon as it is live.',
                  style: TextStyle(color: NwsbColors.mist, height: 1.35, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
