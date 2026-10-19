/// Glance card. Drops under the bell. The bell itself still opens the
/// original notifications sheet.
library;

import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/notifications.dart';
import '../data/phone_notifications.dart';
import '../features/notifications/notif_router.dart';
import '../screens/splash.dart';
import '../theme/liquid_glass_theme.dart';

class NotificationPopupHost extends StatefulWidget {
  const NotificationPopupHost({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationPopupHost> createState() => _NotificationPopupHostState();
}

class _NotificationPopupHostState extends State<NotificationPopupHost> {
  final _hidden = <String>{};

  @override
  void initState() {
    super.initState();
    NwsbEffects.instance.bind();
    NotificationBanner.items.addListener(_on);
    NotificationBanner.showPopups.addListener(_on);
    NotifStore.instance.addListener(_on);
    SplashGate.done.addListener(_on);
  }

  @override
  void dispose() {
    NotificationBanner.items.removeListener(_on);
    NotificationBanner.showPopups.removeListener(_on);
    NotifStore.instance.removeListener(_on);
    SplashGate.done.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  static String _id(NotifItem e) => '${e.type}|${e.at}|${e.title}';

  NotifItem? _pick() {
    if (!SplashGate.done.value || !NotificationBanner.showPopups.value) return null;
    final banner = NotificationBanner.items.value;
    if (banner.isNotEmpty && !_hidden.contains(_id(banner.first))) return banner.first;
    final unread = NotifStore.instance.feed.where((e) => !e.read && !_hidden.contains(_id(e)));
    for (final e in unread) {
      if (e.type == 'coins') return e;
    }
    if (unread.isEmpty) return null;
    return unread.first;
  }

  void _open(NotifItem item) {
    setState(() => _hidden.add(_id(item)));
    NotificationBanner.dismiss(item);
    NotifRouter.instance.openItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final item = _pick();
    final top = MediaQuery.paddingOf(context).top + 64;
    return Stack(
      children: [
        widget.child,
        if (item != null)
          Positioned(
            left: 10,
            right: 10,
            top: top,
            child: _GlanceNotice(
              key: ValueKey(_id(item)),
              item: item,
              onOpen: () => _open(item),
              onClose: () => setState(() => _hidden.add(_id(item))),
            ),
          ),
      ],
    );
  }
}

class _GlanceNotice extends StatelessWidget {
  const _GlanceNotice({super.key, required this.item, required this.onOpen, required this.onClose});
  final NotifItem item;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  String get _category {
    final label = NotifStore.instance.labelOf(item.type);
    if (label.isNotEmpty && label != item.type) return label;
    return 'NowssB';
  }

  String get _headline {
    final title = item.title.trim();
    final body = item.body.trim();
    if (title.isEmpty) return body;
    if (body.isEmpty || body == title) return title;
    return '$title. $body';
  }

  String? get _thumb => switch (item.type) {
        'coins' || 'rewards' => 'assets/rails/rewards-coins.png',
        'gifts' => 'assets/rails/gifts-02.jpg',
        'spin' => 'assets/rails/art-spin.jpg',
        'update' => 'assets/rails/art-coins.jpg',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('glance-${item.at}-${item.title}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onClose(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onOpen();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(6, 0, 4, 6),
              child: Row(
                children: [
                  Text(
                    'nowssb',
                    style: TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Spacer(),
                  Text('News', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 22),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x66101418),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x66FFFFFF)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 10)),
                    ],
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _headline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 86,
                          height: 76,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ColoredBox(
                                  color: const Color(0xFF1A1A1E),
                                  child: _thumb != null
                                      ? Image.asset(_thumb!, width: 86, height: 76, fit: BoxFit.cover)
                                      : CachedNetworkImage(
                                          imageUrl: NotifIcons.urlFor(item.type),
                                          width: 86,
                                          height: 76,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => const SizedBox(width: 86, height: 76),
                                        ),
                                ),
                              ),
                              Positioned(
                                left: -4,
                                top: -8,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: Color(0xFFFF2D2D), shape: BoxShape.circle),
                                  child: const Text(
                                    'NEWS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 6.2,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
