/// Content tab: every picture, clip, logo, icon, heading, text and button
/// label in the current section — replace it (upload to R2) or type new
/// words, or put the original back. A template section edits its own
/// headline, pictures, button and destination here too.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../layout/app_pages.dart';
import '../layout/coupon_sections.dart';
import '../layout/template_sections.dart';
import '../layout/ui_layouts.dart';
import '../media_upload.dart';
import 'svg_picker.dart';
import '../template/editable.dart';
import '../template/media_tune.dart';
import '../template/slot_keys.dart';
import '../template/slot_sheet.dart' show wordOfSlot;
import '../template/ui_overrides.dart';
import '../../data/word_art.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'preview.dart';

class SlotRef {
  const SlotRef(this.key, this.type, this.def);
  final String key;
  final SlotType type;
  final String def;
}

/// The slots in the section on the preview (drawn now, or seen earlier
/// this session — e.g. on another page of a carousel).
List<SlotRef> sectionSlots(EditorController c) {
  final out = <String, SlotRef>{};
  final sec = c.sectioned ? c.sectionKey : null;
  for (final s in c.preview.slots.values) {
    if (sec != null && s.section != sec) continue;
    out.putIfAbsent(s.slotKey, () => SlotRef(s.slotKey, s.type, s.defaultValue));
  }
  if (sec != null) {
    for (final k in SlotRegistry.instance.slotsIn(sec)) {
      final info = SlotRegistry.instance.seen[k];
      if (info != null) out.putIfAbsent(k, () => SlotRef(k, info.type, info.defaultValue));
    }
  }
  final list = out.values.toList();
  int rank(SlotType t) => switch (t) {
        SlotType.video => 0,
        SlotType.image => 1,
        SlotType.text => 2,
        SlotType.orb => 3,
      };
  list.sort((a, b) => rank(a.type).compareTo(rank(b.type)));
  return list;
}

class ContentTab extends StatelessWidget {
  const ContentTab({super.key, required this.c, required this.openTab});
  final EditorController c;
  final ValueChanged<int> openTab;

  @override
  Widget build(BuildContext context) {
    final cur = c.current;
    final slots = sectionSlots(c);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      children: [
        if (cur != null && cur.entry.isTemplate) ...[
          Eyebrow('${kTemplateNames[cur.entry.kind] ?? 'Section'} — its content'),
          TemplateEditor(c: c, entry: cur.entry),
          const SizedBox(height: 8),
        ],
        Eyebrow(
          slots.isEmpty ? 'Editable things' : '${slots.length} editable things here',
          trailing: const Tooltip(
            message: 'Tap an outlined element on the preview to jump to it',
            child: Icon(Icons.info_outline_rounded, size: 16, color: kFaint),
          ),
        ),
        if (slots.isEmpty)
          const Hint('Nothing editable was drawn in this section yet.\n'
              'Switch the preview to "Try it" and swipe its carousel to find more.'),
        for (final s in slots)
          SlotRow(
            c: c,
            slot: s,
            expanded: c.selectedSlot == s.key,
            onStyle: () {
              c.select(s.key, s.type, s.def);
              openTab(s.type == SlotType.orb ? 2 : 1);
            },
          ),
      ],
    );
  }
}

class SlotRow extends StatefulWidget {
  const SlotRow({super.key, required this.c, required this.slot, required this.expanded, required this.onStyle});
  final EditorController c;
  final SlotRef slot;
  final bool expanded;
  final VoidCallback onStyle;

  @override
  State<SlotRow> createState() => _SlotRowState();
}

class _SlotRowState extends State<SlotRow> {
  TextEditingController? _t;
  final _typing = Debouncer();
  double? _progress;
  String? _msg;

  SlotRef get s => widget.slot;
  EditorController get c => widget.c;

  @override
  void dispose() {
    _typing.dispose();
    _t?.dispose();
    super.dispose();
  }

  TextEditingController get _text {
    final o = c.overrideOf(s.key);
    return _t ??= TextEditingController(text: (o != null && o.textSet) ? o.text : s.def);
  }

