/// CA-2: what a publish / section save leaves behind, and the server calls
/// that clean it up (old R2 media + orphaned ui_overrides docs).
///
/// The client only PROPOSES: the server (`media-gc`, `section-purge`,
/// `page-purge`) re-checks every reference across Firestore, only touches
/// keys under our admin upload prefixes, and audit-logs each call.
library;

import 'package:flutter/material.dart';

import '../admin_api.dart';
import '../layout/ui_layouts.dart';
import '../template/ui_overrides.dart';
import 'glass.dart';

const kMediaBase = 'https://media.nowssb.com/';
const _prefixes = ['ui/', 'images/words/', 'video/words/', 'audio/'];

/// True for a URL the server could delete (our bucket, admin upload prefix).
bool isAdminMedia(String url) {
  if (!url.startsWith(kMediaBase)) return false;
  final rest = url.substring(kMediaBase.length);
  return _prefixes.any(rest.startsWith);
}

void _urls(Object? v, Set<String> out) {
  if (v is String) {
    if (isAdminMedia(v)) out.add(v);
  } else if (v is Map) {
    for (final x in v.values) {
      _urls(x, out);
    }
  } else if (v is Iterable) {
    for (final x in v) {
      _urls(x, out);
    }
  }
}

/// Admin media URLs anywhere inside a JSON-ish value.
Set<String> adminMediaIn(Object? v) {
  final out = <String>{};
  _urls(v, out);
  return out;
}

class MediaPlan {
  MediaPlan({
    Set<String>? oldUrls,
    Set<String>? targets,
    List<(String, String)>? deletedSections,
    Set<String>? resetPages,
  })  : oldUrls = oldUrls ?? {},
        targets = targets ?? {},
        deletedSections = deletedSections ?? [],
        resetPages = resetPages ?? {};

  /// Media the change stops using.
  final Set<String> oldUrls;

  /// Slot keys being replaced (their own undo trail may be broken).
  final Set<String> targets;

  /// (pageId, sectionId) newly marked deleted.
  final List<(String, String)> deletedSections;

  /// Pages going back to the shipped layout.
  final Set<String> resetPages;

  bool get hasMedia => oldUrls.isNotEmpty;
  bool get isEmpty => oldUrls.isEmpty && deletedSections.isEmpty && resetPages.isEmpty;

  bool get hasVideo => oldUrls.any((u) => RegExp(r'\.(mp4|mov|webm|m4v)$', caseSensitive: false).hasMatch(u));
}

/// Pure diff: live state vs the drafts about to be published.
MediaPlan planMedia({
  required Map<String, UiOverride?> liveOverrides,
  required Map<String, UiOverride?> draftOverrides,
  required Map<String, PageLayout?> liveLayouts,
  required Map<String, PageLayout?> draftLayouts,
}) {
  final plan = MediaPlan();
  for (final e in draftOverrides.entries) {
    final before = liveOverrides[e.key];
    if (before == null) continue;
    final next = e.value;
    if (isAdminMedia(before.url) && (next == null || next.url != before.url)) {
      plan.oldUrls.add(before.url);
      plan.targets.add(e.key);
    }
  }
  for (final e in draftLayouts.entries) {
    final page = e.key;
    final before = liveLayouts[page];
    final next = e.value;
    if (next == null) {
      if (before != null) {
        plan.resetPages.add(page);
        for (final s in before.sections) {
          plan.oldUrls.addAll(adminMediaIn(s.props));
        }
      }
      continue;
    }
    final prev = {for (final s in before?.sections ?? const <SectionEntry>[]) s.id: s};
    final nextById = {for (final s in next.sections) s.id: s};
    for (final s in next.sections) {
      final old = prev[s.id];
      if (s.deleted && (old == null || !old.deleted)) {
        plan.deletedSections.add((page, s.id));
      }
      if (old != null) {
        final keep = adminMediaIn(s.props);
        for (final u in adminMediaIn(old.props)) {
          if (!keep.contains(u)) plan.oldUrls.add(u);
        }
      }
    }
    // Entries dropped from the layout outright (templates removed).
    for (final old in prev.values) {
      if (!nextById.containsKey(old.id)) plan.oldUrls.addAll(adminMediaIn(old.props));
    }
  }
  return plan;
}

