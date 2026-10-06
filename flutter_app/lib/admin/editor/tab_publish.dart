/// Publish tab: what is waiting, one button to make it live for everyone,
/// an optional schedule for the section or the picked element, the phone
/// size of the preview, and this page's full version history with undo /
/// restore (deleted sections included).
library;

import 'package:flutter/material.dart';

import '../admin_ui.dart' show adminAgo;
import 'editor_controller.dart';
import 'editor_store.dart';
import 'glass.dart';

class PublishTab extends StatelessWidget {
  const PublishTab({super.key, required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    final n = c.pendingCount;
    final cur = c.current;
    final sel = c.selectedSlot;
    final selO = sel == null ? null : c.overrideOf(sel);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        Glass(
          radius: 20,
          glow: n > 0 ? kGold.withValues(alpha: 0.25) : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(n > 0 ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded, color: n > 0 ? kGold : kMint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  n == 0 ? 'Everything is live' : '$n change${n == 1 ? '' : 's'} waiting',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            const Text('Publishing makes it live for everyone at once — every open app updates in seconds.',
                style: TextStyle(color: kDim, fontSize: 12)),
            if (c.message != null) ...[
              const SizedBox(height: 6),
              Text(c.message!, style: const TextStyle(color: kGold, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: kInk,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: n == 0 || c.busy
                      ? null
                      : () async {
                          bigFeel();
                          await c.publish();
                        },
                  icon: c.busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kInk))
                      : const Icon(Icons.rocket_launch_rounded),
                  label: const Text('Publish now', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Pill('Discard', icon: Icons.undo_rounded, onTap: n == 0
                  ? null
                  : () async {
                      if (await confirmAction(context, 'Throw away unpublished changes?',
                          'The preview goes back to what people see now.', yes: 'Discard')) {
                        c.discard();
                      }
                    }),
            ]),
          ]),
        ),
        const Eyebrow('Preview phone'),
        PillSwitch(
          labels: const ['Small phone', 'Large phone'],
          index: c.largeFrame ? 1 : 0,
          onChanged: (i) => c.setFrame(i == 1),
        ),
        if (cur != null) ...[
          Eyebrow('Schedule “${cur.title}”'),
          _ScheduleRow(
            start: cur.entry.start,
            end: cur.entry.end,
            onChanged: (s, e) => c.setSchedule(cur.id, s, e),
          ),
        ],
        if (sel != null && selO != null) ...[
          const Eyebrow('Schedule the picked change'),
          _ScheduleRow(
            start: selO.start,
            end: selO.end,
            onChanged: (s, e) => c.setOverrideSchedule(sel, c.selectedType!, c.selectedDefault, s, e),
          ),
        ],
        const Eyebrow('Version history — this page'),
        // Its own widget: a stream created in build() was re-subscribed on
        // every editor change (each keystroke, each slider tick), flashing
        // the loader and re-reading Firestore.
        _History(key: ValueKey('hist-${c.pageId}'), page: c.pageId),
      ],
    );
  }
}

class _History extends StatefulWidget {
  const _History({super.key, required this.page});
  final String page;

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  late final Stream<List<HistoryEntry>> _stream = EditorStore.instance.history(widget.page);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HistoryEntry>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('History is not readable yet: ${snap.error}',
              style: const TextStyle(color: kDim, fontSize: 12));
        }
        final list = snap.data;
        if (list == null) return const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator(color: kGold));
        if (list.isEmpty) {
          return const Text('Nothing published from the editor on this page yet.',
              style: TextStyle(color: kDim, fontSize: 12));
        }
        return Column(children: [
          for (final h in list.take(60)) _HistoryRow(h: h, page: widget.page),
        ]);
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.h, required this.page});
  final HistoryEntry h;
  final String page;

  String get _what {
    if (h.kind == 'layout') {
      // A tab's layout ('<page>.<tab>') says which tab.
      final tab = h.target.startsWith('$page.') ? ' · ${h.target.substring(page.length + 1)} tab' : '';
      if (h.after == null) return 'Page put back to original$tab';
      final a = (h.after?['sections'] as List?)?.length ?? 0;
      final b = (h.before?['sections'] as List?)?.length;
      return b == null ? 'Layout saved ($a sections)$tab' : 'Layout changed ($b → $a sections)$tab';
    }
    final t = h.target.split('.').last;
    if (h.after == null) return 'Reset “$t”';
    final txt = h.after?['text'];
    if (txt is String && txt.isNotEmpty) return '“${txt.length > 30 ? '${txt.substring(0, 30)}…' : txt}”';
    if ('${h.after?['url'] ?? ''}'.isNotEmpty) return 'New picture/clip for “$t”';
    return 'New look for “$t”';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Glass(
        radius: 14,
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        child: Row(children: [
          Icon(h.kind == 'layout' ? Icons.view_agenda_rounded : Icons.edit_note_rounded, color: kGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_what, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
              Text([adminAgo(h.at), h.by, if (h.note.isNotEmpty) h.note].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(color: kDim, fontSize: 10.5)),
            ]),
          ),
          TextButton(
            onPressed: () async {
              if (!await confirmAction(context, 'Undo this?', 'Puts back what was there before this change, live for everyone.',
                  yes: 'Undo')) {
                return;
              }
              bigFeel();
              try {
                await EditorStore.instance.restore(h, undo: true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Could not undo: $e')));
                }
              }
            },
            child: const Text('Undo', style: TextStyle(color: kGold, fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              if (!await confirmAction(context, 'Restore this version?', 'Makes this change live again for everyone.',
                  yes: 'Restore')) {
                return;
              }
              bigFeel();
              try {
                await EditorStore.instance.restore(h, undo: false);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Could not restore: $e')));
                }
              }
            },
            child: const Text('Restore', style: TextStyle(color: kMint, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.start, required this.end, required this.onChanged});
  final int start;
  final int end;
  final void Function(int start, int end) onChanged;

  String _fmt(int ms) {
    if (ms == 0) return 'any time';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<int?> _pick(BuildContext context, int ms) async {
    final now = DateTime.now();
    final first = now.subtract(const Duration(days: 1));
    final last = now.add(const Duration(days: 730));
    final saved = ms == 0 ? now : DateTime.fromMillisecondsSinceEpoch(ms);
    // A schedule set days ago is before firstDate: showDatePicker asserts
    // (red screen in debug) unless the initial day is inside the range.
    final init = saved.isBefore(first) ? now : (saved.isAfter(last) ? last : saved);
    final day = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: last,
    );
    if (day == null || !context.mounted) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(init));
    if (t == null) return null;
    return DateTime(day.year, day.month, day.day, t.hour, t.minute).millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Pill('Starts: ${_fmt(start)}', icon: Icons.play_arrow_rounded, dense: true, selected: start != 0, onTap: () async {
        final v = await _pick(context, start);
        if (v != null) onChanged(v, end);
      }),
      Pill('Ends: ${_fmt(end)}', icon: Icons.stop_rounded, dense: true, selected: end != 0, onTap: () async {
        final v = await _pick(context, end);
        if (v != null) onChanged(start, v);
      }),
      if (start != 0 || end != 0)
        Pill('No schedule', icon: Icons.close_rounded, dense: true, onTap: () => onChanged(0, 0)),
    ]);
  }
}
