/// Live in-app pop-ups: one horizontal glass row at the top.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/notifications.dart';
import '../data/phone_notifications.dart';
import '../features/notifications/notif_router.dart';
import '../features/economy/reward_overlay.dart';
import '../features/progress/progress_center.dart';
import '../features/progress/progress_popup.dart';
import '../screens/notifications_sheet.dart';
import '../screens/quotes_live.dart';
import '../screens/splash.dart';
import '../theme/liquid_glass_theme.dart';

class NotificationPopupHost extends StatefulWidget {
  const NotificationPopupHost({super.key, required this.child, this.center, this.navigatorKey});
  final Widget child;
  final ProgressCenter? center;

  /// Navigator under this host (it sits in MaterialApp.builder, above it).
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<NotificationPopupHost> createState() => _NotificationPopupHostState();
}

/// Live pop-ups: ONE compact horizontal row at the top. Swipe left/right
/// through them, flick one up to dismiss it, View all opens the inbox,
/// Clear all dismisses every live one. Progress pop-ups ride in the same row.
class _NotificationPopupHostState extends State<NotificationPopupHost> {
  Timer? _hide;
  Object? _token;
  var _hold = false;
  final Set<String> _gone = {};

  ProgressCenter get _pc => widget.center ?? ProgressCenter.instance;

  @override
  void initState() {
    super.initState();
    NwsbEffects.instance.bind();
    NotificationBanner.items.addListener(_on);
    NotificationBanner.showPopups.addListener(_on);
    NotifStore.instance.addListener(_on);
    SplashGate.done.addListener(_on);
    DailyQuoteGate.done.addListener(_on);
    _pc.popup.addListener(_on);
  }

  @override
  void dispose() {
    _hide?.cancel();
    NotificationBanner.items.removeListener(_on);
    NotificationBanner.showPopups.removeListener(_on);
    NotifStore.instance.removeListener(_on);
    SplashGate.done.removeListener(_on);
    DailyQuoteGate.done.removeListener(_on);
    _pc.popup.removeListener(_on);
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
    final unread = NotifStore.instance.feed.where((e) => !e.read && !_gone.contains(_id(e))).toList();
    if (unread.isEmpty) return const [];
    unread.sort((a, b) {
      if (a.type == 'coins' && b.type != 'coins') return -1;
      if (b.type == 'coins' && a.type != 'coins') return 1;
      return b.at.compareTo(a.at);
    });
    return unread.take(12).toList();
  }

  void _arm(Object token, {bool force = false}) {
    if (!force && token == _token) return;
    _token = token;
    _hold = false;
    _hide?.cancel();
    // Long enough to reach View all / Clear all; any touch re-arms it.
    _hide = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _hold = true);
    });
  }

  void _touch() => _arm(_token ?? Object(), force: true);

  void _markRead(NotifItem item) {
    final i = NotifStore.instance.feed.indexOf(item);
    if (i >= 0) unawaited(NotifStore.instance.markRead(i));
  }

  void _open(NotifItem item) {
    _hide?.cancel();
    setState(() => _hold = true);
    NotificationBanner.dismiss(item);
    NotifRouter.instance.openItem(item);
  }

  void _dismissOne(NotifItem item) {
    setState(() => _gone.add(_id(item)));
    NotificationBanner.dismiss(item);
    _markRead(item);
    _touch();
  }

  void _clearAll(List<NotifItem> items) {
    HapticFeedback.mediumImpact();
    _hide?.cancel();
    setState(() {
      _gone.addAll(items.map(_id));
      _hold = true;
    });
    for (final i in items) {
      NotificationBanner.dismiss(i);
    }
    _pc.dismiss();
    unawaited(NotifStore.instance.markAllRead());
  }

  void _viewAll() {
    _hide?.cancel();
    setState(() => _hold = true);
    _pc.dismiss();
    final ctx = (widget.navigatorKey ?? RewardOverlay.navigatorKey).currentContext;
    if (ctx != null) showNotificationsSheet(ctx);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _pc.popup.value;
    final items = _hold ? const <NotifItem>[] : _items();
    final total = items.length + (progress != null ? 1 : 0);
    if (total > 0) {
      _arm(Object.hash(Object.hashAll(items.map(_id)), progress?.kind, progress?.value));
    }
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 12,
          right: 12,
          top: MediaQuery.paddingOf(context).top + 8,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, a) => SlideTransition(
              position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: total == 0
                ? const SizedBox.shrink()
                : NotificationRow(
                    key: const ValueKey('nwsb-notif-row'),
                    items: items,
                    progress: progress,
                    onOpen: _open,
                    onDismiss: _dismissOne,
                    onDismissProgress: _pc.dismiss,
                    onViewAll: _viewAll,
                    onClearAll: () => _clearAll(items),
                    onTouch: _touch,
                  ),
          ),
        ),
      ],
    );
  }
}

