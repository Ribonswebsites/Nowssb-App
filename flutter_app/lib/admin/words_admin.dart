/// Admin — Words.
///
///   words/{key}        what every app shows. `status: published|archived`,
///                      `version`, `updatedAt`, `updatedBy`, and every Word
///                      field (lib/data/models.dart). Archived takes the word
///                      out of every app; published replaces or adds it.
///   word_drafts/{key}  work in progress, admins only.
///
/// ContentStore lays `words` over the shipped / content/library words, so
/// a publish here reaches phones live, without a release. The voice is
/// recorded (or picked) here and uploaded to Cloudflare R2.
library;

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/word_art.dart';
import 'admin_log.dart';
import 'admin_ui.dart';
import 'media_upload.dart';
import '../media/nwsb_video.dart';
import 'template/media_tune.dart';

String wordKeyFor(String word) =>
    word.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '');

class WordsAdminScreen extends StatefulWidget {
  const WordsAdminScreen({super.key});

  @override
  State<WordsAdminScreen> createState() => _WordsAdminScreenState();
}

class _WordsAdminScreenState extends State<WordsAdminScreen> {
  final _db = FirebaseFirestore.instance;
  final _search = TextEditingController();
  Map<String, Map<String, dynamic>> _published = {};
  Map<String, Map<String, dynamic>> _drafts = {};
  final _subs = <StreamSubscription<dynamic>>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _subs.add(_db.collection('words').snapshots().listen(
          (s) => setState(() => _published = {for (final d in s.docs) d.id: d.data()}),
          onError: (e) => setState(() => _error = '$e'),
        ));
    _subs.add(_db.collection('word_drafts').snapshots().listen(
          (s) => setState(() => _drafts = {for (final d in s.docs) d.id: d.data()}),
          onError: (e) => setState(() => _error = '$e'),
        ));
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _search.dispose();
    super.dispose();
  }

  void _open(String? key) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WordEditorScreen(wordKey: key)));
  }

  @override
  Widget build(BuildContext context) {
    final base = {for (final w in ContentStore.instance.baseLibrary) w.key: w};
    final keys = <String>{...base.keys, ..._published.keys, ..._drafts.keys}.toList();
    String nameOf(String k) =>
        '${_drafts[k]?['word'] ?? _published[k]?['word'] ?? base[k]?.word ?? k}';
    final q = _search.text.trim().toLowerCase();
    final shown = keys.where((k) => q.isEmpty || k.contains(q) || nameOf(k).toLowerCase().contains(q)).toList()
      ..sort((a, b) => nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()));
    return AdminScaffold(
      title: 'Words',
      fab: FloatingActionButton.extended(
        backgroundColor: kAdminGold,
        foregroundColor: kAdminBg,
        onPressed: () => _open(null),
        icon: const Icon(Icons.add),
        label: const Text('New word'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search words'),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final k = shown[i];
              final pub = _published[k];
              final chips = <Widget>[
                if (pub == null) const AdminChip('shipped', color: Colors.white54),
                if (pub != null && pub['status'] == 'archived') const AdminChip('archived', color: Colors.redAccent),
                if (pub != null && pub['status'] != 'archived')
                  AdminChip('published v${pub['version'] ?? 1}', color: const Color(0xFF81C784)),
                if (_drafts.containsKey(k)) const AdminChip('draft', color: Color(0xFFFFB74D)),
                if ('${pub?['audio'] ?? ''}'.isNotEmpty) const Icon(Icons.graphic_eq, color: kAdminGold, size: 16),
              ];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(nameOf(k), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                subtitle: Text(k, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                trailing: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: chips),
                onTap: () => _open(k),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// One word, every field.
class WordEditorScreen extends StatefulWidget {
  const WordEditorScreen({super.key, this.wordKey, this.prefill, this.onPublished, this.requestNote});

  /// Null for a new word.
  final String? wordKey;

  /// Starting fields for a new word (e.g. from a word request).
  final Map<String, dynamic>? prefill;

  /// Called with the key after a successful publish (Requests marks the
  /// request fulfilled and tells the person).
  final Future<void> Function(String key, String word)? onPublished;

  /// Shown at the top: what the person asked for.
  final String? requestNote;

  @override
  State<WordEditorScreen> createState() => _WordEditorScreenState();
}

class _PartRow {
  _PartRow(Map p)
      : roman = TextEditingController(text: '${p['roman'] ?? ''}'),
        deva = TextEditingController(text: '${p['deva'] ?? ''}'),
        hold = TextEditingController(text: '${p['hold'] ?? 1.5}'),
        say = TextEditingController(text: '${p['say'] ?? ''}'),
        audio = '${p['audio'] ?? ''}';
  final TextEditingController roman, deva, hold, say;
  String audio;
  Map<String, dynamic> toMap() => {
        'roman': roman.text.trim(),
        'deva': deva.text.trim(),
        'hold': double.tryParse(hold.text.trim()) ?? 1.5,
        'say': say.text.trim(),
        'audio': audio,
      };
  void dispose() {
    roman.dispose();
    deva.dispose();
    hold.dispose();
    say.dispose();
  }
}

class _StageRow {
  _StageRow(Map p)
      : title = TextEditingController(text: '${p['title'] ?? ''}'),
        text = TextEditingController(text: '${p['text'] ?? ''}'),
        audio = '${p['audio'] ?? ''}',
        video = '${p['video'] ?? ''}';
  final TextEditingController title, text;
  String audio;
  String video;
  Map<String, dynamic> toMap() => {'title': title.text.trim(), 'text': text.text.trim(), 'audio': audio, 'video': video};
  void dispose() {
    title.dispose();
    text.dispose();
  }
}

class _WordEditorScreenState extends State<WordEditorScreen> {
  final _db = FirebaseFirestore.instance;
  static const _textFields = <String, String>{
    'word': 'Word',
    'deva': 'Devanagari',
    'translit': 'Transliteration',
    'phonetic': 'Phonetic (empty = built from parts)',
    'meaning': 'Meaning (short)',
    'description': 'Description',
    'meanings': 'More meanings — one per line',
    'benefit': 'Benefit',
    'organ': 'Organ',
    'origin': 'Origin',
    'mouthPos': 'Mouth position',
    'resonance': 'Resonance',
    'mistake': 'Common mistake',
    'tip': 'Tip',
    'categories': 'Categories — comma separated',
    'price': 'Price',
    'stage': 'Stage label (optional)',
    'notes': 'Notes (shown under the meanings)',
    'img': 'Picture URL',
    'images': 'More pictures — one URL per line',
    'video': 'Video URL (R2)',
    'videoPoster': 'Video poster picture URL',
    'audioMale': 'Older field: male audio URL',
    'audioFemale': 'Older field: female audio URL',
  };
  static const _multiline = {'description', 'meanings', 'benefit', 'tip', 'mistake', 'meaning', 'notes', 'images'};

  final Map<String, TextEditingController> _c = {
    for (final k in _textFields.keys) k: TextEditingController(),
  };
  final _key = TextEditingController();
  final List<_PartRow> _parts = [];
  final List<_StageRow> _stages = [];
  String _gender = 'both';
  String _time = 'any';
  String _audio = '';
  double _imgZoom = 1;
  String _status = 'shipped';
  int _version = 0;
  bool _hasDraft = false;
  bool _loading = true;
  bool _busy = false;
  String? _msg;

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _recording = false;
  File? _take;

  bool get _isNew => widget.wordKey == null;
  String get _k => _isNew ? wordKeyFor(_key.text.isEmpty ? _c['word']!.text : _key.text) : widget.wordKey!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Map<String, dynamic>? src;
    if (!_isNew) {
      final k = widget.wordKey!;
      try {
        final d = await _db.collection('word_drafts').doc(k).get();
        final p = await _db.collection('words').doc(k).get();
        if (p.exists) {
          _status = '${p.data()!['status'] ?? 'published'}';
          _version = (p.data()!['version'] as num?)?.toInt() ?? 1;
        }
        _hasDraft = d.exists;
        src = d.data() ?? p.data();
      } catch (e) {
        _msg = 'Could not read Firestore: $e';
      }
      if (src == null) {
        final shipped = ContentStore.instance.baseLibrary.where((w) => w.key == k);
        if (shipped.isNotEmpty) src = shipped.first.toMap();
      }
    }
    _fill(src ?? widget.prefill ?? const {});
    if (mounted) setState(() => _loading = false);
  }

  void _fill(Map<String, dynamic> m) {
    for (final k in _textFields.keys) {
      final v = m[k];
      _c[k]!.text = v is List ? v.join(k == 'categories' ? ', ' : '\n') : (v == null || v == 0 && k == 'price' ? '' : '$v');
    }
    if (m['price'] is num) _c['price']!.text = '${m['price']}';
    _gender = const ['M', 'F', 'both'].contains(m['gender']) ? m['gender'] as String : 'both';
    _time = const ['morning', 'evening', 'night', 'any'].contains(m['time']) ? m['time'] as String : 'any';
    _audio = '${m['audio'] ?? ''}';
    for (final st in _stages) {
      st.dispose();
    }
    _stages
      ..clear()
      ..addAll([
        if (m['stages'] is List)
          for (final st in m['stages'] as List)
            if (st is Map) _StageRow(st),
      ]);
    final word = '${m['word'] ?? widget.wordKey ?? ''}';
    _imgZoom = word.isEmpty ? 1 : WordArt.instance.scaleOf(word);
    if ((m['imgScale'] is num) && _imgZoom == 1) {
      _imgZoom = (m['imgScale'] as num).toDouble().clamp(0.5, 2.6);
    }
    for (final p in _parts) {
      p.dispose();
    }
    _parts
      ..clear()
      ..addAll([
        if (m['parts'] is List)
          for (final p in m['parts'] as List)
            if (p is Map) _PartRow(p) else _PartRow({'roman': '$p'}),
      ]);
  }

  Map<String, dynamic> _collect() {
    List<String> lines(String s, String sep) =>
        s.split(sep).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final out = <String, dynamic>{
      for (final k in _textFields.keys) k: _c[k]!.text.trim(),
    };
    out['meanings'] = lines(_c['meanings']!.text, '\n');
    out['categories'] = lines(_c['categories']!.text, ',');
    out['images'] = lines(_c['images']!.text, '\n').where((u) => u.startsWith('http')).toList();
    out['stages'] = [for (final st in _stages) st.toMap()].where((m) => '${m['title']}${m['text']}'.isNotEmpty).toList();
    out['price'] = num.tryParse(_c['price']!.text.trim()) ?? 0;
    out['parts'] = [for (final p in _parts) p.toMap()].where((p) => '${p['roman']}${p['deva']}'.isNotEmpty).toList();
    out['gender'] = _gender;
    out['time'] = _time;
    out['audio'] = _audio;
    out['key'] = _k;
    return out;
  }

  String? _validate(Map<String, dynamic> m) {
    if ('${m['word']}'.isEmpty) return 'The word is required.';
    if (_k.isEmpty) return 'The key is empty — type the word first.';
    if (Word.from(m) == null) return 'That does not make a usable word.';
    return null;
  }

  Map<String, dynamic> _stamp() {
    final u = FirebaseAuth.instance.currentUser;
    return {'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': u?.email ?? u?.uid ?? ''};
  }

  Future<void> _run(String label, Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _msg = label;
    });
    try {
      await job();
    } catch (e) {
      _msg = 'Failed: $e';
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _saveDraft() => _run('Saving draft…', () async {
        final m = _collect();
        final bad = _validate(m);
        if (bad != null) throw bad;
        await _db.collection('word_drafts').doc(_k).set({...m, ..._stamp()});
        await adminLog('word.draft', _k);
        _hasDraft = true;
        _msg = 'Draft saved — not visible to users yet.';
      });

  Future<void> _publish() => _run('Publishing…', () async {
        final m = _collect();
        final bad = _validate(m);
        if (bad != null) throw bad;
        _version += 1;
        await _db.collection('words').doc(_k).set({...m, 'status': 'published', 'version': _version, ..._stamp()});
        if (_hasDraft) await _db.collection('word_drafts').doc(_k).delete();
        await adminLog('word.publish', _k, {'version': _version});
        final img = '${m['img'] ?? ''}';
        if (img.isNotEmpty) {
          await WordArt.instance.set(_k, image: img, scale: _imgZoom, pushHistory: false);
        }
        _hasDraft = false;
        _status = 'published';
        _msg = 'Published v$_version — every app shows it now.';
        if (widget.onPublished != null) {
          _msg = 'Published v$_version. Marking the request done and telling them…';
          if (mounted) setState(() {});
          await widget.onPublished!(_k, '${m['word']}');
          _msg = 'Published v$_version and the request is fulfilled.';
        }
      });

  Future<void> _archive(bool archive) => _run(archive ? 'Archiving…' : 'Restoring…', () async {
        final m = _collect();
        await _db.collection('words').doc(_k).set({
          ...m,
          'status': archive ? 'archived' : 'published',
          'version': _version == 0 ? 1 : _version,
          ..._stamp(),
        });
        await adminLog(archive ? 'word.archive' : 'word.restore', _k);
        _status = archive ? 'archived' : 'published';
        _msg = archive ? 'Archived — removed from every app.' : 'Restored.';
      });

  // ── Voice ────────────────────────────────────────────────────────────
  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _take = path == null ? null : File(path);
        _msg = _take == null ? 'Nothing recorded.' : 'Recorded — play it back, then upload.';
      });
      return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() => _msg = 'Microphone permission is off.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/nwsb-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100, numChannels: 1),
      path: path,
    );
    setState(() {
      _recording = true;
      _msg = 'Recording… tap stop when done.';
    });
  }

  Future<void> _pickVoice() async {
    final f = await pickMedia(context, PickKind.audio);
    if (f != null) setState(() => _take = f);
  }

  Future<void> _play(String src) async {
    try {
      await _player.stop();
      if (src.startsWith('http')) {
        await _player.setUrl(src);
      } else {
        await _player.setFilePath(src);
      }
      await _player.play();
    } catch (e) {
      setState(() => _msg = 'Could not play: $e');
    }
  }

  Future<void> _uploadVoice() => _run('Uploading voice…', () async {
        final f = _take;
        if (f == null) return;
        if (_k.isEmpty) throw 'Type the word first.';
        final up = await uploadToR2(f, 'audio', _k, PickKind.audio);
        _audio = up.url;
        _take = null;
        await adminLog('word.voice', _k, {'url': up.url});
        _msg = 'Voice uploaded. Publish to send it to every app.';
      });

  Future<void> _nudgeZoom(double delta) async {
    final next = (_imgZoom + delta).clamp(0.5, 2.6);
    setState(() => _imgZoom = next);
    if (_k.isEmpty) return;
    await WordArt.instance.set(_k, scale: next, image: _c['img']!.text.trim().isEmpty ? null : _c['img']!.text.trim());
    if (mounted) setState(() => _imgZoom = WordArt.instance.scaleOf(_k));
  }

  Future<void> _uploadImage() async {
    final f = await pickMedia(context, PickKind.image);
    if (f == null) return;
    await _run('Uploading picture…', () async {
      if (_k.isEmpty) throw 'Type the word first.';
      final up = await uploadToR2(f, 'image', _k, PickKind.image);
      _c['img']!.text = up.url;
      await WordArt.instance.set(_k, image: up.url, scale: _imgZoom);
      await adminLog('word.image', _k, {'url': up.url});
      _msg = 'Picture saved on this word. Library, meaning, signature and ebook use it.';
    });
  }

  Future<void> _uploadVideo() async {
    final f = await pickMedia(context, PickKind.video);
    if (f == null) return;
    await _run('Uploading video…', () async {
      if (_k.isEmpty) throw 'Type the word first.';
      final up = await uploadToR2(f, 'video', _k, PickKind.video);
      _c['video']!.text = up.url;
      await adminLog('word.video', _k, {'url': up.url});
      _msg = 'Video uploaded. Publish to send it to every app.';
    });
  }

  Future<void> _addImage() async {
    final f = await pickMedia(context, PickKind.image);
    if (f == null) return;
    await _run('Uploading picture…', () async {
      if (_k.isEmpty) throw 'Type the word first.';
      final up = await uploadToR2(f, 'image', _k, PickKind.image);
      final t = _c['images']!.text.trim();
      _c['images']!.text = t.isEmpty ? up.url : '$t\n${up.url}';
      await adminLog('word.image', _k, {'url': up.url});
      _msg = 'Picture added. Publish to send it to every app.';
    });
  }

  Future<void> _stageMedia(_StageRow st, PickKind kind) async {
    final f = await pickMedia(context, kind);
    if (f == null) return;
    await _run('Uploading…', () async {
      if (_k.isEmpty) throw 'Type the word first.';
      final up = await uploadToR2(f, kind == PickKind.video ? 'video' : 'audio', '$_k-stage', kind);
      if (kind == PickKind.video) {
        st.video = up.url;
      } else {
        st.audio = up.url;
      }
      _msg = 'Stage ${kind == PickKind.video ? 'video' : 'audio'} uploaded.';
    });
  }

  @override
  void dispose() {
    for (final st in _stages) {
      st.dispose();
    }
    for (final c in _c.values) {
      c.dispose();
    }
    for (final p in _parts) {
      p.dispose();
    }
    _key.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Widget _field(String k) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: _c[k],
          minLines: 1,
          maxLines: _multiline.contains(k) ? 6 : 1,
          keyboardType: k == 'price' ? const TextInputType.numberWithOptions(decimal: true) : null,
          style: const TextStyle(color: Colors.white),
          onChanged: k == 'word' && _isNew ? (_) => setState(() {}) : null,
          decoration: InputDecoration(labelText: _textFields[k]),
        ),
      );

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
        child: Text(t, style: const TextStyle(color: kAdminGold, fontWeight: FontWeight.w800, fontSize: 13)),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AdminScaffold(title: 'Word', body: Center(child: CircularProgressIndicator()));
    }
    return AdminScaffold(
      title: _isNew ? 'New word' : 'Edit ${widget.wordKey}',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        children: [
          Wrap(spacing: 6, children: [
            AdminChip(_status),
            if (_version > 0) AdminChip('v$_version', color: Colors.white54),
            if (_hasDraft) const AdminChip('draft', color: Color(0xFFFFB74D)),
          ]),
          if (_msg != null) ...[
            const SizedBox(height: 8),
            Text(_msg!, style: const TextStyle(color: kAdminDim, fontSize: 12)),
          ],
          if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2)),
          if (widget.requestNote != null && widget.requestNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AdminPanel(
                child: Row(children: [
                  const Icon(Icons.inbox_rounded, color: kAdminGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.requestNote!, style: const TextStyle(color: Colors.white, fontSize: 12.5))),
                ]),
              ),
            ),
          _head('Word'),
          _field('word'),
          if (_isNew)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _key,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: 'Key (optional) — will be “$_k”'),
              ),
            ),
          _field('deva'),
          _field('translit'),
          _field('phonetic'),
          _head('Voice — one recording, played instead of text-to-speech'),
          AdminPanel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_audio.isEmpty ? 'No recording — the app uses text-to-speech.' : _audio,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kAdminDim, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: _recording ? Colors.redAccent : kAdminGold, foregroundColor: kAdminBg),
                  onPressed: _busy ? null : _toggleRecord,
                  icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
                  label: Text(_recording ? 'Stop' : 'Record'),
                ),
                OutlinedButton.icon(
                    onPressed: _busy || _recording ? null : _pickVoice,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Pick file')),
                if (_take != null)
                  OutlinedButton.icon(
                      onPressed: () => _play(_take!.path),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play take')),
                if (_take != null)
                  FilledButton.icon(
                      onPressed: _busy ? null : _uploadVoice,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload take')),
                if (_audio.isNotEmpty)
                  OutlinedButton.icon(
                      onPressed: () => _play(_audio), icon: const Icon(Icons.volume_up), label: const Text('Play current')),
                if (_audio.isNotEmpty)
                  TextButton(onPressed: () => setState(() => _audio = ''), child: const Text('Remove')),
              ]),
            ]),
          ),
          _head('Parts (3–5 pronunciation boxes)'),
          for (var i = 0; i < _parts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminPanel(
                padding: const EdgeInsets.all(10),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _parts[i].roman,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Roman'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: _parts[i].deva,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Deva'))),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 64,
                        child: TextField(
                            controller: _parts[i].hold,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Hold s'))),
                    IconButton(
                      onPressed: () => setState(() => _parts.removeAt(i).dispose()),
                      icon: const Icon(Icons.close, color: Colors.white38),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _parts[i].say,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'How to make the sound')),
                ]),
              ),
            ),
          if (_parts.length < 5)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _parts.add(_PartRow(const {}))),
                icon: const Icon(Icons.add),
                label: const Text('Add part'),
              ),
            ),
          _head('Video — plays on the word page'),
          AdminPanel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field('video'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kAdminGold, foregroundColor: kAdminBg),
                  onPressed: _busy ? null : _uploadVideo,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('Record or pick video'),
                ),
                if (_c['video']!.text.isNotEmpty)
                  TextButton(onPressed: () => setState(() => _c['video']!.clear()), child: const Text('Remove')),
              ]),
              const SizedBox(height: 10),
              _field('videoPoster'),
              if (_c['video']!.text.startsWith('http'))
                SizedBox(height: 180, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: NwsbVideo(asset: _c['video']!.text, fit: BoxFit.cover))),
            ]),
          ),
          _head('Meaning'),
          _field('meaning'),
          _field('description'),
          _field('meanings'),
          _field('benefit'),
          _field('notes'),
          _head('Stages (written steps, each with optional audio / video)'),
          for (var i = 0; i < _stages.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminPanel(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('${i + 1}', style: const TextStyle(color: kAdminGold, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _stages[i].title, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stage title'))),
                    IconButton(onPressed: () => setState(() => _stages.removeAt(i).dispose()), icon: const Icon(Icons.close, color: Colors.white38)),
                  ]),
                  const SizedBox(height: 8),
                  TextField(controller: _stages[i].text, minLines: 2, maxLines: 6, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'What to do in this stage')),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    OutlinedButton.icon(onPressed: _busy ? null : () => _stageMedia(_stages[i], PickKind.audio), icon: const Icon(Icons.graphic_eq, size: 16), label: Text(_stages[i].audio.isEmpty ? 'Audio' : 'Replace audio')),
                    OutlinedButton.icon(onPressed: _busy ? null : () => _stageMedia(_stages[i], PickKind.video), icon: const Icon(Icons.videocam_outlined, size: 16), label: Text(_stages[i].video.isEmpty ? 'Video' : 'Replace video')),
                    if (_stages[i].audio.isNotEmpty) IconButton(onPressed: () => _play(_stages[i].audio), icon: const Icon(Icons.play_arrow, color: kAdminGold)),
                    if (_stages[i].video.isNotEmpty) const AdminChip('video', color: Color(0xFF81C784)),
                  ]),
                ]),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _stages.add(_StageRow(const {}))),
              icon: const Icon(Icons.add),
              label: const Text('Add stage'),
            ),
          ),
          _head('Practice'),
          _field('organ'),
          _field('origin'),
          _field('mouthPos'),
          _field('resonance'),
          _field('mistake'),
          _field('tip'),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Voice gender'),
                items: const [
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                  DropdownMenuItem(value: 'M', child: Text('Male')),
                  DropdownMenuItem(value: 'F', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'both'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _time,
                decoration: const InputDecoration(labelText: 'Time of day'),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'morning', child: Text('Morning')),
                  DropdownMenuItem(value: 'evening', child: Text('Evening')),
                  DropdownMenuItem(value: 'night', child: Text('Night')),
                ],
                onChanged: (v) => setState(() => _time = v ?? 'any'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _head('Store & library'),
          _field('categories'),
          _field('price'),
          _field('stage'),
          MediaTuneBar(
            zoom: _imgZoom,
            canUndo: WordArt.instance.canUndo(_k),
            onUndo: _busy
                ? null
                : () async {
                    final ok = await WordArt.instance.undo(_k);
                    if (!mounted) return;
                    final pic = WordArt.instance.imageOf(_k);
                    setState(() {
                      _imgZoom = WordArt.instance.scaleOf(_k);
                      if (pic != null) _c['img']!.text = pic;
                      _msg = ok ? 'Previous picture restored.' : 'Nothing to undo.';
                    });
                  },
            onZoomOut: _busy ? null : () => _nudgeZoom(-0.15),
            onZoomIn: _busy ? null : () => _nudgeZoom(0.15),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field('img')),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IconButton.filledTonal(
                  onPressed: _busy ? null : _uploadImage, icon: const Icon(Icons.add_photo_alternate_outlined)),
            ),
          ]),
          if (_c['img']!.text.startsWith('http'))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 160,
                child: ClipRect(
                  child: Transform.scale(
                    scale: _imgZoom,
                    child: Image.network(_c['img']!.text, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          _field('images'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: _busy ? null : _addImage, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Add a picture')),
          ),
          if (_c['images']!.text.trim().isNotEmpty)
            SizedBox(
              height: 84,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final u in _c['images']!.text.split('\n').map((e) => e.trim()).where((e) => e.startsWith('http')))
                  Padding(padding: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(u, width: 84, height: 84, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 84)))),
              ]),
            ),
          _head('Older fields'),
          _field('audioMale'),
          _field('audioFemale'),
          const SizedBox(height: 18),
          Wrap(spacing: 10, runSpacing: 10, children: [
            OutlinedButton.icon(
                onPressed: _busy ? null : _saveDraft, icon: const Icon(Icons.save_outlined), label: const Text('Save draft')),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kAdminGold, foregroundColor: kAdminBg),
              onPressed: _busy ? null : _publish,
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Publish'),
            ),
            if (!_isNew && _status != 'archived')
              TextButton.icon(
                onPressed: _busy ? null : () => _archive(true),
                icon: const Icon(Icons.archive_outlined, color: Colors.redAccent),
                label: const Text('Archive', style: TextStyle(color: Colors.redAccent)),
              ),
            if (_status == 'archived')
              TextButton.icon(
                  onPressed: _busy ? null : () => _archive(false),
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Restore')),
          ]),
        ],
      ),
    );
  }
}
