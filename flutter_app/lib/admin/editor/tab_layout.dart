/// Layout tab: drag the picture on the phone up or down to reorder it (the
/// page reflows), sideways to nudge it, pinch to resize; space above/below
/// and side margins in steps. The list below is for order, show, hide, and
/// delete.
library;

import 'package:flutter/material.dart';

import '../layout/scopes.dart';
import '../layout/template_sections.dart';
import 'editor_controller.dart';
import 'glass.dart';

class LayoutTab extends StatelessWidget {
  const LayoutTab({super.key, required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    if (!c.sectioned) {
      return const Hint('This page is shown as one block for now, so its sections cannot be moved yet.\n'
          'You can still change every picture and line in Content.',
          icon: Icons.view_agenda_outlined);
    }
    final secs = c.sections;
    final live = [for (var i = 0; i < secs.length; i++) if (!secs[i].entry.deleted) i];
    final deleted = [for (final s in secs) if (s.entry.deleted) s];
    final cur = c.current;
    final fit = '${cur?.entry.props['fit'] ?? ''}';

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        sliver: SliverList.list(children: [
          Row(children: [
            Expanded(
              child: Pill('Add section', icon: Icons.add_rounded, selected: true, onTap: () => _addSection(context)),
            ),
            const SizedBox(width: 8),
            Pill('Reset page', icon: Icons.settings_backup_restore_rounded, onTap: () async {
              if (await confirmAction(context, 'Put the whole page back?',
                  'Every section goes back to the order and look the app ships with. Nothing changes for people until you publish.',
                  yes: 'Put it back')) {
                c.resetPage();
              }
            }),
          ]),
          if (cur != null) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 14, 4, 10),
              child: Text(
                'Drag the picture on the phone up or down to move it before or after the sections next to it — the page makes room. '
                    'Drag sideways to nudge it. Pinch with two fingers to make it bigger or smaller.',
                style: TextStyle(color: kDim, fontSize: 13, height: 1.35),
              ),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Pill('Center', icon: Icons.filter_center_focus_rounded, dense: true, onTap: () {
                tapFeel();
                c.patchProps(cur.id, {'dx': null, 'dy': null});
              }),
              Pill('Full width', icon: Icons.fullscreen_rounded, dense: true, onTap: () {
                tapFeel();
                c.patchProps(cur.id, {'dx': null, 'padH': null});
              }),
              Pill('Fill picture', icon: Icons.crop_rounded, dense: true, selected: fit != 'contain', onTap: () {
                tapFeel();
                c.patchProps(cur.id, {'fit': null});
              }),
              Pill('Whole picture', icon: Icons.fit_screen_rounded, dense: true, selected: fit == 'contain', onTap: () {
                tapFeel();
                c.patchProps(cur.id, {'fit': 'contain'});
              }),
              Pill('Reset', icon: Icons.restart_alt_rounded, dense: true, onTap: () {
                tapFeel();
                c.patchProps(cur.id, {
                  'height': null,
                  'dx': null,
                  'dy': null,
                  'padTop': null,
                  'padBottom': null,
                  'padH': null,
                  'fit': null,
                });
              }),
            ]),
            // Space above/below and side margins are still drawn for every
            // section that has them (pages published before the sliders
            // went), so they stay visible and changeable here.
            const SizedBox(height: 10),
            _Spacing(
              props: cur.entry.props,
              onChanged: (k, v) => c.patchProps(cur.id, {k: v < 1 ? null : v}),
            ),
            const SizedBox(height: 8),
          ],
          Eyebrow('Order — drag ⠿ to move', trailing: Text('${live.length} sections', style: const TextStyle(color: kDim, fontSize: 11))),
        ]),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverReorderableList(
          itemCount: live.length,
          onReorderItem: (a, b) {
            bigFeel();
            c.move(live[a], live[b]);
          },
          itemBuilder: (context, i) {
            final idx = live[i];
            final s = secs[idx];
            return _Row(
              key: ValueKey('lr-${s.id}'),
              c: c,
              s: s,
              index: i,
              realIndex: idx,
              first: i == 0,
              last: i == live.length - 1,
              onUp: () => c.move(idx, live[i - 1]),
              onDown: () => c.move(idx, live[i + 1]),
            );
          },
        ),
      ),
      if (deleted.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          sliver: SliverList.list(children: [
            const Eyebrow('Deleted — tap to bring back'),
            for (final s in deleted)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Glass(
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: () {
                    actFeel();
                    c.restore(s.id);
                  },
                  child: Row(children: [
                    const Icon(Icons.restore_from_trash_rounded, color: kMint, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.title, style: const TextStyle(color: Colors.white70))),
                    const Text('Restore', style: TextStyle(color: kMint, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ),
          ]),
        )
      else
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }

  Future<void> _addSection(BuildContext context) async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xF20B1120),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      // Scrolls: with the coupon templates the gallery is taller than a
      // small phone's sheet.
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add a section', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('It goes right after the section on the preview. Fill it in from Content.',
              style: TextStyle(color: kDim, fontSize: 12.5)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (final e in kTemplateNames.entries)
                Glass(
                  radius: 18,
                  onTap: () => Navigator.pop(ctx, e.key),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(_icon(e.key), color: kGold),
                    const Spacer(),
                    Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(kTemplateBlurbs[e.key] ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11)),
                  ]),
                ),
            ],
          ),
        ]),
      ),
    );
    if (kind != null) {
      bigFeel();
      c.addTemplate(kind);
    }
  }

  static IconData _icon(String k) => switch (k) {
        'imageBanner' => Icons.image_rounded,
        'videoBanner' => Icons.smart_display_rounded,
        'splitPromo' => Icons.vertical_split_rounded,
        'cardRow' => Icons.view_carousel_rounded,
        'textBlock' => Icons.notes_rounded,
        'couponTicket' => Icons.confirmation_number_outlined,
        'couponCards' => Icons.local_offer_outlined,
        _ => Icons.smart_button_rounded,
      };
}

