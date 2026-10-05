/// Over the user app, for admins only: the gold "Admin" pill (tap = back to
/// NowssB Admin) and the floating "Edit layout" button (tap = pencils on/off,
/// long-press = NowssB Admin, drag to move). Hidden from everyone else, and
/// inside the Admin app itself. The Edit button can be switched off in
/// Admin → Control; the Admin pill stays so there is always a way back.
library;

import 'package:flutter/material.dart';

import 'admin_home.dart';
import 'admin_mode.dart';
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
  void initState() {
    super.initState();
    AdminMode.instance.addListener(_changed);
  }

  @override
  void dispose() {
    AdminMode.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _toAdmin() {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx != null) openAdminHome(ctx);
  }

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final edit = EditMode.instance;
    if (!AdminState.instance.isAdmin || AdminMode.instance.inAdmin) return widget.child;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final pos = _pos ?? Offset(size.width - 64, size.height - pad.bottom - 170);
    final pill = Positioned(
      left: (edit.fabVisible ? pos.dx - 14 : size.width - 92).clamp(4, size.width - 82),
      top: (edit.fabVisible ? pos.dy - 42 : size.height - pad.bottom - 150).clamp(pad.top + 4, size.height - 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: _toAdmin,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kAdminGold,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shield_moon_rounded, color: kAdminBg, size: 14),
              SizedBox(width: 4),
              Text('Admin', style: TextStyle(color: kAdminBg, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
    if (!edit.fabVisible) return Stack(children: [widget.child, pill]);
    return Stack(children: [
      widget.child,
      pill,
      Positioned(
        left: pos.dx.clamp(4, size.width - 56),
        top: pos.dy.clamp(pad.top + 4, size.height - 60),
        child: GestureDetector(
          onPanUpdate: (d) => setState(() => _pos = pos + d.delta),
          onLongPress: _toAdmin,
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