  Future<void> _upload() async {
    final kind = s.type == SlotType.video ? PickKind.video : PickKind.image;
    final File? f = await pickMedia(context, kind);
    if (f == null || !mounted) return;
    setState(() {
      _progress = 0;
      _msg = 'Uploading…';
    });
    try {
      final up = await uploadToR2(f, 'ui', slotDocId(s.key), kind,
          onProgress: (p) => mounted ? setState(() => _progress = p) : null);
      UiOverrides.instance.primeFile(up.url, f);
      final bound = wordOfSlot(s.key);
      if (bound != null) {
        await WordArt.instance.set(
          bound,
          image: s.type == SlotType.video ? null : up.url,
          video: s.type == SlotType.video ? up.url : null,
        );
      }
      c.setMedia(s.key, s.type, s.def, up.url, up.key);
      actFeel();
      if (mounted) {
        setState(() {
          _progress = null;
          _msg = s.type == SlotType.video
              ? 'Uploaded. Clips show in the app after you publish.'
              : 'Uploaded — shown on the preview. Publish to make it live.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _msg = 'Upload failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = c.overrideOf(s.key);
    final pending = c.isPending(s.key);
    final changed = o != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        edge: widget.expanded ? kGold.withValues(alpha: 0.6) : kGlassEdge,
        onTap: () => widget.expanded ? c.clearSelection() : c.select(s.key, s.type, s.def),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Thumb(slot: s, o: o),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(slotFriendly(s.key, s.type, s.def),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(
                    switch (s.type) {
                      SlotType.text => 'Words',
                      SlotType.image => 'Picture / logo / icon',
                      SlotType.video => 'Clip',
                      SlotType.orb => 'Loader — choose it in Animation',
                    },
                    style: const TextStyle(color: kDim, fontSize: 11),
                  ),
                ]),
              ),
              if (pending) const _Tag('not published', kGold) else if (changed) const _Tag('changed', kMint),
            ]),
            if (widget.expanded) ...[
              const SizedBox(height: 10),
              if (s.type == SlotType.text && templateSlotField(s.key, c.layoutPage) != null) ...[
                // One source of truth: these words are the template's own
                // field (above). A second box here wrote an override that
                // silently beat the field.
                Text(
                  'These words are this section’s “${_templateFieldLabel(templateSlotField(s.key, c.layoutPage)!.$2)}” '
                  'above — change them there. Style still changes the look.',
                  style: const TextStyle(color: kDim, fontSize: 12),
                ),
              ] else if (s.type == SlotType.text) ...[
                TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => _typing(() => c.setText(s.key, s.def, v)),
                  onEditingComplete: _typing.flush,
                  decoration: InputDecoration(
                    hintText: 'Type what everyone should see',
                    hintStyle: const TextStyle(color: kFaint),
                    filled: true,
                    fillColor: const Color(0x14FFFFFF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    isDense: true,
                  ),
                ),
              ] else if (s.type != SlotType.orb) ...[
                Builder(builder: (context) {
                  final bound = wordOfSlot(s.key);
                  final undo = bound != null
                      ? WordArt.instance.canUndo(bound)
                      : o?.style['undoUrl'] != null || o?.style['undoZoom'] != null;
                  return MediaTuneBar(
                    canUndo: undo,
                    onUndo: _progress != null
                        ? null
                        : () async {
                            if (bound != null) {
                              await WordArt.instance.undo(bound);
                            } else {
                              final prev = o?.style['undoZoom'];
                              if (prev is num) {
                                c.patchStyle(s.key, s.type, s.def, {'zoom': prev.toDouble(), 'undoZoom': null});
                              }
                            }
                            if (mounted) setState(() {});
                          },
                  );
                }),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Pill('Upload new', icon: Icons.upload_rounded, selected: true, onTap: _progress != null ? null : _upload),
                  if (s.type == SlotType.image && s.def.toLowerCase().endsWith('.svg'))
                    Pill('SVG library', icon: Icons.category_rounded, onTap: () async {
                      final v = await pickSvg(context, current: o?.url ?? s.def);
                      if (v == null || !mounted) return;
                      c.setMedia(s.key, s.type, s.def, v, '');
                      final bound = wordOfSlot(s.key);
                      if (bound != null) await WordArt.instance.set(bound, image: v);
                      setState(() => _msg = 'Swapped — shown on the preview. Publish to make it live.');
                    }),
                ]),
              ],
              if (_progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _progress, color: kGold, backgroundColor: const Color(0x22FFFFFF)),
              ],
              if (_msg != null) ...[
                const SizedBox(height: 6),
                Text(_msg!, style: const TextStyle(color: kDim, fontSize: 11.5)),
              ],
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Pill(s.type == SlotType.orb ? 'Choose orb' : 'Style',
                    icon: Icons.palette_outlined, dense: true, onTap: widget.onStyle),
                Pill('Reset to original',
                    icon: Icons.restart_alt_rounded,
                    dense: true,
                    onTap: !changed
                        ? null
                        : () {
                            _typing.cancel();
                            c.resetSlot(s.key, s.type, s.def);
                            _t?.text = s.def;
                          }),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

