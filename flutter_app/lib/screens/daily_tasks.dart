/// Today's tasks. The list belongs to the signed-in account. Ticking one
/// moves the bar. The editor is where that account sets its own tasks.
library;

import '../widgets/app_thinking_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';
import '../widgets/glass_wrap.dart';
import '../widgets/nwsb_icon.dart';
import '../widgets/program_shelf.dart';
import '../admin/template/editable.dart';

class DailyTaskView {
  const DailyTaskView(this.id, this.title, this.mark, this.done);
  final String id;
  final String title;
  final String mark;
  final bool done;
}

class _Task {
  const _Task(this.id, this.title);
  final String id;
  final String title;
  String get mark => DailyTasks.markFor(id, title);
}

class DailyTasks {
  DailyTasks._();

  static final progress = ValueNotifier<double>(0);
  static final items = ValueNotifier<List<DailyTaskView>>(const [
    DailyTaskView('word', 'Sit with one word', NwsbMarks.book, false),
    DailyTaskView('player', 'Open the player', NwsbMarks.sound, false),
    DailyTaskView('read', 'Read one meaning', NwsbMarks.reader, false),
  ]);

  static const defaults = <_Task>[
    _Task('word', 'Sit with one word'),
    _Task('player', 'Open the player'),
    _Task('read', 'Read one meaning'),
  ];

  static String markFor(String id, String title) {
    switch (id) {
      case 'word':
        return NwsbMarks.book;
      case 'player':
        return NwsbMarks.sound;
      case 'read':
        return NwsbMarks.reader;
    }
    const pool = <String>[
      NwsbMarks.book,
      NwsbMarks.sound,
      NwsbMarks.reader,
      NwsbMarks.flame,
      NwsbMarks.moon,
      NwsbMarks.sun,
    ];
    return pool[title.hashCode.abs() % pool.length];
  }

  static String get _who {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'local';
    } catch (_) {
      return 'local';
    }
  }

  static String _day() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  static String get _templateKey => 'nwsb_task_template_$_who';
  static String get _doneKey => 'nwsb_task_done_${_who}_${_day()}';

  static Future<List<_Task>> template() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_templateKey);
    if (raw == null || raw.isEmpty) return defaults;
    return [
      for (final line in raw)
        if (line.contains('\t'))
          _Task(line.split('\t').first, line.split('\t').skip(1).join('\t')),
    ];
  }

  static Future<Set<String>> done() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_doneKey) ?? const <String>[]).toSet();
  }

  static Future<void> saveTemplate(List<_Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _templateKey,
      [for (final t in tasks) '${t.id}\t${t.title}'],
    );
  }

  /// Drops "done" lists older than a week (one key per account per day).
  static Future<void> _pruneOld() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = DateTime.now().subtract(const Duration(days: 7));
      final cutoff = '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
      final day = RegExp(r'^nwsb_task_done_.+_(\d{8})$');
      for (final key in prefs.getKeys().toList()) {
        final m = day.firstMatch(key);
        if (m != null && m.group(1)!.compareTo(cutoff) < 0) await prefs.remove(key);
      }
    } catch (_) {}
  }

  static Future<void> setDone(String id, bool on) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getStringList(_doneKey) ?? const <String>[]).toSet();
    if (on) {
      next.add(id);
    } else {
      next.remove(id);
    }
    await prefs.setStringList(_doneKey, next.toList());
    await publish();
  }

  static Future<void> publish() async {
    await _pruneOld();
    final tasks = await template();
    final have = await done();
    final finished = tasks.where((t) => have.contains(t.id)).length;
    progress.value = tasks.isEmpty ? 0 : finished / tasks.length;
    items.value = [
      for (final t in tasks)
        DailyTaskView(t.id, t.title, markFor(t.id, t.title), have.contains(t.id)),
    ];
  }
}

class DailyTasksSection extends StatefulWidget {
  const DailyTasksSection({super.key, this.fashion = false});

  final bool fashion;

  @override
  State<DailyTasksSection> createState() => _DailyTasksSectionState();
}

