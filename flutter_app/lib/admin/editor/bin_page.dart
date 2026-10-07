/// The Deleted bin page (pill → Bin): everything deleted, newest first,
/// each with its picture, what it was, where, when, and a big Restore.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../layout/placed_orbs.dart';
import '../layout/ui_layouts.dart';
import '../template/slot_keys.dart';
import 'bin.dart';
import 'editor_controller.dart';
import 'glass.dart';

/// "just now", "5 min ago", "3 h ago", "2 days ago" — then the date.
String binWhen(int ms, {DateTime? now}) {
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  final d = (now ?? DateTime.now()).difference(t);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hh = t.hour.toString().padLeft(2, '0'), mm = t.minute.toString().padLeft(2, '0');
  final date = '${t.day} ${months[t.month - 1]} ${t.year}, $hh:$mm';
  final ago = d.inMinutes < 1
      ? 'just now'
      : d.inMinutes < 60
          ? '${d.inMinutes} min ago'
          : d.inHours < 24
              ? '${d.inHours} h ago'
              : '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
  return 'Deleted $ago · $date';
}

/// Puts [item] back where it was (or at the end of its page when that
/// spot is gone) and takes it out of the bin. Like any edit it is on this
/// phone until Publish. Returns false when it could not be put back.
bool restoreFromBin(EditorController c, BinItem item) {
  final d = item.data;
  switch (item.kind) {
    case BinKind.section:
    case BinKind.banner:
    case BinKind.page:
      final e = SectionEntry.from(d['entry']);
      if (e == null) return false;
      c.onLayout(item.page, item.layout, () => c.restoreSection(e, before: d['before'] as String?, after: d['after'] as String?));
    case BinKind.orb:
      final o = PlacedOrb.from(d['orb']);
      if (o == null) return false;
      c.onLayout(item.page, item.layout, () => c.restoreOrb('${d['section'] ?? ''}', o));
    case BinKind.element:
      final type = SlotType.values.where((t) => t.name == d['type']).firstOrNull;
      final key = '${d['key'] ?? ''}';
      if (type == null || key.isEmpty) return false;
      c.restoreElement(key, type, '${d['default'] ?? ''}');
      if (c.pageId != item.page) c.openPage(item.page);
  }
  unawaited(BinStore.instance.remove(item.id));
  return true;
}

void openBin(BuildContext context, EditorController c) {
  unawaited(BinStore.instance.start());
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BinPage(c: c)));
}

class BinPage extends StatelessWidget {
  const BinPage({super.key, required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    final bin = BinStore.instance;
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(primary: kGold, secondary: kGold, surface: Color(0xFF0F1828)),
      ),
      child: Scaffold(
        key: const ValueKey('bin-page'),
        backgroundColor: const Color(0xFF070B14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF070B14),
          title: const Text('Deleted', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListenableBuilder(
          listenable: bin,
          builder: (context, _) {
            final items = bin.items;
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.delete_outline_rounded, color: kDim, size: 56),
                    SizedBox(height: 14),
                    Text('Nothing deleted',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('Anything you delete shows up here, and stays until you put it back.',
                        textAlign: TextAlign.center, style: TextStyle(color: kDim, fontSize: 15)),
                  ]),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 30),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _BinCard(c: c, item: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _BinCard extends StatelessWidget {
  const _BinCard({required this.c, required this.item});
  final EditorController c;
  final BinItem item;

  IconData get _icon => switch (item.kind) {
        BinKind.section => Icons.view_agenda_rounded,
        BinKind.banner => Icons.panorama_rounded,
        BinKind.element => '${item.data['type']}' == 'text' ? Icons.text_fields_rounded : Icons.image_rounded,
        BinKind.orb => Icons.blur_circular_rounded,
        BinKind.page => Icons.description_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final png = item.thumbBytes;
    return Container(
      key: ValueKey('bin-${item.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111A2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGlassEdge),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 112,
              height: 84,
              color: const Color(0xFF1B2638),
              alignment: Alignment.center,
              child: png != null
                  ? Image.memory(png, fit: BoxFit.contain, width: 112, height: 84, gaplessPlayback: true)
                  : Icon(_icon, color: kGold, size: 34),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${binKindName(item.kind)} · ${item.where}',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kDim, fontSize: 13.5)),
              const SizedBox(height: 4),
              Text(binWhen(item.at), style: const TextStyle(color: kFaint, fontSize: 12.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            key: ValueKey('bin-restore-${item.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: kInk,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              actFeel();
              final ok = restoreFromBin(c, item);
              final m = ScaffoldMessenger.maybeOf(context);
              m?.hideCurrentSnackBar();
              m?.showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(ok
                    ? 'Put back: “${item.label}”. Publish to make it live.'
                    : 'Could not put “${item.label}” back.'),
              ));
              if (ok && Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.restore_rounded, size: 24),
            label: const Text('Restore', style: TextStyle(color: kInk, fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