String _templateFieldLabel(String field) => switch (field) {
      'title' => 'Headline',
      'subtitle' => 'Line under it',
      'body' => 'Paragraph',
      'cta' => 'Button words',
      _ => field,
    };

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800)),
      );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.slot, required this.o});
  final SlotRef slot;
  final UiOverride? o;

  @override
  Widget build(BuildContext context) {
    Widget inner;
    final src = (o != null && o!.url.isNotEmpty) ? o!.url : slot.def;
    if (slot.type == SlotType.image && isSvgUrl(src)) {
      inner = src.startsWith('http') || src.startsWith('asset:')
          ? overrideSvg(src, width: 30, height: 30, fallback: () => Icon(slotIcon(slot.type), color: kGold, size: 18))
          : SvgPicture.asset(src, width: 30, height: 30, placeholderBuilder: (_) => const SizedBox());
    } else if (slot.type == SlotType.image) {
      final local = UiOverrides.instance.fileFor(src);
      inner = local != null
          ? Image.file(File(local), fit: BoxFit.cover)
          : src.startsWith('http')
              ? Image.network(src, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
              : Image.asset(src, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox());
    } else {
      inner = Icon(slotIcon(slot.type), color: kGold, size: 18);
    }
    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(10)),
      child: Center(child: inner),
    );
  }
}

/// Edits a template section's own props (headline, pictures, button…).
class TemplateEditor extends StatefulWidget {
  const TemplateEditor({super.key, required this.c, required this.entry});
  final EditorController c;
  final SectionEntry entry;

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  final Map<String, TextEditingController> _ctl = {};

  /// One per field: the preview redraws when the owner pauses typing.
  final Map<String, Debouncer> _typing = {};
  String? _msg;
  double? _progress;

  @override
  void dispose() {
    for (final d in _typing.values) {
      d.dispose();
    }
    for (final t in _ctl.values) {
      t.dispose();
    }
    super.dispose();
  }

  void _type(String field, VoidCallback save) => _typing.putIfAbsent(field, Debouncer.new)(save);

  /// The template's cards / coupons as they are now (not as they were when
  /// the field was built: a debounced save runs later).
  List<Map<String, dynamic>> get _cards => e.props['cards'] is List
      ? [for (final m in e.props['cards'] as List) if (m is Map) Map<String, dynamic>.from(m)]
      : <Map<String, dynamic>>[];

  SectionEntry get e => widget.c.entries.firstWhere((x) => x.id == widget.entry.id, orElse: () => widget.entry);

