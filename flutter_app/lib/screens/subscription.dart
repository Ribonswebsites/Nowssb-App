import 'dart:async';

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
  int bannerIndex = 0;
  late final PageController planController;
  Timer? bannerTimer;

  static const bannerSlides = <(String, String)>[
    (
      'SUBSCRIPTION · JOIN NOWSSB',
      'Try it free for 30 days · Choose your frequency'
    ),
    ('EVERY WORD · EVERY FREQUENCY', 'Unlock the full NowssB practice'),
    ('JOIN NOWSSB', 'Get your subscription today'),
  ];

  @override
  void initState() {
    super.initState();
    planController = PageController(viewportFraction: .82);
    bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => bannerIndex = (bannerIndex + 1) % bannerSlides.length);
      }
    });
  }

  @override
  void dispose() {
    bannerTimer?.cancel();
    planController.dispose();
    super.dispose();
  }

  static const plans = <({
    String name,
    String detail,
    String monthly,
    String yearly,
    Color accent,
    IconData icon,
    List<String> benefits
  })>[
    (
      name: 'Free',
      detail: 'NowssB Edition',
      monthly: '30 days free',
      yearly: '30 days free',
      accent: Color(0xFFF1F1F4),
      icon: Icons.auto_awesome_rounded,
      benefits: [
        '30-day free trial',
        'Daily word discovery',
        'Essential meanings',
        'Try every frequency'
      ]
    ),
    (
      name: 'Resonance',
      detail: 'A deeper daily practice',
      monthly: r'$4.99 / month',
      yearly: r'$41.90 / year',
      accent: NwsbColors.mist,
      icon: Icons.graphic_eq_rounded,
      benefits: [
        'Unlimited word practice',
        'Resonance sound sessions',
        'Pronunciation scoring',
        'Personal practice history'
      ]
    ),
    (
      name: 'Frequency',
      detail: 'Every word and frequency',
      monthly: r'$9.99 / month',
      yearly: r'$83.90 / year',
      accent: NwsbColors.goldLight,
      icon: Icons.volume_up_rounded,
      benefits: [
        'Everything in Resonance',
        'Full frequency library',
        'Custom healing routines',
        'Advanced word meanings'
      ]
    ),
    (
      name: 'Frequency X',
      detail: 'The complete NowssB experience',
      monthly: r'$19.99 / month',
      yearly: r'$167.90 / year',
      accent: Color(0xFFF1F1F4),
      icon: Icons.auto_fix_high_rounded,
      benefits: [
        'Everything in Frequency',
        'Priority Personal Coach',
        'Exclusive signature words',
        'Complete NowssB access'
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: NwsbVideo(
                asset: 'assets/video/subscription-join-nowssb.mp4',
                poster: 'assets/video/subscription-join-nowssb-poster.webp',
                priority: ClipPriority.feature,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xB0060C18),
                      Color(0x66060C18),
                      Color(0xF0060C18),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
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
                SliverToBoxAdapter(child: _videoBanner()),
                SliverToBoxAdapter(child: _billing()),
                SliverToBoxAdapter(child: _horizontalPlans()),
                SliverToBoxAdapter(child: _benefits()),
                SliverToBoxAdapter(child: _bottomOffer()),
              ]),
            ),
          ],
        ),
      );

  Widget _videoBanner() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(fit: StackFit.expand, children: [
              const NwsbVideo(
                  asset: 'assets/video/subscription-join-nowssb.mp4',
                  poster: 'assets/video/subscription-join-nowssb-poster.webp',
                  priority: ClipPriority.feature),
              DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.black.withValues(alpha: .78),
                    Colors.transparent,
                    Colors.black.withValues(alpha: .84)
                  ]))),
              Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _rotatingBanner(),
                        const Spacer(),
                        const Align(
                            alignment: Alignment.bottomLeft,
                            child: Text('Choose your frequency',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900))),
                        const SizedBox(height: 8),
                        _blackBanner(
                            'JOIN NOWSSB', 'Get your subscription today'),
                      ])),
            ]),
          ),
        ),
      );

  Widget _blackBanner(String title, String subtitle, {Key? key}) => Container(
        key: key,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
            color: const Color(0xEE030303),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10))
              ])),
          const Icon(Icons.arrow_forward_rounded,
              color: Colors.white, size: 18),
        ]),
      );

  Widget _billing() => Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xFF151D2B),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white12)),
          child: Row(children: [
            _billingButton('Monthly', false),
            _billingButton('Yearly · Save 30%', true)
          ])));
  Widget _billingButton(String label, bool value) => Expanded(
      child: GestureDetector(
          onTap: () => setState(() => yearly = value),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: yearly == value
                      ? NwsbColors.goldLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999)),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: yearly == value ? NwsbColors.deep : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)))));

  Widget _horizontalPlans() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
            padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
            child: Text('Choose your frequency',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900))),
        SizedBox(
            height: 152,
            child: PageView.builder(
                controller: planController,
                itemCount: plans.length,
                onPageChanged: (i) => setState(() => selected = i),
                itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _planCard(i, plans[i])))),
      ]);

  Widget _planCard(
      int index,
      ({
        String name,
        String detail,
        String monthly,
        String yearly,
        Color accent,
        IconData icon,
        List<String> benefits
      }) plan) {
    final active = selected == index;
    return GestureDetector(
        onTap: () => setState(() => selected = index),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 270,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color:
                    active ? const Color(0xFF151D2B) : const Color(0xFF0D1420),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? plan.accent : Colors.white12,
                    width: active ? 1.5 : 1)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: plan.accent, shape: BoxShape.circle),
                    child: Icon(plan.icon, color: NwsbColors.deep, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(plan.name,
                        style: TextStyle(
                            color: plan.accent,
                            fontSize: 17,
                            fontWeight: FontWeight.w900))),
                Icon(
                    active
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    color: active ? plan.accent : Colors.white54,
                    size: 20)
              ]),
              const Spacer(),
              Text(plan.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 3),
              Text(yearly ? plan.yearly : plan.monthly,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800))
            ])));
  }

  Widget _benefits() {
    final plan = plans[selected];
    return Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
        child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: const Color(0xFF101927),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: plan.accent.withValues(alpha: .35))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('What you get with ${plan.name}',
                  style: TextStyle(
                      color: plan.accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              ...plan.benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded,
                        color: plan.accent, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(b,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)))
                  ]))),
              const SizedBox(height: 4),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: plan.accent,
                          foregroundColor: NwsbColors.deep,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999))),
                      child: Text(
                          plan.name == 'Free'
                              ? 'Start your 30-day free trial'
                              : 'Subscribe to ${plan.name}',
                          style: const TextStyle(fontWeight: FontWeight.w900))))
            ])));
  }

  Widget _rotatingBanner() {
    final slide = bannerSlides[bannerIndex];
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        child: _blackBanner(slide.$1, slide.$2, key: ValueKey(bannerIndex)));
  }

  Widget _bottomOffer() {
    final slide = bannerSlides[selected % bannerSlides.length];
    return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 42),
        child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            child: _blackBanner(slide.$1, slide.$2,
                key: ValueKey('bottom-$selected'))));
  }
}
