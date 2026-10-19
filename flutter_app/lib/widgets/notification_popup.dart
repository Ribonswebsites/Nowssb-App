/// Chat that drops from the top bell. Not a card on the nav.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/notifications.dart';
import '../data/phone_notifications.dart';
import '../features/notifications/notif_router.dart';
import '../screens/splash.dart';
import '../theme/liquid_glass_theme.dart';

/// The bell opens this. A thread under the button, each line its own page.
Future<void> showNotifChat(BuildContext context) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notifications',
    barrierColor: const Color(0x66000000),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) => const _NotifChat(),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

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
    final top = MediaQuery.paddingOf(context).top + 62;
    return Stack(
      children: [
        widget.child,
        if (item != null)
          Positioned(
            top: top,
            right: 12,
            left: 56,
            child: _ChatBubble(
              item: item,
              onOpen: () => _open(item),
              onClose: () => setState(() => _hidden.add(_id(item))),
            ),
          ),
      ],
    );
  }
}

class _NotifChat extends StatelessWidget {
  const _NotifChat();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 58;
    final maxH = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top, 12, 0),
        child: Align(
          alignment: Alignment.topRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380, maxHeight: maxH),
            child: Material(
              color: Colors.transparent,
              child: ListenableBuilder(
                listenable: NotifStore.instance,
                builder: (context, _) {
                  final feed = NotifStore.instance.feed;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 108),
                        child: _Tail(),
                      ),
                      Flexible(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xF0141418),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0x33FFFFFF)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                                child: Row(
                                  children: [
                                    Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: feed.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                                        child: Text(
                                          'Nothing waiting.',
                                          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                                        itemCount: feed.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, i) {
                                          final n = feed[i];
                                          return _ChatRow(
                                            item: n,
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              NotifRouter.instance.openItem(n);
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.item, required this.onOpen, required this.onClose});
  final NotifItem item;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 108),
          child: _Tail(),
        ),
        GestureDetector(
          onTap: onOpen,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF0141418),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ChatCopy(item: item)),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.item, required this.onTap});
  final NotifItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: item.read ? const Color(0xFF101014) : const Color(0xFF1C1C22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: _ChatCopy(item: item),
        ),
      ),
    );
  }
}

class _ChatCopy extends StatelessWidget {
  const _ChatCopy({required this.item});
  final NotifItem item;

  @override
  Widget build(BuildContext context) {
    final label = NotifStore.instance.labelOf(item.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.isEmpty ? item.title : label,
          style: const TextStyle(color: Color(0xFFE8D5A3), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          item.title,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
        ),
        if (item.body.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.body,
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5, height: 1.3),
          ),
        ],
      ],
    );
  }
}

class _Tail extends StatelessWidget {
  const _Tail();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 8),
      painter: _TailPainter(),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xF0141418));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
