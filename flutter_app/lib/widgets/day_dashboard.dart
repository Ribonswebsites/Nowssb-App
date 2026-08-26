import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../shell/go.dart';
import '../theme/tokens.dart';
import 'neumorphic.dart';
import 'nwsb_icon.dart';

/// The four local-time experiences used by both home modes.
enum NwsbDaySlot { morning, afternoon, evening, night }

extension NwsbDaySlotText on NwsbDaySlot {
  String get title {
    switch (this) {
      case NwsbDaySlot.morning:
        return 'Morning Resonance';
      case NwsbDaySlot.afternoon:
        return 'Afternoon Reset';
      case NwsbDaySlot.evening:
        return 'Evening Release';
      case NwsbDaySlot.night:
        return 'Night Restoration';
    }
  }

  String get subtitle {
    switch (this) {
      case NwsbDaySlot.morning:
        return 'Begin with a clear tone';
      case NwsbDaySlot.afternoon:
        return 'Return to the sound in the middle of the day';
      case NwsbDaySlot.evening:
        return 'Let the day settle through sound';
      case NwsbDaySlot.night:
        return 'Close the day with a quieter frequency';
    }
  }

  String get file {
    switch (this) {
      case NwsbDaySlot.morning:
        return 'time-morning';
      case NwsbDaySlot.afternoon:
        return 'time-afternoon';
      case NwsbDaySlot.evening:
        return 'time-evening';
      case NwsbDaySlot.night:
        return 'time-night';
    }
  }
}

NwsbDaySlot nwsbDaySlot([DateTime? at]) {
  final hour = (at ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 12) return NwsbDaySlot.morning;
  if (hour >= 12 && hour < 17) return NwsbDaySlot.afternoon;
  if (hour >= 17 && hour < 21) return NwsbDaySlot.evening;
  return NwsbDaySlot.night;
}

/// Focus / Progress / Up Next. The data source is intentionally small and
/// local: a fresh install starts at zero, and the recorder increments it after
/// a successful scored attempt. Account sync can be added without changing the
/// visual contract.
class NwsbDayDashboard extends StatefulWidget {
  const NwsbDayDashboard({super.key, required this.fashion});

  final bool fashion;
  static const _streakKey = 'nwsb_dashboard_streak';
  static const _sessionsKey = 'nwsb_dashboard_sessions';
  static const _wordsKey = 'nwsb_dashboard_words';
  static const _lastPracticeKey = 'nwsb_dashboard_last_practice';

  /// Called by the native player after a successful Worker score.
  static Future<void> recordPractice(String word) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final day = '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      final last = prefs.getString(_lastPracticeKey);
      final sessions = (prefs.getInt(_sessionsKey) ?? 0) + 1;
      final words = {...prefs.getStringList('${_wordsKey}_set') ?? <String>[]};
      if (word.trim().isNotEmpty) words.add(word.trim().toUpperCase());
      var streak = prefs.getInt(_streakKey) ?? 0;
      if (last != day) {
        streak = streak + 1;
        await prefs.setString(_lastPracticeKey, day);
      }
      await prefs.setInt(_sessionsKey, sessions);
      await prefs.setInt(_streakKey, streak);
      await prefs.setStringList('${_wordsKey}_set', words.toList());
      await prefs.setInt(_wordsKey, words.length);
    } catch (_) {}
  }

  @override
  State<NwsbDayDashboard> createState() => _NwsbDayDashboardState();
}

class _EssentialItem {
  const _EssentialItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.meta,
      required this.destination,
      required this.asset,
      this.featured = false,
      this.favorite = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final Object destination;
  final String asset;
  final bool featured;
  final bool favorite;
}

class _HelpingItem {
  const _HelpingItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.destination,
      required this.asset});

  final IconData icon;
  final String title;
  final String subtitle;
  final Object destination;
  final String asset;
}

