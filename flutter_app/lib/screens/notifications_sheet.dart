/// Notifications glass sheet — `.nt-overlay` / `.nt-sheet` from part064.js.
///
/// The bell opens this centered sheet, not the settings page. Gear / Manage
/// leads through to [NotificationsSettingsPage].
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/notifications.dart';
import '../features/notifications/notif_router.dart';
import '../widgets/nwsb_coin_fly.dart';
import '../widgets/nwsb_icon.dart';
import '../widgets/restyle_kit.dart';
import 'notifications_settings.dart';
import '../admin/template/editable.dart';

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
                  child: GlassWrap(
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
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
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                                  child: _EmptyState(masterOn: store.master),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                                  shrinkWrap: true,
                                  itemCount: store.feed.length,
                                  itemBuilder: (context, i) {
                                    final n = store.feed[i];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _SheetItem(
                                        item: n,
                                        label: store.labelOf(n.type),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          NotifRouter.instance.openItem(n);
                                        },
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
                const Text('INBOX',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 2.4, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const EditableLabel('notifications_sheet.SheetHead',
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                EditableLabel('notifications_sheet.SheetHead',
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0x8CFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          KitRoundButton(icon: Icons.settings_outlined, size: 38, onTap: onGear, label: 'Settings'),
          const SizedBox(width: 10),
          KitRoundButton(icon: Icons.close, size: 38, onTap: onClose, label: 'Close'),
        ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x24FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
                child: const EditableLabel('notifications_sheet.SheetFoot',
                  'Clear all',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const EditableLabel('notifications_sheet.SheetFoot',
                  'Manage',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B0B10),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Column(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(child: NwsbIcon(NwsbMarks.bell, size: 22, color: Colors.black)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            masterOn ? 'You are all caught up' : 'Notifications are off',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            masterOn
                ? 'New updates land here — orders, messages, offers, your routine and everything else you have switched on.'
                : 'Turn them back on from the gear above to start receiving updates again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0x8CFFFFFF),
              height: 1.45,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xF2050507),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KindIcon(type: item.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!item.read) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('New', style: TextStyle(color: Color(0xFF0B0B10), fontSize: 10.5, fontWeight: FontWeight.w800)),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: item.read ? FontWeight.w600 : FontWeight.w700,
                            color: item.read ? const Color(0xB3FFFFFF) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0x8CFFFFFF),
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '$label · ${NotifStore.ago(item.at)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: Color(0x8CFFFFFF),
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
  const _KindIcon({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final child = type == 'coins'
        ? const NwsbCoinDisc(size: 22)
        : NwsbIcon(_markFor(type), size: 18, color: Colors.white);
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: child,
    );
  }

  static String _markFor(String type) => switch (type) {
        'update' => NwsbMarks.word,
        'orders' || 'delivery' || 'cart' => NwsbMarks.bag,
        'subscription' => NwsbMarks.crown,
        'offers' => NwsbMarks.trending,
        'routine' => NwsbMarks.hourglass,
        'streak' => NwsbMarks.features,
        _ => NwsbMarks.bell,
      };
}
