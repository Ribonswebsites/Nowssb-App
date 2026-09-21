/// “Please select the store” bottom sheet — white tiles, no accent borders.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

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
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
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
                  color: const Color(0x22000000),
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
                color: Color(0xFF0A0A0B),
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: const Color(0x14000000)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                entry.art,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFF2F2F4),
                  child: Center(
                    child: Icon(Icons.storefront_outlined,
                        color: Color(0x66000000)),
                  ),
                ),
              ),
              if (active)
                const Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AppThinkingLoader(
                      size: 36,
                      state: OrbState.solving,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
