import 'package:flutter/foundation.dart';

import 'content.dart';
import 'day_part.dart';
import 'models.dart';
import 'practice_progress.dart';

/// Data for the Today / ritual card, from the same sources the card always
/// used: the word library (ContentStore), PracticeProgress, and the day part.
@immutable
class TodayRitual {
  const TodayRitual({
    required this.part,
    required this.words,
    required this.done,
    required this.todaySessions,
    required this.totalSessions,
    required this.streak,
  });

  /// Words for this part of the day: those timed for it, plus 'any'.
  static List<Word> wordsFor(Iterable<Word> library, DayPart part) =>
      library.where((w) => w.time == part.slot || w.time == 'any').toList();

  factory TodayRitual.from({required Iterable<Word> library, required PracticeProgress progress, required DateTime now}) {
    final part = dayPartFor(now);
    final words = wordsFor(library, part);
    return TodayRitual(
      part: part,
      words: words,
      done: progress.completedTodayFor(words),
      todaySessions: progress.todaySessions,
      totalSessions: progress.totalSessions,
      streak: progress.streak,
    );
  }

  final DayPart part;
  final List<Word> words;
  final int done;
  final int todaySessions;
  final int totalSessions;
  final int streak;

  int get total => words.length;
  String get title => part.ritualTitle;
  double get fraction => total == 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

/// Live [TodayRitual] plus the card's two actions. Listens to the library,
/// progress and the shared [DayClock]; call [dispose] when done.
class TodayRitualModel extends ChangeNotifier {
  TodayRitualModel({
    this.onBegin,
    this.onSeeProgress,
    ContentStore? content,
    PracticeProgress? progress,
  })  : _content = content ?? ContentStore.instance,
        _progress = progress ?? PracticeProgress.instance {
    _content.addListener(notifyListeners);
    _progress.addListener(notifyListeners);
    DayClock.tick.addListener(notifyListeners);
    DayClock.retain();
  }

  /// Opens the Player for the current ritual's words and title.
  final void Function(List<Word> words, String title)? onBegin;
  final VoidCallback? onSeeProgress;
  final ContentStore _content;
  final PracticeProgress _progress;

  TodayRitual get value => TodayRitual.from(library: _content.library, progress: _progress, now: DayClock.now());

  void begin() {
    final v = value;
    onBegin?.call(v.words, v.title);
  }

  /// 8/8 'Play again': restarts today's ritual from its first word in the
  /// same Player route Begin uses.
  void replay() => begin();

  void seeProgress() => onSeeProgress?.call();

  @override
  void dispose() {
    _content.removeListener(notifyListeners);
    _progress.removeListener(notifyListeners);
    DayClock.tick.removeListener(notifyListeners);
    DayClock.release();
    super.dispose();
  }
}

/// Hero words for this user: words they own or bought first, then the words
/// they saved (their routine), then the day part's routine words. Matches by
/// the word itself inside an owned item's title (case-insensitive). Falls
/// back to [routine] when the user owns and saved nothing.
List<Word> personalHeroWords({
  required Iterable<Word> library,
  required List<Word> routine,
  Iterable<String> ownedTitles = const [],
  Iterable<String> saved = const [],
}) {
  final out = <Word>[];
  final seen = <String>{};
  void add(Word w) {
    if (seen.add(w.word.toLowerCase())) out.add(w);
  }

  final titles = [for (final t in ownedTitles) t.toLowerCase()];
  if (titles.isNotEmpty) {
    for (final w in library) {
      final k = w.word.toLowerCase();
      if (k.isEmpty) continue;
      if (titles.any((t) => RegExp('\\b${RegExp.escape(k)}\\b').hasMatch(t))) add(w);
    }
  }
  final s = {for (final x in saved) x.toLowerCase()};
  for (final w in library) {
    if (s.contains(w.word.toLowerCase())) add(w);
  }
  for (final w in routine) {
    add(w);
  }
  return out;
}
