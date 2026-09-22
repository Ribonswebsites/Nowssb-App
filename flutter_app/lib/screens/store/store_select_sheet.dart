/// “Please select the store” bottom sheet — glassmorphism only.
/// Active store uses a subtle glass highlight + check pill (not a thinking orb).
/// Top film: assets/video/choose-store.mp4 (#1) — Choose Store page only.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import 'store_cards.dart';

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

const kStoreSelectEntries = <StoreSelectEntry>[
  StoreSelectEntry(
    id: 'word',
    title: 'Word Atelier',
    art: 'assets/store/picker-words.png',
  ),
  StoreSelectEntry(
    id: 'meaning',
    title: 'Meaning',
    art: kMsMeaningStoreIcon,
  ),
  StoreSelectEntry(
    id: 'signature',
    title: 'Signature',
    art: 'assets/store/picker-signature.png',
  ),
  StoreSelectEntry(
    id: 'ebooks',
    title: 'Ebooks',
    art: kEbProductArt,
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
    barrierColor: const Color(0x99000000),
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
          filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0x33FFFFFF),
              border: Border.all(color: const Color(0x44FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
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
                      color: const Color(0x55FFFFFF),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              entry.art,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF1A1A1E),
                child: Center(
                  child: Icon(Icons.storefront_outlined,
                      color: Color(0x66FFFFFF)),
                ),
              ),
            ),
            // Soft glass highlight when this is the active store page.
            if (active) ...[
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x33FFFFFF),
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 3),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0x88FFFFFF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
