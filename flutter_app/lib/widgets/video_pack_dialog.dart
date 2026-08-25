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

class _PreparationVisual {
  const _PreparationVisual(this.kicker, this.title, this.mark);

  final String kicker;
  final String title;
  final String mark;
}

class _VideoPackDialogState extends State<VideoPackDialog>
    with SingleTickerProviderStateMixin {
  static const _visuals = <_PreparationVisual>[
    _PreparationVisual('PREPARING YOUR EXPERIENCE', 'Almost ready', NwsbMarks.sound),
    _PreparationVisual('LOADING YOUR PRACTICE', 'Setting up your rhythm', NwsbMarks.reader),
    _PreparationVisual('READYING YOUR LIBRARY', 'Arranging your words', NwsbMarks.book),
    _PreparationVisual('TUNING YOUR EXPERIENCE', 'Making space to focus', NwsbMarks.signature),
    _PreparationVisual('OPENING YOUR PATH', 'Almost there', NwsbMarks.people),
  ];

  bool _started = false;
  int _visualIndex = 0;
  late final AnimationController _pulseController;
  Timer? _visualTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _visualTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) setState(() => _visualIndex = (_visualIndex + 1) % _visuals.length);
    });
  }

  @override
  void dispose() {
    _visualTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _prepare({bool close = false}) {
    if (!_started) {
      setState(() => _started = true);
      unawaited(VideoCache.instance.markAccepted());
      unawaited(VideoCache.instance.downloadAll());
    }
    if (close && mounted) Navigator.of(context).pop();
  }

  Future<void> _maybeLater() async {
    await VideoCache.instance.markPrompted();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _iconOrb(_PreparationVisual visual, double pulse) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Transform.scale(
        key: ValueKey(visual.title),
        scale: .96 + pulse * .04,
        child: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: NwsbIcon(
              visual.mark,
              size: 28,
              color: NwsbColors.ink,
            ),
          ),
        ),
      ),
    );
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
          final initial = !_started && !state.running && state.completed == 0;
          final visual = _visuals[_visualIndex];
          final pulse = Curves.easeInOut.transform(_pulseController.value);
          final progress = state.total == 0
              ? 0.0
              : state.progress.clamp(0, 1).toDouble();
          final kicker = done
              ? 'YOUR EXPERIENCE IS READY'
              : initial
                  ? visual.kicker
                  : visual.kicker;
          final title = done ? 'Ready when you are' : visual.title;
          final copy = done
              ? 'Your additional NowssB access is ready in private app storage.'
              : initial
                  ? 'Additional access files are getting ready for a smoother NowssB experience. It may take a few minutes the first time — thanks for your patience.'
                  : '${state.completed} of ${state.total} files ready${state.failed > 0 ? ' · ${state.failed} will retry' : ''}. You can keep using NowssB while the rest finishes.';
          final status = done
              ? 'Everything is ready for your next session.'
              : state.error != null
                  ? 'A connection paused briefly. We will retry automatically.'
                  : 'A few more seconds while NowssB prepares your experience.';

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 17),
            decoration: BoxDecoration(
              color: const Color(0xFF05070B),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(.16)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xB0000000),
                  blurRadius: 38,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(width: 11),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withOpacity(.28),
                    ),
                    const SizedBox(width: 11),
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
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _prepare(close: true),
                      style: FilledButton.styleFrom(
                        foregroundColor: NwsbColors.ink,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Continue to app'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(.13)),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _iconOrb(visual, pulse),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 33,
                      color: Colors.white.withOpacity(.25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Column(
                          key: ValueKey(title),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kicker,
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.9,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  copy,
                  style: const TextStyle(
                    color: Color(0xB8FFFFFF),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 17),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: running || done ? progress : 0,
                    backgroundColor: Colors.white.withOpacity(.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
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
                    if (initial)
                      TextButton(
                        onPressed: _maybeLater,
                        child: const Text(
                          'Maybe later',
                          style: TextStyle(color: Color(0xB8FFFFFF)),
                        ),
                      ),
                    if (initial)
                      FilledButton(
                        onPressed: () => _prepare(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: NwsbColors.ink,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text('Prepare files'),
                      ),
                    if (!initial)
                      FilledButton(
                        onPressed: done ? () => Navigator.of(context).pop() : () => _prepare(close: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: NwsbColors.ink,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(done ? 'Close' : 'Continue to app'),
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
