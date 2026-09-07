/// Glass header-actions sheet — flat Quick actions carousel for Normal home.
///
/// Opens from the slim `_TopRow` SVG control. Outer chrome matches the
/// Notifications dark frosted glass sheet; the icon row sits in an inner
/// darker panel. Horizontal swipe with spring snap — flat tiles, no 3D.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../data/notifications.dart';
import '../../data/settings.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';

/// Blur / glass mark — not in [NwsbMarks]; drawn to match stroke style.
const _kBlurMark =
    '<circle cx="12" cy="12" r="3.2"/>'
    '<path d="M12 3.4v2.2M12 18.4v2.2M20.6 12h-2.2M5.6 12H3.4'
    'M17.7 6.3l-1.6 1.6M7.9 16.1l-1.6 1.6M17.7 17.7l-1.6-1.6M7.9 7.9 6.3 6.3"/>'
    '<circle cx="12" cy="12" r="7.2" stroke-dasharray="2.2 2.4"/>';

const _kPlusMark = '<path d="M12 5v14M5 12h14"/>';

const _kAddId = 'add';

/// Shortest signed distance on a circular list of [n] items.
double _circularDelta(double index, double focus, int n) {
  if (n <= 0) return 0;
  var d = index - focus;
  d = d - n * (d / n).roundToDouble();
  if (d > n / 2) d -= n;
  if (d <= -n / 2) d += n;
  return d;
}

int _wrapIndex(int i, int n) {
  if (n <= 0) return 0;
  return ((i % n) + n) % n;
}

