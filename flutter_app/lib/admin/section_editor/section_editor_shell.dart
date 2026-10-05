/// Section editor shell (CS-3 + CS-4).
///
/// Edit mode → blurred black centred panel. Save / Cancel / Undo persist a
/// [SectionConfig] via `/api/admin/section-set`. CS-4 adds fluid per-card
/// image pinch/drag (focalX/focalY/zoom) and layout drag handles (height,
/// card size, spacing, radius, wrapper), all live-previewed via the UI-0
/// [SectionRegistry].
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../widgets/sections/section_config.dart';
import '../../widgets/sections/section_registry.dart';
import '../editor/glass.dart';
import 'section_config_api.dart';
import 'section_focal_pad.dart';
import 'section_layout_handles.dart';

Future<void> openSectionEditor(
  BuildContext context, {
  required String pageId,
  required String sectionId,
  String title = '',
  String? initialType,
  Widget? preview,
}) {
  return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => SectionEditorShell(
      pageId: pageId,
      sectionId: sectionId,
      title: title.isEmpty ? sectionId : title,
      initialType: initialType,
      preview: preview,
    ),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

/// Seed a couple of editable cards when a section has no items yet, so
/// focal/zoom controls have something to pan.
List<SectionMediaItem> ensureEditableItems(SectionConfig cfg) {
  if (cfg.items.isNotEmpty) return cfg.items;
  return [
    SectionMediaItem(id: '${cfg.id}.a', title: 'Card A'),
    SectionMediaItem(id: '${cfg.id}.b', title: 'Card B'),
  ];
}

class SectionEditorShell extends StatefulWidget {
  const SectionEditorShell({
    super.key,
    required this.pageId,
    required this.sectionId,
    required this.title,
    this.initialType,
    this.preview,
  });

  final String pageId;
  final String sectionId;
  final String title;
  final String? initialType;
  final Widget? preview;

  @override
  State<SectionEditorShell> createState() => _SectionEditorShellState();
}

class _SectionEditorShellState extends State<SectionEditorShell> {
  SectionConfig? _draft;
  SectionConfig? _saved;
  bool _loading = true;
  bool _busy = false;
  String? _msg;
  bool _dirty = false;
  int _itemIndex = 0;

  String get _slot => sectionSlotKey(widget.pageId, widget.sectionId);

  @override
  void initState() {
    super.initState();
    ensureSectionRegistry();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      final remote = await SectionConfigApi.get(
        pageId: widget.pageId,
        sectionId: widget.sectionId,
      );
      final type = remote?.type ?? widget.initialType ?? SectionTypeId.cardRow;
      var base = remote ??
          SectionRegistry.instance.defaultConfigFor(type, id: widget.sectionId);
      if (base.items.isEmpty) {
        base = base.copyWith(items: ensureEditableItems(base));
      }
      if (!mounted) return;
      setState(() {
        _saved = remote;
        _draft = base;
        _loading = false;
        _dirty = remote == null; // seeded items count as draft until saved
        _itemIndex = 0;
      });
    } catch (e) {
      if (!mounted) return;
      final type = widget.initialType ?? SectionTypeId.cardRow;
      var base = SectionRegistry.instance.defaultConfigFor(type, id: widget.sectionId);
      base = base.copyWith(items: ensureEditableItems(base));
      setState(() {
        _draft = base;
        _loading = false;
        _dirty = true;
        _msg = 'Could not load saved config — editing defaults. ($e)';
      });
    }
  }

  void _touch(SectionConfig next) {
    setState(() {
      _draft = next;
      _dirty = true;
      _msg = null;
      if (_itemIndex >= next.items.length) {
        _itemIndex = next.items.isEmpty ? 0 : next.items.length - 1;
      }
    });
  }

  void _updateItem(int i, SectionMediaItem item) {
    final draft = _draft;
    if (draft == null || i < 0 || i >= draft.items.length) return;
    final items = [...draft.items];
    items[i] = item;
    _touch(draft.copyWith(items: items));
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _busy = true;
      _msg = 'Saving…';
    });
    try {
      final saved = await SectionConfigApi.set(
        pageId: widget.pageId,
        sectionId: widget.sectionId,
        config: draft,
        note: 'section.editor',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _saved = saved;
        _draft = saved ?? draft;
        _dirty = false;
        _msg = 'Saved for all users — v${saved?.version ?? draft.version}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Could not save: $e';
      });
    }
  }

  Future<void> _undo() async {
    setState(() {
      _busy = true;
      _msg = 'Undoing…';
    });
    try {
      final restored = await SectionConfigApi.undo(
        pageId: widget.pageId,
        sectionId: widget.sectionId,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _saved = restored;
        var next = restored ??
            SectionRegistry.instance.defaultConfigFor(
              widget.initialType ?? SectionTypeId.cardRow,
              id: widget.sectionId,
            );
        if (next.items.isEmpty) next = next.copyWith(items: ensureEditableItems(next));
        _draft = next;
        _dirty = false;
        _itemIndex = 0;
        _msg = restored == null
            ? 'Cleared — section uses app defaults.'
            : 'Restored v${restored.version}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Nothing to undo (or server said: $e)';
      });
    }
  }

  void _cancel() {
    if (_dirty) {
      setState(() {
        var next = _saved ??
            SectionRegistry.instance.defaultConfigFor(
              widget.initialType ?? SectionTypeId.cardRow,
              id: widget.sectionId,
            );
        if (next.items.isEmpty) next = next.copyWith(items: ensureEditableItems(next));
        _draft = next;
        _dirty = false;
        _itemIndex = 0;
        _msg = 'Edits discarded.';
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final draft = _draft;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(color: const Color(0xE0060C18)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, top > 0 ? 4 : 12, 12, 12),
            child: Column(children: [
              _header(),
              if (_msg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _msg!,
                    style: TextStyle(
                      color: _busy ? kGold : const Color(0xFF81C784),
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: _loading || draft == null
                    ? const Center(child: CircularProgressIndicator(color: kGold))
                    : _body(draft),
              ),
              _footer(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'SECTION EDITOR',
              style: TextStyle(
                color: kGold,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(_slot, style: const TextStyle(color: kDim, fontSize: 11)),
          ]),
        ),
        IconButton(
          onPressed: _busy ? null : _undo,
          tooltip: 'Undo last saved change',
          icon: const Icon(Icons.undo_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ]),
    );
  }

  Widget _body(SectionConfig draft) {
    ensureSectionRegistry();
    final types = SectionTypeId.all.toList()..sort();
    final items = draft.items;
    final item = items.isEmpty ? null : items[_itemIndex.clamp(0, items.length - 1)];
    final previewH = (draft.layout.height ?? 160).clamp(96.0, 280.0);

    return ListView(
      children: [
        // Live preview — rebuilds from draft on every handle / focal change.
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kGold.withValues(alpha: 0.35)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Text(
                  'Live preview',
                  style: TextStyle(color: kDim, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                height: previewH,
                child: Center(
                  child: widget.preview ??
                      SectionRegistry.instance.build(context, draft),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Type / enabled
        Glass(
          radius: 16,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Config',
              style: TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text('Type', style: TextStyle(color: kDim, fontSize: 11)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              key: ValueKey('section-type-${draft.type}'),
              initialValue: types.contains(draft.type) ? draft.type : SectionTypeId.cardRow,
              dropdownColor: const Color(0xFF121826),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0x44E8D5A3)),
                ),
              ),
              items: [
                for (final t in types)
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      SectionRegistry.instance[t]?.label ?? t,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v == null) return;
                      final seeded = SectionRegistry.instance
                          .defaultConfigFor(v, id: widget.sectionId)
                          .copyWith(
                            enabled: draft.enabled,
                            version: draft.version,
                            items: draft.items.isNotEmpty
                                ? draft.items
                                : ensureEditableItems(draft.copyWith(type: v)),
                            layout: draft.layout,
                            behavior: draft.behavior,
                            style: draft.style,
                            animation: draft.animation,
                            type: v,
                          );
                      _touch(seeded);
                    },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text(
                'Off hides this section for everyone',
                style: TextStyle(color: kDim, fontSize: 11),
              ),
              activeTrackColor: kGold,
              value: draft.enabled,
              onChanged: _busy ? null : (v) => _touch(draft.copyWith(enabled: v)),
            ),
            Text(
              'Version ${draft.version}${_dirty ? ' (unsaved)' : (_saved != null ? ' (live)' : ' (defaults)')}',
              style: const TextStyle(color: kDim, fontSize: 11),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // Per-card focal / zoom
        Glass(
          radius: 16,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Image focal / zoom',
                style: TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Text('No cards yet.', style: TextStyle(color: kDim, fontSize: 12))
              else ...[
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final selected = i == _itemIndex;
                      return ChoiceChip(
                        label: Text(items[i].title ?? items[i].id),
                        selected: selected,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _itemIndex = i),
                        selectedColor: kGold,
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF060C18) : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        backgroundColor: const Color(0xFF121826),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (item != null)
                  SectionFocalPad(
                    key: ValueKey('focal-${item.id}'),
                    item: item,
                    onChanged: (fx, fy, z) => _updateItem(
                      _itemIndex,
                      item.copyWith(focalX: fx, focalY: fy, zoom: z),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Layout handles
        SectionLayoutHandles(
          layout: draft.layout,
          onChanged: (layout) => _touch(draft.copyWith(layout: layout)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : _cancel,
            child: Text(_dirty ? 'Discard' : 'Cancel'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: (_busy || _draft == null || !_dirty) ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: const Color(0xFF060C18),
            ),
            child: const Text('Save'),
          ),
        ),
      ]),
    );
  }
}
