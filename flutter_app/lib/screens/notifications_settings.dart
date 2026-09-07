/// Full notifications manage page — `#sub-notifications` / part064 `render()`.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/notifications.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'What reaches you',
      title: 'Notifications',
      film: 'assets/video/hero-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: NotifStore.instance,
              builder: (context, _) {
                final store = NotifStore.instance;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MasterCard(
                      on: store.master,
                      onToggle: () {
                        store.toggleMaster();
                        HapticFeedback.lightImpact();
                      },
                    ),
                    const SizedBox(height: 6),
                    _SecHead(
                      label: 'Updates',
                      trailing: store.feed.isEmpty
                          ? null
                          : GestureDetector(
                              onTap: () {
                                store.clearAll();
                                HapticFeedback.mediumImpact();
                              },
                              child: Container(
                                height: 26,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0x1AE8D5A3),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: const Color(0x4DE8D5A3)),
                                ),
                                child: const Text(
                                  'CLEAR ALL',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: NwsbColors.goldLight,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (store.feed.isEmpty)
                      const _SettingsEmpty()
                    else
                      _FeedList(store: store),
                    const _SecHead(label: 'What you get'),
                    for (final g in NotifStore.groups) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                        child: Text(
                          g.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Color(0x99E8D5A3),
                          ),
                        ),
                      ),
                      _KindGroup(
                        group: g,
                        masterOn: store.master,
                        off: store.offSet,
                        onToggle: (k) {
                          store.toggleKind(k);
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.on, required this.onToggle});
  final bool on;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: on
            ? const Color(0x12E8D5A3)
            : const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: on
              ? const Color(0x52E8D5A3)
              : const Color(0x1AFFFFFF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x66000000),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: on
                    ? const Color(0x59E8D5A3)
                    : const Color(0x24FFFFFF),
              ),
            ),
            child: Icon(
              Icons.notifications_none,
              size: 21,
              color: on ? NwsbColors.goldLight : const Color(0x8CFFFFFF),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Notifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  on
                      ? 'You are receiving notifications'
                      : 'Everything is muted',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w300,
                    color: Color(0x7AFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          _NtSwitch(on: on, onTap: onToggle),
        ],
      ),
    );
  }
}

class _SecHead extends StatelessWidget {
  const _SecHead({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: Color(0x61FFFFFF),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SettingsEmpty extends StatelessWidget {
  const _SettingsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            'You are all caught up',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0x9EFFFFFF),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New updates land here — orders, messages, offers, your routine and everything else you have switched on below.',
            textAlign: TextAlign.center,
            style: TextStyle(
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

class _FeedList extends StatelessWidget {
  const _FeedList({required this.store});
  final NotifStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x17FFFFFF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < store.feed.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: Color(0x0FFFFFFF)),
            _FeedRow(
              item: store.feed[i],
              label: store.labelOf(store.feed[i].type),
              onTap: () => store.markRead(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({
    required this.item,
    required this.label,
    required this.onTap,
  });

  final NotifItem item;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBox(url: NotifIcons.urlFor(item.type)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!item.read)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: const BoxDecoration(
                            color: NwsbColors.goldLight,
                            shape: BoxShape.circle,
                          ),
                        ),
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

class _KindGroup extends StatelessWidget {
  const _KindGroup({
    required this.group,
    required this.masterOn,
    required this.off,
    required this.onToggle,
  });

  final NotifGroup group;
  final bool masterOn;
  final List<String> off;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: masterOn ? 1 : 0.42,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x17FFFFFF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < group.items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: Color(0x0FFFFFFF)),
              _KindRow(
                kind: group.items[i],
                isOn: masterOn && !off.contains(group.items[i].k),
                onToggle: () => onToggle(group.items[i].k),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({
    required this.kind,
    required this.isOn,
    required this.onToggle,
  });

  final NotifKind kind;
  final bool isOn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _IconBox(url: NotifIcons.urlFor(kind.k)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kind.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kind.sub,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: Color(0x6BFFFFFF),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _NtSwitch(on: isOn, onTap: onToggle),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.url});
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

/// `.nt-sw` — 46×26 gold switch.
class _NtSwitch extends StatelessWidget {
  const _NtSwitch({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(2),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on
              ? const Color(0xE6E8D5A3)
              : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on
                ? const Color(0xF2E8D5A3)
                : const Color(0x29FFFFFF),
          ),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x4D000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
