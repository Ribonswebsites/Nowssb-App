/// Today's tasks. The list belongs to the signed-in account. Ticking one
/// moves the bar. The editor is where that account sets its own tasks.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';
import '../widgets/glass_wrap.dart';

class _Task {
  const _Task(this.id, this.title);
  final String id;
  final String title;
}

class DailyTasks {
  DailyTasks._();

  static const defaults = <_Task>[
    _Task('word', 'Sit with one word'),
    _Task('player', 'Open the player'),
    _Task('read', 'Read one meaning'),
  ];

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

  static Future<void> setDone(String id, bool on) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getStringList(_doneKey) ?? const <String>[]).toSet();
    if (on) {
      next.add(id);
    } else {
      next.remove(id);
    }
    await prefs.setStringList(_doneKey, next.toList());
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
              Text(
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
              child: const Text('Set today’s tasks'),
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
    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Today’s tasks'),
      ),
      body: _ready
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  'These tasks are for this account. The bar on the home moves when you tick them.',
                  style: const TextStyle(color: Color(0xB3FFFFFF), height: 1.35),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : finished / total,
                    minHeight: 8,
                    color: NwsbColors.gold,
                    backgroundColor: const Color(0x33FFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$finished of $total done today',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                for (final task in _tasks)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: ListTile(
                      onTap: () => _toggle(task),
                      leading: Icon(
                        _done.contains(task.id)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: NwsbColors.gold,
                      ),
                      title: Text(task.title, style: const TextStyle(color: Colors.white)),
                      trailing: IconButton(
                        onPressed: () => _remove(task),
                        icon: const Icon(Icons.close, color: Color(0x88FFFFFF)),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _add,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add a task',
                          hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                        ),
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addTask,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
