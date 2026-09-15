/// AJIO-style glass “Please select the store” bottom sheet — 4 tall category cards.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class StoreSelectEntry {
  const StoreSelectEntry({
    required this.id,
    required this.title,
    required this.sub,
    required this.art,
    required this.accent,
  });
  final String id;
  final String title;
  final String sub;
  final String art;
  final Color accent;
}

const kStoreSelectEntries = <StoreSelectEntry>[
  StoreSelectEntry(
    id: 'word',
    title: 'Word Atelier',
    sub: 'Vibrational word library',
    art: 'assets/store/intro-words.webp',
    accent: Color(0xFF5CE1FF),
  ),
  StoreSelectEntry(
    id: 'meaning',
    title: 'Meaning',
    sub: 'Decoded origins',
    art: 'assets/store/intro-meanings.webp',
    accent: Color(0xFFB388FF),
  ),
  StoreSelectEntry(
    id: 'ebooks',
    title: 'Ebooks',
    sub: 'Guides to keep forever',
    art: 'assets/store/intro-ebooks.webp',
    accent: Color(0xFFE8D5A3),
  ),
  StoreSelectEntry(
    id: 'signature',
    title: 'Signature',
    sub: 'One per collection',
    art: 'assets/store/intro-signature.webp',
    accent: Color(0xFFFF6BCB),
  ),
];

Future<void> showStoreSelectSheet(
  BuildContext context, {
  required ValueChanged<String> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: const Color(0x99000000),
    builder: (sheetCtx) => StoreSelectSheet(onSelect: onSelect),
  );
}

class StoreSelectSheet extends StatelessWidget {
  const StoreSelectSheet({super.key, required this.onSelect});
  final ValueChanged<String> onSelect;

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
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xD6080C18),
              border: Border.all(color: const Color(0x33FFFFFF)),
              boxShadow: const [
                BoxShadow(color: Color(0x88000000), blurRadius: 30, offset: Offset(0, 12)),
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
                      color: const Color(0x44FFFFFF),
                      borderRadius: BorderRadius.circular(99),
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
                const SizedBox(height: 4),
                const Text(
                  'Four doors. One NowssB atelier.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0x88FFFFFF)),
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
                            onExplore: () => _pick(context, kStoreSelectEntries[i].id),
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
  const _StoreSelectCard({required this.entry, required this.onExplore});
  final StoreSelectEntry entry;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: entry.accent.withValues(alpha: 0.45)),
            color: const Color(0x66101828),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.55,
                child: Image.asset(
                  entry.art,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: entry.accent.withValues(alpha: 0.2),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: entry.accent,
                        boxShadow: [
                          BoxShadow(
                            color: entry.accent.withValues(alpha: 0.55),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xAAFFFFFF),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onExplore,
                      child: Container(
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: entry.accent.withValues(alpha: 0.92),
                        ),
                        child: Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: entry.accent.computeLuminance() > 0.55
                                ? const Color(0xFF060C18)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
