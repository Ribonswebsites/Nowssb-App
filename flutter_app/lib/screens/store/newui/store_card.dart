/// Store product card matching /workspace/specs/card-reference-exact.png:
/// frosted translucent glass, soft white border, large radius, heart top
/// row, round photo near the top, inner frosted panel with bold white
/// title, small grey body, "Skip" bottom-left and a white "Next" pill.
/// Built on nowssb_ui NGlass (no exact kit card exists on main yet).
library;

import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart';

class StoreRefCard extends StatelessWidget {
  const StoreRefCard({
    super.key,
    required this.title,
    required this.body,
    required this.price,
    required this.image,
    this.onOpen,
    this.onNext,
    this.onSkip,
    this.isLast = false,
  });

  final String title, body, price;
  final ImageProvider image;
  final VoidCallback? onOpen, onNext, onSkip;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title, $price',
        child: NGlass(
          radius: 34,
          blur: 14,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          onTap: onOpen,
          child: Column(children: [
            const Row(children: [
              Spacer(),
              Icon(Icons.favorite_rounded, size: 16, color: Colors.white),
            ]),
            const SizedBox(height: 6),
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: image, fit: BoxFit.cover),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: NGlass(
                radius: 22,
                blur: 0,
                elevation: 0,
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('$body · $price',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5, height: 1.35)),
                  const Spacer(),
                  Row(children: [
                    Semantics(
                      button: true,
                      label: 'Skip',
                      child: GestureDetector(
                        onTap: onSkip,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Skip', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: isLast ? 'Open' : 'Next',
                      child: GestureDetector(
                        onTap: isLast ? onOpen : onNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8, offset: Offset(0, 3))],
                          ),
                          child: Text(isLast ? 'Open' : 'Next',
                              style: const TextStyle(color: Color(0xFF1B1B2F), fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class StorePageDots extends StatelessWidget {
  const StorePageDots({super.key, required this.count, required this.index});
  final int count, index;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Card ${index + 1} of $count',
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i == index ? .95 : .4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ]),
      );
}
