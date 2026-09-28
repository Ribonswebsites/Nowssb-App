/// Every editable slot in the app, grouped by page: the generated manifest
/// (what the sweep wrapped), what this phone has drawn in edit sessions,
/// and whatever already has a replacement in Firestore. Tap one to open
/// the same sheet as the pencil on the live screen.
library;

import 'package:flutter/material.dart';

import '../admin_ui.dart';
import 'slot_keys.dart';
import 'slot_manifest.g.dart';
import 'slot_sheet.dart';
import 'ui_overrides.dart';

class _Slot {
  _Slot(this.key, this.type, this.def);
  final String key;
  final SlotType type;
  final String def;
}

class AllSlotsScreen extends StatefulWidget {
  const AllSlotsScreen({super.key});

  @override
  State<AllSlotsScreen> createState() => _AllSlotsScreenState();
}

class _AllSlotsScreenState extends State<AllSlotsScreen> {
  final _q = TextEditingController();
  bool _changedOnly = false;
  SlotType? _type;

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Map<String, _Slot> _all() {
    final out = <String, _Slot>{};
    for (final m in kSlotManifest) {
      final t = slotTypeFrom(m[1]);
      if (t != null) out[m[0]] = _Slot(m[0], t, m[2]);
    }
    for (final s in SlotRegistry.instance.seen.values) {
      out.putIfAbsent(s.key, () => _Slot(s.key, s.type, s.defaultValue));
    }
    for (final o in UiOverrides.instance.all.values) {
      out.putIfAbsent(o.slot, () => _Slot(o.slot, o.type, ''));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final changed = UiOverrides.instance.all;
    final q = _q.text.trim().toLowerCase();
    final slots = _all().values.where((s) {
      if (_changedOnly && !changed.containsKey(s.key)) return false;
      if (_type != null && s.type != _type) return false;
      return q.isEmpty || s.key.toLowerCase().contains(q) || s.def.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final groups = <String, List<_Slot>>{};
    for (final s in slots) {
      groups.putIfAbsent(slotGroup(s.key), () => []).add(s);
    }
    final names = groups.keys.toList()..sort();
    return AdminScaffold(
      title: 'All slots (${slots.length})',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _q,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search key or text'),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            FilterChip(
                label: Text('Changed (${changed.length})'),
                selected: _changedOnly,
                onSelected: (v) => setState(() => _changedOnly = v)),
            const SizedBox(width: 6),
            for (final t in SlotType.values) ...[
              ChoiceChip(
                label: Text(t.name),
                selected: _type == t,
                onSelected: (v) => setState(() => _type = v ? t : null),
              ),
              const SizedBox(width: 6),
            ],
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 40),
            itemCount: names.length,
            itemBuilder: (context, i) {
              final g = names[i];
              final items = groups[g]!;
              final n = items.where((s) => changed.containsKey(s.key)).length;
              return ExpansionTile(
                iconColor: kAdminGold,
                collapsedIconColor: Colors.white54,
                title: Text(g, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text('${items.length} slots${n > 0 ? ' · $n changed' : ''}',
                    style: const TextStyle(color: kAdminDim, fontSize: 11)),
                children: [
                  for (final s in items)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        s.type == SlotType.text
                            ? Icons.text_fields
                            : (s.type == SlotType.video ? Icons.movie_outlined : Icons.image_outlined),
                        color: changed.containsKey(s.key) ? const Color(0xFF34D399) : Colors.white38,
                      ),
                      title: Text(
                        s.type == SlotType.text
                            ? (UiOverrides.instance.textFor(s.key) ?? s.def)
                            : s.def.split('/').last,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(s.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white38, fontSize: 10.5, fontFamily: 'monospace')),
                      onTap: () => openSlotSheet(context, slotKey: s.key, type: s.type, defaultValue: s.def),
                    ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
