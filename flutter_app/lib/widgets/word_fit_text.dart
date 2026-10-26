import 'package:flutter/widgets.dart';

/// Text that wraps only on word boundaries (B022). If the longest word is
/// wider than the box, the font is scaled down until it fits, so no word is
/// ever broken letter by letter and nothing is ellipsised.
class WordFitText extends StatelessWidget {
  const WordFitText(this.text, {super.key, required this.style, this.maxLines = 2, this.textAlign = TextAlign.start});

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final base = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(builder: (context, cs) {
      var k = 1.0;
      if (cs.hasBoundedWidth) {
        final dir = Directionality.of(context);
        bool fits(double k) {
          final s = base.copyWith(fontSize: (base.fontSize ?? 14) * k);
          for (final w in text.split(RegExp(r'\s+'))) {
            final tp = TextPainter(text: TextSpan(text: w, style: s), textDirection: dir, textScaler: scaler, maxLines: 1)..layout();
            if (tp.width > cs.maxWidth) return false;
          }
          final all = TextPainter(text: TextSpan(text: text, style: s), textDirection: dir, textScaler: scaler, maxLines: maxLines)
            ..layout(maxWidth: cs.maxWidth);
          return !all.didExceedMaxLines;
        }
        while (k > 0.4 && !fits(k)) {
          k -= 0.05;
        }
      }
      return Text(text,
          maxLines: maxLines,
          softWrap: true,
          textAlign: textAlign,
          style: style.copyWith(fontSize: (base.fontSize ?? 14) * k));
    });
  }
}