/// Space above, space below and side margins of the section, in steps.
class _Spacing extends StatelessWidget {
  const _Spacing({required this.props, required this.onChanged});
  final Map<String, dynamic> props;
  final void Function(String key, double value) onChanged;

  static const _rows = <(String, String, double)>[
    ('padTop', 'Space above', 80),
    ('padBottom', 'Space below', 80),
    ('padH', 'Side margins', 48),
  ];

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      child: Column(children: [
        for (final (k, label, max) in _rows)
          _Stepper(
            label: label,
            value: props[k] is num ? (props[k] as num).toDouble() : 0,
            max: max,
            onChanged: (v) => onChanged(k, v),
          ),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.max, required this.onChanged});
  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  static const _step = 4.0;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, max);
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
      IconButton(
        tooltip: 'Less space',
        visualDensity: VisualDensity.compact,
        onPressed: v <= 0
            ? null
            : () {
                tapFeel();
                onChanged(((v - _step) / _step).ceil() * _step);
              },
        icon: Icon(Icons.remove_rounded, size: 18, color: v <= 0 ? kFaint : kGold),
      ),
      SizedBox(
        width: 34,
        child: Text(v < 1 ? '0' : v.toStringAsFixed(0),
            textAlign: TextAlign.center,
            style: TextStyle(color: v < 1 ? kDim : Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ),
      IconButton(
        tooltip: 'More space',
        visualDensity: VisualDensity.compact,
        onPressed: v >= max
            ? null
            : () {
                tapFeel();
                onChanged((((v + _step) / _step).floor() * _step).clamp(0.0, max));
              },
        icon: Icon(Icons.add_rounded, size: 18, color: v >= max ? kFaint : kGold),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.c,
    required this.s,
    required this.index,
    required this.realIndex,
    required this.first,
    required this.last,
    required this.onUp,
    required this.onDown,
  });

  final EditorController c;
  final SectionInfo s;
  final int index;
  final int realIndex;
  final bool first;
  final bool last;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final isCur = c.index == realIndex;
    final hidden = !s.entry.visible;
    final sched = s.entry.start != 0 || s.entry.end != 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Glass(
        radius: 14,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        edge: isCur ? kGold : kGlassEdge,
        onTap: () => c.goTo(realIndex),
        child: Row(children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_indicator_rounded, color: kFaint, size: 20),
            ),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hidden ? kFaint : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    decoration: hidden ? TextDecoration.lineThrough : null,
                  )),
              Text(
                [
                  if (s.entry.isTemplate) 'added' else if (s.entry.src.isNotEmpty) 'copy' else 'built-in',
                  if (hidden) 'hidden',
                  if (sched) 'scheduled',
                  if (s.carousel) 'carousel',
                ].join(' · '),
                style: const TextStyle(color: kDim, fontSize: 10.5),
              ),
            ]),
          ),
          IconButton(
            tooltip: hidden ? 'Show it' : 'Hide it',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              tapFeel();
              c.setVisible(s.id, hidden);
            },
            icon: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: hidden ? kFaint : kGold, size: 19),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            color: const Color(0xFF111A2B),
            icon: const Icon(Icons.more_vert_rounded, color: kDim, size: 20),
            onSelected: (v) async {
              switch (v) {
                case 'up':
                  onUp();
                case 'down':
                  onDown();
                case 'dup':
                  actFeel();
                  c.duplicate(s.id);
                case 'del':
                  if (await confirmAction(context, 'Delete “${s.title}”?',
                      s.entry.isTemplate || s.entry.src.isNotEmpty
                          ? 'This section you added is removed. Version history can bring it back.'
                          : 'It stops showing for everyone once you publish. You can restore it from the Deleted list or history.',
                      yes: 'Delete')) {
                    bigFeel();
                    c.delete(s.id);
                  }
              }
            },
            itemBuilder: (_) => [
              if (!first) const PopupMenuItem(value: 'up', child: Text('Move up', style: TextStyle(color: Colors.white))),
              if (!last) const PopupMenuItem(value: 'down', child: Text('Move down', style: TextStyle(color: Colors.white))),
              if (s.copyable) const PopupMenuItem(value: 'dup', child: Text('Duplicate', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'del', child: Text('Delete', style: TextStyle(color: Color(0xFFFF8A8A)))),
            ],
          ),
        ]),
      ),
    );
  }
}
