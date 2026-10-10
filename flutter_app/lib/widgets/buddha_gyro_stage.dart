/// Today's Quotes.
///
/// The Buddha stays put. The pictures behind it change one by one.
/// There is no tilt and no drag — that parallax is gone.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import '../admin/layout/scopes.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'app_thinking_loader.dart';
import 'glass_wrap.dart';
import 'neumorphic.dart';
import '../admin/template/editable.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

/// Pictures behind the Buddha, in order. The first is the quote plate.
const _quoteBacks = <String>[
  'assets/banners/gyro/words-bg.png',
  'assets/banners/stories/prana.png',
  'assets/banners/stories/soma.png',
  'assets/banners/stories/aura.png',
  'assets/banners/stories/pitta.png',
];

class BuddhaGyroStage extends StatefulWidget {
  const BuddhaGyroStage({
    super.key,
    this.neumorphic = false,
    this.onOpenQuotes,
  });

  /// Normal home. Fashion never gets a neu wrapper.
  final bool neumorphic;
  final VoidCallback? onOpenQuotes;

  @override
  State<BuddhaGyroStage> createState() => _BuddhaGyroStageState();
}

class _BuddhaGyroStageState extends State<BuddhaGyroStage> {
  Timer? _pageAuto;
  late final PageController _pager;
  var _page = 0;

  static const _stageH = 680.0;

  @override
  void initState() {
    super.initState();
    _pager = PageController();
    if (_flutterTest) return;
    _pageAuto = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (editorHoldsStill(context)) return;
      if (!mounted) return;
      if (!TickerMode.of(context)) return;
      if (!_pager.hasClients) return;
      final next = (_page + 1) % _quoteBacks.length;
      _pager.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _pageAuto?.cancel();
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.neumorphic ? const Color(0xFF2B2D33) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: EditableLabel('buddha_gyro_stage.BuddhaGyroStage',
            "Today's Quotes",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _enterBar(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _shell(child: _stage()),
        ),
      ],
    );
  }

  Widget _shell({required Widget child}) {
    if (widget.neumorphic) {
      return NeuCard(
        padding: const EdgeInsets.all(8),
        radius: 22,
        elevation: NwsbElevation.md,
        child: child,
      );
    }
    return GlassWrap(
      margin: EdgeInsets.zero,
      radius: 22,
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  Widget _stage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.black,
        child: SizedBox(
          height: _stageH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pager,
                itemCount: _quoteBacks.length,
                onPageChanged: (i) => _page = i,
                itemBuilder: (_, i) {
                  final words = i == 0;
                  return EditableImage.asset(
                    _quoteBacks[i],
                    fit: words ? BoxFit.contain : BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    slot: 'buddha_gyro_stage.BuddhaGyroStage',
                  );
                },
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0x00000000), Color(0xCC000000)],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
              // The Buddha does not move and does not change.
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.42,
                  child: EditableImage.asset(
                    'assets/banners/gyro/buddha.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    slot: 'buddha_gyro_stage.BuddhaGyroStage',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _enterBar() {
    final bar = GestureDetector(
      onTap: widget.onOpenQuotes,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const AppThinkingLoader(
              size: 34,
              state: OrbState.composing,
              blackCircle: true,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 28, color: const Color(0x33FFFFFF)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableLabel('buddha_gyro_stage.BuddhaGyroStage',
                    "This week's quotes",
                    style: TextStyle(
                      color: Color(0xFFE8D5A3),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  EditableLabel('buddha_gyro_stage.BuddhaGyroStage',
                    'Today, last day, and the rest of the week.',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5A3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const EditableLabel('buddha_gyro_stage.BuddhaGyroStage',
                'Enter',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.neumorphic) {
      return NeuCard(
        padding: const EdgeInsets.all(8),
        radius: 18,
        elevation: NwsbElevation.sm,
        child: bar,
      );
    }
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(8),
      child: bar,
    );
  }
}