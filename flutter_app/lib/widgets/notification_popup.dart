/// Notification bubbles that pop out of the bell. Sit above every screen.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/notifications.dart';
import '../data/phone_notifications.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass_motion.dart';

class NotificationPopupHost extends StatefulWidget {
  const NotificationPopupHost({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationPopupHost> createState() => _NotificationPopupHostState();
}

class _NotificationPopupHostState extends State<NotificationPopupHost> {
  @override
  void initState() {
    super.initState();
    NwsbEffects.instance.bind();
    NotificationBanner.items.addListener(_onItems);
    NotificationBanner.showPopups.addListener(_onItems);
  }

  @override
  void dispose() {
    NotificationBanner.items.removeListener(_onItems);
    NotificationBanner.showPopups.removeListener(_onItems);
    super.dispose();
  }

  void _onItems() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = NotificationBanner.items.value;
    final signedIn = FirebaseAuth.instance.currentUser != null;
    final allow = NotificationBanner.showPopups.value;
    return Stack(
      children: [
        widget.child,
        if (signedIn && allow && list.isNotEmpty)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  for (final item in list)
                    _BannerCard(
                      key: ObjectKey(item),
                      item: item,
                      onClose: () => NotificationBanner.dismiss(item),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatefulWidget {
  const _BannerCard({super.key, required this.item, required this.onClose});
  final NotifItem item;
  final VoidCallback onClose;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// A glass chat bubble that springs out of the bell (top right), wobbles
  /// and settles. Swipe it sideways, tap it or tap the cross to dismiss.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ObjectKey(widget.item),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => widget.onClose(),
        child: BubblePopIn(
          origin: Alignment.topRight,
          wobble: -0.18,
          child: SpringPress(
            onTap: widget.onClose,
            scale: 0.98,
            child: Material(
              type: MaterialType.transparency,
              child: GlassBubble(
                tail: BubbleTail.topRight,
                blur: true,
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    const BubblePopIn(
                      origin: Alignment.center,
                      delay: Duration(milliseconds: 120),
                      wobble: 0.5,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.notifications_none_rounded, color: Colors.black, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.item.body.isNotEmpty)
                            Text(
                              widget.item.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