enum MediaChoice { delete, keep, cancel }

/// Confirm before anything is permanently removed.
Future<MediaChoice> confirmMediaDelete(BuildContext context, MediaPlan plan) async {
  if (plan.isEmpty) return MediaChoice.keep;
  final what = plan.hasVideo ? 'video' : 'picture';
  final lines = <String>[
    if (plan.hasMedia)
      '${plan.oldUrls.length} old $what${plan.oldUrls.length == 1 ? '' : 's'} will be permanently deleted from the server. Undo cannot bring ${plan.oldUrls.length == 1 ? 'it' : 'them'} back.',
    if (plan.deletedSections.isNotEmpty)
      '${plan.deletedSections.length} deleted section${plan.deletedSections.length == 1 ? '' : 's'}: its saved settings are removed too.',
    if (plan.resetPages.isNotEmpty) 'Page reset: every saved change on ${plan.resetPages.join(', ')} is removed.',
    'Anything still used somewhere else is kept automatically.',
  ];
  final r = await showDialog<MediaChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF121826),
      title: Text('Old $what will be permanently deleted', style: const TextStyle(color: Colors.white)),
      content: Text(lines.join('\n\n'), style: const TextStyle(color: kDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, MediaChoice.cancel), child: const Text('Cancel')),
        if (plan.hasMedia)
          TextButton(onPressed: () => Navigator.pop(ctx, MediaChoice.keep), child: const Text('Publish, keep old file')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk),
          onPressed: () => Navigator.pop(ctx, MediaChoice.delete),
          child: Text(plan.hasMedia ? 'Publish and delete' : 'Publish'),
        ),
      ],
    ),
  );
  return r ?? MediaChoice.cancel;
}

/// After the publish committed: ask the server to clean up. Returns a short
/// summary line; never throws (the publish itself already succeeded).
Future<String> runMediaCleanup(MediaPlan plan, {required bool deleteMedia}) async {
  var deleted = 0, kept = 0, docs = 0;
  final errors = <String>[];
  void count(Map<String, dynamic> r) {
    final c = r['counts'];
    if (c is Map) {
      deleted += (c['deleted'] as num?)?.toInt() ?? 0;
      kept += ((c['referenced'] as num?)?.toInt() ?? 0) + ((c['unsure'] as num?)?.toInt() ?? 0);
    }
    final d = r['removedDocs'];
    if (d is List) docs += d.length;
  }

  Future<void> guard(Future<Map<String, dynamic>> Function() f) async {
    try {
      count(await f());
    } catch (e) {
      errors.add('$e');
    }
  }

  for (final (page, sid) in plan.deletedSections) {
    await guard(() => AdminApi.call('section-purge', {'pageId': page, 'sectionId': sid, 'confirm': deleteMedia}));
  }
  for (final page in plan.resetPages) {
    await guard(() => AdminApi.call('page-purge', {'pageId': page, 'confirm': deleteMedia}));
  }
  if (deleteMedia && plan.oldUrls.isNotEmpty) {
    await guard(() => AdminApi.call('media-gc', {
          'urls': plan.oldUrls.toList(),
          'targets': plan.targets.toList(),
          'confirm': true,
        }));
  }
  final parts = [
    if (deleted > 0) '$deleted old file${deleted == 1 ? '' : 's'} deleted',
    if (kept > 0) '$kept kept (still used elsewhere)',
    if (docs > 0) '$docs saved setting${docs == 1 ? '' : 's'} removed',
    if (errors.isNotEmpty) 'cleanup failed: ${errors.first}',
  ];
  return parts.join(' · ');
}