/// Glass row: header (NOWSSB · +N · View all · Clear all) over one card-high
/// horizontal pager.
class NotificationRow extends StatefulWidget {
  const NotificationRow({
    super.key,
    required this.items,
    this.progress,
    required this.onOpen,
    required this.onDismiss,
    this.onDismissProgress,
    required this.onViewAll,
    required this.onClearAll,
    this.onTouch,
  });
  final List<NotifItem> items;
  final ProgressItem? progress;
  final void Function(NotifItem item) onOpen;
  final void Function(NotifItem item) onDismiss;
  final VoidCallback? onDismissProgress;
  final VoidCallback onViewAll;
  final VoidCallback onClearAll;
  final VoidCallback? onTouch;

  static const double cardHeight = 86;

  /// Tests switch the remote thumbnails off (no network or cache DB there).
  @visibleForTesting
  static bool networkThumbs = true;

  @override
  State<NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<NotificationRow> {
  final _pager = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final cards = <Widget>[
      if (p != null)
        _swipeUp(
          ValueKey('progress-${p.kind}'),
          widget.onDismissProgress ?? () {},
          DecoratedBox(
            decoration: BoxDecoration(color: const Color(0xF0000000), borderRadius: BorderRadius.circular(16)),
            child: ProgressPopupCard(item: p, bare: true),
          ),
        ),
      for (final item in widget.items)
        _swipeUp(
          ValueKey('n-${item.type}|${item.at}|${item.title}'),
          () => widget.onDismiss(item),
          _BlackPill(item: item, onTap: () => widget.onOpen(item)),
        ),
    ];
    final n = cards.length;
    final page = _page.clamp(0, n - 1);
    final rest = n - 1 - page;
    const ink = TextStyle(color: Colors.white, decoration: TextDecoration.none);
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
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
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 26,
                    child: Row(children: [
                      const SizedBox(width: 8),
                      Text('NOWSSB',
                          style: ink.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      const SizedBox(width: 8),
                      if (n > 1)
                        Text('${page + 1}/$n',
                            style: ink.copyWith(
                                fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xB3FFFFFF))),
                      if (rest > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          key: const ValueKey('notif-more-chip'),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(99)),
                          child: Text('+$rest', style: ink.copyWith(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                      const Spacer(),
                      _action('View all', widget.onViewAll),
                      _action('Clear all', widget.onClearAll),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: NotificationRow.cardHeight,
                    child: PageView(
                      controller: _pager,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        widget.onTouch?.call();
                        setState(() => _page = i);
                      },
                      children: [
                        for (final c in cards) Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: c),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(String label, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        ),
      );

  /// Fast flick-up dismiss for one card.
  Widget _swipeUp(Key key, VoidCallback onGone, Widget child) => Dismissible(
        key: key,
        direction: DismissDirection.up,
        movementDuration: const Duration(milliseconds: 160),
        resizeDuration: null,
        dismissThresholds: const {DismissDirection.up: 0.2},
        onDismissed: (_) {
          HapticFeedback.lightImpact();
          onGone();
        },
        child: SizedBox.expand(child: child),
      );
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
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NotifCategoryBadge(type: item.type),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2D2D),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ink.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ink.copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ink.copyWith(
                            fontSize: 12, fontWeight: FontWeight.w400, height: 1.25, color: const Color(0xE6FFFFFF)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: const Color(0xFF1A1A1E),
                  child: thumb != null
                      ? Image.asset(thumb, width: 58, height: 52, fit: BoxFit.cover)
                      : NotificationRow.networkThumbs == false
                          ? const SizedBox(width: 58, height: 52)
                          : CachedNetworkImage(
                              imageUrl: NotifIcons.urlFor(item.type),
                              width: 58,
                              height: 52,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const SizedBox(width: 58, height: 52),
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

/// Category icon: SVG in a white circle, in a black circle, in a glass circle.
class NotifCategoryBadge extends StatelessWidget {
  const NotifCategoryBadge({super.key, required this.type, this.size = 46});
  final String type;
  final double size;

  /// Every kind NotifStore sends has its own icon; anything else gets [fallback].
  static const known = <String>{
    'routine',
    'streak',
    'reader',
    'coins',
    'rewards',
    'gifts',
    'spin',
    'update',
    'offers',
    'subscription',
    'orders',
  };
  static const fallback = 'assets/icons/notif/default.svg';
  static String assetFor(String type) => known.contains(type) ? 'assets/icons/notif/$type.svg' : fallback;

  @override
  Widget build(BuildContext context) {
    final black = size * 0.78;
    final white = size * 0.56;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x33FFFFFF),
            border: Border.all(color: const Color(0x80FFFFFF), width: 0.8),
          ),
          child: Container(
            width: black,
            height: black,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
            child: Container(
              width: white,
              height: white,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: SvgPicture.asset(
                assetFor(type),
                key: ValueKey('notif-icon-$type'),
                width: white * 0.58,
                height: white * 0.58,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