  Widget _field(String key, String label, {int lines = 1}) {
    final t = _ctl.putIfAbsent(key, () => TextEditingController(text: '${e.props[key] ?? ''}'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: t,
        minLines: 1,
        maxLines: lines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (v) => _type(key, () => widget.c.patchProps(e.id, {key: v})),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kDim),
          filled: true,
          fillColor: const Color(0x14FFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          isDense: true,
        ),
      ),
    );
  }

  Future<String?> _uploadTo(PickKind kind) async {
    final f = await pickMedia(context, kind);
    if (f == null || !mounted) return null;
    setState(() {
      _progress = 0;
      _msg = 'Uploading…';
    });
    try {
      final up = await uploadToR2(f, 'ui', 'tpl~${e.id}', kind,
          onProgress: (p) => mounted ? setState(() => _progress = p) : null);
      UiOverrides.instance.primeFile(up.url, f);
      if (mounted) {
        setState(() {
          _progress = null;
          _msg = 'Uploaded.';
        });
      }
      return up.url;
    } catch (err) {
      if (mounted) {
        setState(() {
          _progress = null;
          _msg = 'Upload failed: $err';
        });
      }
      return null;
    }
  }

  Widget _route(String key, String current, ValueChanged<String> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () async {
          final r = await pickRoute(context, current);
          if (r != null) onPick(r);
        },
        child: Row(children: [
          const Icon(Icons.near_me_rounded, size: 16, color: kGold),
          const SizedBox(width: 8),
          const Text('Goes to  ', style: TextStyle(color: kDim, fontSize: 12.5)),
          Expanded(
            child: Text(routeLabel(current),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const Icon(Icons.chevron_right_rounded, color: kFaint),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = e.kind;
    final p = e.props;
    final cards = p['cards'] is List ? [for (final m in p['cards'] as List) if (m is Map) Map<String, dynamic>.from(m)] : <Map<String, dynamic>>[];
    final coupon = k == 'couponTicket' || k == 'couponCards';
    if (coupon) return _couponEditor(k, p);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (k != 'cta') _field('title', 'Headline'),
      if (k == 'imageBanner' || k == 'videoBanner' || k == 'splitPromo') _field('subtitle', 'Line under it'),
      if (k == 'textBlock') _field('body', 'Paragraph', lines: 6),
      if (k != 'textBlock' && k != 'cardRow') ...[
        _field('cta', 'Button words (empty = no button)'),
        _route('route', '${p['route'] ?? ''}', (r) => widget.c.patchProps(e.id, {'route': r})),
      ],
      if (k == 'imageBanner' || k == 'splitPromo' || k == 'videoBanner')
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill(k == 'videoBanner' ? 'Poster picture' : 'Picture', icon: Icons.image_outlined, onTap: () async {
            final u = await _uploadTo(PickKind.image);
            if (u != null) widget.c.patchProps(e.id, {'image': u});
          }),
          if (k == 'videoBanner')
            Pill('Clip', icon: Icons.movie_outlined, onTap: () async {
              final u = await _uploadTo(PickKind.video);
              if (u != null) widget.c.patchProps(e.id, {'video': u});
            }),
        ]),
      if (k == 'splitPromo') ...[
        const SizedBox(height: 10),
        const Text('Background', style: TextStyle(color: kDim, fontSize: 12)),
        const SizedBox(height: 6),
        ColorRow(
          value: p['bg'] is num ? (p['bg'] as num).toInt() : null,
          allowClear: false,
          onPick: (v) => widget.c.patchProps(e.id, {'bg': v}),
        ),
        const SizedBox(height: 6),
        const Text('Blend into (optional gradient)', style: TextStyle(color: kDim, fontSize: 12)),
        const SizedBox(height: 6),
        ColorRow(
          value: p['bg2'] is num ? (p['bg2'] as num).toInt() : null,
          onPick: (v) => widget.c.patchProps(e.id, {'bg2': v}),
        ),
      ],
      if (k == 'cardRow') ...[
        for (var i = 0; i < cards.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Glass(
              radius: 14,
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Text('Card ${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Remove this card',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final next = [...cards]..removeAt(i);
                      widget.c.patchProps(e.id, {'cards': next});
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: kFaint, size: 18),
                  ),
                ]),
                TextFormField(
                  key: ValueKey('card-$i-${e.id}'),
                  initialValue: '${cards[i]['title'] ?? ''}',
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Card words', isDense: true),
                  onChanged: (v) => _type('card-$i', () {
                    final next = _cards;
                    if (i >= next.length) return;
                    next[i] = {...next[i], 'title': v};
                    widget.c.patchProps(e.id, {'cards': next});
                  }),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Pill('Picture', icon: Icons.image_outlined, dense: true, onTap: () async {
                    final u = await _uploadTo(PickKind.image);
                    if (u == null) return;
                    final next = [...cards];
                    next[i] = {...next[i], 'image': u};
                    widget.c.patchProps(e.id, {'cards': next});
                  }),
                  Pill('Goes to: ${routeLabel('${cards[i]['route'] ?? ''}')}',
                      icon: Icons.near_me_rounded, dense: true, onTap: () async {
                    final r = await pickRoute(context, '${cards[i]['route'] ?? ''}');
                    if (r == null) return;
                    final next = [...cards];
                    next[i] = {...next[i], 'route': r};
                    widget.c.patchProps(e.id, {'cards': next});
                  }),
                ]),
              ]),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Pill('Add a card', icon: Icons.add_rounded, onTap: () {
            widget.c.patchProps(e.id, {
              'cards': [...cards, {'title': 'New card', 'route': 'tab:2'}],
            });
          }),
        ),
      ],
      if (_progress != null) ...[
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _progress, color: kGold, backgroundColor: const Color(0x22FFFFFF)),
      ],
      if (_msg != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_msg!, style: const TextStyle(color: kDim, fontSize: 11.5))),
    ]);
  }
}

