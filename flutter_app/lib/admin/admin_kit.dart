/// The admin console's building blocks, in the app's own Fashion look:
/// the film behind frosted glass, gold for actions, thinking orbs while
/// loading, eyebrow + heading on every section, simple charts drawn here
/// (no chart package). Admin-only — none of this reaches a member's screen.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'admin_api.dart';
import 'editor/glass.dart';

export 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart' show ThinkingOrb, OrbState, OrbTheme;
export 'editor/glass.dart' show Glass, Pill, Eyebrow, PillSwitch, LabeledSlider, Hint, kGold, kMint, kInk, kDim, kFaint, kGlassEdge, kGlassFill, tapFeel, actFeel, bigFeel, AdminBackdrop, confirmAction;

const kRose = Color(0xFFFF7A90);
const kSky = Color(0xFF7CC4FF);
const kViolet = Color(0xFFB79CFF);
const kAmber = Color(0xFFFFC46B);

ThemeData adminTheme() => ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(primary: kGold, secondary: kGold, surface: Color(0xFF0E1522)),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF111A2B)),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF0C1220)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        labelStyle: const TextStyle(color: kDim),
        hintStyle: const TextStyle(color: kFaint),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0x22FFFFFF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGold)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

/// Push a console page with a soft fade + rise.
Future<T?> pushAdmin<T>(BuildContext context, Widget page) {
  tapFeel();
  return Navigator.of(context).push<T>(PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(c), child: child),
      );
    },
  ));
}

/// Marks a subtree as a tab body of the Admin app (admin_app.dart).
class AdminTabScope extends InheritedWidget {
  const AdminTabScope({super.key, required super.child});
  static bool inTab(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AdminTabScope>() != null;
  @override
  bool updateShouldNotify(AdminTabScope oldWidget) => false;
}

/// A console page: film backdrop, back arrow, eyebrow + title, actions.
/// Inside an Admin app tab ([AdminTabScope]) it drops the back arrow and
/// the film, which the Admin shell already provides.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.body,
    this.actions = const [],
    this.fab,
    this.bottom,
    this.dim = 0.55,
  });

  final String title;
  final String eyebrow;
  final Widget body;
  final List<Widget> actions;
  final Widget? fab;
  final Widget? bottom;
  final double dim;

  @override
  Widget build(BuildContext context) {
    if (AdminTabScope.inTab(context)) {
      // A tab of the Admin app: its shell already draws the film, the app bar
      // and the bottom bar — this page brings its heading, actions and body.
      return Theme(
        data: adminTheme(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: fab,
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 8, 2),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(eyebrow.toUpperCase(),
                        style: const TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ]),
                ),
                ...actions,
              ]),
            ),
            if (bottom != null) bottom!,
            Expanded(child: body),
          ]),
        ),
      );
    }
    final top = MediaQuery.of(context).padding.top;
    return Theme(
      data: adminTheme(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          floatingActionButton: fab,
          body: AdminBackdrop(
            dim: dim,
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4, top + 4, 8, 4),
                child: Row(children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(eyebrow.toUpperCase(),
                          style: const TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    ]),
                  ),
                  ...actions,
                ]),
              ),
              if (bottom != null) bottom!,
              Expanded(child: body),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Thinking orb + a line, while something real loads.
class OrbLoading extends StatelessWidget {
  const OrbLoading({super.key, this.label = 'Loading…', this.state = OrbState.searching, this.size = 64});
  final String label;
  final OrbState state;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: size + 18,
            height: size + 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.22), blurRadius: 30)],
            ),
            child: ThinkingOrb(state: state, size: size, theme: OrbTheme.dark),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: kDim, fontSize: 12.5)),
        ]),
      );
}

/// A clear, honest message: what failed and, for a missing secret, which one.
class AdminProblem extends StatelessWidget {
  const AdminProblem({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error is AdminApiException ? error as AdminApiException : null;
    final missing = e?.missing ?? const <String>[];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Glass(
          radius: 22,
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(e?.notConfigured == true ? Icons.key_off_rounded : Icons.cloud_off_rounded, color: kAmber, size: 34),
            const SizedBox(height: 10),
            Text(e?.notConfigured == true ? 'A server secret is missing' : 'That did not load',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: kDim, fontSize: 12.5, height: 1.35)),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                for (final m in missing) Tag(m, color: kAmber),
              ]),
              const SizedBox(height: 8),
              const Text('Cloudflare Pages → nowssb → Settings → Variables and secrets → Production',
                  textAlign: TextAlign.center, style: TextStyle(color: kFaint, fontSize: 11)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              Pill('Try again', icon: Icons.refresh_rounded, selected: true, onTap: onRetry),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Banner listing missing server variables (names only).
class MissingSecrets extends StatelessWidget {
  const MissingSecrets(this.names, {super.key, this.what = 'Some parts are off until these are set in Cloudflare (Production):'});
  final List<String> names;
  final String what;
  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(12),
        edge: kAmber.withValues(alpha: 0.5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.key_rounded, color: kAmber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(what, style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final n in names) Tag(n, color: kAmber)]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = kGold, this.icon});
  final String text;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 11, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
        ]),
      );
}

