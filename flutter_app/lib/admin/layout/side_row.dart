/// A section made smaller can sit on the left, in the middle or on the
/// right of its row ('align' prop: 'left' / 'right'; else the middle), and
/// pictures, words, buttons and small templates can be put anywhere in the
/// room beside it — a free-form row ('beside' prop: a list of
/// [BesideItem]). Animations go there as placed orbs (placed_orbs.dart).
/// Drawn the same in the editor and in the published app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'scopes.dart';
import 'template_sections.dart';

/// −1 left, 0 middle, 1 right.
double sideAlignOf(Map<String, dynamic> props) => switch ('${props['align'] ?? ''}') {
      'left' => -1,
      'right' => 1,
      _ => 0,
    };

/// The 'align' prop for a place across the row (0 = left edge, 1 = right).
String? alignFor(double across) => across < 1 / 3 ? 'left' : (across > 2 / 3 ? 'right' : null);

enum BesideKind { image, text, button, template }

class BesideItem {
  const BesideItem({
    required this.id,
    required this.kind,
    this.value = '',
    this.x = 0.5,
    this.y = 0.5,
    this.width = 0,
  });

  final String id;
  final BesideKind kind;

  /// Picture url/asset, the words, the button's words, or a template kind.
  final String value;

  /// Its middle, as a fraction of the row's width and height.
  final double x, y;

  /// Its width (0: the kind's own).
  final double width;

  double get w => width > 0
      ? width
      : switch (kind) {
          BesideKind.image => 120,
          BesideKind.text => 150,
          BesideKind.button => 130,
          BesideKind.template => 150,
        };

  static String defaultValue(BesideKind k) => switch (k) {
        BesideKind.image => 'assets/banners/stories/aura.png',
        BesideKind.text => 'Your words',
        BesideKind.button => 'Tap here',
        BesideKind.template => 'textBlock',
      };

  static String label(BesideKind k) => switch (k) {
        BesideKind.image => 'Picture',
        BesideKind.text => 'Words',
        BesideKind.button => 'Button',
        BesideKind.template => 'Template',
      };

  BesideItem copyWith({double? x, double? y, String? value, double? width}) => BesideItem(
        id: id,
        kind: kind,
        value: value ?? this.value,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'value': value,
        'x': double.parse(x.toStringAsFixed(4)),
        'y': double.parse(y.toStringAsFixed(4)),
        if (width > 0) 'w': width,
      };

  static BesideItem? from(dynamic m) {
    if (m is! Map) return null;
    final kind = BesideKind.values.where((k) => k.name == '${m['kind']}').firstOrNull;
    final id = '${m['id'] ?? ''}';
    if (kind == null || id.isEmpty) return null;
    double n(String k, double d) => m[k] is num ? (m[k] as num).toDouble() : d;
    return BesideItem(
      id: id,
      kind: kind,
      value: '${m['value'] ?? ''}',
      x: n('x', 0.5).clamp(0.0, 1.0),
      y: n('y', 0.5).clamp(0.0, 1.0),
      width: n('w', 0).clamp(0.0, 600.0),
    );
  }
}

List<BesideItem> besideOf(Map<String, dynamic> props) {
  final v = props['beside'];
  if (v is! List) return const [];
  return [for (final m in v) BesideItem.from(m)].whereType<BesideItem>().toList();
}

Map<String, dynamic> besidePatch(List<BesideItem> items) =>
    {'beside': items.isEmpty ? null : [for (final i in items) i.toJson()]};

/// The section with the things put beside it.
class BesideCanvas extends StatelessWidget {
  const BesideCanvas({super.key, required this.pageId, required this.sectionId, required this.items, required this.child});
  final String pageId;
  final String sectionId;
  final List<BesideItem> items;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return child;
    final preview = EditorPreviewScope.peek(context);
    return Stack(clipBehavior: Clip.none, children: [
      child,
      for (final i in items)
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _At(i),
            child: _Report(
              onBox: preview == null ? null : (b) => preview.besideBoxes['$pageId/$sectionId/${i.id}'] = b,
              child: BesideView(key: ValueKey('beside-${i.id}'), item: i),
            ),
          ),
        ),
    ]);
  }
}

class _At extends SingleChildLayoutDelegate {
  _At(this.i);
  final BesideItem i;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) => BoxConstraints(maxWidth: i.w, minWidth: i.w);

  @override
  Offset getPositionForChild(Size size, Size child) =>
      Offset(i.x * size.width - child.width / 2, i.y * size.height - child.height / 2);

  @override
  bool shouldRelayout(_At old) =>
      old.i.x != i.x || old.i.y != i.y || old.i.w != i.w || old.i.kind != i.kind || old.i.value != i.value;
}

class _Report extends SingleChildRenderObjectWidget {
  const _Report({required this.onBox, required super.child});
  final void Function(RenderBox)? onBox;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderReport(onBox);

  @override
  void updateRenderObject(BuildContext context, _RenderReport renderObject) => renderObject.onBox = onBox;
}

class _RenderReport extends RenderProxyBox {
  _RenderReport(this.onBox);
  void Function(RenderBox)? onBox;

  @override
  void performLayout() {
    super.performLayout();
    onBox?.call(this);
  }
}

/// The page's text colour when it is solid, else a near-black.
Color _ink(Color? c) => c != null && c.a > 0.9 ? c : const Color(0xFF1A1A1A);

/// One thing beside a section, as the app draws it.
class BesideView extends StatelessWidget {
  const BesideView({super.key, required this.item});
  final BesideItem item;

  @override
  Widget build(BuildContext context) {
    final v = item.value.isEmpty ? BesideItem.defaultValue(item.kind) : item.value;
    return switch (item.kind) {
      BesideKind.image => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(aspectRatio: 3 / 4, child: NetPicture(url: v)),
        ),
      BesideKind.text => Text(
          v,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink(DefaultTextStyle.of(context).style.color),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      BesideKind.button => Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: const Color(0xFFE8D5A3), borderRadius: BorderRadius.circular(99)),
          child: Text(v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF111111), fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      BesideKind.template => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: TemplateThumb(kind: v),
        ),
    };
  }
}
