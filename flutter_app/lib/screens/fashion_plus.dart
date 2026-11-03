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

import '../widgets/glass_list_card.dart';
import '../widgets/nwsb_choice_chip.dart';
import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../theme/tokens.dart';
import '../widgets/intro_gate.dart';
import '../widgets/concept/r27/how_it_works.dart';
import '../widgets/banner_mix.dart';
import '../widgets/page_shell.dart';
import '../admin/template/editable.dart';
import '../admin/layout/layout_sections.dart';

/// Which part of Fashion Plus a caller opens. [all] is the full page behind
/// its intro; the other two open straight onto one chooser — the Drop Studio
/// "Background" door (the video list) and "Start art" door (the still list,
/// the one that writes `nwsb_fashplus_image`).
enum FashionPlusMode { all, background, startArt }

class FashionPlusScreen extends StatefulWidget {
  const FashionPlusScreen({super.key, this.mode = FashionPlusMode.all});

  final FashionPlusMode mode;

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
    if (widget.mode != FashionPlusMode.all) {
      final video = widget.mode == FashionPlusMode.background;
      return PageShell(
        eyebrow: 'Zen Plus',
        title: video ? 'Background' : 'Start art',
        film: 'assets/video/fashion-plus-bg-6.mp4',
        fashionDim: true,
        onBack: () => Navigator.of(context).maybePop(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(children: [
              if (video) ...[
                _Switch(on: on, onChanged: (v) => Settings.instance.setFashionPlus(v)),
                const SizedBox(height: 14),
              ],
              _BackgroundChooser(videos: video),
            ]),
          ),
        ],
      );
    }

    return IntroGate(
      tag: 'Zen · Plus',
      eyebrow: 'Experience',
      title: 'The still ones\nstart moving.',
      body: 'The Zen home in motion — the tiles, the practice card, and '
          'every page that was wearing a photograph. One switch, and the '
          'battery it costs.',
      stats: [
        '${_changes.length} changes',
        'Zen home',
        on ? 'On' : 'Off by default',
      ],
      art: 'assets/fashion/fp-intro.webp',
      enterLabel: 'ENTER ZEN PLUS',
      child: r27Guide('plus', r27PlusGuide, PageShell(
        eyebrow: 'Experience',
        title: 'Zen Plus',
        film: 'assets/video/fashion-plus-bg-6.mp4',
        fashionDim: true,
        onBack: () => Navigator.of(context).maybePop(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(
                // Server-driven order (Admin → UI Editor); bundled order by default.
                children: layoutChildren(context, 'fashionplus', [
              LSection(
                  'switch',
                  'Zen Plus switch',
                  _Switch(
                    on: on,
                    onChanged: (v) => Settings.instance.setFashionPlus(v),
                  )),
              const SizedBox(height: 14),
              const LSection('banners', 'Banner mix', BannerMix(seed: 2)),
              const SizedBox(height: 14),
              const LSection(
                  'backgrounds', 'Background chooser', _BackgroundChooser()),
              const SizedBox(height: 24),
              LSection(
                  'changes',
                  'What the switch touches',
                  GlassListCard(
                    margin: EdgeInsets.zero,
                    icon: Icons.auto_awesome_motion_outlined,
                    overline: 'What the switch touches',
                    title: 'Seven things',
                    children: [
                      for (final (title, sub) in _changes)
                        GlassTile(
                          icon: on ? Icons.play_arrow_rounded : Icons.image_outlined,
                          title: title,
                          sub: sub,
                          trailing: const SizedBox.shrink(),
                        ),
                    ],
                  )),
              const SizedBox(height: 18),
              const LSection('cost', 'Cost', _Cost()),
            ])),
          ),
        ],
      )),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Settings.instance,
      builder: (context, _) {
        final currentOn = Settings.instance.fashionPlus;
        return GestureDetector(
          onTap: () => onChanged(!currentOn),
          behavior: HitTestBehavior.opaque,
          child: GlassListCard(
            margin: EdgeInsets.zero,
            icon: currentOn ? Icons.play_arrow_rounded : Icons.pause_rounded,
            overline: 'Zen Plus',
            title: currentOn ? 'Motion is on' : 'Motion is off',
            subtitle: currentOn
                ? 'Backgrounds are playing'
                : 'Backgrounds are holding their first frame',
            trailing: Switch(
              value: currentOn,
              onChanged: onChanged,
              activeThumbColor: NwsbColors.goldLight,
            ),
          ),
        );
      },
    );
  }
}

class _BackgroundChooser extends StatelessWidget {
  const _BackgroundChooser({this.videos});

  /// null: follow the switch (videos when motion is on). true / false: pin
  /// the video list or the start-art stills.
  final bool? videos;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Settings.instance,
      builder: (_, __) {
        final settings = Settings.instance;
        final motionOn = videos ?? settings.fashionPlus;
        final pinnedStill = videos == false;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                motionOn
                    ? 'Selected Zen Plus video'
                    : pinnedStill
                        ? 'Start art'
                        : 'Background when motion is off',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                motionOn
                    ? 'This video plays behind every page.'
                    : 'Choose one still for every page, or keep default black.',
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (motionOn)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < Settings.fashionVideos.length; i++)
                      _BackgroundChoice(
                        label: Settings.fashionVideoNames[i],
                        selected: settings.fashionVideoIndex == i,
                        onTap: () => Settings.instance.setFashionVideo(i),
                      ),
                  ],
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BackgroundChoice(
                      label: 'Default black',
                      selected: settings.fashionImageIndex < 0,
                      onTap: () => Settings.instance.setFashionImage(null),
                    ),
                    for (var i = 0; i < Settings.fashionImages.length; i++)
                      _BackgroundChoice(
                        label: Settings.fashionImageName(i),
                        selected: settings.fashionImageIndex == i,
                        onTap: () => Settings.instance.setFashionImage(i),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BackgroundChoice extends StatelessWidget {
  const _BackgroundChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => NwsbChoiceChip(
        label: EditableLabel('fashion_plus.BackgroundChoice', label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
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
