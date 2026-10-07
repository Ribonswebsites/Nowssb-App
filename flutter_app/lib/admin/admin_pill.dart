/// Over the user app, for admins only: the gold "Admin" pill (tap = back to
/// NowssB Admin), so there is always a way back. Nothing on the user app
/// edits anything: editing is only in the admin UI Editor. Hidden from
/// everyone else, and inside the Admin app itself.
library;

import 'package:flutter/material.dart';

import 'admin_home.dart';
import 'admin_mode.dart';
import 'admin_state.dart';
import 'admin_ui.dart';
import 'template/ui_overrides.dart';

class AdminReturnPill extends StatefulWidget {
  const AdminReturnPill({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AdminReturnPill> createState() => _AdminReturnPillState();
}

class _AdminReturnPillState extends State<AdminReturnPill> {
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
    if (!AdminState.instance.isAdmin || AdminMode.instance.inAdmin) return widget.child;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final pill = Positioned(
      left: (size.width - 92).clamp(4, size.width - 82),
      top: (size.height - pad.bottom - 150).clamp(pad.top + 4, size.height - 100),
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
    return Stack(children: [widget.child, pill]);
  }
}
