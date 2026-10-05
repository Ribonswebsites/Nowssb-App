/// One voice recorder for every admin audio slot (a word's voice, each
/// stage's audio): record with a running timer, pause/resume, stop, listen
/// back with play/pause and a progress bar, re-record, discard, or pick a
/// file instead; then upload (the caller stores the URL). The current
/// published recording can be played or removed.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'admin_ui.dart';
import 'media_upload.dart';

class VoiceRecorderPanel extends StatefulWidget {
  const VoiceRecorderPanel({
    super.key,
    required this.current,
    required this.upload,
    required this.onRemove,
    this.emptyText = 'No recording yet.',
    this.compact = false,
    this.enabled = true,
  });

  /// The URL already saved for this slot ('' = none).
  final String current;

  /// Uploads a take; the caller saves the URL and shows its own message.
  final Future<void> Function(File take) upload;
  final VoidCallback onRemove;
  final String emptyText;
  final bool compact;
  final bool enabled;

  @override
  State<VoiceRecorderPanel> createState() => _VoiceRecorderPanelState();
}

enum _Rec { idle, recording, paused }

class _VoiceRecorderPanelState extends State<VoiceRecorderPanel> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  _Rec _rec = _Rec.idle;
  File? _take;
  String? _loaded;
  Duration _elapsed = Duration.zero;
  Timer? _tick;
  String? _note;
  bool _uploading = false;
  StreamSubscription<PlayerState>? _ps;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _ps = _player.playerStateStream.listen((s) {
      final playing = s.playing && s.processingState != ProcessingState.completed;
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      if (mounted && playing != _playing) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ps?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() => _elapsed += const Duration(milliseconds: 250));
    });
  }

  Future<void> _record() async {
    try {
      await _player.stop();
      if (!await _recorder.hasPermission()) {
        setState(() => _note = 'Microphone permission is off — allow it in phone settings.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/nwsb-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100, numChannels: 1), path: path);
      setState(() {
        _rec = _Rec.recording;
        _take = null;
        _loaded = null;
        _elapsed = Duration.zero;
        _note = null;
      });
      _startTick();
    } catch (e) {
      setState(() => _note = 'Could not start recording: $e');
    }
  }

  Future<void> _pauseResume() async {
    if (_rec == _Rec.recording) {
      await _recorder.pause();
      _tick?.cancel();
      setState(() => _rec = _Rec.paused);
    } else if (_rec == _Rec.paused) {
      await _recorder.resume();
      _startTick();
      setState(() => _rec = _Rec.recording);
    }
  }

  Future<void> _stop() async {
    _tick?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _rec = _Rec.idle;
      _take = path == null ? null : File(path);
      _note = _take == null ? 'Nothing was recorded.' : 'Listen back, then upload — or record again.';
    });
  }

  Future<void> _pick() async {
    final f = await pickMedia(context, PickKind.audio);
    if (f != null && mounted) {
      await _player.stop();
      setState(() {
        _take = f;
        _loaded = null;
        _elapsed = Duration.zero;
        _note = 'File ready — listen, then upload.';
      });
    }
  }

  Future<void> _toggle(String src) async {
    try {
      if (_playing && _loaded == src) {
        await _player.pause();
        return;
      }
      if (_loaded != src) {
        await _player.stop();
        if (src.startsWith('http')) {
          await _player.setUrl(src);
        } else {
          await _player.setFilePath(src);
        }
        _loaded = src;
      }
      unawaited(_player.play());
      setState(() {});
    } catch (e) {
      setState(() => _note = 'Could not play: $e');
    }
  }

  Future<void> _discard() async {
    await _player.stop();
    try {
      final t = _take;
      if (t != null && t.path.contains('nwsb-voice-') && await t.exists()) await t.delete();
    } catch (_) {}
    setState(() {
      _take = null;
      _loaded = null;
      _elapsed = Duration.zero;
      _note = 'Take discarded.';
    });
  }

  Future<void> _upload() async {
    final t = _take;
    if (t == null) return;
    setState(() => _uploading = true);
    try {
      await _player.stop();
      await widget.upload(t);
      if (mounted) {
        setState(() {
          _take = null;
          _loaded = null;
          _note = 'Uploaded.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _note = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _progress(String src) => StreamBuilder<Duration>(
        stream: _player.positionStream,
        builder: (context, snap) {
          final total = _player.duration ?? Duration.zero;
          final pos = _loaded == src ? (snap.data ?? Duration.zero) : Duration.zero;
          final v = total.inMilliseconds <= 0 ? 0.0 : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
          return Row(children: [
            Expanded(child: LinearProgressIndicator(value: v, minHeight: 3, color: kAdminGold, backgroundColor: Colors.white12)),
            const SizedBox(width: 8),
            Text(_loaded == src ? '${_fmt(pos)} / ${_fmt(total)}' : '', style: const TextStyle(color: kAdminDim, fontSize: 11)),
          ]);
        },
      );

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled && !_uploading;
    final recording = _rec != _Rec.idle;
    final take = _take;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // the saved one
      Row(children: [
        Icon(widget.current.isEmpty ? Icons.mic_off_rounded : Icons.graphic_eq_rounded, color: widget.current.isEmpty ? kAdminDim : kAdminGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(widget.current.isEmpty ? widget.emptyText : 'Saved: ${widget.current.split('/').last}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kAdminDim, fontSize: 12)),
        ),
        if (widget.current.isNotEmpty) ...[
          IconButton(
            tooltip: _playing && _loaded == widget.current ? 'Pause' : 'Play saved',
            onPressed: recording ? null : () => _toggle(widget.current),
            icon: Icon(_playing && _loaded == widget.current ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: kAdminGold),
          ),
          IconButton(tooltip: 'Remove', onPressed: on && !recording ? widget.onRemove : null, icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38)),
        ],
      ]),
      if (widget.current.isNotEmpty && _loaded == widget.current) _progress(widget.current),
      const SizedBox(height: 6),
      // recorder
      if (recording)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5))),
          child: Row(children: [
            Icon(_rec == _Rec.recording ? Icons.fiber_manual_record_rounded : Icons.pause_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(_rec == _Rec.recording ? 'Recording  ${_fmt(_elapsed)}' : 'Paused  ${_fmt(_elapsed)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
            const Spacer(),
            IconButton(tooltip: _rec == _Rec.recording ? 'Pause' : 'Resume', onPressed: _pauseResume, icon: Icon(_rec == _Rec.recording ? Icons.pause_rounded : Icons.mic_rounded, color: Colors.white)),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
            ),
          ]),
        )
      else if (take != null)
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(color: kAdminGold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: kAdminGold.withValues(alpha: 0.35))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(
                tooltip: _playing && _loaded == take.path ? 'Pause' : 'Play take',
                onPressed: () => _toggle(take.path),
                icon: Icon(_playing && _loaded == take.path ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: kAdminGold, size: 32),
              ),
              Expanded(
                child: Text('New take${_elapsed > Duration.zero ? ' · ${_fmt(_elapsed)}' : ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              IconButton(tooltip: 'Record again', onPressed: on ? _record : null, icon: const Icon(Icons.replay_rounded, color: Colors.white70)),
              IconButton(tooltip: 'Discard', onPressed: on ? _discard : null, icon: const Icon(Icons.close_rounded, color: Colors.white38)),
            ]),
            _progress(take.path),
            const SizedBox(height: 6),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kAdminGold, foregroundColor: kAdminBg),
              onPressed: on ? _upload : null,
              icon: _uploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kAdminBg))
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(_uploading ? 'Uploading…' : 'Upload this take'),
            ),
          ]),
        )
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kAdminGold, foregroundColor: kAdminBg),
            onPressed: on ? _record : null,
            icon: const Icon(Icons.mic_rounded),
            label: Text(widget.current.isEmpty ? 'Record' : 'Record new'),
          ),
          OutlinedButton.icon(onPressed: on ? _pick : null, icon: const Icon(Icons.folder_open_rounded), label: const Text('Pick file')),
        ]),
      if (_note != null)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text(_note!, style: const TextStyle(color: kAdminDim, fontSize: 11.5))),
    ]);
  }
}
