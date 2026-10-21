/// Layout pieces for the rebuilt Menu & Settings (`newui_menu_settings`),
/// built on the shared nowssb_ui kit (NGlass, GlassPill) over the app's
/// original background.
library;

import 'package:flutter/material.dart';

import '../../data/app_control.dart';
import '../../nowssb_ui/nowssb_ui.dart';
import '../../screens/fashion/header.dart';
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
  const MsScaffold({super.key, required this.title, this.subtitle, required this.children, this.background, this.trailing, this.icon = Icons.auto_awesome});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? background;
  final Widget? trailing;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    void back() => Navigator.of(context).maybePop();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Same backdrop as Home (AppBackdrop: the saved film or still).
        Positioned.fill(child: background ?? MsBackground.of(context)),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Home's own top bar; its menu button closes this page.
          HomeHeader(onMenu: canPop ? back : null),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40 + MediaQuery.paddingOf(context).bottom),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Title row like Home's "How can we help today?".
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(children: [
                    if (canPop)
                      Tooltip(
                        message: 'Back',
                        child: GestureDetector(
                          onTap: back,
                          child: const MsCircle(size: 48, child: Icon(Icons.arrow_back_rounded, size: 21, color: kMsInk)),
                        ),
                      )
                    else
                      MsCircle(size: 48, child: Icon(icon, size: 21, color: kMsInk)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.2)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: const TextStyle(color: kTextLo, fontSize: 13)),
                        ],
                      ]),
                    ),
                    if (trailing != null) trailing!,
                  ]),
                ),
                ...children,
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Home's ink colour for icons/text on white (neomorphic_action_bar.dart).
const kMsInk = Color(0xFF111827);

/// White circle as in Home's "How can we help today?" bar (_NeoCircle, glass).
class MsCircle extends StatelessWidget {
  const MsCircle({super.key, required this.size, required this.child});
  final double size;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xEBFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 6), blurRadius: 14)],
        ),
        child: Center(child: child),
      );
}

/// Home's white "Enter" pill (text + arrow).
class MsEnterPill extends StatelessWidget {
  const MsEnterPill({super.key, required this.label, this.onTap, this.danger = false});
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final ink = danger ? const Color(0xFFB00030) : kMsInk;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xEBFFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white),
          boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 18)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 15, color: ink),
        ]),
      ),
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

/// A titled dark-glass section, like Home's action bar surface.
class MsSection extends StatelessWidget {
  const MsSection({super.key, required this.title, this.note, required this.rows});
  final String title;
  final String? note;
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.2)),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
              child: Text(note!, style: const TextStyle(color: kTextLo, fontSize: 12)),
            ),
          for (final r in rows) Padding(padding: const EdgeInsets.only(bottom: 10), child: r),
        ]),
      );
}

/// One row = Home's Personal Coach pill: dark glass capsule, white circular
/// icon, bold label, white Enter pill (or a switch for toggles).
class MsRow extends StatelessWidget {
  const MsRow({super.key, required this.icon, required this.title, this.subtitle, this.onTap, this.action = 'Enter', this.danger = false, this.toggle});
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xA4070A11),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x2AFFFFFF)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(0, 12), blurRadius: 28)],
        ),
        child: Row(children: [
          MsCircle(size: 40, child: Icon(icon, size: 18, color: danger ? const Color(0xFFB00030) : kMsInk)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w800)),
              if (subtitle != null)
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextLo, fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 8),
          if (toggle != null)
            Switch(value: toggle!, activeTrackColor: const Color(0xFF7C5CFF), onChanged: (_) => onTap?.call())
          else
            MsEnterPill(label: action, onTap: onTap, danger: danger),
        ]),
      ),
    );
  }
}
