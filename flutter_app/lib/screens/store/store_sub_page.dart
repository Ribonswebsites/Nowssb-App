/// Words / Meanings page frame (Oct 21 style): shared app backdrop, Home's
/// HomeHeader.sub (back arrow + title), then a slim row with the subtitle,
/// the guide "?", the bag and an outlined "All stores" pill.
library;

import 'package:flutter/material.dart';

import '../../nowssb_ui/app_video_backdrop.dart';
import '../../theme/tokens.dart';
import 'dart:ui' as ui;
import 'bag_ui.dart';
import 'store_first_use_guide.dart';

/// Spec's outlined pill CTA.
class StoreOutlinePill extends StatelessWidget {
  const StoreOutlinePill({super.key, required this.label, this.icon, this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      );
}

class StoreSubPage extends StatelessWidget {
  const StoreSubPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onStorePicker,
    required this.slivers,
  });

  final String title;
  final String subtitle;
  final VoidCallback onStorePicker;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: NwsbColors.deep,
        body: NAppBackdrop(
          child: Column(children: [
            _SubHeader(title: title),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(children: [
                Expanded(
                  child: Text(subtitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: NwsbColors.gold, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                ),
                const StoreGuideButton(),
                const StoreBagBar(),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StoreOutlinePill(label: 'All stores', icon: Icons.storefront_outlined, onTap: onStorePicker),
              ),
            ),
            Expanded(child: CustomScrollView(slivers: slivers)),
          ]),
        ),
      );
}

/// Oct 21 HomeHeader.sub look: white glass bar, back arrow + title.
class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 14, 20, 14),
            decoration: const BoxDecoration(
              color: Color(0x14FFFFFF),
              border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: Row(children: [
              Semantics(
                button: true,
                label: 'Back',
                child: GestureDetector(
                  key: const Key('home-header-back'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.maybePop(context),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                      shadows: [Shadow(color: Color(0x80000000), blurRadius: 8, offset: Offset(0, 1))],
                    )),
              ),
            ]),
          ),
        ),
      );
}
