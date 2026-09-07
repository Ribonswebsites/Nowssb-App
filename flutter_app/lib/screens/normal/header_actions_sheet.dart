/// Glass header-actions sheet — 3D cover-flow of Normal home controls.
///
/// Opens from the slim `_TopRow` SVG control. Visual language matches
/// [NormalGlassSection] / notifications sheet: blur, translucent fill,
/// soft white rim. Options that used to crowd the header live here as
/// rounded SVG tiles; the centred tile is larger and is the one that
/// activates on tap.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/notifications.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';

/// Blur / glass mark — not in [NwsbMarks]; drawn to match stroke style.
const _kBlurMark =
    '<circle cx="12" cy="12" r="3.2"/>'
    '<path d="M12 3.4v2.2M12 18.4v2.2M20.6 12h-2.2M5.6 12H3.4'
    'M17.7 6.3l-1.6 1.6M7.9 16.1l-1.6 1.6M17.7 17.7l-1.6-1.6M7.9 7.9 6.3 6.3"/>'
    '<circle cx="12" cy="12" r="7.2" stroke-dasharray="2.2 2.4"/>';

Future<void> showHeaderActionsSheet(
  BuildContext context, {
  required bool glassMode,
  required VoidCallback onGlassToggle,
  required VoidCallback onNotifications,
  required VoidCallback onFashionHome,
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
  });

  final bool glassMode;
  final VoidCallback onGlassToggle;
  final VoidCallback onNotifications;
  final VoidCallback onFashionHome;

  @override
  State<HeaderActionsSheet> createState() => _HeaderActionsSheetState();
}

