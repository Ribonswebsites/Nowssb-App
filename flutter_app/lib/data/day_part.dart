import 'dart:async';

import 'package:flutter/widgets.dart';

/// The four parts of the day every home, card and chip uses.
///
/// Bands (local wall-clock hour), the split the app already used in its
/// five-band header greeting (`FashionHeader.hello`, part083.js), the Earth
/// films and the practice slots:
///   morning   05:00–11:59
///   afternoon 12:00–16:59
///   evening   17:00–20:59
///   night     21:00–04:59
enum DayPart { morning, afternoon, evening, night }

/// The part of the day for [at]. Always read in local time: a UTC
/// [DateTime] is converted first, so server/UTC instants can't leak in.
DayPart dayPartFor(DateTime at) {
  final h = (at.isUtc ? at.toLocal() : at).hour;
  if (h < 5) return DayPart.night;
  if (h < 12) return DayPart.morning;
  if (h < 17) return DayPart.afternoon;
  if (h < 21) return DayPart.evening;
  return DayPart.night;
}

extension DayPartText on DayPart {
  /// 'morning' … 'night': the slot key word data uses (Word.time).
  String get slot => name;
  String get label => switch (this) {
        DayPart.morning => 'Morning',
        DayPart.afternoon => 'Afternoon',
        DayPart.evening => 'Evening',
        DayPart.night => 'Night',
      };
  String get greeting => 'Good $label';
  String get ritualTitle => switch (this) {
        DayPart.morning => 'Morning Ritual',
        DayPart.afternoon => 'Afternoon Session',
        DayPart.evening => 'Evening Practice',
        DayPart.night => 'Night Restoration',
      };
  DayPart get next => DayPart.values[(index + 1) % DayPart.values.length];
}

/// The one shared clock ticker. [tick] bumps at every top of the hour (so
/// day-part boundaries and the hourly Drop Studio words both land live) and
/// when the app resumes. Ref-counted: the timer runs only while something
/// is [retain]ed, and the last [release] cancels it.
abstract final class DayClock {
  static final ValueNotifier<int> tick = ValueNotifier(0);
  static DateTime Function() _clock = DateTime.now;
  static Timer? _timer;
  static int _users = 0;
  static _Resume? _resume;

  /// Local now (from the injected clock in tests).
  static DateTime now() {
    final t = _clock();
    return t.isUtc ? t.toLocal() : t;
  }

  static DayPart get part => dayPartFor(now());

  @visibleForTesting
  static set clock(DateTime Function()? c) {
    _clock = c ?? DateTime.now;
    if (_users > 0) _arm();
  }

  @visibleForTesting
  static bool get running => _timer != null;

  static void retain() {
    _users++;
    if (_timer == null) _arm();
    if (_resume == null) {
      _resume = _Resume();
      WidgetsBinding.instance.addObserver(_resume!);
    }
  }

  static void release() {
    if (_users > 0) _users--;
    if (_users == 0) {
      _timer?.cancel();
      _timer = null;
      if (_resume != null) WidgetsBinding.instance.removeObserver(_resume!);
      _resume = null;
    }
  }

  /// Recompute now (e.g. after resume or a clock change) and re-arm.
  static void refresh() {
    tick.value++;
    if (_users > 0) _arm();
  }

  static void _arm() {
    _timer?.cancel();
    final n = now();
    final next = DateTime(n.year, n.month, n.day, n.hour + 1);
    _timer = Timer(next.difference(n), () {
      tick.value++;
      _arm();
    });
  }
}

class _Resume with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) DayClock.refresh();
  }
}

/// Rebuilds [builder] whenever the hour turns or the app resumes.
class DayPartBuilder extends StatefulWidget {
  const DayPartBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, DayPart part, DateTime now) builder;
  @override
  State<DayPartBuilder> createState() => _DayPartBuilderState();
}

class _DayPartBuilderState extends State<DayPartBuilder> {
  @override
  void initState() {
    super.initState();
    DayClock.retain();
  }

  @override
  void dispose() {
    DayClock.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: DayClock.tick,
        builder: (context, _, __) {
          final n = DayClock.now();
          return widget.builder(context, dayPartFor(n), n);
        },
      );
}
