/// The Deleted bin: everything deleted in the UI Editor (sections and
/// banners, elements, orbs), each with a picture of how it looked, what it
/// was, where, and when. Kept until it is restored — no expiry.
///
/// Saved to Firestore (`ui_bin/{id}`, admin-only in firestore.rules) so it
/// survives restarts and shows on every device the owner edits from, and
/// mirrored on this phone so nothing is lost while offline.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What kind of thing is in the bin.
enum BinKind { section, banner, element, orb, page }

String binKindName(BinKind k) => switch (k) {
      BinKind.section => 'Section',
      BinKind.banner => 'Banner',
      BinKind.element => 'Element',
      BinKind.orb => 'Animation',
      BinKind.page => 'Page',
    };

class BinItem {
  BinItem({
    required this.id,
    required this.kind,
    required this.page,
    required this.layout,
    required this.label,
    required this.where,
    required this.at,
    this.data = const {},
    this.thumb,
    this.by = '',
  });

  final String id;
  final BinKind kind;

  /// The app page it was on (what the editor opens) and the layout it
  /// belongs to (the page, or '<page>.<tab>').
  final String page;
  final String layout;

  /// What it was ("Image banner · Spring sale") and where ("Home, after
  /// “Stories”").
  final String label;
  final String where;

  /// When it was deleted, epoch ms.
  final int at;

  /// What restore needs: the section entry and its neighbours, the orb, or
  /// the element's key/type/default.
  final Map<String, dynamic> data;

  /// A small PNG of it, base64 (null: none could be taken).
  final String? thumb;
  final String by;

  Uint8List? get thumbBytes {
    final t = thumb;
    if (t == null || t.isEmpty) return null;
    try {
      return base64Decode(t);
    } catch (_) {
      return null;
    }
  }

  BinItem withThumb(String? t) => BinItem(
        id: id,
        kind: kind,
        page: page,
        layout: layout,
        label: label,
        where: where,
        at: at,
        data: data,
        thumb: t,
        by: by,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'page': page,
        'layout': layout,
        'label': label,
        'where': where,
        'at': at,
        'data': data,
        if (thumb != null) 'thumb': thumb,
        'by': by,
      };

  static BinItem? from(dynamic m) {
    if (m is! Map) return null;
    final id = '${m['id'] ?? ''}';
    if (id.isEmpty) return null;
    final kind = BinKind.values.where((k) => k.name == m['kind']).firstOrNull;
    if (kind == null) return null;
    final at = m['at'];
    return BinItem(
      id: id,
      kind: kind,
      page: '${m['page'] ?? ''}',
      layout: '${m['layout'] ?? m['page'] ?? ''}',
      label: '${m['label'] ?? ''}',
      where: '${m['where'] ?? ''}',
      at: at is num ? at.toInt() : (at is Timestamp ? at.millisecondsSinceEpoch : 0),
      data: m['data'] is Map ? Map<String, dynamic>.from(m['data'] as Map) : const {},
      thumb: m['thumb'] is String ? m['thumb'] as String : null,
      by: '${m['by'] ?? ''}',
    );
  }
}

/// Where the bin is kept.
abstract class BinBackend {
  Stream<List<BinItem>> watch();
  Future<void> put(BinItem item);
  Future<void> remove(String id);
}

class FirestoreBin implements BinBackend {
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('ui_bin');

  @override
  Stream<List<BinItem>> watch() => _col.snapshots().map((s) => [
        for (final d in s.docs)
          if (BinItem.from({...d.data(), 'id': d.id}) case final i?) i,
      ]);

  @override
  Future<void> put(BinItem item) => _col.doc(item.id).set(item.toJson());

  @override
  Future<void> remove(String id) => _col.doc(id).delete();
}

/// In memory: tests, and builds without Firebase. Two stores on one
/// backend behave like two devices (or a restart).
class MemoryBin implements BinBackend {
  final Map<String, BinItem> docs = {};
  final _out = StreamController<List<BinItem>>.broadcast();

  void _emit() => _out.add(docs.values.toList());

  @override
  Stream<List<BinItem>> watch() async* {
    yield docs.values.toList();
    yield* _out.stream;
  }

  @override
  Future<void> put(BinItem item) async {
    docs[item.id] = item;
    _emit();
  }

  @override
  Future<void> remove(String id) async {
    docs.remove(id);
    _emit();
  }
}

/// This phone's copy of the bin.
const kBinLocalKey = 'ui_bin_local_v1';

class BinStore extends ChangeNotifier {
  BinStore(this.backend);

  final BinBackend backend;

  static BinStore? _instance;
  static BinStore get instance => _instance ??= BinStore(_hasFirebase() ? FirestoreBin() : MemoryBin());
  @visibleForTesting
  static set instance(BinStore s) => _instance = s;

