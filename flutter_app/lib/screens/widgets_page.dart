/// Settings — the widgets and shortcuts page.
///
/// The website calls this Settings and describes it as "widgets and
/// shortcuts": which blocks appear on your home, and in what order. That
/// list is what `hlApplyLayout` in app/js/part062.js reads.
///
/// What is here now is the half of it that is real: the switches that
/// actually do something today — which home, whether backgrounds move — and
/// the doors to the pages that have been built. Reordering the home's blocks
/// needs the home to be built from a stored list rather than written out in
/// order, which is a change to the homes and not to this page, so it is named
/// here rather than faked with controls that do nothing.
library;

import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';
import 'fashion_plus.dart';
import 'sound_library.dart';

class WidgetsPage extends StatefulWidget {
  const WidgetsPage({super.key});

  @override
  State<WidgetsPage> createState() => _WidgetsPageState();
}

class _WidgetsPageState extends State<WidgetsPage> {
  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;

    return PageShell(
      eyebrow: 'Widgets and shortcuts',
      title: 'Settings',
      film: 'assets/video/hero-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            const DarkHead(
              eyebrow: 'How the app looks',
              title: 'Appearance',
              icon: Icons.tune,
            ),
            const SizedBox(height: 14),
            _Toggle(
              title: 'Fashion home',
              sub: 'The dark home with the film behind it, instead of the '
                  'pale neumorphic one',
              icon: Icons.dark_mode_outlined,
              on: s.fashionHome,
              onChanged: s.setFashionHome,
            ),
            _Toggle(
              title: 'Fashion Plus',
              sub: 'Page backgrounds play instead of holding their first '
                  'frame',
              icon: Icons.play_circle_outline,
              on: s.fashionPlus,
              onChanged: s.setFashionPlus,
            ),
            const SizedBox(height: 24),
            const DarkHead(
              eyebrow: 'Everything, one tap away',
              title: 'Shortcuts',
              icon: Icons.apps,
            ),
            const SizedBox(height: 14),
            _Door(
              title: 'Sound Library',
              sub: 'Root frequencies',
              icon: Icons.graphic_eq,
              go: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SoundLibraryScreen())),
            ),
            _Door(
              title: 'Fashion Plus',
              sub: 'Open the motion mode',
              icon: Icons.auto_awesome_motion_outlined,
              go: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FashionPlusScreen())),
            ),
          ]),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.sub,
    required this.icon,
    required this.on,
    required this.onChanged,
  });

  final String title;
  final String sub;
  final IconData icon;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on ? const Color(0x40C8A96E) : const Color(0x14FFFFFF),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 19,
                color: on ? NwsbColors.goldLight : const Color(0x8CFFFFFF)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0x8CFFFFFF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: on,
              onChanged: onChanged,
              activeThumbColor: NwsbColors.goldLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  const _Door({
    required this.title,
    required this.sub,
    required this.icon,
    required this.go,
  });

  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback go;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: go,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF14141C),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: NwsbColors.goldLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0x8CFFFFFF)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 16, color: Color(0xB3FFFFFF)),
          ],
        ),
      ),
    );
  }
}
