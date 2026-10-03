/// Settings › Notifications › Preferences — one switch per category, quiet
/// hours, and the daily reminder time (the same time Profile's "Daily
/// Reminder" sets). Changes re-plan the local schedules at once.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../admin/layout/layout_sections.dart';
import '../../admin/template/editable.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/page_shell.dart';
import 'notif_categories.dart';
import 'notif_prefs.dart';
import 'notif_scheduler.dart';

const _gold = Color(0xFFE8D5A3);
const _muted = Color(0x99FFFFFF);

String _fmt(BuildContext context, int minute) =>
    TimeOfDay(hour: minute ~/ 60, minute: minute % 60).format(context);

Future<int?> _pick(BuildContext context, int minute) async {
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

class NotifPreferencesScreen extends StatefulWidget {
  const NotifPreferencesScreen({super.key});

  @override
  State<NotifPreferencesScreen> createState() => _NotifPreferencesScreenState();
}

class _NotifPreferencesScreenState extends State<NotifPreferencesScreen> {
  final prefs = NotifPrefs.instance;

  @override
  void initState() {
    super.initState();
    prefs.load(fresh: true);
  }

  @override
  void dispose() {
    NotifScheduler.instance.replanSoon();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'What reaches you',
      title: 'Preferences',
      film: 'assets/video/hero-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: prefs,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: layoutChildren(context, 'notifications.preferences', [
                  LSection('timing', 'Timing', _TimingCard(prefs: prefs)),
                  for (final g in NotifCategories.groups)
                    LSection('group-${g.toLowerCase().replaceAll(' ', '-')}', g,
                        _GroupCard(group: g, prefs: prefs)),
                  const LSection('footnote', 'Footnote', _Footnote()),
                  const SizedBox(height: 28),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 18, bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0x99E8D5A3)),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required String sub, this.trailing, this.onTap}) : line = sub;
  final Widget title;

  /// Often built from the person's own times, so not an editable slot.
  final String line;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle.merge(
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      child: title,
                    ),
                    const SizedBox(height: 2),
                    Text(line, style: const TextStyle(fontSize: 11.5, height: 1.3, color: _muted)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      );
}

class _TimePill extends StatelessWidget {
  const _TimePill(this.value);

  /// A time on the clock — data, not copy (stays out of the template editor).
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x1AE8D5A3),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x4DE8D5A3)),
        ),
        child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NwsbColors.goldLight)),
      );
}

class _TimingCard extends StatelessWidget {
  const _TimingCard({required this.prefs});
  final NotifPrefs prefs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Head('Timing'),
        GlassWrap(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _Row(
                title: const EditableLabel('notif_preferences_screen.TimingCard', 'Daily reminder'),
                sub: 'When the word of the day arrives',
                trailing: _TimePill(_fmt(context, prefs.reminder)),
                onTap: () async {
                  final v = await _pick(context, prefs.reminder);
                  if (v != null) await prefs.setReminder(v);
                },
              ),
              _Row(
                title: const EditableLabel('notif_preferences_screen.TimingCard', 'Quiet hours'),
                sub: prefs.quietOn
                    ? 'Silent from ${_fmt(context, prefs.quietFrom)} to ${_fmt(context, prefs.quietTo)}. Offers wait; nothing else makes a sound.'
                    : 'Off — notifications may sound at any hour',
                trailing: Switch(
                  value: prefs.quietOn,
                  activeThumbColor: _gold,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    prefs.setQuiet(on: v);
                  },
                ),
              ),
              if (prefs.quietOn) ...[
                _Row(
                  title: const EditableLabel('notif_preferences_screen.TimingCard', 'Quiet from'),
                  sub: 'Start of quiet hours',
                  trailing: _TimePill(_fmt(context, prefs.quietFrom)),
                  onTap: () async {
                    final v = await _pick(context, prefs.quietFrom);
                    if (v != null) await prefs.setQuiet(from: v);
                  },
                ),
                _Row(
                  title: const EditableLabel('notif_preferences_screen.TimingCard', 'Quiet until'),
                  sub: 'End of quiet hours',
                  trailing: _TimePill(_fmt(context, prefs.quietTo)),
                  onTap: () async {
                    final v = await _pick(context, prefs.quietTo);
                    if (v != null) await prefs.setQuiet(to: v);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.prefs});
  final String group;
  final NotifPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final items = [for (final c in NotifCategories.all) if (c.group == group) c];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(group),
        GlassWrap(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              for (final c in items)
                _Row(
                  title: Text(c.label),
                  sub: c.sub,
                  trailing: Switch(
                    value: prefs.isOn(c),
                    activeThumbColor: _gold,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      prefs.setOn(c, v);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(6, 16, 6, 0),
        child: EditableLabel(
          'notif_preferences_screen.Footnote',
          'Each kind has its own channel in Android’s notification settings, where you can also change its sound or hide it from the lock screen.',
          style: TextStyle(fontSize: 11, height: 1.4, color: _muted),
        ),
      );
}

/// The one entry on Settings › Notifications that opens this page.
class NotifPreferencesEntry extends StatelessWidget {
  const NotifPreferencesEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: GlassWrap(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(8),
        child: _Row(
          title: const EditableLabel('notif_preferences_screen.NotifPreferencesEntry', 'Preferences'),
          sub: 'Choose each kind, quiet hours and your reminder time',
          trailing: const Icon(Icons.chevron_right, color: _gold),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NotifPreferencesScreen()),
          ),
        ),
      ),
    );
  }
}
