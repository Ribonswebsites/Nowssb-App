/// Vertical scroll rail in the language of Your essentials: an 18px node
/// travelling a 3px connector. The node tracks [controller] from top to
/// bottom as the list scrolls.
library;

import 'package:flutter/material.dart';

class ScrollProgressRail extends StatefulWidget {
  const ScrollProgressRail({super.key, required this.controller});

  final ScrollController controller;

  @override
  State<ScrollProgressRail> createState() => _ScrollProgressRailState();
}

class _ScrollProgressRailState extends State<ScrollProgressRail> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_tick);
  }

  @override
  void didUpdateWidget(covariant ScrollProgressRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_tick);
    widget.controller.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tick);
    super.dispose();
  }

  double get _t {
    final c = widget.controller;
    if (!c.hasClients || !c.position.hasContentDimensions) return 0;
    final max = c.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (c.offset / max).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: LayoutBuilder(
        builder: (context, c) {
          const node = 18.0;
          const inset = 2.0;
          final travel =
              (c.maxHeight - node - inset * 2).clamp(0.0, c.maxHeight);
          final top = inset + travel * _t;
          return Stack(
            children: [
              const Positioned(
                left: 12.5,
                top: inset + node / 2,
                bottom: inset + node / 2,
                width: 3,
                child: ColoredBox(color: Color(0xFFC7CDD9)),
              ),
              Positioned(
                left: 12.5,
                width: 3,
                top: inset + node / 2,
                height: (top - inset).clamp(0.0, c.maxHeight),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFB794F6), Color(0xFF7E57C2)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: top,
                left: 5,
                child: Container(
                  width: node,
                  height: node,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB794F6), Color(0xFF7E57C2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x667E57C2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
