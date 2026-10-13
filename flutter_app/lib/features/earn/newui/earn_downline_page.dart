import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart';
import 'earn_backdrop.dart';
import 'earn_motion.dart';
import 'earn_view_data.dart';

/// "Your team" (spec 14/15: downline tree, capped at 2 levels, pinch to zoom,
/// tap a node for stats; motion idea: a tree of light with pulsing nodes).
///
/// Honest data only: people come from the server's `earnSummary.team`.
/// The server does not yet say which level-1 person brought each level-2
/// person, so level 2 sits on its own outer ring instead of guessed links.
class EarnDownlinePage extends StatelessWidget {
  const EarnDownlinePage({super.key, required this.data});
  final EarnViewData data;

  @override
  Widget build(BuildContext context) {
    final l1 = data.team.where((m) => m.level == 1).toList();
    final l2 = data.team.where((m) => m.level == 2).toList();
    return Scaffold(
      backgroundColor: NTokens.bgBottom,
      appBar: const GlassTopBar(title: 'Your team'),
      extendBodyBehindAppBar: true,
      body: EarnBackdrop(
        child: SafeArea(
          child: data.team.isEmpty
              ? const Center(
                  key: Key('earn-team-empty'),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: GlassStateCard(
                      icon: Icons.account_tree_rounded,
                      title: 'No team yet',
                      message: 'When someone joins through you, they show up here.',
                    ),
                  ),
                )
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text('${l1.length} direct · ${l2.length} through your team',
                        key: const Key('earn-team-counts'), style: const TextStyle(color: NTokens.textLo)),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 0.6,
                      maxScale: 3,
                      boundaryMargin: const EdgeInsets.all(200),
                      child: LayoutBuilder(builder: (context, c) => _Tree(size: c.biggest, l1: l1, l2: l2)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text('Pinch to zoom. Tap a person to see their progress.',
                        textAlign: TextAlign.center, style: TextStyle(color: NTokens.textLo, fontSize: 12)),
                  ),
                ]),
        ),
      ),
    );
  }
}

class _Tree extends StatefulWidget {
  const _Tree({required this.size, required this.l1, required this.l2});
  final Size size;
  final List<EarnTeamMember> l1;
  final List<EarnTeamMember> l2;

  @override
  State<_Tree> createState() => _TreeState();
}

class _TreeState extends State<_Tree> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (earnStill(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  List<Offset> _ring(Offset c, double r, int n, double phase) =>
      [for (var i = 0; i < n; i++) c + Offset.fromDirection(-math.pi / 2 + phase + 2 * math.pi * i / math.max(1, n), r)];

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final c = Offset(s.width / 2, s.height / 2);
    final r1 = s.shortestSide * 0.24, r2 = s.shortestSide * 0.42;
    final p1 = _ring(c, r1, widget.l1.length, 0);
    final p2 = _ring(c, r2, widget.l2.length, math.pi / math.max(1, widget.l2.length));
    final still = earnStill(context);
    // Branches grow in once (skipped under reduced motion).
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, grow, _) => Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => CustomPaint(painter: _BranchPainter(c, p1, p2, grow, _pulse.value)),
            ),
          ),
        ),
        _node(context, c, null, 56, grow),
        for (var i = 0; i < p1.length; i++) _node(context, p1[i], widget.l1[i], 44, grow),
        for (var i = 0; i < p2.length; i++) _node(context, p2[i], widget.l2[i], 32, grow),
      ]),
    );
  }

  Widget _node(BuildContext context, Offset at, EarnTeamMember? m, double d, double grow) {
    final color = m == null ? NTokens.gold : (m.level == 1 ? NTokens.violet : NTokens.mint);
    final label = m == null ? 'You' : m.name;
    return Positioned(
      left: at.dx - d / 2,
      top: at.dy - d / 2,
      child: Opacity(
        opacity: grow,
        child: Semantics(
          button: m != null,
          label: m == null ? 'You' : '${m.name}, level ${m.level}',
          child: GestureDetector(
            key: Key(m == null ? 'earn-node-you' : 'earn-node-${m.id}'),
            onTap: m == null ? null : () => _showMember(context, m),
            child: Container(
              width: d,
              height: d,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  colors: [Color.lerp(color, Colors.white, 0.5)!, color, Color.lerp(color, Colors.black, 0.4)!],
                ),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14)],
              ),
              child: Text(label.isEmpty ? '?' : label.characters.first.toUpperCase(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: d * 0.36)),
            ),
          ),
        ),
      ),
    );
  }

  void _showMember(BuildContext context, EarnTeamMember m) {
    showGlassSheet<void>(
      context,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        StatPanel(rows: [
          (Icons.workspace_premium_rounded, 'Rank', m.rank.isEmpty ? '—' : m.rank),
          (Icons.auto_awesome_rounded, 'Words sold', '${m.words}'),
          (Icons.account_tree_rounded, 'Level', m.level == 1 ? 'Direct (1)' : 'Through your team (2)'),
        ]),
      ]),
    );
  }
}

class _BranchPainter extends CustomPainter {
  _BranchPainter(this.c, this.p1, this.p2, this.grow, this.t);
  final Offset c;
  final List<Offset> p1, p2;
  final double grow, t;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = NTokens.violet.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (final p in p1) {
      canvas.drawLine(c, Offset.lerp(c, p, grow)!, glow);
      // A bead of light travelling outward along each branch.
      final b = Offset.lerp(c, p, (t * grow) % 1)!;
      canvas.drawCircle(b, 3, Paint()..color = Colors.white.withValues(alpha: 0.7));
    }
    // Level 2: soft dotted ring (no guessed parent links).
    if (p2.isNotEmpty) {
      final r = (p2.first - c).distance;
      final dot = Paint()..color = NTokens.mint.withValues(alpha: 0.35 * grow);
      for (var a = 0.0; a < 2 * math.pi; a += math.pi / 40) {
        canvas.drawCircle(c + Offset.fromDirection(a, r), 1.2, dot);
      }
    }
    // Pulse ring around "You".
    canvas.drawCircle(
      c,
      30 + 20 * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = NTokens.gold.withValues(alpha: 0.4 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_BranchPainter o) => o.t != t || o.grow != grow;
}
