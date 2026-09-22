/// "Please select the store" bottom sheet — strong glassmorphism.
/// Active store: glowing ring + bottom bar (not a lone "Here" pill).
/// Picker arts ONLY here — picker-words/meaning/signature/ebooks.
/// Top film: assets/video/choose-store.mp4 (#1) — Choose Store page only.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../widgets/app_thinking_loader.dart';

class StoreSelectEntry {
  const StoreSelectEntry({
    required this.id,
    required this.title,
    required this.art,
  });
  final String id;
  final String title;
  final String art;
}

/// Four picker images — strictly only used in this choose-store sheet.
const kStoreSelectEntries = <StoreSelectEntry>[
  StoreSelectEntry(
    id: 'word',
    title: 'Word Atelier',
    art: 'assets/store/picker-words.png',
  ),
  StoreSelectEntry(
    id: 'meaning',
    title: 'Meaning',
    art: 'assets/store/picker-meaning.png',
  ),
  StoreSelectEntry(
    id: 'signature',
    title: 'Signature',
    art: 'assets/store/picker-signature.png',
  ),
  StoreSelectEntry(
    id: 'ebooks',
    title: 'Ebooks',
    art: 'assets/store/picker-ebooks.png',
  ),
];

/// Choose Store sheet film — attachment #1 only. Never used for Signature/Subscribe.
const kChooseStoreVideo = 'assets/video/choose-store.mp4';

Future<void> showStoreSelectSheet(
  BuildContext context, {
  required ValueChanged<String> onSelect,
  String? current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: const Color(0xCC000000),
    builder: (sheetCtx) => StoreSelectSheet(
      onSelect: onSelect,
      current: current,
    ),
  );
}

class StoreSelectSheet extends StatelessWidget {
  const StoreSelectSheet({
    super.key,
    required this.onSelect,
    this.current,
  });
  final ValueChanged<String> onSelect;
  final String? current;

  void _pick(BuildContext context, String id) {
    Navigator.of(context).pop();
    onSelect(id);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0x66FFFFFF),
                  const Color(0x33FFFFFF),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: const Color(0x77FFFFFF), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x77FFFFFF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: NwsbVideo(
                      asset: kChooseStoreVideo,
                      priority: ClipPriority.feature,
                      autoplay: true,
                      loop: true,
                      showPoster: false,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Please select the store',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      for (var i = 0; i < kStoreSelectEntries.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _StoreSelectCard(
                            entry: kStoreSelectEntries[i],
                            active: current == kStoreSelectEntries[i].id,
                            onExplore: () =>
                                _pick(context, kStoreSelectEntries[i].id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreSelectCard extends StatelessWidget {
  const _StoreSelectCard({
    required this.entry,
    required this.onExplore,
    required this.active,
  });
  final StoreSelectEntry entry;
  final VoidCallback onExplore;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExplore,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? const Color(0xFFE8D5A3) : const Color(0x33FFFFFF),
            width: active ? 2.5 : 1,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x88E8D5A3),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                entry.art,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, sync) {
                  if (sync || frame != null) return child;
                  return const ColoredBox(
                    color: Color(0xFF0A0A0E),
                    child: Center(
                      child: AppThinkingLoader(
                        size: 36,
                        state: OrbState.composing,
                        circlePad: 4,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF1A1A1E),
                  child: Center(
                    child: Icon(Icons.storefront_outlined,
                        color: Color(0x66FFFFFF)),
                  ),
                ),
              ),
              if (active) ...[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33E8D5A3), Color(0x00000000), Color(0x66E8D5A3)],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 5,
                    color: const Color(0xFFE8D5A3),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xEE000000),
                        border: Border.all(color: const Color(0xFFE8D5A3), width: 1.6),
                        boxShadow: const [
                          BoxShadow(color: Color(0x88E8D5A3), blurRadius: 10),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 16, color: Color(0xFFE8D5A3)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
