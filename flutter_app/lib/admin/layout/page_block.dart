/// Pages built as one block (a lazy list, a staged flow) still take what
/// the UI Editor drops: the block is one section, "page", so orbs and
/// effects land on it, and sections added from the Sections tab sit above
/// or below it. Nothing saved: the page exactly as built.
library;

import 'package:flutter/material.dart';

import 'layout_sections.dart';
import 'section_pinch.dart';
import 'ui_layouts.dart';

class PageBlock extends StatelessWidget {
  const PageBlock({super.key, required this.pageId, required this.child, this.title = 'The page'});

  /// The block's section id.
  static const id = 'page';

  final String pageId;
  final String title;

  /// Fills the space it is given (a list, a Column with Expanded parts).
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: UiLayouts.instance,
        builder: (context, _) {
          final out = layoutChildren(context, pageId, [LSection(id, title, child, copyable: false)]);
          if (out.length == 1 && out.single is LSection) return child;
          final at = out.indexWhere(_isBlock);
          if (at < 0) {
            // The block itself was hidden: just the added sections.
            return ListView(padding: EdgeInsets.zero, children: out);
          }
          if (out.length == 1) return out.single;
          // Added sections keep their own height (scrolling if many);
          // the block takes the rest, as it always did.
          final most = MediaQuery.sizeOf(context).height * 0.45;
          Widget group(List<Widget> ws) => ws.isEmpty
              ? const SizedBox.shrink()
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: most),
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: ws),
                  ),
                );
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            group(out.sublist(0, at)),
            Expanded(child: out[at]),
            group(out.sublist(at + 1)),
          ]);
        },
      );
}

bool _isBlock(Widget w) => (w is SectionPinch && w.sectionId == PageBlock.id) || (w is LSection && w.id == PageBlock.id);
