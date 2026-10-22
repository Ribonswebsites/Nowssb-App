/// Glass card under the bell. The bell still opens the original sheet.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

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
    _hide = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hold = true);
    });
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
    final top = MediaQuery.paddingOf(context).top + 86;
    final tailRight = 149.0 - 12 - 8;
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
            ),
          ),
      ],
    );
  }
}

class _GlanceStack extends StatelessWidget {
  const _GlanceStack({required this.items, required this.tailRight, required this.onOpen});
  final List<NotifItem> items;
  final double tailRight;
  final void Function(NotifItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: tailRight),
          child: CustomPaint(size: const Size(16, 9), painter: _TailPainter()),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x2EFFFFFF),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
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
                    for (final item in items) ...[
                      _BlackPill(item: item, onTap: () => onOpen(item)),
                      if (item != items.last) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
    canvas.drawPath(path, Paint()..color = const Color(0xB3FFFFFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
