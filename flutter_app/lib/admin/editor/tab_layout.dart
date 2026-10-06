/// Sections tab (in the + drawer): the page at a glance. Everything about a
/// section's size and place is done on the page itself (drag, pinch, edges, trash —
/// see preview.dart); this list is a map of the page: tap to go to a
/// section, hold and drag to reorder, swipe left to delete, eye to hide.
library;

import 'package:flutter/material.dart';

import '../layout/scopes.dart';
import '../layout/template_sections.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'preview.dart' show deleteWithUndo;

class LayoutTab extends StatelessWidget {
  const LayoutTab({super.key, required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    if (!c.sectioned) {
      return const Hint('This page is shown as one block for now, so its sections cannot be moved yet.\n'
          'Tap any picture or line on the page to change it.',
          icon: Icons.view_agenda_outlined);
    }
    final secs = c.sections;
    final live = [for (var i = 0; i < secs.length; i++) if (!secs[i].entry.deleted) i];
    final deleted = [for (final s in secs) if (s.entry.deleted) s];

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
        sliver: SliverList.list(children: [
          Row(children: [
            const Expanded(
              child: Text('Hold and drag to reorder · swipe left to delete',
                  style: TextStyle(color: kDim, fontSize: 12.5)),
            ),
            Pill('Reset page', icon: Icons.settings_backup_restore_rounded, dense: true, onTap: () async {
              if (await confirmAction(context, 'Put the whole page back?',
                  'Every section goes back to the order and look the app ships with. Nothing changes for people until you publish.',
                  yes: 'Put it back')) {
                c.resetPage();
              }
            }),
          ]),
          const SizedBox(height: 10),
        ]),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverReorderableList(
          itemCount: live.length,
          onReorderItem: (a, b) {
            bigFeel();
            c.endStep();
            c.move(live[a], live[b]);
            c.endStep();
          },
          itemBuilder: (context, i) {
            final idx = live[i];
            final s = secs[idx];
            return _Row(
              key: ValueKey('lr-${s.id}'),
              c: c,
              s: s,
              index: i,
              realIndex: idx
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
}

/// Drawer tab: the ready-made sections. A tap adds one right after the
/// picked section (or the one on screen) and closes the drawer.
class AddSectionsTab extends StatelessWidget {
  const AddSectionsTab({super.key, required this.c, required this.onAdded});
  final EditorController c;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    if (!c.sectioned) {
      return const Hint('This page is shown as one block for now, so sections cannot be added to it yet.',
          icon: Icons.view_agenda_outlined);
    }
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        for (final e in kTemplateNames.entries)
          Glass(
            key: ValueKey('add-${e.key}'),
            radius: 18,
            onTap: () {
              bigFeel();
              c.endStep();
              c.addTemplate(e.key);
              c.endStep();
              onAdded();
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_templateIcon(e.key), color: kGold),
              const Spacer(),
              Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 2),
              Text(kTemplateBlurbs[e.key] ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 11)),
            ]),
          ),
      ],
    );
  }
}

IconData _templateIcon(String k) => switch (k) {
        'imageBanner' => Icons.image_rounded,
        'videoBanner' => Icons.smart_display_rounded,
        'splitPromo' => Icons.vertical_split_rounded,
        'cardRow' => Icons.view_carousel_rounded,
        'textBlock' => Icons.notes_rounded,
        'couponTicket' => Icons.confirmation_number_outlined,
        'couponCards' => Icons.local_offer_outlined,
        _ => Icons.smart_button_rounded,
      };

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.c,
    required this.s,
    required this.index,
    required this.realIndex
  });

  final EditorController c;
  final SectionInfo s;
  final int index;
  final int realIndex;

  @override
  Widget build(BuildContext context) {
    final isCur = c.index == realIndex;
    final hidden = !s.entry.visible;
    final sched = s.entry.start != 0 || s.entry.end != 0;
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Dismissible(
          key: ValueKey('del-${s.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: const Color(0xCCE5484D), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          onDismissed: (_) => deleteWithUndo(context, c, s.id, s.title),
          child: Glass(
            radius: 14,
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        edge: isCur ? kGold : kGlassEdge,
        onTap: () => c.goTo(realIndex),
        child: Row(children: [
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
              c.endStep();
                  c.setVisible(s.id, hidden);
                  c.endStep();
            },
            icon: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: hidden ? kFaint : kGold, size: 19),
          )
            ]),
          ),
        ),
      ),
    );
  }
}
