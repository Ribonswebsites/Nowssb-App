import 'package:flutter/material.dart';

import '../../data/practice_progress.dart';

/// Fashion-home version of the former My Progress practice card.
class OriginPracticePanel extends StatelessWidget {
  const OriginPracticePanel({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress = PracticeProgress.instance;
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('ORIGIN WORDS',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3)),
            ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                height: 360,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .18)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 30,
                        offset: Offset(0, 16))
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/profile_source/img-progress.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF211637))),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xAA51207C),
                              Color(0xB30D0914),
                              Color(0xE6000000)
                            ]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            _Pill(label: '+12'),
                            Spacer(),
                            _Pill(label: 'ACTIVE')
                          ]),
                          const Spacer(),
                          const Text('Origin Words',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.schedule_outlined,
                                color: Colors.white70, size: 17),
                            const SizedBox(width: 5),
                            const Text('Om',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(width: 14),
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFD36B), size: 18),
                            const SizedBox(width: 4),
                            const Text('4.7',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(width: 14),
                            const Icon(Icons.play_circle_outline,
                                color: Colors.white70, size: 17),
                            const SizedBox(width: 4),
                            Text('${progress.totalSessions}',
                                style: const TextStyle(color: Colors.white70)),
                          ]),
                          const SizedBox(height: 18),
                          Row(children: [
                            const Text('1 of 5',
                                style: TextStyle(color: Colors.white70)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 11),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24)),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Continue',
                                        style: TextStyle(
                                            color: Color(0xFF171021),
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(width: 8),
                                    Icon(Icons.chevron_right_rounded,
                                        color: Color(0xFF171021), size: 19),
                                  ]),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: const Color(0x99110D1A),
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .10))),
              child: const Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('From Sound to Stillness',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Continue your origin practice',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                    ])),
                Icon(Icons.arrow_forward_rounded, color: Colors.white70),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(22)),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF3B2A59),
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      );
}
