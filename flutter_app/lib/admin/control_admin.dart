/// The top of the Control tab: the tools that act on the whole app
/// (push + banner, UI Editor, activity, audit log) and this phone's
/// editing switches. The live switches (force update, maintenance, flags)
/// follow underneath in settings_admin.dart.
library;

import 'package:flutter/material.dart';

import 'activity_admin.dart';
import 'admin_kit.dart';
import 'admin_state.dart';
import 'broadcast_admin.dart';
import 'editor/ui_editor_screen.dart';
import 'settings_admin.dart' show AuditLogScreen;
import 'template/all_slots_screen.dart';
import 'template/ui_overrides.dart';

class ControlTools extends StatelessWidget {
  const ControlTools({super.key});

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final edit = EditMode.instance;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TileGrid(children: [
        _Tool(Icons.campaign_rounded, 'Broadcast', 'Push to everyone, a plan, free or one person · in-app banner', kAmber,
            () => pushAdmin(context, const BroadcastAdminScreen())),
        _Tool(Icons.auto_awesome_mosaic_rounded, 'UI Editor', 'Change any page live, preview, publish', kGold, () {
          bigFeel();
          openUiEditor(context);
        }),
        _Tool(Icons.timeline_rounded, 'Activity', 'Sign-ups, logins, purchases, requests — live', kViolet,
            () => pushAdmin(context, const ActivityAdminScreen())),
        _Tool(Icons.history_rounded, 'Audit log', 'Every admin action, UI edit and settings version', kSky,
            () => pushAdmin(context, const AuditLogScreen())),
      ]),
      const SectionHead('This phone', 'Editing the user app'),
      Glass(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(children: [
          SwitchListTile(
            value: edit.on,
            onChanged: edit.setOn,
            activeThumbColor: kGold,
            title: const Text('Pencils on the user app', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Open the user app and tap a pencil on any picture, clip or line to replace it',
                style: TextStyle(color: kDim, fontSize: 12)),
          ),
          SwitchListTile(
            value: edit.fabPreference,
            onChanged: (v) => edit.setFab(v),
            activeThumbColor: kGold,
            title: const Text('Floating Edit button in the user app', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Tap = pencils on/off · hold = back to Admin', style: TextStyle(color: kDim, fontSize: 12)),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded, color: kGold),
            title: const Text('Every editable slot', style: TextStyle(color: Colors.white)),
            subtitle: Text('${UiOverrides.instance.all.length} changed', style: const TextStyle(color: kDim, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: kFaint),
            onTap: () => pushAdmin(context, const AllSlotsScreen()),
          ),
        ]),
      ),
    ]);
  }
}

class _Tool extends StatelessWidget {
  const _Tool(this.icon, this.title, this.sub, this.color, this.onTap);
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Glass(
        radius: 22,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14)]),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11.5)),
        ]),
      );
}
