/// Native Flutter translation of app/widgets/neumorphic-essentials.html.
///
/// This is a standalone Normal Home section. It deliberately has no phone or
/// page frame around it; only the supplied timeline cards are surfaced.
library;

import 'package:flutter/material.dart';


import '../../theme/tokens.dart';
import '../daily_tasks.dart';
import 'glassmorphism_theme.dart';
import 'home_v4.dart' show V4Lottie, kMeditateLottie;
import '../../admin/template/editable.dart';

class NmSuppliedEssentials extends StatefulWidget {
  const NmSuppliedEssentials({super.key});

  @override
  State<NmSuppliedEssentials> createState() => _NmSuppliedEssentialsState();
}

class _NmSuppliedEssentialsState extends State<NmSuppliedEssentials> {
  var _expanded = false;

  static const _base = Color(0xFFECEEF2);
  static const _text = Color(0xFF2B2D33);
  static const _subtext = Color(0xFF8A8F9A);

  @override
  void initState() {
    super.initState();
    DailyTasks.items.addListener(_tick);
    DailyTasks.publish();
  }

  @override
  void dispose() {
    DailyTasks.items.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _openTasks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DailyTasksPage()),
    );
  }

  List<Widget> _taskEntries() {
    final all = DailyTasks.items.value;
    final tasks = _expanded || all.length <= 4 ? all : all.take(4).toList();
    return [
      for (var i = 0; i < tasks.length; i++)
        _TimelineEntry(
          hero: i == 0,
          icon: _iconFor(tasks[i].id),
          title: tasks[i].title,
          subtitle: tasks[i].done ? 'Done' : 'Still open',
          duration: tasks[i].done ? 'Done' : 'To do',
          active: tasks[i].done,
          lineOn: tasks[i].done,
          last: i == tasks.length - 1,
          onTap: _openTasks,
        ),
    ];
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'word':
        return Icons.menu_book_outlined;
      case 'player':
        return Icons.play_circle_outline;
      case 'read':
        return Icons.auto_stories_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 18),
            child: EditableLabel('neomorphic_essentials.NmSuppliedEssentials', 'Your essentials',
                style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w700, color: _text)),
          ),
          ..._taskEntries(),
          if (DailyTasks.items.value.length > 4)
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 4, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                  decoration: BoxDecoration(
                      color: glass ? const Color(0x66FFFFFF) : _base,
                      borderRadius: BorderRadius.circular(22),
                      border: glass
                          ? Border.all(
                              color: const Color(0xF2FFFFFF), width: 1.5)
                          : null,
                      boxShadow: glass ? null : NwsbShadows.raisedXs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_expanded ? 'See less' : 'See more',
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _subtext)),
                      const SizedBox(width: 10),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: glass ? const Color(0x66FFFFFF) : _base,
                            shape: BoxShape.circle,
                            border: glass
                                ? Border.all(
                                    color: const Color(0xF2FFFFFF), width: 1.5)
                                : null,
                            boxShadow: glass ? null : NwsbShadows.raisedXs),
                        child: Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: _subtext),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.icon,
    required this.title,
    required this.duration,
    this.subtitle,
    this.hero = false,
    this.active = false,
    this.lineOn = false,
    this.last = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String duration;
  final String? subtitle;
  final bool hero;
  final bool active;
  final bool lineOn;
  final bool last;
  final VoidCallback? onTap;

  static const _base = Color(0xFFECEEF2);

  @override
  Widget build(BuildContext context) {
    final card = hero
        ? _HeroEssential(
            icon: icon, title: title, subtitle: subtitle!, duration: duration)
        : _PillEssential(icon: icon, title: title, duration: duration);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: active
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFB794F6),
                                Color(0xFF7E57C2),
                              ],
                            )
                          : null,
                      color: active ? null : _base,
                      boxShadow: active
                          ? const [
                              BoxShadow(
                                  color: Color(0x337E57C2),
                                  blurRadius: 7,
                                  spreadRadius: 3),
                              BoxShadow(
                                  color: Color(0x55000000),
                                  offset: Offset(3, 3),
                                  blurRadius: 6),
                              BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-2, -2),
                                  blurRadius: 6),
                            ]
                          : NwsbShadows.raisedXs,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: lineOn
                          ? const Color(0xFF7E57C2)
                          : const Color(0xFFC7CDD9),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: GestureDetector(onTap: onTap, child: card))),
        ],
      ),
    );
  }
}

