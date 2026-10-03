/// The sheet that opens when the owner taps a pencil on the live screen (or a
/// row in All slots): what is there now, replace it, or put it back.
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/word_art.dart';
import '../admin_log.dart';
import '../admin_state.dart';
import '../media_upload.dart';
import 'media_tune.dart';
import 'slot_keys.dart';
import 'ui_overrides.dart';

Future<void> openSlotSheet(
  BuildContext context, {
  required String slotKey,
  required SlotType type,
  required String defaultValue,
  String? word,
}) {
  if (!AdminState.instance.isAdmin) return Future.value();
  final bound = word ?? wordOfSlot(slotKey);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: const Color(0xFF0C1220),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => SlotSheet(slotKey: slotKey, type: type, defaultValue: defaultValue, word: bound),
  );
}

/// `….word-aarogya` slots are the shared picture for that word.
String? wordOfSlot(String key) {
  const mark = '.word-';
  final i = key.lastIndexOf(mark);
  if (i < 0) return null;
  final rest = key.substring(i + mark.length);
  return rest.isEmpty ? null : rest;
}

class SlotSheet extends StatefulWidget {
  const SlotSheet({
    super.key,
    required this.slotKey,
    required this.type,
    required this.defaultValue,
    this.word,
  });

  final String slotKey;
  final SlotType type;
  final String defaultValue;
  final String? word;

  @override
  State<SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends State<SlotSheet> {
  late final TextEditingController _text;
  bool _busy = false;
  double? _progress;
  String? _msg;
  late double _zoom;
  var _canUndo = false;

  UiOverride? get _current => UiOverrides.instance.get(widget.slotKey);
  String? get _bound => widget.word;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: UiOverrides.instance.textFor(widget.slotKey) ?? widget.defaultValue,
    );
    final bound = _bound;
    if (bound != null) {
      _zoom = WordArt.instance.scaleOf(bound);
      _canUndo = WordArt.instance.canUndo(bound);
    } else {
      final z = _current?.style['zoom'];
      _zoom = z is num ? z.toDouble().clamp(0.5, 2.6) : 1;
      _canUndo = _current?.style['undoUrl'] != null || _current?.style['undoZoom'] != null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('ui_overrides')
      .doc(slotDocId(widget.slotKey));

  Future<void> _saveText() async {
    final t = _text.text;
    if (t == widget.defaultValue) return _reset();
    await _write({'text': t}, UiOverride(slot: widget.slotKey, type: SlotType.text, text: t));
  }

  Future<void> _replaceMedia() async {
    final kind = widget.type == SlotType.video ? PickKind.video : PickKind.image;
    final file = await pickMedia(context, kind);
    if (file == null || !mounted) return;
    setState(() {
      _busy = true;
      _progress = 0;
      _msg = 'Uploading…';
    });
    try {
      final up = await uploadToR2(
        file,
        'ui',
        slotDocId(widget.slotKey),
        kind,
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      );
      UiOverrides.instance.primeFile(up.url, file);
      final bound = _bound;
      if (bound != null) {
        final kindVideo = widget.type == SlotType.video;
        await WordArt.instance.set(
          bound,
          image: kindVideo ? null : up.url,
          video: kindVideo ? up.url : null,
        );
      }
      final style = Map<String, dynamic>.from(_current?.style ?? {});
      style['undoUrl'] = _current?.url.isNotEmpty == true ? _current!.url : widget.defaultValue;
      style['undoZoom'] = _zoom;
      style['zoom'] = _zoom;
      await _write(
        {'url': up.url, 'storagePath': up.key, 'style': style},
        UiOverride(
          slot: widget.slotKey,
          type: widget.type,
          url: up.url,
          storagePath: up.key,
          textSet: false,
          style: style,
        ),
      );
      if (mounted && bound != null) {
        setState(() => _canUndo = WordArt.instance.canUndo(bound));
      } else if (mounted) {
        setState(() => _canUndo = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _msg = 'Upload failed: $e';
        });
      }
    }
  }

