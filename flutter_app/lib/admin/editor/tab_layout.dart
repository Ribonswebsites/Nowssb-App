/// Map tab (in the + drawer): the page at a glance. Everything about a
/// section's size and place is done on the page itself (drag, pinch, edges, trash —
/// see preview.dart); this list is a map of the page: tap to go to a
/// section, hold and drag to reorder, swipe left to delete, eye to hide.
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
      return const Hint('This page is one block. Tap any picture or line on it to change it.',
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

/// A section or banner (template kind) carried out of the drawer, to be
/// dropped between two sections on the page.
class SectionDrop {
  const SectionDrop(this.kind);
  final String kind;
}

/// Drawer tab: every section and banner, each drawn live and small. Hold
/// one and drag it onto the page: a gold line shows where it lands, between
/// two sections. A tap adds it right after the picked section.
class AddSectionsTab extends StatelessWidget {
  const AddSectionsTab({super.key, required this.c, required this.onAdded});
  final EditorController c;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    if (!c.sectioned) {
      return const Hint('This page can’t take new sections yet.', icon: Icons.view_agenda_outlined);
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: kTemplateGallery.length,
      itemBuilder: (context, i) => SectionTile(c: c, kind: kTemplateGallery[i], onAdded: onAdded),
    );
  }
}

/// White coupons are drawn on the white page they are made for.
bool _onWhite(String kind) => kind == 'couponTicket' || kind == 'couponCards';

/// One live thumbnail in the Sections tab.
class SectionTile extends StatelessWidget {
  const SectionTile({super.key, required this.c, required this.kind, required this.onAdded});
  final EditorController c;
  final String kind;
  final VoidCallback onAdded;

  Widget _art({double? width}) => Container(
        width: width,
        decoration: BoxDecoration(
          color: _onWhite(kind) ? const Color(0xFFF5F2EC) : const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(4),
        child: TemplateThumb(kind: kind),
      );

  @override
  Widget build(BuildContext context) {
    final name = kTemplateNames[kind] ?? kind;
    final tile = Glass(
      radius: 16,
      padding: const EdgeInsets.all(6),
      onTap: () {
        bigFeel();
        c.endStep();
        c.addTemplate(kind);
        c.endStep();
        onAdded();
      },
      child: Column(children: [
        Expanded(child: SizedBox(width: double.infinity, child: _art())),
        const SizedBox(height: 5),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
    return LongPressDraggable<Object>(
      key: ValueKey('add-$kind'),
      data: SectionDrop(kind),
      delay: const Duration(milliseconds: 120),
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => c.setFxDragging(true),
      onDragEnd: (_) => c.setFxDragging(false),
      feedback: Material(
        color: Colors.transparent,
        // Held by its middle, a little above the finger so the line shows.
        child: Transform.translate(
          offset: const Offset(-90, -150),
          child: Opacity(
            opacity: 0.92,
            child: Container(
              width: 180,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGold, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: _art(width: 180),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}

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
    );
  }
}