/// Eyebrow + heading for a block inside a page.
class SectionHead extends StatelessWidget {
  const SectionHead(this.eyebrow, this.title, {super.key, this.trailing});
  final String eyebrow;
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eyebrow.toUpperCase(), style: const TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// A number that matters, with what it means.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.sub, this.icon, this.color = kGold, this.onTap});
  final String label;
  final String value;
  final String? sub;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Glass(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            if (icon != null)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 15),
              ),
            const Spacer(),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: kFaint, size: 18),
          ]),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (_, s, child) => Transform.scale(scale: s, alignment: Alignment.centerLeft, child: child),
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11.5, fontWeight: FontWeight.w600)),
          if (sub != null && sub!.isNotEmpty)
            Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kFaint, fontSize: 10.5)),
        ]),
      );
}

/// Two-up grid of tiles that sizes to its content.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.columns = 2});
  final List<Widget> children;
  final int columns;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: 10),
              Expanded(child: i + j < children.length ? children[i + j] : const SizedBox()),
            ],
          ]),
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// Bars for a series (e.g. sign-ups per day). Animated in.
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, this.labels = const [], this.height = 150, this.color = kGold});
  final List<num> values;
  final List<String> labels;
  final double height;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 0 : values.reduce(math.max);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        height: height,
        child: CustomPaint(
          painter: _BarsPainter(values: values, maxV: maxV.toDouble(), t: t, color: color, labels: labels),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.values, required this.maxV, required this.t, required this.color, required this.labels});
  final List<num> values;
  final double maxV;
  final double t;
  final Color color;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height - 16;
    final grid = Paint()..color = const Color(0x18FFFFFF)..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = bottom - bottom * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final n = values.length;
    final w = size.width / n;
    for (var i = 0; i < n; i++) {
      final v = values[i].toDouble();
      final h = maxV <= 0 ? 0.0 : (v / maxV) * (bottom - 8) * t;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(i * w + w * 0.18, bottom - h, w * 0.64, math.max(h, v > 0 ? 2 : 0)), const Radius.circular(3));
      canvas.drawRRect(
          r,
          Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withValues(alpha: 0.35)])
                .createShader(r.outerRect));
    }
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String s, double x) {
      tp.text = TextSpan(text: s, style: const TextStyle(color: kFaint, fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset((x - tp.width / 2).clamp(0, size.width - tp.width), bottom + 4));
    }
    if (labels.length == n && n > 1) {
      label(labels.first, w / 2);
      label(labels[n ~/ 2], (n ~/ 2) * w + w / 2);
      label(labels.last, (n - 1) * w + w / 2);
    }
    tp.text = TextSpan(text: maxV.toStringAsFixed(0), style: const TextStyle(color: kFaint, fontSize: 9));
    tp.layout();
    tp.paint(canvas, const Offset(0, 0));
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.t != t || old.values != values;
}

/// A ring split into parts (e.g. subscribers by plan).
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.parts, this.size = 120, this.center});
  final List<(String, num, Color)> parts;
  final double size;
  final Widget? center;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _DonutPainter(parts, t), child: Center(child: center)),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.parts, this.t);
  final List<(String, num, Color)> parts;
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.14;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()..color = const Color(0x18FFFFFF)..style = PaintingStyle.stroke..strokeWidth = stroke);
    final total = parts.fold<num>(0, (s, p) => s + p.$2);
    if (total <= 0) return;
    var a = -math.pi / 2;
    for (final p in parts) {
      final sweep = (p.$2 / total) * math.pi * 2 * t;
      if (sweep <= 0) continue;
      canvas.drawArc(r, a, math.max(0, sweep - 0.04), false,
          Paint()..color = p.$3..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
      a += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.t != t || old.parts != parts;
}

/// Horizontal share bar with a label and a number.
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.label, required this.value, required this.total, this.color = kGold});
  final String label;
  final num value;
  final num total;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final f = total <= 0 ? 0.0 : (value / total).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
          Text(fmtNum(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: f),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, color: color, backgroundColor: const Color(0x18FFFFFF)),
          ),
        ),
      ]),
    );
  }
}