  Future<void> _write(Map<String, dynamic> fields, UiOverride local) async {
    setState(() {
      _busy = true;
      _msg = 'Saving…';
    });
    try {
      final u = FirebaseAuth.instance.currentUser;
      await _doc.set({
        'slot': widget.slotKey,
        'type': widget.type.name,
        'url': '',
        'text': '',
        'storagePath': '',
        ...fields,
        'default': widget.defaultValue,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': u?.email ?? u?.uid ?? '',
      });
      UiOverrides.instance.applyLocal(local);
      await adminLog('template.replace', widget.slotKey, {
        'type': widget.type.name,
        if (fields['text'] != null) 'text': fields['text'],
        if (fields['url'] != null) 'url': fields['url'],
      });
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _msg = 'Live — every open app shows it now.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _msg = 'Could not save: $e';
        });
      }
    }
  }

  Future<void> _nudge(double delta) async {
    final next = (_zoom + delta).clamp(0.5, 2.6);
    if ((next - _zoom).abs() < 0.001) return;
    final bound = _bound;
    if (bound != null) {
      await WordArt.instance.set(bound, scale: next);
      if (!mounted) return;
      setState(() {
        _zoom = WordArt.instance.scaleOf(bound);
        _canUndo = WordArt.instance.canUndo(bound);
        _msg = 'Zoom saved on this word. Every place it appears uses it.';
      });
      return;
    }
    await _stashSlot(zoom: next);
  }

  Future<void> _undo() async {
    final bound = _bound;
    if (bound != null) {
      final ok = await WordArt.instance.undo(bound);
      if (!mounted) return;
      setState(() {
        _zoom = WordArt.instance.scaleOf(bound);
        _canUndo = WordArt.instance.canUndo(bound);
        _msg = ok ? 'Previous picture restored.' : 'Nothing to undo.';
      });
      return;
    }
    final cur = _current;
    final prevUrl = cur?.style['undoUrl'];
    final prevZoom = cur?.style['undoZoom'];
    if (cur == null || (prevUrl == null && prevZoom == null)) return;
    final style = Map<String, dynamic>.from(cur.style)..remove('undoUrl')..remove('undoZoom');
    final z = prevZoom is num ? prevZoom.toDouble() : 1.0;
    style['zoom'] = z;
    final url = prevUrl is String ? prevUrl : cur.url;
    await _write(
      {'url': url == widget.defaultValue ? '' : url, 'storagePath': '', 'style': style},
      cur.copyWith(url: url == widget.defaultValue ? '' : url, storagePath: '', style: style),
    );
    if (mounted) {
      setState(() {
        _zoom = z;
        _canUndo = false;
        _msg = 'Previous picture restored.';
      });
    }
  }

  Future<void> _stashSlot({String? url, double? zoom}) async {
    final cur = _current;
    final style = Map<String, dynamic>.from(cur?.style ?? {});
    style['undoUrl'] = cur?.url.isNotEmpty == true ? cur!.url : widget.defaultValue;
    style['undoZoom'] = _zoom;
    if (zoom != null) style['zoom'] = zoom;
    final nextUrl = url ?? cur?.url ?? '';
    await _write(
      {
        'url': nextUrl,
        'storagePath': cur?.storagePath ?? '',
        'style': style,
      },
      UiOverride(
        slot: widget.slotKey,
        type: widget.type,
        url: nextUrl,
        storagePath: cur?.storagePath ?? '',
        textSet: false,
        style: style,
      ),
    );
    if (mounted) {
      setState(() {
        if (zoom != null) _zoom = zoom;
        _canUndo = true;
      });
    }
  }

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _msg = 'Putting the original back…';
    });
    try {
      final bound = _bound;
      if (bound != null) {
        await WordArt.instance.set(bound, image: '', video: '', scale: 1);
      }
      await _doc.delete();
      UiOverrides.instance.removeLocal(widget.slotKey);
      await adminLog('template.reset', widget.slotKey);
      if (widget.type == SlotType.text) _text.text = widget.defaultValue;
      if (mounted) {
        setState(() {
          _busy = false;
          _msg = 'Back to the original.';
          if (bound != null) {
            _zoom = 1;
            _canUndo = WordArt.instance.canUndo(bound);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _msg = 'Could not reset: $e';
        });
      }
    }
  }

  Widget _preview(String source, {bool replaced = false}) {
    if (widget.type == SlotType.text) {
      return Text(source, style: const TextStyle(color: Colors.white, fontSize: 15));
    }
    final isRemote = source.startsWith('http');
    if (widget.type == SlotType.video) {
      return Row(children: [
        const Icon(Icons.movie_outlined, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            replaced ? 'Uploaded clip' : source,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ]);
    }
    final local = UiOverrides.instance.fileFor(source);
    final Widget img = local != null
        ? Image.file(File(local), fit: BoxFit.contain)
        : isRemote
            ? Image.network(source, fit: BoxFit.contain)
            : source.endsWith('.svg')
                ? const Icon(Icons.image_outlined, color: Colors.white54, size: 48)
                : Image.asset(source, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, color: Colors.white54));
    final shown = (_zoom - 1).abs() < 0.02
        ? img
        : ClipRect(child: Transform.scale(scale: _zoom, child: img));
    return SizedBox(height: 160, child: Center(child: shown));
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current;
    final isText = widget.type == SlotType.text;
    return AnimatedBuilder(
      animation: Listenable.merge([UiOverrides.instance, WordArt.instance]),
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(
            18, 16, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(
                  isText
                      ? Icons.text_fields_rounded
                      : (widget.type == SlotType.video ? Icons.movie_outlined : Icons.image_outlined),
                  color: const Color(0xFFE8D5A3),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isText ? 'Edit text' : (widget.type == SlotType.video ? 'Replace clip' : 'Replace picture'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                if (cur != null)
                  const Chip(
                    label: Text('Changed', style: TextStyle(fontSize: 11)),
                    backgroundColor: Color(0xFF34D399),
                    visualDensity: VisualDensity.compact,
                  ),
              ]),
              const SizedBox(height: 6),
              GestureDetector(
                onLongPress: () => Clipboard.setData(ClipboardData(text: widget.slotKey)),
                child: Text(
                  'Slot: ${widget.slotKey}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Original', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              _preview(widget.defaultValue),
              if (!isText && _bound != null && (WordArt.instance.imageOf(_bound!) ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('This word, everywhere', style: const TextStyle(color: Color(0xFFE8D5A3), fontSize: 12)),
                const SizedBox(height: 6),
                _preview(WordArt.instance.imageOf(_bound!)!, replaced: true),
              ],
              if (!isText && cur != null && cur.url.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Now showing', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                _preview(cur.url, replaced: true),
              ],
              if (isText) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Text everyone sees',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8D5A3))),
                  ),
                ),
              ],
              if (_progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress, color: const Color(0xFFE8D5A3)),
              ],
              if (_msg != null) ...[
                const SizedBox(height: 10),
                Text(_msg!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              if (!isText) ...[
                MediaTuneBar(
                  zoom: _zoom,
                  canUndo: _canUndo,
                  onUndo: _busy ? null : _undo,
                  onZoomOut: _busy ? null : () => _nudge(-0.15),
                  onZoomIn: _busy ? null : () => _nudge(0.15),
                ),
                const SizedBox(height: 10),
              ],
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8D5A3),
                      foregroundColor: const Color(0xFF060C18),
                    ),
                    onPressed: _busy ? null : (isText ? _saveText : _replaceMedia),
                    icon: Icon(isText ? Icons.check_rounded : Icons.upload_rounded),
                    label: Text(isText ? 'Save for everyone' : 'Choose replacement'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: _busy || (cur == null && _bound == null) ? null : _reset,
                  child: const Text('Reset'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
