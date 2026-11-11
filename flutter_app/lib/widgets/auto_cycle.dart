/// Ticker-driven cycle (no Timers, so widget tests never see a pending
/// timer): calls [onTick] every [period] while mounted.
library;

import 'package:flutter/widgets.dart';

mixin AutoCycle<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController _cycle;
  double _last = 0;

  Duration get period;
  void onTick();

  @override
  void initState() {
    super.initState();
    _cycle = AnimationController(vsync: this, duration: period)
      ..addListener(() {
        final v = _cycle.value;
        if (v < _last) onTick();
        _last = v;
      })
      ..repeat();
  }

  /// Stand still (a finger is on the row).
  void pauseCycle() => _cycle.stop();

  /// Carry on, a whole [period] from now.
  void restartCycle() {
    _last = 0;
    _cycle.value = 0;
    _cycle.repeat();
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }
}