/// Gold primary button.
class GoldButton extends StatelessWidget {
  const GoldButton(this.label, {super.key, this.icon, this.onTap, this.busy = false, this.color = kGold});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool busy;
  final Color color;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: kInk,
          disabledBackgroundColor: color.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: busy || onTap == null
            ? null
            : () {
                actFeel();
                onTap!();
              },
        icon: busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kInk))
            : Icon(icon ?? Icons.check_rounded, size: 18),
        label: Text(label),
      );
}

void adminSnack(BuildContext context, String msg, {bool error = false}) {
  if (error) {
    HapticFeedback.heavyImpact();
  } else {
    HapticFeedback.lightImpact();
  }
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? const Color(0xFF5A1E28) : const Color(0xFF1C2638),
    content: Text(msg, style: const TextStyle(color: Colors.white)),
  ));
}

/// Runs a server action with a snack for the outcome. Returns the result or null.
Future<Map<String, dynamic>?> runAdmin(BuildContext context, String action, Map<String, dynamic> body, {String? ok}) async {
  try {
    final r = await AdminApi.call(action, body);
    if (context.mounted) {
      final warn = '${r['warning'] ?? ''}';
      adminSnack(context, warn.isNotEmpty ? '${ok ?? 'Done.'} $warn' : (ok ?? 'Done.'));
    }
    return r;
  } on AdminApiException catch (e) {
    if (context.mounted) {
      adminSnack(context, e.missing.isEmpty ? e.message : '${e.message} Missing: ${e.missing.join(', ')}', error: true);
    }
    return null;
  }
}

/// Asks for a reason (and optional confirmation copy). Null = cancelled.
Future<String?> askReason(BuildContext context, String title, {String hint = 'Reason (kept in the audit log)', bool required = true, String yes = 'Confirm'}) async {
  final c = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => Theme(
      data: adminTheme(),
      child: AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(controller: c, autofocus: true, maxLines: 3, minLines: 1, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk),
            onPressed: () {
              if (required && c.text.trim().isEmpty) return;
              Navigator.pop(ctx, c.text.trim());
            },
            child: Text(yes),
          ),
        ],
      ),
    ),
  );
  c.dispose();
  return r;
}

String fmtNum(num? v) {
  if (v == null) return '—';
  final n = v.round();
  if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n.abs() >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

int msOf(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is DateTime) return v.millisecondsSinceEpoch;
  try {
    final d = (v as dynamic).toDate();
    if (d is DateTime) return d.millisecondsSinceEpoch;
  } catch (_) {}
  final p = DateTime.tryParse('$v');
  return p?.millisecondsSinceEpoch ?? (int.tryParse('$v') ?? 0);
}

String fmtDate(dynamic v, {bool time = false}) {
  final ms = msOf(v);
  if (ms <= 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final base = '${d.day} ${m[d.month - 1]} ${d.year}';
  if (!time) return base;
  return '$base, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String fmtAgo(dynamic v) {
  final ms = msOf(v);
  if (ms <= 0) return 'never';
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return fmtDate(ms);
}

String usd(num cents) => '\$${(cents / 100).toStringAsFixed(2)}';

const kTierNames = {'resonance': 'Resonance', 'frequency': 'Frequency', 'frequencyX': 'Frequency X'};
const kTierColors = {'resonance': kSky, 'frequency': kGold, 'frequencyX': kViolet};

/// Round avatar from a photo URL or initials.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.photo = '', this.size = 40, this.online = false});
  final String name;
  final String photo;
  final double size;
  final bool online;
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1B2436), border: Border.all(color: kGold.withValues(alpha: 0.4))),
        alignment: Alignment.center,
        child: photo.startsWith('http')
            ? Image.network(photo, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(initials, style: TextStyle(color: kGold, fontWeight: FontWeight.w800, fontSize: size * 0.36)))
            : Text(initials, style: TextStyle(color: kGold, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
      ),
      if (online)
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(color: kMint, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
          ),
        ),
    ]);
  }
}

/// Key → value line inside a glass card.
class KV extends StatelessWidget {
  const KV(this.k, this.v, {super.key, this.color = Colors.white, this.selectable = false});
  final String k;
  final String v;
  final Color color;
  final bool selectable;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 118, child: Text(k, style: const TextStyle(color: kDim, fontSize: 12))),
          Expanded(
            child: selectable
                ? SelectableText(v.isEmpty ? '—' : v, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600))
                : Text(v.isEmpty ? '—' : v, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

/// Empty state with a reason, never a fake number.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.icon = Icons.inbox_rounded});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(children: [
          Icon(icon, color: kFaint, size: 28),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kDim, fontSize: 12.5)),
        ]),
      );
}
