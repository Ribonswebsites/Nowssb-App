/// Shared look for the rebuilt Menu & Settings (`newui_menu_settings`).
/// Frosted MeditationCard-style glass over the app's original background.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/app_control.dart';
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

const kTextLo = Color(0xB3FFFFFF);

/// Frosted card: white 17%, blur 18, 24px radius, 1px white 30% border.
class MsGlass extends StatelessWidget {
  const MsGlass({super.key, required this.child, this.radius = 24, this.padding = const EdgeInsets.all(16), this.blur = true});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool blur;
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
          Colors.white.withValues(alpha: .22),
          Colors.white.withValues(alpha: .08),
        ]),
        border: Border.all(color: Colors.white.withValues(alpha: .30)),
      ),
      child: Material(type: MaterialType.transparency, child: Padding(padding: padding, child: child)),
    );
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations == true;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: const [
        BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
      ]),
      child: ClipRRect(
        borderRadius: r,
        child: blur && !reduce
            ? BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: box)
            : box,
      ),
    );
  }
}

/// Small pill: white with dark text, or violet filled for the primary action.
class MsPill extends StatelessWidget {
  const MsPill({super.key, required this.label, this.onTap, this.primary = false, this.danger = false});
  final String label;
  final VoidCallback? onTap;
  final bool primary, danger;
  @override
  Widget build(BuildContext context) {
    final bg = primary ? const Color(0xFF7C5CFF) : danger ? const Color(0xFFFFE3E8) : Colors.white;
    final fg = primary ? Colors.white : danger ? const Color(0xFFB00030) : const Color(0xFF17142A);
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.only(bottom: 14),
        child: MsGlass(
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
            MsPill(label: action, onTap: onTap, danger: danger),
        ]),
      ),
    );
  }
}
