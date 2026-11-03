/// R27 — the four new home sections. Each has a NORMAL variant (white
/// neumorphic frame, greeting head, dark poster cards) and a FASHION variant
/// (`fashion: true`: full black, giant poster word bleeding off the edge).
/// Every card row auto-rotates; every tap is a required hook.
library;

import '../../../screens/concept/drop_v5.dart' show CornerPeel;
import 'package:flutter/material.dart';
import '../../../features/economy/money.dart' show FxBook;

import '../../../features/economy/reward_fx.dart' show rarityColor, rarityTitle;
import 'anims.dart';
import 'data.dart';
import 'kit.dart';
import '../normal/surface.dart';

String _shortDate(int ms) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day} ${m[d.month - 1]}';
}

String _n(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// Shared outer shell: normal = neumorphic frame, fashion = black band.
class _Shell extends StatelessWidget {
  const _Shell({required this.fashion, required this.head, required this.row, required this.links, this.poster});
  final bool fashion;
  final Widget head, row;
  final List<Widget> links;
  final Widget? poster;
  @override
  Widget build(BuildContext context) {
    if (!fashion) {
      return R27NeuFrame(
          child: R27Tone(light: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(right: 18), child: head),
        const SizedBox(height: 16),
        ClipRect(child: row),
        const SizedBox(height: 4),
        ...links,
      ])));
    }
    return ColoredBox(
      color: r27Black,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (poster != null) poster!,
          row,
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: head),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: links)),
        ]),
      ),
    );
  }
}

// ══ EARN — rising rank steps, spinning coin ═══════════════════════════════
class R27EarnSection extends StatelessWidget {
  const R27EarnSection({super.key, required this.data, required this.onOpen, required this.onRank, this.fashion = false});
  final R27Earn data;
  final VoidCallback onOpen;
  final void Function(int index) onRank;
  final bool fashion;
  @override
  Widget build(BuildContext context) {
    final cur = data.current;
    final next = cur + 1 < data.ranks.length ? data.ranks[cur + 1] : null;
    final h = r27H(context, fashion ? 250 : 220, 56);
    return _Shell(
      fashion: fashion,
      poster: fashion
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: SizedBox(height: 84, child: R27Word('${_n(data.topRate)}%', color: r27Gold, outline: true))),
                const R27Coin(size: 64),
              ]))
          : null,
      head: fashion ? _earnHead(true, next) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _earnHead(false, next)), const R27Coin(size: 56)]),
      row: R27AutoRow(
        count: data.ranks.length,
        height: h,
        fraction: fashion ? .5 : .46,
        initial: cur,
        every: const Duration(milliseconds: 2800),
        builder: (c, i, off) => R27RankStep(data.ranks[i], index: i, top: data.topRate, current: i == cur, offset: off, onTap: () => onRank(i)),
      ),
      links: [R27Link('Open NowssB Earn', dark: fashion, onTap: onOpen)],
    );
  }

  Widget _earnHead(bool dark, R27Rank? next) => R27Head(
        dark: dark,
        hello: 'NowssB Earn',
        title: '${_n(data.shownRate)}% on net',
        sub: 'Commission on net. Two levels. ${data.wordsSold} words sold'
            '${next == null ? ' · top rank' : ' · ${next.title} at ${next.minWords}'}',
      );
}

class R27RankStep extends StatelessWidget {
  const R27RankStep(this.r, {super.key, required this.index, required this.top, required this.current, required this.onTap, this.offset = 0});
  final R27Rank r;
  final int index;
  final num top;
  final bool current;
  final VoidCallback onTap;
  final double offset;
  @override
  Widget build(BuildContext context) {
    final rise = 1 - .3 * offset.abs().clamp(0.0, 1.0);
    final f = top <= 0 ? .4 : (.3 + .45 * (r.ratePct / top)) * rise;
    final light = R27Tone.isLight(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: NPress(
        onTap: onTap,
        label: '${r.title} ${_n(r.ratePct)} percent',
        child: Container(
          foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: current ? r27Gold : (light ? const Color(0x1F000000) : r27Line), width: current ? 2 : 1)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(fit: StackFit.expand, children: [
              if (light) const ColoredBox(color: r27LCard) else ...[R27Img(r27Hours[(index + 5) % r27Hours.length]), const ColoredBox(color: Color(0x99000000))],
              LayoutBuilder(
                  // B029: the name keeps its natural height; the bar takes
                  // f of the step but yields to it (no overflow at top rank).
                  builder: (c, box) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.end, children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            if (current) ...[const R27TagLabel('You'), const SizedBox(height: 8)],
                            Text(r.title, style: dSub.copyWith(color: light ? r27LInk : Colors.white, fontWeight: FontWeight.w800)),
                            Text('${r.minWords}+ words', style: light ? dSub.copyWith(color: r27LSub) : dSub),
                          ]),
                        ),
                        Flexible(
                            child: SizedBox(
                          height: box.maxHeight * f,
                          child: ClipPath(
                            clipper: R27Torn(seed: index + 4, bottom: false, depth: 6),
                            child: ColoredBox(
                              color: light ? (current ? const Color(0xFFF7F8FB) : const Color(0xFFE6E9F0)) : (current ? r27Gold : r27Paper),
                              child: Padding(padding: const EdgeInsets.fromLTRB(10, 12, 10, 8), child: R27Word('${_n(r.ratePct)}%', color: r27PaperInk, shadow: false, align: Alignment.bottomLeft)),
                            ),
                          ),
                        )),
                      ])),
            ]),
          ),
        ),
      ),
    );
  }
}
