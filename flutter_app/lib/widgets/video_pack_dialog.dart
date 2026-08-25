import 'dart:async';

import 'package:flutter/material.dart';

import '../media/video_cache.dart';
import '../theme/tokens.dart';
import 'nwsb_icon.dart';

class VideoPackDialog extends StatefulWidget {
  const VideoPackDialog({super.key});

  @override
  State<VideoPackDialog> createState() => _VideoPackDialogState();
}

class _VideoPackDialogState extends State<VideoPackDialog>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: AnimatedBuilder(
        animation: Listenable.merge([VideoCache.instance, _pulseController]),
        builder: (context, _) {
          final state = VideoCache.instance.state;
          final running = state.running || _started;
          final done = state.complete;
          final pulse = Curves.easeInOut.transform(_pulseController.value);

          return Container(
            padding: const EdgeInsets.fromLTRB(21, 20, 21, 17),
            decoration: BoxDecoration(
              color: const Color(0xFF05070B),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(.14)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xA6000000),
                  blurRadius: 34,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/media/image/logo-disc-8b052034.webp',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: .94 + (pulse * .06),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(7),
                              child: NwsbIcon(
                                NwsbMarks.sound,
                                size: 26,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 25,
                            color: Colors.white.withOpacity(.26),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOWSSB',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Natural word science',
                                  style: TextStyle(
                                    color: Color(0x7AFFFFFF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(.13)),
                const SizedBox(height: 16),
                const Text(
                  'PREPARING YOUR EXPERIENCE',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Almost ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  done
                      ? 'Your additional NowssB access is ready in private app storage.'
                      : running
                          ? '${state.completed} of ${state.total} files ready. You can keep using NowssB while the remaining access files finish.'
                          : 'Additional access files are getting ready for a smoother NowssB experience. It may take a few minutes the first time — thanks for your patience.',
                  style: const TextStyle(
                    color: Color(0xB8FFFFFF),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: running || done
                        ? (state.total == 0
                            ? 0
                            : state.progress.clamp(0, 1).toDouble())
                        : 0,
                    backgroundColor: Colors.white.withOpacity(.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error == null
                      ? (running || done
                          ? (state.activeUrl == null
                              ? 'Preparing your experience… a few more seconds.'
                              : 'Preparing the next access file…')
                          : 'A few more seconds while NowssB prepares your experience.')
                      : 'Some access files will retry later.',
                  style: const TextStyle(
                    color: Color(0x7AFFFFFF),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!running && !done)
                      TextButton(
                        onPressed: () async {
                          await VideoCache.instance.markPrompted();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Maybe later',
                          style: TextStyle(color: Color(0xB8FFFFFF)),
                        ),
                      ),
                    if (running || done)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          done ? 'Close' : 'Continue',
                          style: const TextStyle(color: Colors.white),
                        ),
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
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Prepare now'),
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