class _NwsbDayDashboardState extends State<NwsbDayDashboard> {
  NwsbDaySlot _slot = nwsbDaySlot();
  int _streak = 0;
  int _sessions = 0;
  int _words = 0;
  bool _essentialsExpanded = false;
  Timer? _clock;

  static const _essentials = <_EssentialItem>[
    _EssentialItem(
        icon: Icons.mic_none_outlined,
        title: 'Today’s word ritual',
        subtitle: 'Today’s pronunciation',
        meta: '3–20 min',
        destination: Dest.player,
        asset: 'assets/media/image/essentials-featured-ritual-v2.png',
        featured: true,
        favorite: true),
    _EssentialItem(
        icon: Icons.graphic_eq_outlined,
        title: 'Sound Library',
        subtitle: 'Root frequencies for focused listening',
        meta: 'Explore',
        destination: Dest.sound,
        asset: 'assets/media/image/essentials-sound-library-v2.png',
        favorite: true),
    _EssentialItem(
        icon: Icons.lock_outline,
        title: 'Healing Journey',
        subtitle: 'Choose a body, organ or mind path',
        meta: 'Explore',
        destination: Dest.healing,
        asset: 'assets/media/image/essentials-healing-journey-v2.png',
        favorite: true),
    _EssentialItem(
        icon: Icons.science_outlined,
        title: 'Word Science',
        subtitle: 'Discover the origin behind any word',
        meta: 'Explore',
        destination: Dest.library,
        asset: 'assets/media/image/essentials-word-science-v2.png'),
    _EssentialItem(
        icon: Icons.track_changes_outlined,
        title: 'My Progress',
        subtitle: 'See your practice and sound score',
        meta: 'Open',
        destination: Dest.profile,
        asset: 'assets/media/image/essentials-progress-v2.png',
        favorite: true),
    _EssentialItem(
        icon: Icons.repeat_rounded,
        title: 'Build your routine',
        subtitle: 'Set a daily practice system',
        meta: 'Open',
        destination: Dest.routines,
        asset: 'assets/media/image/essentials-routine-v2.png'),
    _EssentialItem(
        icon: Icons.groups_outlined,
        title: 'Connect',
        subtitle: 'People, chat and the NowssB feed',
        meta: 'Open',
        destination: Dest.connect,
        asset: 'assets/media/image/essentials-connect-v2.png'),
    _EssentialItem(
        icon: Icons.auto_awesome_outlined,
        title: 'Fashion Plus',
        subtitle: 'Explore the moving visual practice',
        meta: 'Open',
        destination: Dest.fashionPlus,
        asset: 'assets/media/image/essentials-fashion-plus-v2.png'),
  ];

  static const _helping = <_HelpingItem>[
    _HelpingItem(
        icon: Icons.graphic_eq_outlined,
        title: 'Study Beats',
        subtitle: 'Focus Music',
        destination: Dest.sound,
        asset: 'assets/media/image/essentials-study-beats-v2.png'),
    _HelpingItem(
        icon: Icons.nightlight_round,
        title: 'Pink Noise',
        subtitle: 'Sleep Music',
        destination: Dest.sound,
        asset: 'assets/media/image/essentials-pink-noise-v2.png'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = nwsbDaySlot();
      if (next != _slot && mounted) setState(() => _slot = next);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _streak = prefs.getInt(NwsbDayDashboard._streakKey) ?? 0;
        _sessions = prefs.getInt(NwsbDayDashboard._sessionsKey) ?? 0;
        _words = prefs.getInt(NwsbDayDashboard._wordsKey) ?? 0;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final focus = _focusCard(context);
    final progress = _progressCard(context);
    final upNext = _upNextCard(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        focus,
        const SizedBox(height: 24),
        _heading(
          context,
          widget.fashion ? 'Your practice' : 'Your meditation',
          widget.fashion ? 'Your Progress' : 'Meditation progress',
          Dest.profile,
        ),
        const SizedBox(height: 12),
        progress,
        const SizedBox(height: 24),
        _heading(context, 'Keep the ritual moving', 'Up next', Dest.routines),
        const SizedBox(height: 12),
        upNext,
        const SizedBox(height: 30),
        _essentialsSection(context),
      ],
    );
  }

