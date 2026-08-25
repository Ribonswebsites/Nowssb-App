import 'dart:async';

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
  const _EssentialItem({required this.icon, required this.title, required this.subtitle, required this.meta, required this.destination, this.featured = false, this.favorite = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final Object destination;
  final bool featured;
  final bool favorite;
}

class _HelpingItem {
  const _HelpingItem({required this.icon, required this.title, required this.subtitle, required this.destination, required this.asset});

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
    _EssentialItem(icon: Icons.mic_none_outlined, title: 'Today’s word ritual', subtitle: 'Today’s pronunciation', meta: '3–20 min', destination: Dest.player, featured: true, favorite: true),
    _EssentialItem(icon: Icons.graphic_eq_outlined, title: 'Sound Library', subtitle: 'Root frequencies for focused listening', meta: 'Explore', destination: Dest.sound, favorite: true),
    _EssentialItem(icon: Icons.lock_outline, title: 'Healing Journey', subtitle: 'Choose a body, organ or mind path', meta: 'Explore', destination: Dest.healing, favorite: true),
    _EssentialItem(icon: Icons.science_outlined, title: 'Word Science', subtitle: 'Discover the origin behind any word', meta: 'Explore', destination: Dest.library),
    _EssentialItem(icon: Icons.track_changes_outlined, title: 'My Progress', subtitle: 'See your practice and sound score', meta: 'Open', destination: Dest.profile, favorite: true),
    _EssentialItem(icon: Icons.repeat_rounded, title: 'Build your routine', subtitle: 'Set a daily practice system', meta: 'Open', destination: Dest.routines),
    _EssentialItem(icon: Icons.groups_outlined, title: 'Connect', subtitle: 'People, chat and the NowssB feed', meta: 'Open', destination: Dest.connect),
    _EssentialItem(icon: Icons.auto_awesome_outlined, title: 'Fashion Plus', subtitle: 'Explore the moving visual practice', meta: 'Open', destination: Dest.fashionPlus),
  ];

  static const _helping = <_HelpingItem>[
    _HelpingItem(icon: Icons.graphic_eq_outlined, title: 'Study Beats', subtitle: 'Focus Music', destination: Dest.sound, asset: 'assets/media/image/essentials-study-beats.png'),
    _HelpingItem(icon: Icons.nightlight_round, title: 'Pink Noise', subtitle: 'Sleep Music', destination: Dest.sound, asset: 'assets/media/image/essentials-pink-noise.png'),
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
        height: 200,
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

  Widget _heading(BuildContext context, String eyebrow, String title, Object dest) {
    final color = widget.fashion ? Colors.white : NwsbColors.ink;
    final faint = widget.fashion ? const Color(0xB3E8D5A3) : NwsbColors.inkFaint;
    final mark = title == 'Up next' ? NwsbMarks.reader : NwsbMarks.sound;
    return Row(
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
            child: NwsbIcon(mark, size: 23, color: widget.fashion ? const Color(0xFF171326) : NwsbColors.gold),
          ),
        ),
        const SizedBox(width: 14),
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
    final visible = _essentialsExpanded ? _essentials : _essentials.take(3).toList(growable: false);
    final shell = widget.fashion
        ? _glass(child: _essentialStack(context, visible), padding: const EdgeInsets.all(14))
        : NeuCard(radius: 26, padding: const EdgeInsets.all(14), child: _essentialStack(context, visible));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
            child: Center(child: NwsbIcon(NwsbMarks.sliders, size: 23, color: widget.fashion ? const Color(0xFF171326) : NwsbColors.gold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR DAILY PRACTICE', style: TextStyle(color: widget.fashion ? const Color(0xB3E8D5A3) : NwsbColors.inkFaint, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
                const SizedBox(height: 3),
                Text('Your essentials', style: TextStyle(color: headingColor, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.7)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      shell,
      if (_essentials.length > 3)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextButton.icon(
            onPressed: () => setState(() => _essentialsExpanded = !_essentialsExpanded),
            icon: Icon(_essentialsExpanded ? Icons.expand_less : Icons.expand_more, size: 19),
            label: Text(_essentialsExpanded ? 'Show less' : 'See more'),
            style: TextButton.styleFrom(
              foregroundColor: widget.fashion ? Colors.white : NwsbColors.ink,
              backgroundColor: widget.fashion ? const Color(0x221FFFFFF) : const Color(0xFFF4F2EE),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            ),
          ),
        ),
      const SizedBox(height: 30),
      Row(
        children: [
          Expanded(child: Text('What’s helping others', style: TextStyle(color: headingColor, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.4))),
          Material(
            color: widget.fashion ? const Color(0x2EFFFFFF) : NwsbColors.surface,
            shape: const CircleBorder(),
            elevation: widget.fashion ? 0 : 2,
            child: IconButton(
              tooltip: 'Open Word Science',
              onPressed: () => Dest.open(context, Dest.library),
              icon: Icon(Icons.chevron_right, color: widget.fashion ? Colors.white : NwsbColors.ink, size: 25),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 228,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(right: 4, bottom: 4),
          itemCount: _helping.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final item = _helping[index];
            return _helpCard(context, item);
          },
        ),
      ),
    ]);
  }

  Widget _essentialStack(BuildContext context, List<_EssentialItem> items) => Stack(
        children: [
          Positioned(
            left: 9,
            top: items.isNotEmpty && items.first.featured ? 214 : 26,
            bottom: 28,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: widget.fashion ? const Color(0x66FFFFFF) : const Color(0x4D7B7F8A),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(left: 0, top: 14, child: _railDot(active: true)),
          Positioned(left: 2, top: 236, child: _railDot()),
          Positioned(left: 2, top: 318, child: _railDot()),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
                    child: _essentialRow(context, items[i]),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _railDot({bool active = false}) => Container(
        width: active ? 18 : 14,
        height: active ? 18 : 14,
        decoration: BoxDecoration(
          color: active ? (widget.fashion ? const Color(0xFFFF9C26) : const Color(0xFFFF8B27)) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: active ? Colors.transparent : (widget.fashion ? const Color(0x99FFFFFF) : const Color(0x4D7B7F8A)), width: 2),
          boxShadow: active ? const [BoxShadow(color: Color(0x447B4B16), blurRadius: 7)] : null,
        ),
      );

  Widget _essentialRow(BuildContext context, _EssentialItem item) {
    if (item.featured) {
      final featured = ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/media/image/essentials-featured-ritual.png', fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xB8FFD000), Color(0x36FFB51B), Color(0x08FF8121)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(.78), borderRadius: BorderRadius.circular(99)), child: const Text('NOWSSB · 543', style: TextStyle(color: Color(0xFF3A3024), fontSize: 11, fontWeight: FontWeight.w800))),
                    const SizedBox(height: 13),
                    const Text('Today’s word ritual', style: TextStyle(color: Color(0xFF28252A), fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 9),
                    Text(item.subtitle, style: const TextStyle(color: Color(0xFF3F392F), fontSize: 13)),
                    const SizedBox(height: 9),
                    Text(item.meta, style: const TextStyle(color: Color(0xFF3F392F), fontSize: 12)),
                  ],
                ),
              ),
              Positioned(right: 18, top: 18, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(.78), shape: BoxShape.circle), child: const Icon(Icons.graphic_eq, color: Color(0xFF3C3424), size: 19))),
            ],
          ),
        ),
      );
      return Semantics(button: true, label: item.title, child: InkWell(onTap: () => Dest.open(context, item.destination), borderRadius: BorderRadius.circular(23), child: featured));
    }
    final text = widget.fashion ? Colors.white : const Color(0xFF4C4A52);
    final sub = widget.fashion ? const Color(0x99FFFFFF) : const Color(0xFF68666B);
    final card = Container(constraints: const BoxConstraints(minHeight: 69), padding: const EdgeInsets.symmetric(horizontal: 17), decoration: BoxDecoration(color: widget.fashion ? const Color(0x8C141027) : const Color(0xFFF7F5F2), borderRadius: BorderRadius.circular(21), border: widget.fashion ? Border.all(color: Colors.white.withOpacity(.13)) : null, boxShadow: const [BoxShadow(color: Color(0x143D3747), blurRadius: 12, offset: Offset(0, 7))]), child: Row(children: [Icon(item.icon, size: 18, color: widget.fashion ? Colors.white70 : const Color(0xFF45434A)), const SizedBox(width: 10), Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w600))), Text(item.meta, style: TextStyle(color: sub, fontSize: 12)), const SizedBox(width: 8), Icon(Icons.chevron_right, color: sub, size: 22)]));
    return Semantics(button: true, label: item.title, child: InkWell(onTap: () => Dest.open(context, item.destination), borderRadius: BorderRadius.circular(21), child: card));
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
            color: widget.fashion ? const Color(0x8C141027) : const Color(0xFFF7F5F2),
            borderRadius: radius,
            boxShadow: const [BoxShadow(color: Color(0x143D3747), blurRadius: 12, offset: Offset(0, 7))],
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
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.fashion ? Colors.white : NwsbColors.ink, fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.fashion ? const Color(0x99FFFFFF) : NwsbColors.inkFaint, fontSize: 11, height: 1.25)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(button: true, label: item.title, child: InkWell(onTap: () => Dest.open(context, item.destination), borderRadius: radius, child: card));
  }

  Widget _startPracticeButton(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(999), child: InkWell(onTap: () => Dest.open(context, Dest.player), borderRadius: BorderRadius.circular(999), child: Padding(padding: const EdgeInsets.fromLTRB(19, 8, 8, 8), child: Row(mainAxisSize: MainAxisSize.min, children: [const Text('Start practice', style: TextStyle(color: NwsbColors.ink, fontSize: 13, fontWeight: FontWeight.w800)), const SizedBox(width: 14), Container(width: 34, height: 34, decoration: const BoxDecoration(color: Color(0xFF080B13), shape: BoxShape.circle), child: const Icon(Icons.arrow_forward, color: Colors.white, size: 19))]))));


  Widget _glass({required Widget child, required EdgeInsets padding}) => Container(padding: padding, decoration: BoxDecoration(color: const Color(0x7810132B), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x2DFFFFFF)), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 12))]), child: child);
}