class _HeroEssential extends StatelessWidget {
  const _HeroEssential(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.duration});
  final IconData icon;
  final String title;
  final String subtitle;
  final String duration;

  static const _ink = Color(0xFF2A1848);
  static const _inkSoft = Color(0xFF3D2A66);

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 148),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB794F6), Color(0xFF7E57C2)]),
          boxShadow: NwsbShadows.raised,
        ),
        // No LayoutBuilder here: the timeline row sizes us with
        // IntrinsicHeight. B022: on narrow phones / large text the art moves
        // into the top row and the words take the full card width.
        child: Builder(builder: (context) {
          final narrow = _narrow(context);
          return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: narrow ? 0 : 88),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0x8CFFFFFF),
                            borderRadius: BorderRadius.circular(20)),
                        // Real dots, not '●' glyphs the bundled fonts lack.
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          for (var i = 0; i < 3; i++) ...[
                            const Icon(Icons.circle, size: 7, color: _ink),
                            const SizedBox(width: 3),
                          ],
                          const SizedBox(width: 4),
                          const EditableLabel('neomorphic_essentials.HeroEssential', '543',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: _ink,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const Spacer(),
                      if (narrow)
                        const V4Lottie(kMeditateLottie, size: 48)
                      else
                        const EditableLabel('neomorphic_essentials.HeroEssential', '•••',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: _ink)),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Icon(icon, size: 17, color: _ink),
                      const SizedBox(width: 8),
                      Expanded(
                          child: narrow
                              ? Text(title,
                                  maxLines: 3,
                                  softWrap: true,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _ink))
                              : EditableLabel('neomorphic_essentials.HeroEssential', title,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _ink)))
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.volume_up_outlined,
                          size: 15, color: _inkSoft),
                      const SizedBox(width: 6),
                      Expanded(
                          child: EditableLabel('neomorphic_essentials.HeroEssential', subtitle,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: _inkSoft)))
                    ]),
                    Padding(
                        padding: const EdgeInsets.only(left: 22, top: 2),
                        child: Text(duration,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: _inkSoft))),
                  ]),
            ),
            // The v4 'Your essentials' meditation Lottie (was the composing orb).
            if (!narrow)
              const Positioned(
                right: 0,
                bottom: 0,
                child: V4Lottie(kMeditateLottie, size: 64),
              ),
          ],
        );
        }),
      );
}

class _PillEssential extends StatelessWidget {
  const _PillEssential(
      {required this.icon, required this.title, required this.duration});
  final IconData icon;
  final String title;
  final String duration;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
            color: const Color(0xFFECEEF2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: NwsbShadows.raisedSm),
        // B022: on narrow phones / large text the circles go on top so the
        // title gets the full width (no LayoutBuilder: IntrinsicHeight).
        child: Builder(builder: (context) {
          final narrow = _narrow(context);
          final circles = <Widget>[
          Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Color(0xFFECEEF2),
                  shape: BoxShape.circle,
                  boxShadow: NwsbShadows.raisedXs),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFF9AA0AB), size: 18)),
          const SizedBox(width: 8),
          Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Color(0xFFECEEF2),
                  shape: BoxShape.circle,
                  boxShadow: NwsbShadows.raisedXs),
              child: Icon(icon, color: const Color(0xFF9AA0AB), size: 20)),
          ];
          const titleStyle = TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2D33));
          final text = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                narrow
                    ? Text(title, maxLines: 3, softWrap: true, style: titleStyle)
                    : EditableLabel('neomorphic_essentials.PillEssential', title,
                        style: titleStyle),
                const SizedBox(height: 3),
                Text(duration,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A8F9A)))
              ]);
          if (narrow) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: circles),
              const SizedBox(height: 10),
              text,
            ]);
          }
          return Row(children: [
            ...circles,
            const SizedBox(width: 14),
            Expanded(child: text),
          ]);
        }),
      );
}

/// Narrow = the essentials cards would leave under ~ 18 em for the words.
bool _narrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 400 * MediaQuery.textScalerOf(context).scale(1);
