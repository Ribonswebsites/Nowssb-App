/// Glance-style notification card. Sits above every screen, over the bar.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/notifications.dart';
import '../data/phone_notifications.dart';
import '../screens/notifications_sheet.dart';
import '../theme/liquid_glass_theme.dart';

class NotificationPopupHost extends StatefulWidget {
  const NotificationPopupHost({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationPopupHost> createState() => _NotificationPopupHostState();
}

class _NotificationPopupHostState extends State<NotificationPopupHost> {
  var _surfaced = false;

  @override
  void initState() {
    super.initState();
    NwsbEffects.instance.bind();
    NotificationBanner.items.addListener(_onItems);
    NotificationBanner.showPopups.addListener(_onItems);
    NotifStore.instance.addListener(_surfaceUnread);
    _surfaceUnread();
  }

  @override
  void dispose() {
    NotificationBanner.items.removeListener(_onItems);
    NotificationBanner.showPopups.removeListener(_onItems);
    NotifStore.instance.removeListener(_surfaceUnread);
    super.dispose();
  }

  void _onItems() {
    if (mounted) setState(() {});
  }

  /// One waiting item, once, so a card is there when the inbox already has
  /// something. New arrivals still come through [NotificationBanner.push].
  void _surfaceUnread() {
    if (_surfaced || !NotifStore.instance.loaded) return;
    final unread = NotifStore.instance.feed.where((e) => !e.read);
    if (unread.isEmpty) {
      if (NotificationBanner.items.value.isNotEmpty) _surfaced = true;
      return;
    }
    _surfaced = true;
    if (NotificationBanner.items.value.isNotEmpty) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    NotificationBanner.push(unread.first);
  }

  @override
  Widget build(BuildContext context) {
    final list = NotificationBanner.items.value;
    final signedIn = FirebaseAuth.instance.currentUser != null;
    final allow = NotificationBanner.showPopups.value;
    final item = list.isEmpty ? null : list.first;
    return Stack(
      children: [
        widget.child,
        if (signedIn && allow && item != null)
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 86),
                child: _GlanceNotice(
                  key: ValueKey('${item.at}|${item.type}|${item.title}'),
                  item: item,
                  onClose: () => NotificationBanner.dismiss(item),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlanceNotice extends StatefulWidget {
  const _GlanceNotice({super.key, required this.item, required this.onClose});
  final NotifItem item;
  final VoidCallback onClose;

  @override
  State<_GlanceNotice> createState() => _GlanceNoticeState();
}

class _GlanceNoticeState extends State<_GlanceNotice> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (mounted) widget.onClose();
    });
  }

  String get _category {
    final label = NotifStore.instance.labelOf(widget.item.type);
    if (label.isNotEmpty && label != widget.item.type) return label;
    return switch (widget.item.type) {
      'messages' => 'Messages',
      'posts' => 'Reels',
      'reactions' => 'Connect',
      'follows' => 'People',
      'orders' => 'Orders',
      'delivery' => 'Delivery',
      'cart' => 'Cart',
      'arrivals' => 'Library',
      'offers' => 'Offers',
      'trending' => 'Trending',
      'routine' => 'Practice',
      'rx' => 'Practice',
      'streak' => 'Streak',
      'reader' => 'Reading',
      'subscription' => 'Plans',
      'support' => 'NowssB',
      _ => 'NowssB',
    };
  }

  String get _headline {
    final title = widget.item.title.trim();
    final body = widget.item.body.trim();
    if (title.isEmpty) return body;
    if (body.isEmpty || body == title) return title;
    return '$title $body';
  }

  void _open() {
    HapticFeedback.selectionClick();
    widget.onClose();
    showNotificationsSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('glance-${widget.item.at}-${widget.item.title}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => widget.onClose(),
      child: GestureDetector(
        onTap: _open,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 2, 6),
              child: Row(
                children: const [
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
                  Text(
                    'News',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 22),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xE6101014),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
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
                              child: CachedNetworkImage(
                                imageUrl: NotifIcons.urlFor(widget.item.type),
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
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF2D2D),
                                shape: BoxShape.circle,
                              ),
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
          ],
        ),
      ),
    );
  }
}