  final Map<String, BinItem> _local = {};
  final Map<String, BinItem> _remote = {};

  /// Removed here but maybe not yet on the server.
  final Set<String> _gone = {};
  StreamSubscription<List<BinItem>>? _sub;
  bool _started = false;

  /// The last error writing to the server (shown in the bin), if any.
  String? syncError;

  /// Everything in the bin, newest first.
  List<BinItem> get items {
    final m = <String, BinItem>{..._remote, ..._local};
    for (final g in _gone) {
      m.remove(g);
    }
    return m.values.toList()..sort((a, b) => b.at.compareTo(a.at));
  }

  BinItem? byId(String id) => items.where((i) => i.id == id).firstOrNull;

  /// Loads this phone's copy and follows the server.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kBinLocalKey);
      if (raw != null) {
        for (final m in (jsonDecode(raw) as List)) {
          if (BinItem.from(m) case final i?) _local[i.id] = i;
        }
      }
    } catch (_) {}
    notifyListeners();
    _sub = backend.watch().listen((list) {
      _remote
        ..clear()
        ..addEntries(list.map((i) => MapEntry(i.id, i)));
      // On the server now: no need to keep this phone's copy around.
      final synced = [for (final id in _local.keys) if (_remote.containsKey(id) && _remote[id]!.thumb == _local[id]!.thumb) id];
      for (final id in synced) {
        _local.remove(id);
      }
      _gone.removeWhere((id) => !_remote.containsKey(id));
      if (synced.isNotEmpty) _save();
      notifyListeners();
    }, onError: (Object e) {
      syncError = '$e';
      notifyListeners();
    });
    // Anything that never reached the server: try again.
    for (final i in _local.values.toList()) {
      unawaited(_push(i));
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBinLocalKey, jsonEncode([for (final i in _local.values) i.toJson()]));
    } catch (_) {}
  }

  Future<void> _push(BinItem i) async {
    try {
      await backend.put(i);
      syncError = null;
    } catch (e) {
      syncError = '$e';
      notifyListeners();
    }
  }

  /// Puts [item] in the bin.
  Future<void> add(BinItem item) async {
    unawaited(start());
    _gone.remove(item.id);
    _local[item.id] = item;
    notifyListeners();
    await _save();
    await _push(item);
  }

  /// Adds the picture once it is taken.
  Future<void> setThumb(String id, Uint8List png) async {
    final cur = byId(id);
    if (cur == null) return;
    await add(cur.withThumb(base64Encode(png)));
  }

  /// Takes [id] out of the bin (restored, or the delete was undone).
  Future<void> remove(String id) async {
    _gone.add(id);
    _local.remove(id);
    notifyListeners();
    await _save();
    try {
      await backend.remove(id);
    } catch (e) {
      syncError = '$e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

bool _hasFirebase() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Who is deleting (for the bin's record).
String binWho() {
  try {
    if (!_hasFirebase()) return '';
    final u = FirebaseAuth.instance.currentUser;
    return u?.email ?? u?.uid ?? '';
  } catch (_) {
    return '';
  }
}

/// A new bin id.
String newBinId() => 'b${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

/// A picture of what [box] draws now ([local]: part of it), at most
/// [maxWidth] wide, as PNG. Null when it cannot be taken. The layer is
/// grabbed at once (before the thing is gone); the PNG follows.
Future<Uint8List?> captureBox(RenderBox? box, {Rect? local, double maxWidth = 260}) async {
  try {
    if (box == null || !box.attached || !box.hasSize) return null;
    RenderObject? o = box;
    RenderRepaintBoundary? rb;
    while (o != null) {
      if (o is RenderRepaintBoundary && o.hasSize) {
        rb = o;
        break;
      }
      o = o.parent;
    }
    if (rb == null || rb.debugNeedsPaint) return null;
    final want = local ?? Offset.zero & box.size;
    final tl = rb.globalToLocal(box.localToGlobal(want.topLeft));
    final r = (tl & want.size).intersect(Offset.zero & rb.size);
    if (r.isEmpty || r.width < 2 || r.height < 2) return null;
    final sw = maxWidth / r.width, sh = 420 / r.height;
    final scale = (sw < sh ? sw : sh).clamp(0.05, 1.0);
    final img = await rb.toImage(pixelRatio: scale);
    final rec = ui.PictureRecorder();
    final out = Size((r.width * scale).roundToDouble(), (r.height * scale).roundToDouble());
    ui.Canvas(rec).drawImageRect(
      img,
      Rect.fromLTWH(r.left * scale, r.top * scale, out.width, out.height),
      Offset.zero & out,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final pic = await rec.endRecording().toImage(out.width.toInt().clamp(1, 2000), out.height.toInt().clamp(1, 2000));
    final bytes = await pic.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pic.dispose();
    return bytes?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
