import 'dart:async';

import 'package:flutter/material.dart';

import '../media/video_cache.dart';
import '../theme/tokens.dart';

class VideoPackDialog extends StatefulWidget {
  const VideoPackDialog({super.key});

  @override
  State<VideoPackDialog> createState() => _VideoPackDialogState();
}

class _VideoPackDialogState extends State<VideoPackDialog> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedBuilder(
        animation: VideoCache.instance,
        builder: (context, _) {
          final state = VideoCache.instance.state;
          final running = state.running || _started;
          final done = state.complete;
          return Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF121722),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(.12)),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 12))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.movie_filter_outlined, color: NwsbColors.ink, size: 21),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('NowssB video pack', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  done
                      ? 'The video pack is ready in NowssB private storage.'
                      : running
                          ? '${state.completed} of ${state.total} videos ready. You can keep using the app while the rest downloads.'
                          : 'Download the videos once for smoother playback. They stay inside the app and never appear in your gallery.',
                  style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 13, height: 1.45),
                ),
                if (running || done) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: state.total == 0 ? 0 : state.progress.clamp(0, 1).toDouble(),
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8D5A3)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error == null ? (state.activeUrl == null ? 'Private app storage' : 'Downloading next video…') : 'Some files will retry later.',
                    style: const TextStyle(color: Color(0x82FFFFFF), fontSize: 11),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!running && !done)
                      TextButton(
                        onPressed: () async {
                          await VideoCache.instance.markPrompted();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Not now', style: TextStyle(color: Color(0xBFFFFFFF))),
                      ),
                    if (running || done)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(done ? 'Close' : 'Continue', style: const TextStyle(color: Color(0xFFE8D5A3))),
                      ),
                    if (!running && !done)
                      FilledButton(
                        onPressed: () {
                          setState(() => _started = true);
                          unawaited(VideoCache.instance.markAccepted());
                          unawaited(VideoCache.instance.downloadAll());
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: NwsbColors.ink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Download videos'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