  Widget _focusCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        // On narrow phones the reference title wraps to two lines. The former
        // 200px card left no room for the subtitle and action button and caused
        // the entire home list to report a RenderFlex overflow.
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NwsbVideo(
              key: ValueKey(_slot.file),
              asset: 'assets/video/${_slot.file}.mp4',
              poster: 'assets/video/${_slot.file}-poster.webp',
              priority: ClipPriority.feature,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xB8070A18),
                    const Color(0x55070A18),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Dest.open(context, Dest.player),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 285),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TODAY’S FOCUS',
                            style: TextStyle(
                              color: Color(0xE6E8D5A3),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            _slot.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              letterSpacing: -.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _slot.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _startPracticeButton(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(
      BuildContext context, String eyebrow, String title, Object dest) {
    final normal = !widget.fashion;
    final reference = true;
    final color = widget.fashion ? const Color(0xFF1C1C1C) : NwsbColors.ink;
    final faint =
        widget.fashion ? const Color(0xFF6B6B7D) : const Color(0xFFA4A7B0);
    final accent = widget.fashion ? const Color(0xFF6D5BD0) : NwsbColors.gold;
    final mark = title == 'Up next' ? NwsbMarks.reader : NwsbMarks.sound;
    final discSize = reference ? 58.0 : 52.0;
    final icon = title == 'Meditation progress'
        ? Icon(Icons.track_changes_outlined, size: 28, color: accent)
        : title == 'Up next'
            ? Icon(Icons.calendar_today_outlined,
                size: reference ? 25 : 21, color: accent)
            : NwsbIcon(mark, size: reference ? 27 : 23, color: accent);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: discSize,
          height: discSize,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.fashion
                ? Colors.white.withOpacity(.74)
                : NwsbColors.surface,
            shape: BoxShape.circle,
            border: widget.fashion
                ? Border.all(color: Colors.black.withOpacity(.06))
                : null,
            boxShadow: widget.fashion
                ? const [
                    BoxShadow(
                        color: Color(0x19311A50),
                        blurRadius: 14,
                        offset: Offset(0, 6))
                  ]
                : NwsbShadows.raisedXs,
          ),
          child: Center(child: icon),
        ),
        SizedBox(width: normal ? 15 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: TextStyle(
                  color: faint,
                  fontSize: reference ? 12 : 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: reference ? 2.8 : 1.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: reference ? 26 : 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: reference ? -.9 : -.4,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Dest.open(context, dest),
          style: TextButton.styleFrom(
            foregroundColor:
                widget.fashion ? const Color(0xFF1C1C1C) : NwsbColors.ink,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
          ),
          child: Text(
            'View all  ›',
            style: TextStyle(
                fontSize: reference ? 15 : 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _progressCard(BuildContext context) {
    final goal = (_sessions * 10).clamp(0, 100);
    final children = widget.fashion
        ? [
            _stat(Icons.check_circle_outline, '$_sessions', 'tasks done'),
            _stat(Icons.timer_outlined, '${_words}m', 'focused time'),
            _stat(
                Icons.local_fire_department_outlined, '$_streak', 'day streak'),
            _stat(Icons.track_changes_outlined, '$goal%', 'goal progress'),
          ]
        : [
            _stat(Icons.check_circle_outline, '$_sessions',
                'meditation sessions'),
            _stat(Icons.timer_outlined, '$_words', 'words in practice'),
            _stat(
                Icons.local_fire_department_outlined, '$_streak', 'day streak'),
            _stat(Icons.track_changes_outlined, '$goal%', 'meditation goal'),
          ];
    final card = Row(children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) _divider(),
        Expanded(child: children[i])
      ]
    ]);
    if (!widget.fashion) {
      return NeuCard(
        radius: 26,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: card,
      );
    }
    return _glassReference(child: card, radius: 24);
  }

  Widget _stat(IconData icon, String value, String label) {
    final normal = !widget.fashion;
    final accent = widget.fashion ? const Color(0xFF6D5BD0) : NwsbColors.gold;
    final size = normal || widget.fashion ? 54.0 : 38.0;
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: normal ? 0 : 17, horizontal: normal ? 4 : 6),
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: widget.fashion
                  ? Colors.white.withOpacity(.82)
                  : NwsbColors.surface,
              shape: BoxShape.circle,
              border: widget.fashion
                  ? Border.all(color: Colors.black.withOpacity(.06))
                  : null,
              boxShadow: widget.fashion
                  ? const [
                      BoxShadow(
                          color: Color(0x19311A50),
                          blurRadius: 14,
                          offset: Offset(0, 6))
                    ]
                  : NwsbShadows.raisedXs,
            ),
            child: Icon(icon,
                size: normal || widget.fashion ? 25 : 20, color: accent),
          ),
          SizedBox(height: normal ? 11 : 9),
          Text(
            value,
            style: TextStyle(
              color: widget.fashion ? const Color(0xFF1C1C1C) : NwsbColors.ink,
              fontSize: normal || widget.fashion ? 25 : 21,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          SizedBox(height: normal ? 8 : 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: widget.fashion
                  ? const Color(0xFF6B6B7D)
                  : NwsbColors.inkFaint,
              fontSize: normal || widget.fashion ? 11 : 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1,
      height: 108,
      color:
          widget.fashion ? const Color(0x80FFFFFF) : const Color(0x141A1A2E));

  Widget _upNextCard(BuildContext context) {
    final rows = Column(
      children: [
        _upNextRow(context, 'Open today’s practice',
            'Choose a word and begin your next sound ritual', Dest.player),
        _upNextDivider(),
        _upNextRow(context, 'Build your routine', 'Set a daily practice system',
            Dest.routines),
      ],
    );
    if (widget.fashion) return _glassReference(child: rows, radius: 24);
    return NeuCard(radius: 26, padding: EdgeInsets.zero, child: rows);
  }

  Widget _upNextRow(
      BuildContext context, String title, String subtitle, Object destination) {
    final normal = !widget.fashion;
    final iconColor =
        widget.fashion ? const Color(0xFF6D5BD0) : NwsbColors.gold;
    final textColor = widget.fashion ? const Color(0xFF1C1C1C) : NwsbColors.ink;
    final subColor =
        widget.fashion ? const Color(0xFF6B6B7D) : NwsbColors.inkFaint;
    final iconSize = normal || widget.fashion ? 48.0 : 44.0;
    return InkWell(
      onTap: () => Dest.open(context, destination),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: normal || widget.fashion ? 20 : 15,
            vertical: normal || widget.fashion ? 17 : 15),
        child: Row(children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: widget.fashion
                  ? Colors.white.withOpacity(.82)
                  : NwsbColors.surface,
              shape: BoxShape.circle,
              border: widget.fashion
                  ? Border.all(color: Colors.black.withOpacity(.06))
                  : null,
              boxShadow: widget.fashion
                  ? const [
                      BoxShadow(
                          color: Color(0x19311A50),
                          blurRadius: 12,
                          offset: Offset(0, 5))
                    ]
                  : NwsbShadows.raisedXs,
            ),
            child: Icon(Icons.calendar_today_outlined,
                size: normal || widget.fashion ? 23 : 20, color: iconColor),
          ),
          SizedBox(width: normal || widget.fashion ? 14 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: textColor,
                        fontSize: normal || widget.fashion ? 17 : 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: subColor,
                        fontSize: normal || widget.fashion ? 13 : 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward,
              color:
                  widget.fashion ? const Color(0xFF9797A8) : NwsbColors.inkSoft,
              size: normal || widget.fashion ? 22 : 20),
        ]),
      ),
    );
  }

  Widget _upNextDivider() => Divider(
      height: 1,
      thickness: 1,
      color:
          widget.fashion ? const Color(0x59FFFFFF) : const Color(0x141A1A2E));

  Widget _essentialsSection(BuildContext context) {
    final visible = _essentialsExpanded
        ? _essentials
        : _essentials.take(4).toList(growable: false);
    final timeline = Column(
      children: [
        _essentialFeatured(context, visible.first),
        for (var i = 1; i < visible.length; i++)
          _essentialTimelineRow(context, visible[i]),
      ],
    );
    final shell = widget.fashion
        ? _glass(child: timeline, padding: const EdgeInsets.all(14))
        : NeuCard(
            radius: 28, padding: const EdgeInsets.all(14), child: timeline);
    final headingColor = widget.fashion ? Colors.white : NwsbColors.ink;
    final eyebrowColor =
        widget.fashion ? const Color(0xB3E8D5A3) : NwsbColors.inkFaint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: widget.fashion ? Colors.white : NwsbColors.surface,
                shape: BoxShape.circle,
                boxShadow: widget.fashion ? null : NwsbShadows.raisedXs,
              ),
              child: Center(
                  child: NwsbIcon(NwsbMarks.sliders,
                      size: 23,
                      color: widget.fashion
                          ? const Color(0xFF171326)
                          : NwsbColors.gold)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR DAILY PRACTICE',
                      style: TextStyle(
                          color: eyebrowColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8)),
                  const SizedBox(height: 3),
                  Text('Your essentials',
                      style: TextStyle(
                          color: headingColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        shell,
        if (_essentials.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _essentialsExpanded = !_essentialsExpanded),
              icon: Icon(
                  _essentialsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18),
              label: Text(_essentialsExpanded ? 'Show less' : 'See more'),
              style: TextButton.styleFrom(
                foregroundColor: widget.fashion ? Colors.white : NwsbColors.ink,
                backgroundColor: widget.fashion
                    ? const Color(0x221FFFFFF)
                    : const Color(0xFFF4F2EE),
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _essentialFeatured(BuildContext context, _EssentialItem item) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        // The reference card is compact, but the title wraps on 360px phones.
        // Give the text a little more vertical room so the native home never
        // throws a RenderFlex overflow during its first layout.
        height: 172,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(item.asset, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.fashion
                      ? const [
                          Color(0xD9FFB44D),
                          Color(0x9AFF8A3D),
                          Color(0x22111118)
                        ]
                      : const [
                          Color(0xE6FFB44D),
                          Color(0xB8FF8A3D),
                          Color(0x33111118)
                        ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.55),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('NOWSSB · 543',
                        style: TextStyle(
                            color: Color(0xFF6B3F13),
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  Text(item.title,
                      style: const TextStyle(
                          color: Color(0xFF4A2A09),
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(item.subtitle,
                      style: const TextStyle(
                          color: Color(0xFF5C3812),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.meta,
                      style: const TextStyle(
                          color: Color(0xFF5C3812),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.78),
                    shape: BoxShape.circle),
                child: const Icon(Icons.graphic_eq,
                    color: Color(0xFF3C3424), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
        button: true,
        label: item.title,
        child: InkWell(
            onTap: () => Dest.open(context, item.destination),
            borderRadius: BorderRadius.circular(26),
            child: card));
  }

  Widget _essentialTimelineRow(BuildContext context, _EssentialItem item) {
    // The home is a sliver list with unbounded vertical constraints. IntrinsicHeight
    // gives the dotted rail the finite height of its pill; without it, the
    // stretch row passes h=Infinity into the rail Column and the whole home body
    // is discarded by Flutter's layout assertion.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 26),
                _essentialDot(),
                Expanded(
                    child: CustomPaint(
                        painter: _DottedTrackPainter(widget.fashion
                            ? const Color(0x6670707A)
                            : const Color(0x4D7B7F8A)))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _essentialPill(context, item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _essentialDot() => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: widget.fashion ? const Color(0x66FFFFFF) : NwsbColors.surface,
          shape: BoxShape.circle,
          boxShadow: widget.fashion ? null : NwsbShadows.raisedXs,
        ),
      );

  Widget _essentialPill(BuildContext context, _EssentialItem item) {
    final text = widget.fashion ? const Color(0xFFF2F2F2) : NwsbColors.ink;
    final sub = widget.fashion ? const Color(0x99FFFFFF) : NwsbColors.inkFaint;
    final surface = Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: widget.fashion ? const Color(0xC7000000) : NwsbColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            widget.fashion ? Border.all(color: const Color(0x1AFFFFFF)) : null,
        boxShadow: widget.fashion
            ? const [
                BoxShadow(
                    color: Color(0x243C425A),
                    blurRadius: 16,
                    offset: Offset(0, 6))
              ]
            : NwsbShadows.raisedSm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.fashion
                  ? Colors.white.withOpacity(.92)
                  : NwsbColors.surface,
              shape: BoxShape.circle,
              boxShadow: widget.fashion ? null : NwsbShadows.raisedXs,
            ),
            child: Icon(item.icon,
                size: 20,
                color: widget.fashion
                    ? const Color(0xFF6D7280)
                    : const Color(0xFF9AA0AB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: sub, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item.meta,
              style: TextStyle(
                  color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward,
              color: widget.fashion ? Colors.white70 : NwsbColors.inkSoft,
              size: 20),
        ],
      ),
    );
    return Semantics(
        button: true,
        label: item.title,
        child: InkWell(
            onTap: () => Dest.open(context, item.destination),
            borderRadius: BorderRadius.circular(20),
            child: surface));
  }

  Widget _helpCard(BuildContext context, _HelpingItem item) {
    final radius = BorderRadius.circular(22);
    final card = SizedBox(
      width: 190,
      height: 220,
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.fashion
                ? const Color(0x8C141027)
                : const Color(0xFFF7F5F2),
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(
                  color: Color(0x143D3747),
                  blurRadius: 12,
                  offset: Offset(0, 7))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 124,
                child: Image.asset(item.asset, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: widget.fashion
                                  ? Colors.white
                                  : NwsbColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: widget.fashion
                                  ? const Color(0x99FFFFFF)
                                  : NwsbColors.inkFaint,
                              fontSize: 11,
                              height: 1.25)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
        button: true,
        label: item.title,
        child: InkWell(
            onTap: () => Dest.open(context, item.destination),
            borderRadius: radius,
            child: card));
  }

  Widget _startPracticeButton(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
          onTap: () => Dest.open(context, Dest.player),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(19, 8, 8, 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Start practice',
                    style: TextStyle(
                        color: NwsbColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 14),
                Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: Color(0xFF080B13), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 19))
              ]))));

  Widget _glassReference(
      {required Widget child,
      required double radius,
      EdgeInsets padding = EdgeInsets.zero}) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x47FFFFFF),
            borderRadius: shape,
            border: Border.all(color: const Color(0x8CFFFFFF)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x2E1F1A50),
                  blurRadius: 32,
                  offset: Offset(0, 8)),
              BoxShadow(
                  color: Color(0x80FFFFFF),
                  blurRadius: 0,
                  offset: Offset(0, -1)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glass({required Widget child, required EdgeInsets padding}) =>
      Container(
          padding: padding,
          decoration: BoxDecoration(
              color: const Color(0x7810132B),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x2DFFFFFF)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 22,
                    offset: Offset(0, 12))
              ]),
          child: child);
}

class _DottedTrackPainter extends CustomPainter {
  const _DottedTrackPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 5.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2, (y + dash).clamp(0, size.height).toDouble()),
          paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedTrackPainter oldDelegate) =>
      oldDelegate.color != color;
}
