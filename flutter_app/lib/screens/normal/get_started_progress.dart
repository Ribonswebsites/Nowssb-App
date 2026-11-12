/// Which "Get Started" steps this person has really done.
///
/// A step is done only when the thing itself happened: today's word was
/// opened, a practice session was finished in the player (PracticeProgress),
/// the player guide was opened, the Sound Library was opened, a word was
/// saved with the heart (`nwsb_liked_words`), a task was ticked today
/// (DailyTasks) or Connect was opened. Done steps are kept on the phone
/// (`nwsb_get_started_done`) so they stay done.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/practice_progress.dart';
import '../daily_tasks.dart';

class GetStartedProgress extends ChangeNotifier {
  GetStartedProgress._();
  static final GetStartedProgress instance = GetStartedProgress._();

  static const prefsKey = 'nwsb_get_started_done';
  static const likedWordsKey = 'nwsb_liked_words';

  /// The seven steps, in order.
  static const steps = <String>['word', 'practise', 'guide', 'sounds', 'save', 'tasks', 'connect'];

  final Set<String> _done = {};
  bool _listening = false;

  Set<String> get done => Set.unmodifiable(_done);
  bool isDone(String id) => _done.contains(id);
  int get doneCount => steps.where(_done.contains).length;

  /// Loads what is stored, then checks the real signals again.
  Future<void> load() async {
    if (!_listening) {
      _listening = true;
      PracticeProgress.instance.addListener(_onPractice);
    }
    try {
      final p = await SharedPreferences.getInstance();
      _done.addAll(p.getStringList(prefsKey) ?? const <String>[]);
    } catch (_) {}
    await refresh();
  }

  void _onPractice() {
    if (PracticeProgress.instance.totalSessions > 0 && !_done.contains('practise')) {
      mark('practise');
    }
  }

  /// Re-reads the signals the app already keeps (call after a page closes).
  Future<void> refresh() async {
    final found = <String>{};
    try {
      if (PracticeProgress.instance.totalSessions > 0) found.add('practise');
      final p = await SharedPreferences.getInstance();
      if ((p.getStringList(likedWordsKey) ?? const <String>[]).isNotEmpty) found.add('save');
      if ((await DailyTasks.done()).isNotEmpty) found.add('tasks');
    } catch (_) {}
    if (found.difference(_done).isEmpty) {
      notifyListeners();
      return;
    }
    _done.addAll(found);
    await _save();
    notifyListeners();
  }

  /// Marks [id] done (the person did that step).
  Future<void> mark(String id) async {
    if (!_done.add(id)) return;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(prefsKey, _done.toList()..sort());
    } catch (_) {}
  }

  @visibleForTesting
  void debugReset() => _done.clear();
}
