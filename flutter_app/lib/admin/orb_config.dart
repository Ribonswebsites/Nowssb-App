/// Thinking-orb config: admin set / undo / list via `/api/admin/orb-*`,
/// public read via Firestore `ui_overrides` (and GET `/api/orbs`).
///
/// Slot keys: `orb.all` (app-wide) or `orb.<pageId>.<sectionId>`.
library;

import 'admin_api.dart';

class OrbSlotChoice {
  OrbSlotChoice({
    required this.slot,
    this.orb,
    this.orbSize,
    this.orbCircle,
    this.updatedAt = 0,
    this.updatedBy = '',
  });

  final String slot;
  final String? orb;
  final num? orbSize;
  final bool? orbCircle;
  final int updatedAt;
  final String updatedBy;

  factory OrbSlotChoice.from(Map<String, dynamic> m) => OrbSlotChoice(
        slot: '${m['slot'] ?? ''}',
        orb: m['orb'] == null ? null : '${m['orb']}',
        orbSize: m['orbSize'] is num ? m['orbSize'] as num : null,
        orbCircle: m['orbCircle'] is bool ? m['orbCircle'] as bool : null,
        updatedAt: m['updatedAt'] is num ? (m['updatedAt'] as num).toInt() : 0,
        updatedBy: '${m['updatedBy'] ?? ''}',
      );
}

class OrbHistoryEntry {
  OrbHistoryEntry({
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
  final String? before;
  final String? after;

  factory OrbHistoryEntry.from(Map<String, dynamic> m) => OrbHistoryEntry(
        id: '${m['id'] ?? ''}',
        at: m['at'] is num ? (m['at'] as num).toInt() : 0,
        by: '${m['by'] ?? ''}',
        note: '${m['note'] ?? ''}',
        before: m['before'] == null ? null : '${m['before']}',
        after: m['after'] == null ? null : '${m['after']}',
      );
}

class OrbConfig {
  OrbConfig._();

  /// Admin: every orb override, optionally one slot's history.
  static Future<({List<OrbSlotChoice> slots, List<OrbHistoryEntry> history})> list({
    String? slot,
  }) async {
    final r = await AdminApi.call('orbs', {
      if (slot != null && slot.isNotEmpty) 'slot': slot,
    });
    final slots = <OrbSlotChoice>[
      for (final e in (r['slots'] as List? ?? const []))
        if (e is Map) OrbSlotChoice.from(Map<String, dynamic>.from(e)),
    ];
    final history = <OrbHistoryEntry>[
      for (final e in (r['history'] as List? ?? const []))
        if (e is Map) OrbHistoryEntry.from(Map<String, dynamic>.from(e)),
    ];
    return (slots: slots, history: history);
  }

  /// Admin: save a choice for [slot]. Pass null / empty / `random` to clear.
  static Future<OrbSlotChoice> set({
    required String slot,
    String? orb,
    num? orbSize,
    bool? orbCircle,
    String note = '',
  }) async {
    final r = await AdminApi.call('orb-set', {
      'slot': slot,
      'orb': orb ?? 'random',
      if (orbSize != null) 'orbSize': orbSize,
      if (orbCircle != null) 'orbCircle': orbCircle,
      if (note.isNotEmpty) 'note': note,
      'allowUnknown': true,
    });
    return OrbSlotChoice(
      slot: '${r['slot'] ?? slot}',
      orb: r['orb'] == null ? null : '${r['orb']}',
    );
  }

  /// Admin: restore the previous choice for [slot] from ui_history.
  static Future<OrbSlotChoice> undo({required String slot}) async {
    final r = await AdminApi.call('orb-undo', {'slot': slot});
    return OrbSlotChoice(
      slot: '${r['slot'] ?? slot}',
      orb: r['orb'] == null ? null : '${r['orb']}',
    );
  }
}
