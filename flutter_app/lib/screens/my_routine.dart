/// My routine — the user's own practice routines (Flutter surface).
///
/// Same page language as the Player's other pages: round back button and
/// title, black top banner, black nested action rows, a heading and one
/// heavy glass panel. Black and white only. A routine is built from the
/// words this account can open, ordered by dragging, each with its own
/// minutes, a time of day, days and an optional reminder. Start plays it
/// in order in the Player.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_haptics.dart';
import '../data/content.dart';
import '../data/entitlements.dart';
import '../data/models.dart';
import '../data/word_voice.dart';
import '../features/routine/routine_store.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/nwsb_icon.dart';
import 'practice_player.dart';
import 'sound_library.dart';
import 'store/word_atelier.dart';

/// The routine mark (lines with a small clock) used by the Player button.
const kRoutineMark =
    '<path d="M4 6.5h11M4 11.5h8M4 16.5h5"/><circle cx="16.5" cy="16" r="4"/><path d="M16.5 14.2v2l1.3.9"/>';

/// Words this account can put in a routine: the ones it can open (free,
/// bought or with a plan). Words with a recording come first.
List<Word> routineWords() {
  final e = Entitlements.instance;
  final open = [
    for (final w in ContentStore.instance.library)
      if (w.word.trim().isNotEmpty && e.canOpenWord(w)) w,
  ];
  return [
    ...open.where(WordVoice.hasVoice),
    ...open.where((w) => !WordVoice.hasVoice(w)),
  ];
}

/// Opens the Player on [r]: its words in order, each for its minutes.
Future<void> startRoutine(BuildContext context, Routine r) async {
  final resolved = RoutineStore.resolve(r, ContentStore.instance.library);
  if (resolved.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('The words in this routine are not in your library any more. Edit it to add words.'),
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }
  AppHaptics.medium();
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => PracticePlayerScreen(
      words: [for (final (w, _) in resolved) w],
      title: r.name,
      showIntro: false,
      routineName: r.name,
      routineMinutes: [for (final (_, i) in resolved) i.minutes],
    ),
  ));
}

class MyRoutineScreen extends StatefulWidget {
  const MyRoutineScreen({super.key});

  @override
  State<MyRoutineScreen> createState() => _MyRoutineScreenState();
}

