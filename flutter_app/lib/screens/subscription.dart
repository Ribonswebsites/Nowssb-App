import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool yearly = false;
  int selected = 0;

  static const plans = <({
    String name,
    String detail,
    String monthly,
    String yearly,
    Color accent,
    IconData icon
  })>[
    (
      name: 'Free',
      detail: 'NowssB Edition',
      monthly: '30 days free',
      yearly: '30 days free',
      accent: Color(0xFFF1F1F4),
      icon: Icons.auto_awesome_rounded
    ),
    (
      name: 'Resonance',
      detail: 'A deeper daily practice',
      monthly: r'$4.99 / month',
      yearly: r'$41.90 / year',
      accent: NwsbColors.mist,
      icon: Icons.graphic_eq_rounded
    ),
    (
      name: 'Frequency',
      detail: 'Every word and frequency',
      monthly: r'$9.99 / month',
      yearly: r'$83.90 / year',
      accent: NwsbColors.goldLight,
      icon: Icons.volume_up_rounded
    ),
    (
      name: 'Frequency X',
      detail: 'The complete NowssB experience',
      monthly: r'$19.99 / month',
      yearly: r'$167.90 / year',
      accent: Color(0xFFF1F1F4),
      icon: Icons.auto_fix_high_rounded
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: NwsbColors.deep.withValues(alpha: .92),
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white)),
              title: const Text('Subscription',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              centerTitle: true,
            ),
            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _billing()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
              sliver: SliverList.separated(
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _planCard(index, plans[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 330,
            child: Stack(fit: StackFit.expand, children: [
              const NwsbVideo(
                asset: 'assets/video/subscription-join-nowssb.mp4',
                poster: 'assets/video/subscription-join-nowssb-poster.webp',
                priority: ClipPriority.feature,
                showPoster: true,
              ),
              DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.black.withValues(alpha: .12),
                    Colors.black.withValues(alpha: .82)
                  ]))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('NOWSBANSIU EDITION',
                          style: TextStyle(
                              color: NwsbColors.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.4)),
                      SizedBox(height: 8),
                      Text('Join NowssB',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1,
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 8),
                      Text('Try it free for 30 days. Choose your frequency.',
                          style: TextStyle(
                              color: Color(0xD9FFFFFF), fontSize: 13)),
                    ]),
              ),
            ]),
          ),
        ),
      );

  Widget _billing() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xFF151D2B),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white12)),
          child: Row(children: [
            _billingButton('Monthly', false),
            _billingButton('Yearly · Save 30%', true),
          ]),
        ),
      );

  Widget _billingButton(String label, bool value) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => yearly = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color:
                    yearly == value ? NwsbColors.goldLight : Colors.transparent,
                borderRadius: BorderRadius.circular(999)),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: yearly == value ? NwsbColors.deep : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
        ),
      );

  Widget _planCard(
      int index,
      ({
        String name,
        String detail,
        String monthly,
        String yearly,
        Color accent,
        IconData icon
      }) plan) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => setState(() => selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: active ? const Color(0xFF151D2B) : const Color(0xFF0D1420),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active
                    ? plan.accent.withValues(alpha: .72)
                    : Colors.white12,
                width: active ? 1.4 : 1)),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(color: plan.accent, shape: BoxShape.circle),
              child: Icon(plan.icon, color: NwsbColors.deep, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(plan.name,
                    style: TextStyle(
                        color: plan.accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(plan.detail,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(yearly ? plan.yearly : plan.monthly,
                    style: const TextStyle(color: Colors.white54, fontSize: 11))
              ])),
          Icon(
              active ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
              color: active ? plan.accent : Colors.white54,
              size: 22),
        ]),
      ),
    );
  }
}
