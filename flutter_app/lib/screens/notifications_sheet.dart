/// Notifications glass sheet — `.nt-overlay` / `.nt-sheet` from part064.js.
///
/// The bell opens this centered sheet, not the settings page. Gear / Manage
/// leads through to [NotificationsSettingsPage].
library;

import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/notifications.dart';
import '../theme/tokens.dart';
import 'notifications_settings.dart';

Future<void> showNotificationsSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notifications',
    barrierColor: const Color(0xB7040812), // rgba(4,8,18,0.72)
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, secondary) {
      return const NotificationsSheet();
    },
    transitionBuilder: (context, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.4, 0, 0.2, 1),
      );
      return FadeTransition(
        opacity: curved,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  void _openSettings(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationsSettingsPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.8;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
            child: ListenableBuilder(
              listenable: NotifStore.instance,
              builder: (context, _) {
                final store = NotifStore.instance;
                return Material(
                  type: MaterialType.transparency,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x24FFFFFF)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x8C000000),
                              blurRadius: 60,
                              offset: Offset(0, 26),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SheetHead(
                              subtitle: store.sheetSubtitle(),
                              onGear: () => _openSettings(context),
                              onClose: () => Navigator.of(context).pop(),
                            ),
                            Flexible(
                              child: store.feed.isEmpty
                                  ? SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 12, 12, 6),
                                      child: _EmptyState(masterOn: store.master),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 12, 12, 6),
                                      shrinkWrap: true,
                                      itemCount: store.feed.length,
                                      itemBuilder: (context, i) {
                                        final n = store.feed[i];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: _SheetItem(
                                            item: n,
                                            label: store.labelOf(n.type),
                                            onTap: () => store.markRead(i),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            _SheetFoot(
                              onClear: () {
                                store.clearAll();
                                HapticFeedback.mediumImpact();
                              },
                              onManage: () => _openSettings(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({
    required this.subtitle,
    required this.onGear,
    required this.onClose,
  });

  final String subtitle;
  final VoidCallback onGear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w300,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          _HBtn(
            color: NwsbColors.goldLight,
            onTap: onGear,
            child: const Icon(Icons.settings_outlined,
                size: 16, color: NwsbColors.deep),
          ),
          const SizedBox(width: 10),
          _HBtn(
            color: Colors.white,
            onTap: onClose,
            child: const Icon(Icons.close, size: 16, color: NwsbColors.deep),
          ),
        ],
      ),
    );
  }
}

class _HBtn extends StatelessWidget {
  const _HBtn({
    required this.color,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

class _SheetFoot extends StatelessWidget {
  const _SheetFoot({required this.onClear, required this.onManage});

  final VoidCallback onClear;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x21FFFFFF)),
                ),
                child: const Text(
                  'CLEAR ALL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onManage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: const Text(
                  'MANAGE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: NwsbColors.deep,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.masterOn});
  final bool masterOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CustomPaint(painter: _EmptyBellPainter()),
          ),
          const SizedBox(height: 12),
          Text(
            masterOn ? 'You are all caught up' : 'Notifications are off',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0x9EFFFFFF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            masterOn
                ? 'New updates land here — orders, messages, offers, your routine and everything else you have switched on.'
                : 'Turn them back on from the gear above to start receiving updates again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w300,
              color: Color(0x61FFFFFF),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.item,
    required this.label,
    required this.onTap,
  });

  final NotifItem item;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x52000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x17FFFFFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KindIcon(url: NotifIcons.urlFor(item.type)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!item.read) ...[
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: const BoxDecoration(
                            color: NwsbColors.goldLight,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x99E8D5A3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                                item.read ? FontWeight.w600 : FontWeight.w700,
                            color: item.read
                                ? const Color(0xB8FFFFFF)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Color(0x80FFFFFF),
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    '$label · ${NotifStore.ago(item.at)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      color: Color(0x52FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 120),
        errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
      ),
    );
  }
}

/// Same SVG paths as the empty-state bell in part064.js.
class _EmptyBellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x4DFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final sx = size.width / 24;
    final sy = size.height / 24;
    final bell = Path()
      ..moveTo(18 * sx, 8 * sy)
      ..cubicTo(18 * sx, 4.7 * sy, 15.3 * sx, 2 * sy, 12 * sx, 2 * sy)
      ..cubicTo(8.7 * sx, 2 * sy, 6 * sx, 4.7 * sy, 6 * sx, 8 * sy)
      ..cubicTo(6 * sx, 15 * sy, 3 * sx, 17 * sy, 3 * sx, 17 * sy)
      ..lineTo(21 * sx, 17 * sy)
      ..cubicTo(21 * sx, 17 * sy, 18 * sx, 15 * sy, 18 * sx, 8 * sy);
    canvas.drawPath(bell, p);
    final clapper = Path()
      ..moveTo(13.7 * sx, 21 * sy)
      ..cubicTo(13.2 * sx, 22.2 * sy, 10.8 * sx, 22.2 * sy, 10.3 * sx, 21 * sy);
    canvas.drawPath(clapper, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