extension on _TemplateEditorState {
  /// Coupon templates: every word, code and colour of each coupon.
  Widget _couponEditor(String k, Map<String, dynamic> p) {
    final coupons = couponsOf(p);
    void save(List<Map<String, dynamic>> next) => widget.c.patchProps(e.id, {'coupons': next});
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kDim),
          filled: true,
          fillColor: const Color(0x14FFFFFF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          isDense: true,
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Text, borders and barcode colour', style: TextStyle(color: kDim, fontSize: 12)),
      const SizedBox(height: 6),
      ColorRow(
        value: p['ink'] is num ? (p['ink'] as num).toInt() : null,
        onPick: (v) => widget.c.patchProps(e.id, {'ink': v}),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < coupons.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Glass(
            radius: 14,
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Text('Coupon ${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove this coupon',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => save([...coupons]..removeAt(i)),
                  icon: const Icon(Icons.delete_outline_rounded, color: kFaint, size: 18),
                ),
              ]),
              for (final (key, label, lines) in couponFields(k))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    key: ValueKey('cp-${e.id}-$i-$key-${coupons.length}'),
                    initialValue: '${coupons[i][key] ?? ''}',
                    minLines: 1,
                    maxLines: lines,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: deco(label),
                    onChanged: (v) => _type('cp-$i-$key', () {
                      final next = [...couponsOf(e.props)];
                      if (i >= next.length) return;
                      next[i] = {...next[i], key: v};
                      save(next);
                    }),
                  ),
                ),
              const Text('Ribbon colour (the code takes it too)', style: TextStyle(color: kDim, fontSize: 12)),
              const SizedBox(height: 6),
              ColorRow(
                value: coupons[i]['tagColor'] is num ? (coupons[i]['tagColor'] as num).toInt() : null,
                onPick: (v) {
                  final next = [...couponsOf(e.props)];
                  if (i >= next.length) return;
                  next[i] = {...next[i], 'tagColor': v}..removeWhere((_, x) => x == null);
                  save(next);
                },
              ),
            ]),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: Pill('Add a coupon', icon: Icons.add_rounded, onTap: () => save([...coupons, couponBlank(k, coupons.length)])),
      ),
      const SizedBox(height: 6),
      const Text('Tapping a code in the app copies it.', style: TextStyle(color: kDim, fontSize: 11.5)),
    ]);
  }
}

/// Where should this button go? Tabs, pages, or a web address.
Future<String?> pickRoute(BuildContext context, String current) {
  final choices = routeChoices();
  final url = TextEditingController(text: current.startsWith('url:') ? current.substring(4) : '');
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xF20B1120),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Where does it go?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final e in choices.entries)
            ListTile(
              dense: true,
              leading: Icon(e.key.startsWith('tab:') ? Icons.tab_rounded : Icons.web_asset_rounded, color: kGold, size: 18),
              title: Text(e.value, style: const TextStyle(color: Colors.white)),
              trailing: e.key == current ? const Icon(Icons.check_rounded, color: kMint) : null,
              onTap: () => Navigator.pop(ctx, e.key),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: url,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Or a web address (https://…)', isDense: true),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? null : 'url:${v.trim()}'),
          ),
        ],
      ),
    ),
  );
}

/// Coalesces keystrokes: the edit is applied once typing pauses, so the
/// preview redraws once per pause instead of once per letter.
class Debouncer {
  Debouncer([this.delay = const Duration(milliseconds: 300)]);
  final Duration delay;
  Timer? _t;
  VoidCallback? _job;

  bool get pending => _job != null;

  void call(VoidCallback job) {
    _job = job;
    _t?.cancel();
    _t = Timer(delay, flush);
  }

  /// Applies the waiting edit now.
  void flush() {
    _t?.cancel();
    _t = null;
    final j = _job;
    _job = null;
    j?.call();
  }

  /// Drops the waiting edit.
  void cancel() {
    _t?.cancel();
    _t = null;
    _job = null;
  }

  /// Keeps the last letters typed: the waiting edit is applied right after
  /// the widget goes (not during, when the tree is locked). If the editor
  /// itself is gone by then, there is nothing left to apply it to.
  void dispose() {
    _t?.cancel();
    _t = null;
    final j = _job;
    _job = null;
    if (j == null) return;
    scheduleMicrotask(() {
      try {
        j();
      } catch (_) {}
    });
  }
}
