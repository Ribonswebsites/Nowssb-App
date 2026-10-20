/// Layout pieces for the rebuilt Menu & Settings (`newui_menu_settings`),
/// built on the shared nowssb_ui kit (NGlass, GlassPill) over the app's
/// original background.
library;

import 'package:flutter/material.dart';

import '../../data/app_control.dart';
import '../../nowssb_ui/nowssb_ui.dart';
import '../../widgets/app_backdrop.dart';

const String kMenuSettingsFlag = 'newui_menu_settings';

/// ON for everyone; remote `false` is the kill switch. Tests can pin it.
class MenuSettingsFlag {
  MenuSettingsFlag._();
  static bool? debugOverride;
  static bool get isOn {
    if (debugOverride != null) return debugOverride!;
    try {
      return AppControl.instance.flags[kMenuSettingsFlag] != false;
    } catch (_) {
      return true;
    }
  }
}

const kTextLo = NTokens.textLo;

/// Large-surface blur for the shared NGlass.
const double kMsBlur = 18;

/// Pill on the shared kit: white (default), violet solid (primary) or
/// outlined (danger).
Widget msPill(String label, VoidCallback? onTap, {Key? key, bool primary = false, bool danger = false}) =>
    GlassPill(key: key, label: label, onTap: onTap, dense: true,
        style: primary ? PillStyle.solid : danger ? PillStyle.outlined : PillStyle.white);

/// Scaffold: original background + safe list + back + title.
class MsScaffold extends StatelessWidget {
  const MsScaffold({super.key, required this.title, this.subtitle, required this.children, this.background, this.trailing});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? background;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: background ?? MsBackground.of(context)),
        SafeArea(
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (canPop)
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              const Spacer(),
              if (trailing != null) trailing!,
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(color: kTextLo, fontSize: 13)),
                ],
              ]),
            ),
            ...children,
          ])),
        ),
      ]),
    );
  }
}

/// Lets tests swap the video backdrop for a still.
class MsBackground extends InheritedWidget {
  const MsBackground({super.key, required this.background, required super.child});
  final Widget background;
  static Widget of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<MsBackground>()?.background ?? const AppBackdrop();
  @override
  bool updateShouldNotify(MsBackground old) => false;
}

/// A titled glass section with rows.
class MsSection extends StatelessWidget {
  const MsSection({super.key, required this.title, this.note, required this.rows});
  final String title;
  final String? note;
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: NGlass(
          blur: kMsBlur,
          // Low elevation: the kit glow spread into the neighbouring card.
          elevation: .35,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if (note != null) Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(note!, style: const TextStyle(color: kTextLo, fontSize: 12)),
            ),
            const SizedBox(height: 4),
            ...rows,
          ]),
        ),
      );
}

class MsRow extends StatelessWidget {
  const MsRow({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.action = 'Open', this.danger = false, this.toggle});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final String action;
  final bool danger;
  final bool? toggle;
  @override
  Widget build(BuildContext context) {
    final c = danger ? const Color(0xFFFFB3C0) : Colors.white;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(color: kTextLo, fontSize: 12)),
            ]),
          ),
          if (toggle != null)
            Switch(value: toggle!, activeTrackColor: const Color(0xFF7C5CFF), onChanged: (_) => onTap?.call())
          else
            msPill(action, onTap, danger: danger),
        ]),
      ),
    );
  }
}
