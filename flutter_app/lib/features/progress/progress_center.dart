/// Per-kind progress (tasks, routine, coins, quest, check-in) and the
/// completion events that drive the top Progress pop-up.
///
/// Each kind keeps its own bar. The pop-up fires only on the step INTO
/// complete, once per kind per day (quests: once per quest id).
library;

import 'package:flutter/foundation.dart';

enum ProgressKind { tasks, routine, coins, quest, checkin }

@immutable
class ProgressItem {
  const ProgressItem({
    required this.kind,
    required this.title,
    required this.done,
    required this.total,
    this.subtitle = '',
  });

  final ProgressKind kind;
  final String title;
  final int done;
  final int total;
  final String subtitle;

  bool get complete => total > 0 && done >= total;
  double get value => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);

  /// e.g. "Daily coins 2/2 collected".
  String get line {
    final verb = switch (kind) {
      ProgressKind.coins => 'collected',
      ProgressKind.tasks => 'done',
      ProgressKind.routine => 'played',
      ProgressKind.quest => 'claimed',
      ProgressKind.checkin => 'checked in',
    };
    return '$title ${done.clamp(0, total)}/$total $verb';
  }
}

class ProgressCenter extends ChangeNotifier {
  ProgressCenter({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  static final ProgressCenter instance = ProgressCenter();

  final DateTime Function() _clock;

  static const titles = {
    ProgressKind.tasks: 'Daily tasks',
    ProgressKind.routine: "Today's practice",
    ProgressKind.coins: 'Daily coins',
    ProgressKind.quest: 'Quest',
    ProgressKind.checkin: 'Daily check-in',
  };
  static const defaultTotals = {
    ProgressKind.tasks: 3,
    ProgressKind.routine: 3,
    ProgressKind.coins: 2,
    ProgressKind.quest: 1,
    ProgressKind.checkin: 1,
  };

  final Map<ProgressKind, ProgressItem> _items = {};
  final Set<String> _fired = {};
  String _day = '';

  /// The pop-up currently showing (null = none).
  final ValueNotifier<ProgressItem?> popup = ValueNotifier(null);

  String _today() {
    final d = _clock();
    return '${d.year}-${d.month}-${d.day}';
  }

  void _rollDay() {
    final t = _today();
    if (t == _day) return;
    _day = t;
    _items.clear();
    _fired.clear();
  }

  /// Every kind, in a stable order, for the panel.
  List<ProgressItem> get items {
    _rollDay();
    return [
      for (final k in ProgressKind.values)
        _items[k] ??
            ProgressItem(kind: k, title: titles[k]!, done: 0, total: defaultTotals[k]!),
    ];
  }

  ProgressItem? itemOf(ProgressKind kind) {
    _rollDay();
    return _items[kind];
  }

  /// Updates [kind]. Returns true when this call completed it and fired the
  /// pop-up. [key] separates repeatable kinds (one quest id = one pop-up).
  bool report(ProgressKind kind, int done, int total, {String? title, String subtitle = '', String? key}) {
    _rollDay();
    final item = ProgressItem(
      kind: kind,
      title: title ?? titles[kind]!,
      done: done < 0 ? 0 : done,
      total: total < 0 ? 0 : total,
      subtitle: subtitle,
    );
    _items[kind] = item;
    var fired = false;
    if (item.complete) {
      final id = '${kind.name}:${key ?? ''}';
      if (_fired.add(id)) {
        popup.value = item;
        fired = true;
      }
    }
    notifyListeners();
    return fired;
  }

  void dismiss() => popup.value = null;

  @visibleForTesting
  void reset() {
    _items.clear();
    _fired.clear();
    _day = '';
    popup.value = null;
  }
}
