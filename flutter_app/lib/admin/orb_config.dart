/// Thinking-orb config: admin set / undo / list via `/api/admin/orb-*`,
/// public read via Firestore `ui_overrides` (and GET `/api/orbs`).
///
/// Slot keys: `orb.all` (app-wide) or `orb.<pageId>.<sectionId>`.
/// Choices may be a package [OrbState] name (`kind: orb`) or a bundled
/// Lottie/Rive asset (`kind: lottie|rive` + `asset`).
library;

import 'admin_api.dart';

class OrbSlotChoice {
  OrbSlotChoice({
    required this.slot,
    this.orb,
    this.kind,
    this.asset,
    this.token,
    this.orbSize,
    this.orbCircle,
    this.updatedAt = 0,
    this.updatedBy = '',
  });

  final String slot;
  final String? orb;
  final String? kind;
  final String? asset;
  final String? token;
  final num? orbSize;
  final bool? orbCircle;
  final int updatedAt;
  final String updatedBy;

  factory OrbSlotChoice.from(Map<String, dynamic> m) => OrbSlotChoice(
        slot: '${m['slot'] ?? ''}',
        orb: m['orb'] == null ? null : '${m['orb']}',
        kind: m['kind'] == null ? null : '${m['kind']}',
        asset: m['asset'] == null ? null : '${m['asset']}',
        token: m['token'] == null ? null : '${m['token']}',
        orbSize: m['orbSize'] is num ? m['orbSize'] as num : null,
        orbCircle: m['orbCircle'] is bool ? m['orbCircle'] as bool : null,
        updatedAt: m['updatedAt'] is num ? (m['updatedAt'] as num).toInt() : 0,
        updatedBy: '${m['updatedBy'] ?? ''}',
      );

  Map<String, dynamic> toStyle() {
    final out = <String, dynamic>{};
    if (kind != null && kind!.isNotEmpty) out['kind'] = kind;
    if (asset != null && asset!.isNotEmpty) out['asset'] = asset;
    if (orb != null && orb!.isNotEmpty) out['orb'] = orb;
    if (orbSize != null) out['orbSize'] = orbSize;
    if (orbCircle != null) out['orbCircle'] = orbCircle;
    return out;
  }
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
  /// For Lottie/Rive pass [kind] + [asset] (and leave [orb] null).
  static Future<OrbSlotChoice> set({
    required String slot,
    String? orb,
    String? kind,
    String? asset,
    num? orbSize,
    bool? orbCircle,
    String note = '',
  }) async {
    final r = await AdminApi.call('orb-set', {
      'slot': slot,
      if (kind != null && kind.isNotEmpty) 'kind': kind,
      if (asset != null && asset.isNotEmpty) 'asset': asset,
      'orb': (kind == 'lottie' || kind == 'rive') ? '' : (orb ?? 'random'),
      if (orbSize != null) 'orbSize': orbSize,
      if (orbCircle != null) 'orbCircle': orbCircle,
      if (note.isNotEmpty) 'note': note,
      'allowUnknown': true,
    });
    return OrbSlotChoice(
      slot: '${r['slot'] ?? slot}',
      orb: r['orb'] == null ? null : '${r['orb']}',
      kind: r['kind'] == null ? null : '${r['kind']}',
      asset: r['asset'] == null ? null : '${r['asset']}',
      token: r['token'] == null ? null : '${r['token']}',
    );
  }

  /// Admin: restore the previous choice for [slot] from ui_history.
  static Future<OrbSlotChoice> undo({required String slot}) async {
    final r = await AdminApi.call('orb-undo', {'slot': slot});
    return OrbSlotChoice(
      slot: '${r['slot'] ?? slot}',
      orb: r['orb'] == null ? null : '${r['orb']}',
      kind: r['kind'] == null ? null : '${r['kind']}',
      asset: r['asset'] == null ? null : '${r['asset']}',
      token: r['token'] == null ? null : '${r['token']}',
    );
  }
}
