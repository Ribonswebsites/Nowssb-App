/// Store look: gold pills and chips, Luxe-style category tabs and
/// "Spotlight Picks" banner cards. Store layout is unchanged; these sit in
/// the existing header section under Home's HomeHeader.
library;

import 'package:flutter/material.dart';

const kStoreGold = Color(0xFFE9C46A);
const kStoreGoldDeep = Color(0xFFB8862B);
const kStoreGoldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF3E4B7), Color(0xFFC8A96E)],
);

/// Solid gold pill, e.g. "Shop Now".
class StoreGoldPill extends StatelessWidget {
  const StoreGoldPill({super.key, required this.label, this.onTap, this.small = false});
  final String label;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16, vertical: small ? 6 : 8),
              decoration: BoxDecoration(
                gradient: kStoreGoldGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(color: Color(0x55B8862B), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Text(label,
                  style: TextStyle(
                      color: const Color(0xFF2A1C05),
                      fontSize: small ? 11 : 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3)),
            ),
          ),
        ),
      );
}

/// Outlined gold chip; gold-filled when selected.
class StoreGoldChip extends StatelessWidget {
  const StoreGoldChip({super.key, required this.label, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: selected ? kStoreGoldGradient : null,
                color: selected ? null : const Color(0x33000000),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? Colors.transparent : const Color(0xAAE9C46A)),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: selected ? const Color(0xFF2A1C05) : kStoreGold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );
}

class StoreCategory {
  const StoreCategory(this.label, this.onTap);
  final String label;
  final VoidCallback? onTap;
}

/// Luxe-style top category tabs. "All" is the Store home; others open
/// their department.
class StoreCategoryTabs extends StatelessWidget {
  const StoreCategoryTabs({super.key, required this.categories});
  final List<StoreCategory> categories;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: ListView.separated(
          key: const Key('storeCategoryTabs'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => StoreGoldChip(
            label: categories[i].label,
            selected: i == 0,
            onTap: categories[i].onTap,
          ),
        ),
      );
}

class SpotlightPick {
  const SpotlightPick({required this.title, required this.sub, required this.image, required this.onTap});
  final String title;
  final String sub;
  final String image;
  final VoidCallback onTap;
}

/// "Spotlight Picks" banner cards with a gold Shop Now pill.
class StoreSpotlightPicks extends StatelessWidget {
  const StoreSpotlightPicks({super.key, required this.picks});
  final List<SpotlightPick> picks;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Semantics(
              header: true,
              label: 'Spotlight Picks',
              child: ExcludeSemantics(
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF0B0B0D)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: const Text('Spotlight Picks',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              key: const Key('storeSpotlight'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: picks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _SpotlightCard(pick: picks[i]),
            ),
          ),
        ],
      );
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.pick});
  final SpotlightPick pick;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${pick.title}. ${pick.sub}. Shop now',
        child: GestureDetector(
          onTap: pick.onTap,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B0D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(pick.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0x33000000))),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xCC000000), Color(0x22000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SPOTLIGHT',
                          style: TextStyle(color: kStoreGold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(pick.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 170,
                        child: Text(pick.sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, height: 1.3)),
                      ),
                      const Spacer(),
                      StoreGoldPill(label: 'Shop Now', small: true, onTap: pick.onTap),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Home's white round-arrow "Enter →" pill.
class StoreEnterPill extends StatelessWidget {
  const StoreEnterPill({super.key, this.label = 'Enter', this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    style: const TextStyle(color: Color(0xFF0B0B0D), fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0B0B0D)),
                  child: const Icon(Icons.arrow_forward, size: 13, color: Colors.white),
                ),
              ]),
            ),
          ),
        ),
      );
}