class _DailyTasksSectionState extends State<DailyTasksSection> {
  List<_Task> _tasks = DailyTasks.defaults;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await DailyTasks.template();
    final done = await DailyTasks.done();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _done = done;
    });
    await DailyTasks.publish();
  }

  Future<void> _toggle(_Task task) async {
    final on = !_done.contains(task.id);
    setState(() {
      if (on) {
        _done = {..._done, task.id};
      } else {
        _done = {..._done}..remove(task.id);
      }
    });
    await DailyTasks.setDone(task.id, on);
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DailyTasksPage()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final finished = _tasks.where((t) => _done.contains(t.id)).length;
    final value = total == 0 ? 0.0 : finished / total;
    final fg = widget.fashion ? Colors.white : const Color(0xFF14141C);
    final dim = widget.fashion ? const Color(0xB3FFFFFF) : const Color(0xFF5C5C66);
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EditableLabel('daily_tasks.DailyTasksSection',
                'TODAY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: NwsbColors.gold,
                ),
              ),
              const Spacer(),
              Text(
                '$finished of $total',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: NwsbColors.gold,
              backgroundColor: widget.fashion
                  ? const Color(0x33FFFFFF)
                  : const Color(0x14000000),
            ),
          ),
          const SizedBox(height: 10),
          for (final task in _tasks)
            InkWell(
              onTap: () => _toggle(task),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _done.contains(task.id)
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                      color: _done.contains(task.id) ? NwsbColors.gold : dim,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: _done.contains(task.id)
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _edit,
              child: const EditableLabel('daily_tasks.DailyTasksSection', 'Set today’s tasks'),
            ),
          ),
        ],
      ),
    );
    if (!widget.fashion) return body;
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: body,
    );
  }
}

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final _add = TextEditingController();
  List<_Task> _tasks = DailyTasks.defaults;
  Set<String> _done = {};
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tasks = await DailyTasks.template();
    final done = await DailyTasks.done();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _done = done;
      _ready = true;
    });
    await DailyTasks.publish();
  }

  Future<void> _persist() => DailyTasks.saveTemplate(_tasks);

  Future<void> _addTask() async {
    final title = _add.text.trim();
    if (title.isEmpty) return;
    final id = 't${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _tasks = [..._tasks, _Task(id, title)];
      _add.clear();
    });
    await _persist();
  }

  Future<void> _remove(_Task task) async {
    setState(() => _tasks = _tasks.where((t) => t.id != task.id).toList());
    await _persist();
    await DailyTasks.setDone(task.id, false);
  }

  Future<void> _toggle(_Task task) async {
    final on = !_done.contains(task.id);
    setState(() {
      if (on) {
        _done = {..._done, task.id};
      } else {
        _done = {..._done}..remove(task.id);
      }
    });
    await DailyTasks.setDone(task.id, on);
  }

  @override
  Widget build(BuildContext context) {
    final finished = _tasks.where((t) => _done.contains(t.id)).length;
    final total = _tasks.length;
    final value = total == 0 ? 0.0 : finished / total;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _ready
            ? ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const WhiteCircleOrb(size: 22, mark: NwsbMarks.book),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: EditableLabel('daily_tasks.DailyTasksPage',
                          'Today’s tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const ProgramShelf(),
                  const SizedBox(height: 14),
                  const GlassLine(
                    text: 'Tick a task and the line on the home moves. These belong to this account.',
                    mark: NwsbMarks.book,
                  ),
                  const SizedBox(height: 14),
                  GlassWrap(
                    margin: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '$finished of $total done today',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 8,
                            color: NwsbColors.gold,
                            backgroundColor: const Color(0x33FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final task = _tasks[i];
                        final on = _done.contains(task.id);
                        return GestureDetector(
                          onTap: () => _toggle(task),
                          child: GlassWrap(
                            margin: EdgeInsets.zero,
                            child: SizedBox(
                              width: 200,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      WhiteCircleOrb(size: 16, mark: task.mark),
                                      const Spacer(),
                                      Icon(
                                        on ? Icons.check_circle : Icons.circle_outlined,
                                        color: NwsbColors.gold,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      decoration: on ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final task in _tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassWrap(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _toggle(task),
                              icon: Icon(
                                _done.contains(task.id)
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: NwsbColors.gold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _remove(task),
                              icon: const Icon(Icons.close, color: Color(0x88FFFFFF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  GlassWrap(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _add,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a task',
                              hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addTask(),
                          ),
                        ),
                        TextButton(onPressed: _addTask, child: const EditableLabel('daily_tasks.DailyTasksPage', 'Add')),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(child: AppThinkingLoader(size: 64)),
      ),
    );
  }
}
