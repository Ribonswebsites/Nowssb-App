/// The Quick actions sheet, opened by Quick on both homes (the greeting /
/// header Quick and the Your day Quick button).
///
/// Built like the Menu / Settings cards ([GlassListCard]): a dark
/// translucent glass card, then black tiles with a white circle mark and a
/// plain label. Four shortcuts, each opens on one tap: Notifications,
/// Store, Player and Zen Plus.
library;

import '../../shell/tablet.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/notifications.dart';
import '../../data/settings.dart';
import '../fashion_plus.dart';
import '../../widgets/glass_list_card.dart' show kGlassTile;
import '../../widgets/nwsb_icon.dart';
import '../../admin/template/editable.dart';
import 'package:nowssb/data/app_haptics.dart';

/// Zen Plus droplet.
const _kZenMark = '<path d="M12 3.6c3.3 4.1 5.6 7.2 5.6 10.1a5.6 5.6 0 0 1-11.2 0c0-2.9 2.3-6 5.6-10.1z"/>';

Future<void> showHeaderActionsSheet(
  BuildContext context, {
  required VoidCallback onNotifications,
  VoidCallback? onStore,
  VoidCallback? onPlayer,
}) {
  AppHaptics.light();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Quick actions',
    barrierColor: const Color(0xB7040812),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, secondary) {
      return TabletSheet(child: HeaderActionsSheet(
        onNotifications: onNotifications,
        onStore: onStore,
        onPlayer: onPlayer,
      ));
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
    required this.onNotifications,
    this.onStore,
    this.onPlayer,
  });

  final VoidCallback onNotifications;
  final VoidCallback? onStore;
  final VoidCallback? onPlayer;

  @override
  State<HeaderActionsSheet> createState() => _HeaderActionsSheetState();
}

class _HeaderActionsSheetState extends State<HeaderActionsSheet> {
  /// One tap opens one thing; a second tap during the close is ignored.
  bool _opened = false;

  void _open(String id) {
    if (_opened) return;
    _opened = true;
    AppHaptics.medium();
    final nav = Navigator.of(context);
    switch (id) {
      case 'notifications':
        nav.pop();
        Future<void>.delayed(const Duration(milliseconds: 220), widget.onNotifications);
      case 'store':
        nav.pop();
        widget.onStore?.call();
      case 'player':
        nav.pop();
        widget.onPlayer?.call();
      case 'zenplus':
        nav.pop();
        nav.push(MaterialPageRoute<void>(builder: (_) => const FashionPlusScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    const ids = Settings.availableQuickActions;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    key: const ValueKey('quick-actions-sheet'),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xD914141C),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x8C000000), blurRadius: 60, offset: Offset(0, 26)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SheetHead(onClose: () => Navigator.of(context).pop()),
                        const SizedBox(height: 14),
                        ListenableBuilder(
                          listenable: NotifStore.instance,
                          builder: (context, _) {
                            final unread = NotifStore.instance.unreadRaw;
                            final text = NotifStore.instance.badgeText;
                            final badge = unread <= 0 ? null : (text.isEmpty ? '${unread > 99 ? 99 : unread}' : text);
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < ids.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(
                                    child: _ActionTile(
                                      key: ValueKey('tile-$i-${_label(ids[i])}'),
                                      label: _label(ids[i]),
                                      mark: _mark(ids[i]),
                                      badge: ids[i] == 'notifications' ? badge : null,
                                      onTap: () => _open(ids[i]),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
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

  static String _label(String id) => switch (id) {
        'notifications' => 'Notifications',
        'store' => 'Store',
        'player' => 'Player',
        'zenplus' => 'Zen Plus',
        _ => id,
      };

  static String _mark(String id) => switch (id) {
        'notifications' => NwsbMarks.bell,
        'store' => NwsbMarks.bag,
        'player' => NwsbMarks.play,
        'zenplus' => _kZenMark,
        _ => NwsbMarks.features,
      };
}

class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const NwsbIcon(NwsbMarks.features, size: 21, color: Color(0xFF0B0B10), strokeWidth: 1.9),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: EditableLabel('header_actions_sheet.SheetHead',
            'Quick actions',
            maxLines: 1,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Close',
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// A black Menu-style tile: white circle mark over a plain label.
class _ActionTile extends StatefulWidget {
  const _ActionTile({
    super.key,
    required this.label,
    required this.mark,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String mark;
  final VoidCallback onTap;
  final String? badge;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
            decoration: BoxDecoration(
              color: kGlassTile,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: NwsbIcon(widget.mark, size: 20, color: const Color(0xFF0B0B10), strokeWidth: 1.9),
                      ),
                      if (widget.badge != null)
                        Positioned(
                          top: -4,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0342B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.badge!,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: -0.1),
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
