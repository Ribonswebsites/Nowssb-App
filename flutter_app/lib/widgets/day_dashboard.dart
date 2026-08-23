import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../shell/go.dart';
import '../theme/tokens.dart';
import 'neumorphic.dart';

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
  const _EssentialItem({required this.icon, required this.title, required this.subtitle, required this.meta, required this.destination, this.featured = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final Object destination;
  final bool featured;
}

class _NwsbDayDashboardState extends State<NwsbDayDashboard> {

  NwsbDaySlot _slot = nwsbDaySlot();
  int _streak = 0;
  int _sessions = 0;
  int _words = 0;
  Timer? _clock;

  static const _essentials = <_EssentialItem>[
    _EssentialItem(icon: Icons.mic_none_outlined, title: 'Today’s word ritual', subtitle: 'Listen, speak and score your next word', meta: '3–20 min', destination: Dest.player, featured: true),
    _EssentialItem(icon: Icons.graphic_eq_outlined, title: 'Sound Library', subtitle: 'Root frequencies for focused listening', meta: 'Explore', destination: Dest.sound),
    _EssentialItem(icon: Icons.auto_awesome_outlined, title: 'Word Science', subtitle: 'Discover what a word truly means', meta: 'Explore', destination: Dest.library),
    _EssentialItem(icon: Icons.route_outlined, title: 'Healing Journey', subtitle: 'Choose a body, organ or mind path', meta: 'Explore', destination: Dest.healing),
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
        _heading(context, 'Your practice', 'Your Progress', Dest.profile),
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
        height: 214,
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
                          _pill('Start practice  →'),
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

  Widget _heading(BuildContext context, String eyebrow, String title, Object dest) {
    final color = widget.fashion ? Colors.white : NwsbColors.ink;
    final faint = widget.fashion ? const Color(0xB3E8D5A3) : NwsbColors.inkFaint;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: TextStyle(color: faint, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
              const SizedBox(height: 3),
              Text(title, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.4)),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Dest.open(context, dest),
          style: TextButton.styleFrom(foregroundColor: widget.fashion ? Colors.white : NwsbColors.ink, padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
          child: const Text('View all  ›', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _progressCard(BuildContext context) {
    final goal = (_sessions * 10).clamp(0, 100);
    final children = [
      _stat(Icons.check_circle_outline, '$_sessions', 'tasks done'),
      _stat(Icons.timer_outlined, '${_words}m', 'focused time'),
      _stat(Icons.local_fire_department_outlined, '$_streak', 'day streak'),
      _stat(Icons.track_changes_outlined, '$goal%', 'goal progress'),
    ];
    final card = Row(children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) _divider(), Expanded(child: children[i])]]);
    if (!widget.fashion) return NeuCard(radius: 22, padding: EdgeInsets.zero, child: card);
    return _glass(child: card, padding: EdgeInsets.zero);
  }

  Widget _stat(IconData icon, String value, String label) {
    final accent = widget.fashion ? const Color(0xFFE8D5A3) : NwsbColors.gold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 6),
      child: Column(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: widget.fashion ? Colors.white.withOpacity(.10) : NwsbColors.surface, shape: BoxShape.circle, boxShadow: widget.fashion ? null : NwsbShadows.raisedXs), child: Icon(icon, size: 20, color: accent)),
          const SizedBox(height: 9),
          Text(value, style: TextStyle(color: widget.fashion ? Colors.white : NwsbColors.ink, fontSize: 21, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: widget.fashion ? const Color(0x99FFFFFF) : NwsbColors.inkFaint, fontSize: 10, height: 1.2)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 74, color: widget.fashion ? const Color(0x24FFFFFF) : const Color(0x141A1A2E));

  Widget _upNextCard(BuildContext context) {
    final surface = widget.fashion
        ? _glass(child: Column(children: [_upNextRow(context, 'Open today’s practice', 'Choose a word and begin your next sound ritual', Dest.player), _upNextDivider(), _upNextRow(context, 'Build your routine', 'Set a daily practice system', Dest.routines)]), padding: EdgeInsets.zero)
        : NeuCard(radius: 22, padding: EdgeInsets.zero, child: Column(children: [_upNextRow(context, 'Open today’s practice', 'Choose a word and begin your next sound ritual', Dest.player), _upNextDivider(), _upNextRow(context, 'Build your routine', 'Set a daily practice system', Dest.routines)]));
    return surface;
  }

  Widget _upNextRow(BuildContext context, String title, String subtitle, Object destination) {
    final iconColor = widget.fashion ? const Color(0xFFE8D5A3) : NwsbColors.gold;
    final textColor = widget.fashion ? Colors.white : NwsbColors.ink;
    final subColor = widget.fashion ? const Color(0x99FFFFFF) : NwsbColors.inkFaint;
    return InkWell(
      onTap: () => Dest.open(context, destination),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: widget.fashion ? Colors.white.withOpacity(.10) : NwsbColors.surface, shape: BoxShape.circle, boxShadow: widget.fashion ? null : NwsbShadows.raisedXs), child: Icon(Icons.calendar_today_outlined, size: 20, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subColor, fontSize: 11))])),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: widget.fashion ? Colors.white70 : NwsbColors.inkSoft, size: 20),
        ]),
      ),
    );
  }

  Widget _upNextDivider() => Divider(height: 1, thickness: 1, color: widget.fashion ? const Color(0x24FFFFFF) : const Color(0x141A1A2E));

  Widget _essentialsSection(BuildContext context) {
    final headingColor = widget.fashion ? Colors.white : NwsbColors.ink;
    final faint = widget.fashion ? const Color(0xB3FFFFFF) : NwsbColors.inkFaint;
    final shell = widget.fashion
        ? _glass(child: _essentialStack(context), padding: const EdgeInsets.all(12))
        : NeuCard(radius: 26, padding: const EdgeInsets.all(12), child: _essentialStack(context));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('YOUR DAILY PATHS', style: TextStyle(color: faint, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8)), const SizedBox(height: 4), Text('Your essentials', style: TextStyle(color: headingColor, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.7))])), Text('NOWSSB', style: TextStyle(color: widget.fashion ? const Color(0xFFE8D5A3) : NwsbColors.gold, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.2))]),
      const SizedBox(height: 13),
      shell,
    ]);
  }

  Widget _essentialStack(BuildContext context) => Stack(children: [
    Positioned(left: 17, top: 27, bottom: 27, child: Container(width: 2, decoration: BoxDecoration(color: widget.fashion ? const Color(0x66FFFFFF) : const Color(0x4D7B7F8A), borderRadius: BorderRadius.circular(2)))),
    Column(children: [for (var i = 0; i < _essentials.length; i++) Padding(padding: EdgeInsets.only(bottom: i == _essentials.length - 1 ? 0 : 9), child: _essentialRow(context, _essentials[i]))]),
  ]);

  Widget _essentialRow(BuildContext context, _EssentialItem item) {
    final textColor = Colors.white;
    final subColor = const Color(0x99FFFFFF);
    final card = Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
      decoration: BoxDecoration(color: const Color(0xFF090A0E), borderRadius: BorderRadius.circular(18), border: widget.fashion ? Border.all(color: Colors.white.withOpacity(.13)) : null, boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 7))]),
      child: Row(children: [
        SizedBox(width: 32, child: Center(child: Container(width: item.featured ? 15 : 12, height: item.featured ? 15 : 12, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: const Color(0xFF090A0E), width: 2))))),
        const SizedBox(width: 8),
        Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Icon(item.icon, size: 20, color: Color(0xFF090A0E))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subColor, fontSize: 11))])),
        const SizedBox(width: 8),
        Text(item.meta, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
      ]),
    );
    return Semantics(button: true, label: item.title, child: InkWell(onTap: () => Dest.open(context, item.destination), borderRadius: BorderRadius.circular(18), child: card));
  }

  Widget _pill(String text) => DecoratedBox(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5))]), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), child: Text(text, style: const TextStyle(color: NwsbColors.ink, fontSize: 12, fontWeight: FontWeight.w800))));

  Widget _glass({required Widget child, required EdgeInsets padding}) => Container(padding: padding, decoration: BoxDecoration(color: const Color(0x7810132B), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x2DFFFFFF)), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 12))]), child: child);
}
