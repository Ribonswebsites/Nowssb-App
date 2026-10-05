/// Admin API for UI-0 [SectionConfig] blobs (CS-3…).
/// Server: `/api/admin/sections`, `section-set`, `section-undo`.
/// Stored in `ui_overrides` with type `section`, slot `section.<page>.<id>`.
library;

import '../../widgets/sections/section_config.dart';
import '../admin_api.dart';

String sectionSlotKey(String pageId, String sectionId) =>
    'section.$pageId.$sectionId';

class SectionHistoryEntry {
  SectionHistoryEntry({
    required this.id,
    this.at = 0,
    this.by = '',
    this.note = '',
    this.before,
    this.after,
  });

  final String id;
  final int at;
  final String by;
  final String note;
  final SectionConfig? before;
  final SectionConfig? after;

  factory SectionHistoryEntry.from(Map<String, dynamic> m) => SectionHistoryEntry(
        id: '${m['id'] ?? ''}',
        at: m['at'] is num ? (m['at'] as num).toInt() : 0,
        by: '${m['by'] ?? ''}',
        note: '${m['note'] ?? ''}',
        before: SectionConfig.fromJson(m['before']),
        after: SectionConfig.fromJson(m['after']),
      );
}

class SectionConfigApi {
  SectionConfigApi._();

  static Future<({List<(String slot, SectionConfig? config)> sections, List<SectionHistoryEntry> history})>
      list({String? pageId, String? sectionId, String? slot}) async {
    final r = await AdminApi.call('sections', {
      if (slot != null && slot.isNotEmpty) 'slot': slot,
      if (pageId != null && pageId.isNotEmpty) 'pageId': pageId,
      if (sectionId != null && sectionId.isNotEmpty) 'sectionId': sectionId,
    });
    final sections = <(String, SectionConfig?)>[
      for (final e in (r['sections'] as List? ?? const []))
        if (e is Map)
          (
            '${e['slot'] ?? ''}',
            SectionConfig.fromJson(e['config']),
          ),
    ];
    final history = <SectionHistoryEntry>[
      for (final e in (r['history'] as List? ?? const []))
        if (e is Map) SectionHistoryEntry.from(Map<String, dynamic>.from(e)),
    ];
    return (sections: sections, history: history);
  }

  static Future<SectionConfig?> get({
    required String pageId,
    required String sectionId,
  }) async {
    final r = await list(pageId: pageId, sectionId: sectionId);
    if (r.sections.isEmpty) return null;
    return r.sections.first.$2;
  }

  static Future<SectionConfig?> set({
    required String pageId,
    required String sectionId,
    required SectionConfig config,
    String note = '',
  }) async {
    final r = await AdminApi.call('section-set', {
      'pageId': pageId,
      'sectionId': sectionId,
      'config': config.toJson(),
      if (note.isNotEmpty) 'note': note,
    });
    return SectionConfig.fromJson(r['config']);
  }

  static Future<SectionConfig?> clear({
    required String pageId,
    required String sectionId,
    String note = 'section.reset',
  }) async {
    await AdminApi.call('section-set', {
      'pageId': pageId,
      'sectionId': sectionId,
      'clear': true,
      'note': note,
    });
    return null;
  }

  static Future<SectionConfig?> undo({
    required String pageId,
    required String sectionId,
  }) async {
    final r = await AdminApi.call('section-undo', {
      'pageId': pageId,
      'sectionId': sectionId,
    });
    return SectionConfig.fromJson(r['config']);
  }
}
