/// Home quotes section (Oct 23 rebuild).
///
/// Card 1, "Daily Quote": black poster, the Buddha on the right, and a
/// swipeable column of bold condensed type on the left. Today's quote first;
/// swipe back through this week. Quotes live in `data/daily_quotes.dart`.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_wrap.dart';
import 'neumorphic.dart';
import '../admin/template/editable.dart';
import '../data/daily_quotes.dart';
import '../data/quotes_remote.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');
const _slot = 'buddha_gyro_stage.BuddhaGyroStage';
const _gold = Color(0xFFE8D5A3);

TextStyle _poster(double size, Color color) {
  final base = TextStyle(
    fontSize: size,
    color: color,
    height: 1.02,
    letterSpacing: 0.3,
    fontWeight: FontWeight.w400,
  );
  return base.copyWith(fontFamily: 'Anton');
}

TextStyle _serif(double size, Color color, {FontStyle? style}) {
  final base = TextStyle(
    fontSize: size,
    color: color,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontStyle: style,
  );
  return base.copyWith(fontFamily: 'CormorantGaramond');
}

const _wd = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _mo = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

String _dateLabel(DateTime d) => '${_wd[d.weekday - 1]} ${d.day} ${_mo[d.month - 1]}';

String _timeLabel(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

class BuddhaGyroStage extends StatelessWidget {
  const BuddhaGyroStage({super.key, this.neumorphic = false, this.onOpenQuotes, this.now});

  final bool neumorphic;
  final VoidCallback? onOpenQuotes;

  /// Fixed clock for tests and renders.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final ink = neumorphic ? const Color(0xFF2B2D33) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: EditableLabel(_slot, "Today's Quotes",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: ink)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _shell(DailyQuoteCard(now: now, onOpen: onOpenQuotes), radius: 20),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _shell(Widget child, {required double radius}) {
    if (neumorphic) {
      return NeuCard(padding: const EdgeInsets.all(6), radius: radius, child: child);
    }
    return GlassWrap(margin: EdgeInsets.zero, radius: radius, padding: const EdgeInsets.all(6), child: child);
  }
}

// ───────────────────────────── Card 1 ─────────────────────────────

class DailyQuoteCard extends StatefulWidget {
  const DailyQuoteCard({super.key, this.now, this.onOpen});
  final DateTime? now;
  final VoidCallback? onOpen;

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  final _pager = PageController();
  Timer? _clock;
  late DateTime _now = widget.now ?? DateTime.now();
  var _page = 0;

  @override
  void initState() {
    super.initState();
    QuoteStore.instance.addListener(_changed);
    if (widget.now == null && !_flutterTest) {
      _clock = Timer.periodic(const Duration(seconds: 30), (_) => _changed());
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() => _now = widget.now ?? DateTime.now());
  }

  @override
  void dispose() {
    QuoteStore.instance.removeListener(_changed);
    _clock?.cancel();
    _pager.dispose();
    super.dispose();
  }

  String _override(DateTime d) {
    final store = QuoteStore.instance;
    final today = DateTime(_now.year, _now.month, _now.day);
    if (d == today && store.live.trim().isNotEmpty) return store.live;
    return store.byDate[quoteDayKey(d)] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final week = weekQuotes(_now, override: _override);
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = (w * 1.18).clamp(400.0, 480.0);
      return SizedBox(
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Figure: right-anchored, full height. Changes with the page.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Align(
                    key: ValueKey(week[_page].background),
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      height: h,
                      width: math.min(w * 0.62, h * 844 / 1500),
                      child: EditableImage.asset(week[_page].background,
                          fit: BoxFit.cover, alignment: Alignment.centerRight,
                          filterQuality: FilterQuality.high, slot: _slot),
                    ),
                  ),
                ),
                // Black falls off left-to-right so type sits on clean black.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.black, Color(0x00000000)],
                      stops: [0, 0.42, 0.72],
                    ),
                  ),
                ),
                PageView.builder(
                  controller: _pager,
                  itemCount: week.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: widget.onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 58, w * 0.42, 40),
                      child: _QuotePoster(quote: week[i].quote, variant: i == 0
                          ? quoteIndexFor(week[i].day) % 4
                          : (quoteIndexFor(week[i].day) + i) % 4),
                    ),
                  ),
                ),
                // Kept inside the black text column so it never touches the figure.
                Positioned(
                  left: 16,
                  top: 16,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: w * 0.56 - 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _pill(week[_page], _page == 0),
                    ),
                  ),
                ),
                Positioned(left: 20, bottom: 16, child: _dots(week.length)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _pill(DatedQuote q, bool today) {
    final text = today
        ? 'TODAY  ·  ${_dateLabel(q.day)}  ·  ${_timeLabel(_now)}'
        : '${_page == 1 ? 'YESTERDAY' : 'THIS WEEK'}  ·  ${_dateLabel(q.day)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: _gold, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
    );
  }

  Widget _dots(int n) => Row(
        children: [
          for (var i = 0; i < n; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 5),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page ? Colors.white : const Color(0x55FFFFFF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      );
}

/// Poster type that always fits its box: tries big, shrinks until it fits.
class _QuotePoster extends StatelessWidget {
  const _QuotePoster({required this.quote, required this.variant});
  final DailyQuote quote;
  final int variant;

  List<InlineSpan> _spans(double base) {
    final text = quote.text.toUpperCase();
    final emph = quote.emphasis?.toUpperCase();
    final accent = variant.isEven ? Colors.white : _gold;
    final body = variant.isEven ? const Color(0xFFEDEDED) : Colors.white;
    final ratio = const [2.3, 1.9, 2.1, 1.7][variant];
    final at = emph == null ? -1 : text.indexOf(emph);
    if (at < 0) return [TextSpan(text: text, style: _poster(base, body))];
    final before = text.substring(0, at).trimRight();
    final after = text.substring(at + emph!.length).trimLeft();
    // Variants 1 and 3 give the key word its own line.
    final own = variant.isOdd;
    return [
      if (before.isNotEmpty) TextSpan(text: own ? '$before\n' : '$before ', style: _poster(base, body)),
      TextSpan(text: emph, style: _poster(base * ratio, accent)),
      if (after.isNotEmpty)
        TextSpan(text: own ? '\n$after' : ' $after', style: _poster(base, body)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final scale = MediaQuery.textScalerOf(context);
      var base = 34.0;
      late TextSpan span;
      while (true) {
        span = TextSpan(children: _spans(base));
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr, textScaler: scale)
          ..layout(maxWidth: c.maxWidth);
        var fits = tp.height <= c.maxHeight;
        tp.dispose();
        // Never break a word mid-way: each word must fit on one line.
        if (fits) {
          for (final s in span.children!.whereType<TextSpan>()) {
            for (final word in s.text!.split(RegExp(r'\s+'))) {
              final wp = TextPainter(
                  text: TextSpan(text: word, style: s.style),
                  textDirection: TextDirection.ltr,
                  textScaler: scale)
                ..layout();
              final wide = wp.width > c.maxWidth;
              wp.dispose();
              if (wide) {
                fits = false;
                break;
              }
            }
            if (!fits) break;
          }
        }
        if (fits || base <= 9) break;
        base -= 1;
      }
      return Align(
        alignment: const [Alignment.topLeft, Alignment.centerLeft, Alignment.bottomLeft, Alignment.centerLeft][variant],
        child: Text.rich(span, textScaler: scale),
      );
    });
  }
}

