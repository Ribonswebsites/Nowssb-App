/// The floating "Edit layout" button, over every screen, for admins only.
/// Tap: edit mode on/off (pencils on everything editable). Long-press: the
/// admin home. Hidden from everyone else and when switched off in Admin.
library;

import 'package:flutter/material.dart';

import 'admin_home.dart';
import 'admin_state.dart';
import 'admin_ui.dart';
import 'template/ui_overrides.dart';

class AdminEditFab extends StatefulWidget {
  const AdminEditFab({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AdminEditFab> createState() => _AdminEditFabState();
}

class _AdminEditFabState extends State<AdminEditFab> {
  Offset? _pos;

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final edit = EditMode.instance;
    if (!edit.fabVisible) return widget.child;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final pos = _pos ?? Offset(size.width - 64, size.height - pad.bottom - 170);
    return Stack(children: [
      widget.child,
      Positioned(
        left: pos.dx.clamp(4, size.width - 56),
        top: pos.dy.clamp(pad.top + 4, size.height - 60),
        child: GestureDetector(
          onPanUpdate: (d) => setState(() => _pos = pos + d.delta),
          onLongPress: () {
            final ctx = widget.navigatorKey.currentContext;
            if (ctx != null) openAdminHome(ctx);
          },
          child: Material(
            color: edit.on ? kAdminGold : const Color(0xE60C1220),
            shape: const CircleBorder(side: BorderSide(color: kAdminGold, width: 1.2)),
            elevation: 6,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: edit.toggle,
              child: SizedBox(
                width: 50,
                height: 50,
                child: Tooltip(
                  message: edit.on ? 'Done editing' : 'Edit layout (hold for Admin)',
                  child: Icon(edit.on ? Icons.check_rounded : Icons.edit_rounded,
                      color: edit.on ? kAdminBg : kAdminGold),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
