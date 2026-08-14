/// Fashion Plus — the switch that makes the still ones move.
///
/// Off, every page background in the app is its clip's own first frame: a
/// picture, costing nothing, and the pool is never even asked for a decoder.
/// On, those same backgrounds play.
///
/// It is off by default and this page says why in plain words rather than
/// hiding it: moving pictures cost battery, and someone should be able to
/// decide that for themselves. That is the same posture the website takes,
/// and it is the honest one — "7 changes · Fashion home · Off by default".
library;

import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../theme/tokens.dart';
import '../widgets/intro_gate.dart';
import '../widgets/page_shell.dart';

class FashionPlusScreen extends StatefulWidget {
  const FashionPlusScreen({super.key});

  @override
  State<FashionPlusScreen> createState() => _FashionPlusScreenState();
}

class _FashionPlusScreenState extends State<FashionPlusScreen> {
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

  /// What the switch actually changes. Named rather than counted, because
  /// "7 changes" tells nobody anything.
  static const _changes = [
    ('Page backgrounds', 'Every store, library and intro page'),
    ('The homes', 'The hero and the section films'),
    ('The televisions', 'The tablet screens on both homes'),
    ('The banners', 'The wide films between sections'),
    ('The word page', 'The film behind a word'),
    ('The Sound Library', 'Its archive backdrop'),
    ('This page', 'The one you are looking at'),
  ];

  @override
  Widget build(BuildContext context) {
    final on = Settings.instance.fashionPlus;

    return IntroGate(
      tag: 'Fashion · Plus',
      eyebrow: 'Experience',
      title: 'The still ones\nstart moving.',
      body: 'The Fashion home in motion — the tiles, the practice card, and '
          'every page that was wearing a photograph. One switch, and the '
          'battery it costs.',
      stats: [
        '${_changes.length} changes',
        'Fashion home',
        on ? 'On' : 'Off by default',
      ],
      film: 'assets/video/fashion-plus-bg.mp4',
      enterLabel: 'ENTER FASHION PLUS',
      child: PageShell(
        eyebrow: 'Experience',
        title: 'Fashion Plus',
        film: 'assets/video/fashion-plus-bg.mp4',
        onBack: () => Navigator.of(context).maybePop(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(children: [
              _Switch(
                on: on,
                onChanged: (v) => Settings.instance.setFashionPlus(v),
              ),
              const SizedBox(height: 24),
              const DarkHead(
                eyebrow: 'What the switch touches',
                title: 'Seven things',
                icon: Icons.auto_awesome_motion_outlined,
              ),
              const SizedBox(height: 14),
              for (final (title, sub) in _changes)
                _ChangeRow(title: title, sub: sub, on: on),
              const SizedBox(height: 18),
              const _Cost(),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: on ? const Color(0x1FC8A96E) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? const Color(0x59C8A96E) : const Color(0x1FFFFFFF),
          ),
        ),
        child: Row(
          children: [
            Icon(
              on ? Icons.play_circle : Icons.pause_circle_outline,
              size: 32,
              color: on ? NwsbColors.goldLight : const Color(0x8CFFFFFF),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    on ? 'Motion is on' : 'Motion is off',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    on
                        ? 'Backgrounds are playing'
                        : 'Backgrounds are holding their first frame',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0x99FFFFFF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
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

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.title, required this.sub, required this.on});
  final String title;
  final String sub;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(
            on ? Icons.play_arrow : Icons.image_outlined,
            size: 15,
            color: on ? NwsbColors.goldLight : const Color(0x66FFFFFF),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
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
        ],
      ),
    );
  }
}

class _Cost extends StatelessWidget {
  const _Cost();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.battery_saver_outlined,
              size: 16, color: NwsbColors.goldLight),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'A still costs nothing at all — with motion off the app never '
              'even asks the phone for a decoder. With it on, at most four '
              'clips decode at once, which is what keeps this from being '
              'the thing that drains the battery.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0x99FFFFFF),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