class _HeaderActionsSheetState extends State<HeaderActionsSheet>
    with TickerProviderStateMixin {
  /// Fractional focus index — 0 = glass, 1 = notifications, 2 = fashion.
  double _focus = 1;

  /// Idle cover-flow drift (radians of slow orbit).
  late final AnimationController _drift;
  late final AnimationController _snap;

  double? _dragStartFocus;
  double _snapFrom = 0;
  double _snapTo = 0;

  static const _itemCount = 3;
  static const _tile = 64.0;
  static const _gap = 78.0;

  late bool _glassOn;

  @override
  void initState() {
    super.initState();
    _glassOn = widget.glassMode;
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _snap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
        final t = Curves.easeOutCubic.transform(_snap.value);
        setState(() => _focus = _snapFrom + (_snapTo - _snapFrom) * t);
      });
  }

  @override
  void dispose() {
    _drift.dispose();
    _snap.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final wrapped = target.clamp(0.0, (_itemCount - 1).toDouble());
    _snap.stop();
    _snapFrom = _focus;
    _snapTo = wrapped;
    _snap
      ..value = 0
      ..forward();
  }

  void _onDragStart(DragStartDetails _) {
    _snap.stop();
    _dragStartFocus = _focus;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final start = _dragStartFocus ?? _focus;
    setState(() {
      _focus = (start - d.primaryDelta! / _gap)
          .clamp(0.0, (_itemCount - 1).toDouble());
      _dragStartFocus = _focus;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    _dragStartFocus = null;
    final velocity = d.primaryVelocity ?? 0;
    var target = _focus.roundToDouble();
    if (velocity.abs() > 280) {
      target = velocity < 0
          ? (_focus + 0.55).ceilToDouble()
          : (_focus - 0.55).floorToDouble();
    }
    _animateTo(target.clamp(0.0, (_itemCount - 1).toDouble()));
  }

  void _activateCenter() {
    final i = _focus.round().clamp(0, _itemCount - 1);
    HapticFeedback.mediumImpact();
    switch (i) {
      case 0:
        setState(() => _glassOn = !_glassOn);
        widget.onGlassToggle();
        // Stay open so the glass language behind the sheet updates live.
        break;
      case 1:
        Navigator.of(context).pop();
        // Let the actions sheet dismiss before the notifications sheet.
        Future<void>.delayed(const Duration(milliseconds: 220), () {
          widget.onNotifications();
        });
      case 2:
        Navigator.of(context).pop();
        widget.onFashionHome();
    }
  }

  void _onTileTap(int index) {
    final centered = _focus.round() == index && (_focus - index).abs() < 0.18;
    if (centered) {
      _activateCenter();
    } else {
      HapticFeedback.selectionClick();
      _animateTo(index.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // Normal glass section fill / rim.
                      color: const Color(0x66FFFFFF),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xF2FFFFFF),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x330B2447),
                          blurRadius: 40,
                          offset: Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Color(0xCCFFFFFF),
                          blurRadius: 18,
                          offset: Offset(-4, -4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SheetChrome(
                            onClose: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 6),
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
                          const SizedBox(height: 4),
                          Text(
                            'Scroll to centre · tap to open',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: NwsbColors.inkSoft,
                                  letterSpacing: 0.4,
                                ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 148,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_drift, _snap]),
                              builder: (context, _) => _CoverFlow(
                                focus: _focus,
                                drift: _drift.value,
                                glassOn: _glassOn,
                                onDragStart: _onDragStart,
                                onDragUpdate: _onDragUpdate,
                                onDragEnd: _onDragEnd,
                                onTileTap: _onTileTap,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _CenterLabel(focus: _focus, glassOn: _glassOn),
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
          width: 36,
          height: 4,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x55FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xDFFFFFFF)),
            ),
            child: const Icon(Icons.close_rounded,
                size: 18, color: NwsbColors.ink),
          ),
        ),
      ],
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({required this.focus, required this.glassOn});

  final double focus;
  final bool glassOn;

  @override
  Widget build(BuildContext context) {
    final i = focus.round().clamp(0, 2);
    final labels = <String>[
      glassOn ? 'Glassmorphism on' : 'Glassmorphism off',
      'Notifications',
      'Fashion home',
    ];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Text(
        labels[i],
        key: ValueKey('$i-$glassOn'),
        style: const TextStyle(
          color: NwsbColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
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
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTileTap,
  });

  final double focus;
  final double drift;
  final bool glassOn;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final ValueChanged<int> onTileTap;

  @override
  Widget build(BuildContext context) {
    // Subtle idle sway so the carousel never feels static.
    final sway = math.sin(drift * math.pi * 2) * 0.045;

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
            _ActionSpec(
              label: glassOn ? 'Glass on' : 'Glass off',
              body: _kBlurMark,
              active: glassOn,
            ),
            _ActionSpec(
              label: 'Alerts',
              body: NwsbMarks.bell,
              badge: badge,
              badgeLabel: badgeLabel,
            ),
            _ActionSpec(
              label: 'Fashion',
              body: NwsbMarks.moon,
            ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final cx = constraints.maxWidth / 2;
              final cy = constraints.maxHeight / 2;
              // Paint side tiles first so the centre tile sits on top.
              final order = List<int>.generate(items.length, (i) => i)
                ..sort((a, b) {
                  final da = (a - focus).abs();
                  final db = (b - focus).abs();
                  return db.compareTo(da);
                });

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final i in order)
                    _buildTile(
                      items[i],
                      i,
                      cx,
                      cy,
                      sway,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTile(
    _ActionSpec spec,
    int index,
    double cx,
    double cy,
    double sway,
  ) {
    final offset = (index - focus) + sway;
    final abs = offset.abs().clamp(0.0, 2.0);
    // Centre ~1.35×; sides fall off with depth.
    final scale = ui.lerpDouble(1.36, 0.78, (abs / 1.15).clamp(0.0, 1.0))!;
    final opacity = ui.lerpDouble(1.0, 0.42, (abs / 1.35).clamp(0.0, 1.0))!;
    final dx = offset * 78;
    final dy = abs * abs * 6;
    // Cover-flow yaw — perspective via Matrix4.
    final yaw = offset * 0.72;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.00185)
      ..translate(dx, dy, -abs * 28)
      ..rotateY(yaw)
      ..scale(scale, scale, 1.0);

    final size = _HeaderActionsSheetState._tile;

    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2 - 10,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: GestureDetector(
            onTap: () => onTileTap(index),
            child: _ActionTile(spec: spec, emphasized: abs < 0.35),
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
  const _ActionTile({required this.spec, required this.emphasized});

  final _ActionSpec spec;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final size = _HeaderActionsSheetState._tile;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: spec.active
                ? const Color(0xD9FFFFFF)
                : const Color(0xAFFFFFFF),
            border: Border.all(
              color: emphasized
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xDFFFFFFF),
              width: emphasized ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(emphasized ? 0x330B2447 : 0x220B2447),
                blurRadius: emphasized ? 22 : 14,
                offset: const Offset(0, 10),
              ),
              const BoxShadow(
                color: Color(0xCCFFFFFF),
                blurRadius: 10,
                offset: Offset(-3, -3),
              ),
            ],
          ),
          child: Center(
            child: NwsbIcon(
              spec.body,
              size: emphasized ? 28 : 24,
              color: const Color(0xFF31577F),
              strokeWidth: 1.75,
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