class _MyRoutineScreenState extends State<MyRoutineScreen> {
  final _store = RoutineStore.instance;
  final _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_store.start());
    unawaited(ContentStore.instance.start());
    _store.addListener(_changed);
    ContentStore.instance.addListener(_changed);
  }

  @override
  void dispose() {
    _store.removeListener(_changed);
    ContentStore.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    AppHaptics.selection();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RoutineEditorScreen()));
  }

  Future<void> _edit(Routine r) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RoutineEditorScreen(routine: r)));
  }

  Future<void> _delete(Routine r) async {
    final ok = await confirmDeleteRoutine(context, r);
    if (ok != true) return;
    await _store.delete(r.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${r.name} deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Undo', textColor: Colors.white, onPressed: () => unawaited(_store.save(r))),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final routines = _store.routines;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            RoutinePageHeader(
              title: 'My routine',
              trailing: routines.isEmpty
                  ? null
                  : Text('${routines.length} SAVED',
                      style: const TextStyle(
                          color: Color(0x99FFFFFF), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('my-routine-list'),
                padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottom),
                children: [
                  CustomizeBlackBanner(
                    title: 'Build your\nroutine',
                    subtitle: 'Your words, in your order, at your time',
                    onTap: _create,
                  ),
                  NestedDarkWrap(
                    onTap: _create,
                    child: const RoutineActionRow(
                      mark: '<path d="M12 5v14M5 12h14"/>',
                      title: 'Create a routine',
                      sub: 'Pick words, set the order, the time and the days',
                    ),
                  ),
                  NestedDarkWrap(
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SoundLibraryScreen())),
                    child: RoutineActionRow(
                      mark: NwsbMarks.sound,
                      title: 'Sound Library',
                      sub: 'Listen to your words before you add them',
                    ),
                  ),
                  NestedDarkWrap(
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WordAtelierScreen())),
                    child: RoutineActionRow(
                      mark: NwsbMarks.bag,
                      title: 'Get more words',
                      sub: 'Grow your library in the Store',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 10, 4, 12),
                    child: Text('Your routines',
                        style: TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.35)),
                  ),
                  KeyedSubtree(
                    key: _listKey,
                    child: HeavyGlassPanel(
                      child: !_store.loaded
                          ? const SizedBox(height: 120)
                          : routines.isEmpty
                              ? _Empty(onCreate: _create)
                              : Column(
                                  children: [
                                    for (final r in routines)
                                      _RoutineCard(
                                        routine: r,
                                        onStart: () => startRoutine(context, r),
                                        onEdit: () => _edit(r),
                                        onDelete: () => _delete(r),
                                      ),
                                  ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> confirmDeleteRoutine(BuildContext context, Routine r) => showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: NestedDarkWrap(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete ${r.name}?',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Its words stay in your library. Only this routine and its reminder are removed.',
                    style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, height: 1.4)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                        child: RoutinePill(label: 'Keep', outline: true, onTap: () => Navigator.of(ctx).pop(false))),
                    const SizedBox(width: 10),
                    Expanded(child: RoutinePill(label: 'Delete', onTap: () => Navigator.of(ctx).pop(true))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x38FFFFFF)),
              ),
              alignment: Alignment.center,
              child: const NwsbIcon(kRoutineMark, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 14),
            const Text('Create your routine',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Choose the words you practise, put them in order and pick the time and days. Start plays them one after another in the Player.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 16),
            RoutinePill(label: 'Create your routine', onTap: onCreate),
          ],
        ),
      );
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.onStart, required this.onEdit, required this.onDelete});
  final Routine routine;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final r = routine;
    final words = r.items.map((i) => i.word).join(' · ');
    return NestedDarkWrap(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const RoutineIconBox(mark: kRoutineMark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${r.timeLabel} · ${r.daysLabel}',
                        style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 11.5, height: 1.35)),
                  ],
                ),
              ),
              if (r.reminder)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: NwsbIcon(NwsbMarks.bell, size: 16, color: Color(0xB8FFFFFF)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(words,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 4),
          Text('${r.items.length} word${r.items.length == 1 ? '' : 's'} · ${r.totalMinutes} min',
              style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 11)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 3, child: RoutinePill(label: 'Start', icon: Icons.play_arrow_rounded, onTap: onStart)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: RoutinePill(label: 'Edit', outline: true, onTap: onEdit)),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Delete ${r.name}',
                child: RoutineRoundButton(icon: Icons.delete_outline_rounded, onTap: onDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Editor ─────────────────────────────────────────────────────────────────

class RoutineEditorScreen extends StatefulWidget {
  const RoutineEditorScreen({super.key, this.routine});
  final Routine? routine;

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  late final TextEditingController _name;
  late List<RoutineItem> _items;
  late int _minute;
  late Set<int> _days;
  late bool _reminder;
  var _saving = false;

  static const _minuteSteps = [1, 2, 3, 5, 7, 10, 15, 20, 30];

  bool get _editing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    final r = widget.routine;
    _name = TextEditingController(text: r?.name ?? '');
    _items = [...?r?.items];
    _minute = r?.minuteOfDay ?? 7 * 60;
    _days = Set.of(r?.days ?? const {1, 2, 3, 4, 5, 6, 7});
    _reminder = r?.reminder ?? false;
    unawaited(ContentStore.instance.start());
    ContentStore.instance.addListener(_changed);
    Entitlements.instance.addListener(_changed);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_changed);
    Entitlements.instance.removeListener(_changed);
    _name.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool _has(Word w) => _items.any((i) => i.wordKey == w.key);

  void _toggle(Word w) {
    AppHaptics.selection();
    setState(() {
      if (_has(w)) {
        _items.removeWhere((i) => i.wordKey == w.key);
      } else {
        _items.add(RoutineItem(wordKey: w.key, word: w.word));
      }
    });
  }

  void _step(int index, int dir) {
    final cur = _items[index].minutes;
    var pos = _minuteSteps.indexWhere((m) => m >= cur);
    if (pos < 0) pos = _minuteSteps.length - 1;
    if (_minuteSteps[pos] != cur && dir < 0) pos++;
    final next = _minuteSteps[(pos + dir).clamp(0, _minuteSteps.length - 1)];
    AppHaptics.selection();
    setState(() => _items[index] = _items[index].copyWith(minutes: next));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minute ~/ 60, minute: _minute % 60),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Colors.white, onPrimary: Colors.black, surface: Color(0xFF111114), onSurface: Colors.white),
          timePickerTheme: const TimePickerThemeData(backgroundColor: Color(0xFF0B0B0D)),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => _minute = t.hour * 60 + t.minute);
  }

  void _say(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  Future<void> _save() async {
    if (_saving) return;
    if (_items.isEmpty) {
      _say('Add at least one word to your routine.');
      return;
    }
    if (_reminder && _days.isEmpty) {
      _say('Pick the days for your reminder.');
      return;
    }
    setState(() => _saving = true);
    final name = _name.text.trim().isEmpty ? 'My routine' : _name.text.trim();
    final r = (widget.routine ?? Routine(id: RoutineStore.newId(), name: name, items: const [])).copyWith(
      name: name,
      items: List.of(_items),
      minuteOfDay: _minute,
      days: Set.of(_days),
      reminder: _reminder,
    );
    await RoutineStore.instance.save(r);
    if (!mounted) return;
    AppHaptics.medium();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(_editing ? '$name saved' : '$name created'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _delete() async {
    final r = widget.routine;
    if (r == null) return;
    final ok = await confirmDeleteRoutine(context, r);
    if (ok != true) return;
    await RoutineStore.instance.delete(r.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final pool = routineWords();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            RoutinePageHeader(title: _editing ? 'Edit routine' : 'New routine'),
            Expanded(
              child: ListView(
                key: const ValueKey('routine-editor-list'),
                padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottom),
                children: [
                  NestedDarkWrap(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: TextField(
                      key: const ValueKey('routine-name'),
                      controller: _name,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: 'Name your routine, e.g. Morning calm',
                        hintStyle: TextStyle(color: Color(0x66FFFFFF), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const _Heading('Words in order'),
                  HeavyGlassPanel(
                    child: _items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                            child: Text('Tap words in your library below to add them. Drag to change the order.',
                                style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.45)),
                          )
                        : ReorderableListView.builder(
                            key: const ValueKey('routine-order'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: _items.length,
                            proxyDecorator: (child, _, __) => Material(type: MaterialType.transparency, child: child),
                            onReorderItem: (from, to) {
                              AppHaptics.selection();
                              setState(() {
                                final it = _items.removeAt(from);
                                _items.insert(to, it);
                              });
                            },
                            itemBuilder: (_, i) => _OrderRow(
                              key: ValueKey('item-${_items[i].wordKey}'),
                              index: i,
                              item: _items[i],
                              onLess: () => _step(i, -1),
                              onMore: () => _step(i, 1),
                              onRemove: () => setState(() => _items.removeAt(i)),
                            ),
                          ),
                  ),
                  const _Heading('When'),
                  HeavyGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NestedDarkWrap(
                          onTap: _pickTime,
                          child: RoutineActionRow(
                            mark: '<circle cx="12" cy="12" r="8"/><path d="M12 8v4l2.6 1.8"/>',
                            title: Routine.formatMinute(_minute),
                            sub: 'Time of day',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            children: [
                              for (var d = 1; d <= 7; d++)
                                RoutineChip(
                                  label: Routine.dayShort[d - 1],
                                  selected: _days.contains(d),
                                  onTap: () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                                ),
                            ],
                          ),
                        ),
                        NestedDarkWrap(
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          child: Row(
                            children: [
                              const RoutineIconBox(mark: NwsbMarks.bell),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Reminder',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 2),
                                    Text('A notification at this time on these days',
                                        style: TextStyle(color: Color(0x73FFFFFF), fontSize: 11, height: 1.35)),
                                  ],
                                ),
                              ),
                              Switch(
                                key: const ValueKey('routine-reminder'),
                                value: _reminder,
                                activeThumbColor: Colors.black,
                                activeTrackColor: Colors.white,
                                inactiveThumbColor: const Color(0xB8FFFFFF),
                                inactiveTrackColor: const Color(0x22FFFFFF),
                                onChanged: (v) => setState(() => _reminder = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Heading('Your library'),
                  HeavyGlassPanel(
                    child: pool.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(6, 6, 6, 12),
                                child: Text(
                                    'There are no words in your library yet. Get words in the Store and they appear here.',
                                    style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.45)),
                              ),
                              RoutinePill(
                                label: 'Open the Store',
                                outline: true,
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute<void>(builder: (_) => const WordAtelierScreen())),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final w in pool)
                                RoutineChip(
                                  key: ValueKey('pick-${w.key}'),
                                  label: w.word,
                                  selected: _has(w),
                                  onTap: () => _toggle(w),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 18),
                  RoutinePill(
                    key: const ValueKey('routine-save'),
                    label: _editing ? 'Save changes' : 'Save routine',
                    big: true,
                    onTap: _save,
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 10),
                    RoutinePill(label: 'Delete routine', outline: true, big: true, onTap: _delete),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    super.key,
    required this.index,
    required this.item,
    required this.onLess,
    required this.onMore,
    required this.onRemove,
  });
  final int index;
  final RoutineItem item;
  final VoidCallback onLess;
  final VoidCallback onMore;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => NestedDarkWrap(
        padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Icon(Icons.drag_indicator_rounded, color: Color(0x99FFFFFF), size: 20),
              ),
            ),
            SizedBox(
              width: 22,
              child: Text('${index + 1}',
                  style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Text(item.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            RoutineRoundButton(icon: Icons.remove_rounded, size: 30, onTap: onLess),
            SizedBox(
              width: 50,
              child: Text('${item.minutes} min',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            RoutineRoundButton(icon: Icons.add_rounded, size: 30, onTap: onMore),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Remove ${item.word}',
              child: RoutineRoundButton(icon: Icons.close_rounded, size: 30, onTap: onRemove),
            ),
          ],
        ),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(text,
            style:
                const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      );
}

// ─── Shared pieces (same shapes as the Player's pages) ──────────────────────

class RoutinePageHeader extends StatelessWidget {
  const RoutinePageHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Back',
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child:
                          NwsbIcon('<path d="M15 6l-6 6 6 6"/>', size: 18, color: Color(0xFF0A0A12), strokeWidth: 1.8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class RoutineIconBox extends StatelessWidget {
  const RoutineIconBox({super.key, required this.mark});
  final String mark;
  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A12),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x38FFFFFF)),
        ),
        alignment: Alignment.center,
        child: NwsbIcon(mark, size: 18, color: Colors.white),
      );
}

class RoutineActionRow extends StatelessWidget {
  const RoutineActionRow({super.key, required this.mark, required this.title, required this.sub});
  final String mark;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          RoutineIconBox(mark: mark),
          Container(
              width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 12), color: const Color(0x33FFFFFF)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 11, height: 1.35)),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x33FFFFFF)),
              color: const Color(0x14FFFFFF),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white70),
          ),
        ],
      );
}

class RoutineChip extends StatelessWidget {
  const RoutineChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? Colors.white : const Color(0x33FFFFFF)),
            ),
            child: Text(label,
                style: TextStyle(
                  color: selected ? const Color(0xFF0A0A12) : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      );
}

class RoutinePill extends StatelessWidget {
  const RoutinePill(
      {super.key, required this.label, required this.onTap, this.outline = false, this.icon, this.big = false});
  final String label;
  final VoidCallback onTap;
  final bool outline;
  final IconData? icon;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final fg = outline ? Colors.white : const Color(0xFF0A0A12);
    return Material(
      color: outline ? Colors.transparent : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: outline ? const Color(0x55FFFFFF) : Colors.white)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: SizedBox(
          height: big ? 52 : 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 4)],
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontSize: big ? 15 : 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoutineRoundButton extends StatelessWidget {
  const RoutineRoundButton({super.key, required this.icon, required this.onTap, this.size = 40});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0x14FFFFFF),
        shape: const CircleBorder(side: BorderSide(color: Color(0x33FFFFFF))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, color: Colors.white, size: size * .5)),
        ),
      );
}