Future<void> showHeaderActionsSheet(
  BuildContext context, {
  required bool glassMode,
  required VoidCallback onGlassToggle,
  required VoidCallback onNotifications,
  required VoidCallback onFashionHome,
  VoidCallback? onStore,
  VoidCallback? onPlayer,
}) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Header actions',
    barrierColor: const Color(0xB7040812),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, secondary) {
      return HeaderActionsSheet(
        glassMode: glassMode,
        onGlassToggle: onGlassToggle,
        onNotifications: onNotifications,
        onFashionHome: onFashionHome,
        onStore: onStore,
        onPlayer: onPlayer,
      );
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

class HeaderActionsSheet extends StatefulWidget {
  const HeaderActionsSheet({
    super.key,
    required this.glassMode,
    required this.onGlassToggle,
    required this.onNotifications,
    required this.onFashionHome,
    this.onStore,
    this.onPlayer,
  });

  final bool glassMode;
  final VoidCallback onGlassToggle;
  final VoidCallback onNotifications;
  final VoidCallback onFashionHome;
  final VoidCallback? onStore;
  final VoidCallback? onPlayer;

  @override
  State<HeaderActionsSheet> createState() => _HeaderActionsSheetState();
}

class _HeaderActionsSheetState extends State<HeaderActionsSheet>
    with SingleTickerProviderStateMixin {
  /// Fractional focus index into [_ids] (includes trailing Add).
  double _focus = 0;

  late final AnimationController _snap;

  double? _dragStartFocus;
  double _snapTo = 0;
  bool _snapping = false;

  static const _tile = 56.0;
  static const _gap = 72.0;

  late bool _glassOn;
  late List<String> _ids;

  int get _itemCount => _ids.length;

  @override
  void initState() {
    super.initState();
    _glassOn = widget.glassMode;
    _ids = _buildIds(Settings.instance.quickActions);
    _focus = _defaultFocus(_ids);
    Settings.instance.addListener(_onSettings);
    _snap = AnimationController.unbounded(vsync: this)
      ..addListener(_onSnapTick);
  }

  void _onSnapTick() {
    if (!_snapping) return;
    setState(() => _focus = _snap.value);
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    _snap.dispose();
    super.dispose();
  }

  void _onSettings() {
    if (!mounted) return;
    final next = _buildIds(Settings.instance.quickActions);
    setState(() {
      _ids = next;
      if (_itemCount == 0) {
        _focus = 0;
      } else {
        _focus = _normalizeFocus(_focus);
      }
    });
  }

  static List<String> _buildIds(List<String> saved) {
    final core = Settings.sanitizeQuickActions(saved);
    return [...core, _kAddId];
  }

  static double _defaultFocus(List<String> ids) {
    final i = ids.indexOf('notifications');
    if (i >= 0) return i.toDouble();
    return 0;
  }

  double _normalizeFocus(double f) {
    final n = _itemCount;
    if (n <= 0) return 0;
    var x = f % n;
    if (x < 0) x += n;
    return x;
  }

  /// Animate along the shortest circular path to [target] (integer index).
  void _animateTo(double target, {double velocity = 0}) {
    final n = _itemCount;
    if (n <= 0) return;
    final from = _focus;
    final delta = _circularDelta(target, from, n);
    final to = from + delta;
    _snapping = true;
    _snapTo = to;
    _snap.stop();
    _snap.value = from;

    final spring = SpringDescription(
      mass: 1,
      stiffness: 220,
      damping: 22,
    );
    final sim = SpringSimulation(spring, from, to, velocity / _gap);
    _snap.animateWith(sim).whenCompleteOrCancel(() {
      if (!mounted) return;
      _snapping = false;
      setState(() => _focus = _normalizeFocus(_snapTo.roundToDouble()));
    });
  }

  void _onDragStart(DragStartDetails _) {
    _snap.stop();
    _snapping = false;
    _dragStartFocus = _focus;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final start = _dragStartFocus ?? _focus;
    setState(() {
      _focus = start - d.primaryDelta! / _gap;
      _dragStartFocus = _focus;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    _dragStartFocus = null;
    final n = _itemCount;
    if (n <= 0) return;
    final velocity = d.primaryVelocity ?? 0;
    var projected = _focus - (velocity / _gap) * 0.18;
    var target = projected.roundToDouble();
    if (velocity.abs() > 240) {
      target = velocity < 0
          ? (_focus + 0.45).ceilToDouble()
          : (_focus - 0.45).floorToDouble();
    }
    final nearest = _normalizeFocus(target);
    _animateTo(nearest, velocity: -velocity);
  }

  int get _centerIndex {
    final n = _itemCount;
    if (n <= 0) return 0;
    return _wrapIndex(_focus.round(), n);
  }

  void _activateCenter() {
    final id = _ids[_centerIndex];
    HapticFeedback.mediumImpact();
    switch (id) {
      case 'glass':
        setState(() => _glassOn = !_glassOn);
        widget.onGlassToggle();
        break;
      case 'notifications':
        Navigator.of(context).pop();
        Future<void>.delayed(const Duration(milliseconds: 220), () {
          widget.onNotifications();
        });
        break;
      case 'fashion':
        Navigator.of(context).pop();
        widget.onFashionHome();
        break;
      case 'store':
        Navigator.of(context).pop();
        widget.onStore?.call();
        break;
      case 'player':
        Navigator.of(context).pop();
        widget.onPlayer?.call();
        break;
      case _kAddId:
        _openCustomize();
        break;
    }
  }

  Future<void> _openCustomize() async {
    HapticFeedback.selectionClick();
    final chosen = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CustomizeShortcutsSheet(
        initial: Settings.instance.quickActions,
      ),
    );
    if (chosen == null || !mounted) return;
    await Settings.instance.setQuickActions(chosen);
    final next = _buildIds(Settings.instance.quickActions);
    setState(() {
      _ids = next;
      _focus = _defaultFocus(next);
    });
  }

  void _onTileTap(int index) {
    final n = _itemCount;
    if (n <= 0) return;
    final delta = _circularDelta(index.toDouble(), _focus, n);
    final centered = delta.abs() < 0.22;
    if (centered) {
      _activateCenter();
    } else {
      HapticFeedback.selectionClick();
      _animateTo(index.toDouble());
    }
  }

  String _labelFor(String id) {
    switch (id) {
      case 'glass':
        return _glassOn ? 'Glassmorphism on' : 'Glassmorphism off';
      case 'notifications':
        return 'Notifications';
      case 'fashion':
        return 'Fashion home';
      case 'store':
        return 'Store';
      case 'player':
        return 'Player';
      case _kAddId:
        return 'Add shortcut';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerId = _ids.isEmpty ? _kAddId : _ids[_centerIndex];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // Same dark frosted glass as NotificationsSheet.
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
                          onClose: () => Navigator.of(context).pop(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 14,
                                sigmaY: 14,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xB7060C18),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0x33FFFFFF),
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    14,
                                    8,
                                    12,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 72,
                                        child: AnimatedBuilder(
                                          animation: _snap,
                                          builder: (context, _) =>
                                              _FlatCarousel(
                                            focus: _focus,
                                            glassOn: _glassOn,
                                            ids: _ids,
                                            tile: _tile,
                                            gap: _gap,
                                            onDragStart: _onDragStart,
                                            onDragUpdate: _onDragUpdate,
                                            onDragEnd: _onDragEnd,
                                            onTileTap: _onTileTap,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _CenterLabel(
                                        focus: _focus,
                                        itemCount: _itemCount,
                                        label: _labelFor(centerId),
                                        glassOn: _glassOn,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.onClose});

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Swipe · centre to open',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w300,
                    color: Color(0x99FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: NwsbColors.deep),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({
    required this.focus,
    required this.itemCount,
    required this.label,
    required this.glassOn,
  });

  final double focus;
  final int itemCount;
  final String label;
  final bool glassOn;

  @override
  Widget build(BuildContext context) {
    final i = itemCount <= 0 ? 0 : _wrapIndex(focus.round(), itemCount);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        label,
        key: ValueKey('$i-$label-$glassOn'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xF2FFFFFF),
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

/// Flat horizontal carousel — equal tiles, translateX only, no 3D.
class _FlatCarousel extends StatelessWidget {
  const _FlatCarousel({
    required this.focus,
    required this.glassOn,
    required this.ids,
    required this.tile,
    required this.gap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTileTap,
  });

  final double focus;
  final bool glassOn;
  final List<String> ids;
  final double tile;
  final double gap;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final ValueChanged<int> onTileTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: onDragStart,
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: ListenableBuilder(
        listenable: NotifStore.instance,
        builder: (context, _) {
          final unread = NotifStore.instance.unreadRaw;
          final badge = unread > 0 ? (unread > 99 ? 99 : unread) : null;
          final badgeLabel = NotifStore.instance.badgeText.isEmpty
              ? null
              : NotifStore.instance.badgeText;

          final items = <_ActionSpec>[
            for (final id in ids)
              _specFor(id, badge: badge, badgeLabel: badgeLabel),
          ];
          final n = items.length;
          if (n == 0) return const SizedBox.shrink();

          return LayoutBuilder(
            builder: (context, constraints) {
              final cx = constraints.maxWidth / 2;
              final cy = constraints.maxHeight / 2;

              // Continuous circular offsets so tiles physically slide under
              // the fixed centre focus as the user swipes / spring-snaps.
              final reach = n >= 5 ? 2 : (n >= 3 ? 1 : 0);
              final order = <int>[
                for (var i = 0; i < n; i++) i,
              ]..sort((a, b) {
                  final da = _circularDelta(a.toDouble(), focus, n).abs();
                  final db = _circularDelta(b.toDouble(), focus, n).abs();
                  return db.compareTo(da); // far → near (centre on top)
                });

              return ClipRect(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final index in order)
                      if (_circularDelta(index.toDouble(), focus, n)
                              .abs() <=
                          reach + 0.55)
                        _buildItem(
                          items: items,
                          index: index,
                          cx: cx,
                          cy: cy,
                        ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  _ActionSpec _specFor(String id, {int? badge, String? badgeLabel}) {
    switch (id) {
      case 'glass':
        return _ActionSpec(
          label: glassOn ? 'Glass on' : 'Glass off',
          body: _kBlurMark,
          active: glassOn,
        );
      case 'notifications':
        return _ActionSpec(
          label: 'Alerts',
          body: NwsbMarks.bell,
          badge: badge,
          badgeLabel: badgeLabel,
        );
      case 'fashion':
        return _ActionSpec(
          label: 'Fashion',
          body: NwsbMarks.moon,
        );
      case 'store':
        return _ActionSpec(
          label: 'Store',
          body: NwsbMarks.bag,
        );
      case 'player':
        return _ActionSpec(
          label: 'Player',
          body: NwsbMarks.play,
        );
      case _kAddId:
        return const _ActionSpec(
          label: 'Add',
          body: _kPlusMark,
        );
      default:
        return _ActionSpec(label: id, body: NwsbMarks.features);
    }
  }

  Widget _buildItem({
    required List<_ActionSpec> items,
    required int index,
    required double cx,
    required double cy,
  }) {
    final n = items.length;
    final visualOffset = _circularDelta(index.toDouble(), focus, n);
    final abs = visualOffset.abs().clamp(0.0, 2.2);

    // Flat: equal size; soft opacity fade for far neighbours.
    final opacity = ui.lerpDouble(
      1.0,
      0.5,
      Curves.easeOut.transform((abs / 1.6).clamp(0.0, 1.0)),
    )!;
    final dx = visualOffset * gap;
    final emphasized = abs < 0.38;

    return Positioned(
      key: ValueKey('tile-$index-${items[index].label}'),
      left: cx - tile / 2 + dx,
      top: cy - tile / 2,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: () => onTileTap(index),
          child: _ActionTile(
            spec: items[index],
            emphasized: emphasized,
            size: tile,
          ),
        ),
      ),
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.label,
    required this.body,
    this.active = false,
    this.badge,
    this.badgeLabel,
  });

  final String label;
  final String body;
  final bool active;
  final int? badge;
  final String? badgeLabel;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.spec,
    required this.emphasized,
    required this.size,
  });

  final _ActionSpec spec;
  final bool emphasized;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Centre focus = solid white (Notifications MANAGE look);
            // sides stay muted dark against the inner tray.
            color: emphasized
                ? const Color(0xFFFFFFFF)
                : (spec.active
                    ? const Color(0x33FFFFFF)
                    : const Color(0x22FFFFFF)),
            border: Border.all(
              color: emphasized
                  ? const Color(0xFFFFFFFF)
                  : const Color(0x33FFFFFF),
              width: emphasized ? 1.6 : 1.0,
            ),
            boxShadow: [
              if (emphasized)
                const BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Center(
            child: NwsbIcon(
              spec.body,
              size: emphasized ? 24 : 22,
              color: emphasized
                  ? NwsbColors.deep
                  : const Color(0xB8FFFFFF),
              strokeWidth: emphasized ? 1.85 : 1.7,
            ),
          ),
        ),
        if (spec.badge != null && spec.badge! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0342B),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                spec.badgeLabel ?? '${spec.badge}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CustomizeShortcutsSheet extends StatefulWidget {
  const _CustomizeShortcutsSheet({required this.initial});

  final List<String> initial;

  @override
  State<_CustomizeShortcutsSheet> createState() =>
      _CustomizeShortcutsSheetState();
}

class _CustomizeShortcutsSheetState extends State<_CustomizeShortcutsSheet> {
  late List<String> _selected;

  static const _labels = <String, String>{
    'notifications': 'Notifications',
    'store': 'Store',
    'player': 'Player',
    'glass': 'Glassmorphism',
    'fashion': 'Fashion home',
  };

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initial);
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        if (_selected.length <= 1) return;
        _selected.remove(id);
      } else {
        if (_selected.length >= 6) return;
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x24FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8C000000),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x44FFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Customize shortcuts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose up to 6 · Add stays at the end',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final id in Settings.availableQuickActions)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _selected.contains(id),
                      onChanged: (_) => _toggle(id),
                      activeColor: Colors.white,
                      checkColor: NwsbColors.deep,
                      side: const BorderSide(color: Color(0x66FFFFFF)),
                      title: Text(
                        _labels[id] ?? id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: NwsbColors.deep,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Save shortcuts',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
}
