/// Glass card under the bell. The bell still opens the original sheet.
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/notifications.dart';
import '../data/phone_notifications.dart';
import '../features/notifications/notif_router.dart';
import '../screens/quotes_live.dart';
import '../screens/splash.dart';
import '../theme/liquid_glass_theme.dart';

class NotificationPopupHost extends StatefulWidget {
  const NotificationPopupHost({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationPopupHost> createState() => _NotificationPopupHostState();
}

class _NotificationPopupHostState extends State<NotificationPopupHost> {
  Timer? _hide;
  Object? _token;
  var _hold = false;

  @override
  void initState() {
    super.initState();
    NwsbEffects.instance.bind();
    NotificationBanner.items.addListener(_on);
    NotificationBanner.showPopups.addListener(_on);
    NotifStore.instance.addListener(_on);
    SplashGate.done.addListener(_on);
    DailyQuoteGate.done.addListener(_on);
  }

  @override
  void dispose() {
    _hide?.cancel();
    NotificationBanner.items.removeListener(_on);
    NotificationBanner.showPopups.removeListener(_on);
    NotifStore.instance.removeListener(_on);
    SplashGate.done.removeListener(_on);
    DailyQuoteGate.done.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  static String _id(NotifItem e) => '${e.type}|${e.at}|${e.title}';

  List<NotifItem> _items() {
    if (!SplashGate.done.value || !DailyQuoteGate.done.value || !NotificationBanner.showPopups.value) {
      return const [];
    }
    final unread = NotifStore.instance.feed.where((e) => !e.read).toList();
    if (unread.isEmpty) return const [];
    unread.sort((a, b) {
      if (a.type == 'coins' && b.type != 'coins') return -1;
      if (b.type == 'coins' && a.type != 'coins') return 1;
      return b.at.compareTo(a.at);
    });
    return unread.take(5).toList();
  }

  void _arm(List<NotifItem> items) {
    final token = Object.hashAll(items.map(_id));
    if (token == _token) return;
    _token = token;
    _hold = false;
    _hide?.cancel();
    // One-by-one entrance, then the whole list stays for 4 seconds.
    final enter = 420 * items.length;
    _hide = Timer(Duration(milliseconds: enter + 4000), () {
      if (mounted) setState(() => _hold = true);
    });
  }

  void _dismiss() {
    _hide?.cancel();
    if (mounted) setState(() => _hold = true);
  }

  void _open(NotifItem item) {
    _hide?.cancel();
    setState(() => _hold = true);
    NotificationBanner.dismiss(item);
    NotifRouter.instance.openItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final items = _hold ? const <NotifItem>[] : _items();
    if (items.isNotEmpty) _arm(items);
    final top = MediaQuery.paddingOf(context).top + 78;
    const tailRight = 149.0 - 12 - 8;
    return Stack(
      children: [
        widget.child,
        if (items.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            top: top,
            child: _GlanceStack(
              items: items,
              tailRight: tailRight,
              onOpen: _open,
              onClose: _dismiss,
            ),
          ),
      ],
    );
  }
}

class _GlanceStack extends StatefulWidget {
  const _GlanceStack({
    required this.items,
    required this.tailRight,
    required this.onOpen,
    required this.onClose,
  });
  final List<NotifItem> items;
  final double tailRight;
  final void Function(NotifItem item) onOpen;
  final VoidCallback onClose;

  @override
  State<_GlanceStack> createState() => _GlanceStackState();
}

class _GlanceStackState extends State<_GlanceStack> {
  var _visible = 1;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 420), (t) {
      if (!mounted) return;
      if (_visible >= widget.items.length) {
        t.cancel();
        return;
      }
      setState(() => _visible++);
    });
  }

  @override
  void didUpdateWidget(covariant _GlanceStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      _visible = 1;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.items.take(_visible).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: widget.tailRight),
          child: CustomPaint(size: const Size(16, 9), painter: _TailPainter()),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF2101014),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 2, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'NOWSSB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < shown.length; i++) ...[
                        _Arrive(child: _BlackPill(item: shown[i], onTap: () => widget.onOpen(shown[i]))),
                        if (i != shown.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Arrive extends StatelessWidget {
  const _Arrive({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: child,
    );
  }
}

class _BlackPill extends StatelessWidget {
  const _BlackPill({required this.item, required this.onTap});
  final NotifItem item;
  final VoidCallback onTap;

  String get _category {
    final label = NotifStore.instance.labelOf(item.type);
    if (label.isNotEmpty && label != item.type) return label;
    return 'NowssB';
  }

  @override
  Widget build(BuildContext context) {
    final thumb = switch (item.type) {
      'coins' || 'rewards' => 'assets/rails/rewards-coins.png',
      'gifts' => 'assets/rails/gifts-02.jpg',
      'spin' => 'assets/rails/art-spin.jpg',
      'update' => 'assets/rails/art-coins.jpg',
      _ => null,
    };
    const ink = TextStyle(decoration: TextDecoration.none, color: Colors.white);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF0000000),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2D2D),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ink.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ink.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ink.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.25, color: const Color(0xE6FFFFFF)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: const Color(0xFF1A1A1E),
                  child: thumb != null
                      ? Image.asset(thumb, width: 72, height: 64, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: NotifIcons.urlFor(item.type),
                          width: 72,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox(width: 72, height: 64),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xF2101014));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
