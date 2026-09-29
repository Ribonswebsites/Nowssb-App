/// Slide-down notification card. Sits above every screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/notifications.dart';
import '../data/phone_notifications.dart';
import '../theme/liquid_glass_theme.dart';

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
  }

  @override
  void dispose() {
    NotificationBanner.items.removeListener(_onItems);
    super.dispose();
  }

  void _onItems() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = NotificationBanner.items.value;
    return Stack(
      children: [
        widget.child,
        if (list.isNotEmpty)
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
  const _BannerCard({required this.item, required this.onClose});
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xF0141418),
        elevation: 8,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onClose,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.notifications_none_rounded,
                      color: Colors.black, size: 18),
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
    );
  }
}
