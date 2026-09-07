/// Glass header-actions sheet — cinematic 3D cover-flow of Normal home controls.
///
/// Opens from the slim `_TopRow` SVG control. Visual language matches
/// [NormalGlassSection] / notifications sheet: blur, translucent fill,
/// soft white rim. Options that used to crowd the header live here as
/// rounded SVG tiles; the centred tile is larger and is the one that
/// activates on tap.
///
/// Always shows neighbour | centre | neighbour (list wraps at both ends
/// so the sides are never empty).
library;

import 'dart:math' as math;
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
  // Keep in (-n/2, n/2]
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
    barrierColor: const Color(0x99040A18),
    transitionDuration: const Duration(milliseconds: 320),
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
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.03),
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
    with TickerProviderStateMixin {
  /// Fractional focus index into [_ids] (includes trailing Add).
  double _focus = 0;

  late final AnimationController _drift;
  late final AnimationController _snap;

  double? _dragStartFocus;
  double _snapFrom = 0;
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
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
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
    _drift.dispose();
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
    var delta = _circularDelta(target, from, n);
    // Prefer landing on the unwrapped target near `from`.
    final to = from + delta;
    _snapping = true;
    _snapFrom = from;
    _snapTo = to;
    _snap.stop();
    _snap.value = from;

    // Springy cinematic snap — slight overshoot, settles cleanly.
    final spring = SpringDescription(
      mass: 1,
      stiffness: 180,
      damping: 18,
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
      // Unbounded while dragging — wrap is applied when rendering.
      _focus = start - d.primaryDelta! / _gap;
      _dragStartFocus = _focus;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    _dragStartFocus = null;
    final n = _itemCount;
    if (n <= 0) return;
    final velocity = d.primaryVelocity ?? 0;
    // Project a bit with fling, then snap to nearest wrapped index.
    var projected = _focus - (velocity / _gap) * 0.18;
    var target = projected.roundToDouble();
    if (velocity.abs() > 240) {
      target = velocity < 0
          ? (_focus + 0.45).ceilToDouble()
          : (_focus - 0.45).floorToDouble();
    }
    // Convert unbounded target into nearest absolute index path.
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
        // Stay open so the glass language behind the sheet updates live.
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x72FFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xF2FFFFFF),
                        width: 1.4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x280B2447),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Color(0xAAFFFFFF),
                          blurRadius: 14,
                          offset: Offset(-3, -3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SheetChrome(
                            onClose: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quick actions',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: NwsbColors.ink,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Swipe · centre to open',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: NwsbColors.inkSoft,
                                  letterSpacing: 0.4,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 112,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_drift, _snap]),
                              builder: (context, _) => _CoverFlow(
                                focus: _focus,
                                drift: _drift.value,
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
                          const SizedBox(height: 4),
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
          ),
        ),
      ),
    );
  }
}

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 3.5,
          decoration: BoxDecoration(
            color: const Color(0x55FFFFFF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0x88FFFFFF)),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x55FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xDFFFFFFF)),
            ),
            child: const Icon(Icons.close_rounded,
                size: 16, color: NwsbColors.ink),
          ),
        ),
      ],
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
    final i = itemCount <= 0
        ? 0
        : _wrapIndex(focus.round(), itemCount);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        label,
        key: ValueKey('$i-$label-$glassOn'),
        style: const TextStyle(
          color: NwsbColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _CoverFlow extends StatelessWidget {
  const _CoverFlow({
    required this.focus,
    required this.drift,
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
  final double drift;
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
    // Subtle idle sway — yaw + parallax, never enough to hide a side.
    final sway = math.sin(drift * math.pi * 2) * 0.028;
    final lift = math.cos(drift * math.pi * 2) * 1.2;

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

              // Always paint at least ±1 neighbours (wrap). Also paint
              // ±2 for depth when the list is long enough.
              final reach = n >= 5 ? 2 : 1;
              final center = focus.round();
              final slots = <int>[
                for (var s = -reach; s <= reach; s++) s,
              ];
              // Paint far → near so centre is on top.
              slots.sort((a, b) => b.abs().compareTo(a.abs()));

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Soft stage shadow under the carousel.
                  Positioned(
                    left: cx - 70,
                    top: cy + tile * 0.42,
                    child: IgnorePointer(
                      child: Container(
                        width: 140,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: RadialGradient(
                            colors: [
                              const Color(0x330B2447),
                              const Color(0x000B2447),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final slot in slots)
                    _buildSlot(
                      items: items,
                      slot: slot,
                      centerRound: center,
                      cx: cx,
                      cy: cy,
                      sway: sway,
                      lift: lift,
                    ),
                ],
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

  Widget _buildSlot({
    required List<_ActionSpec> items,
    required int slot,
    required int centerRound,
    required double cx,
    required double cy,
    required double sway,
    required double lift,
  }) {
    final n = items.length;
    final index = _wrapIndex(centerRound + slot, n);
    // Slot-based offset keeps LEFT | CENTRE | RIGHT always populated,
    // even when the list wraps or has only 1–2 items (sides may repeat).
    final frac = focus - centerRound;
    final visualOffset = slot - frac + sway;
    final abs = visualOffset.abs().clamp(0.0, 2.2);

    // Cinematic falloffs.
    final t = (abs / 1.05).clamp(0.0, 1.0);
    final scale = ui.lerpDouble(1.34, 0.78, Curves.easeOutCubic.transform(t))!;
    final opacity = ui.lerpDouble(
      1.0,
      0.58,
      Curves.easeOut.transform((abs / 1.35).clamp(0.0, 1.0)),
    )!;
    final dx = visualOffset * gap;
    final dy = abs * abs * 6.5 + (abs < 0.35 ? -lift : lift * 0.35);
    final yaw = visualOffset * 0.92;
    final pitch = abs * 0.06;
    final z = -abs * 36.0;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.00235)
      ..translate(dx, dy, z)
      ..rotateY(yaw)
      ..rotateX(pitch)
      ..scale(scale, scale, 1.0);

    final light = (1.0 - (visualOffset.clamp(-1.2, 1.2).abs() * 0.22))
        .clamp(0.72, 1.0);

    return Positioned(
      key: ValueKey('slot-$slot-$index'),
      left: cx - tile / 2,
      top: cy - tile / 2 - 8,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: GestureDetector(
            onTap: () => onTileTap(index),
            child: _ActionTile(
              spec: items[index],
              emphasized: abs < 0.38,
              size: tile,
              light: light,
              yaw: yaw,
            ),
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
    required this.light,
    required this.yaw,
  });

  final _ActionSpec spec;
  final bool emphasized;
  final double size;
  final double light;
  final double yaw;

  @override
  Widget build(BuildContext context) {
    final shadowDx = (yaw * 10).clamp(-8.0, 8.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Contact shadow — shifts with yaw for depth.
        Positioned(
          left: 4 + shadowDx,
          right: 4 - shadowDx,
          bottom: -6,
          child: IgnorePointer(
            child: Container(
              height: emphasized ? 14 : 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(emphasized ? 0x3A0B2447 : 0x220B2447),
                    blurRadius: emphasized ? 16 : 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-0.8 - yaw * 0.4, -1),
              end: Alignment(0.9 - yaw * 0.3, 1.1),
              colors: [
                Color.lerp(
                  spec.active
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xF2FFFFFF),
                  const Color(0xFFD7E4F4),
                  1.0 - light,
                )!,
                Color.lerp(
                  spec.active
                      ? const Color(0xD9FFFFFF)
                      : const Color(0xA8FFFFFF),
                  const Color(0xFFB8C9DE),
                  (1.0 - light) * 0.85,
                )!,
              ],
            ),
            border: Border.all(
              color: emphasized
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xD8FFFFFF),
              width: emphasized ? 1.85 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(emphasized ? 0x2E0B2447 : 0x1A0B2447),
                blurRadius: emphasized ? 20 : 12,
                offset: Offset(shadowDx * 0.35, emphasized ? 10 : 7),
              ),
              BoxShadow(
                color: Color(emphasized ? 0xCCFFFFFF : 0x88FFFFFF),
                blurRadius: emphasized ? 10 : 6,
                offset: Offset(-2 - shadowDx * 0.15, -2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Specular rim.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        Color(emphasized ? 0x66FFFFFF : 0x33FFFFFF),
                        const Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: NwsbIcon(
                  spec.body,
                  size: emphasized ? 25 : 20,
                  color: Color.lerp(
                    const Color(0xFF31577F),
                    const Color(0xFF1E3A55),
                    1.0 - light,
                  )!,
                  strokeWidth: emphasized ? 1.85 : 1.7,
                ),
              ),
            ],
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
              color: const Color(0xEEF7FAFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xDFFFFFFF)),
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
                        color: const Color(0x33000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Customize shortcuts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NwsbColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose up to 6 · Add stays at the end',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NwsbColors.inkSoft,
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
                      activeColor: const Color(0xFF31577F),
                      title: Text(
                        _labels[id] ?? id,
                        style: const TextStyle(
                          color: NwsbColors.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF31577F),
                      foregroundColor: Colors.white,
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
