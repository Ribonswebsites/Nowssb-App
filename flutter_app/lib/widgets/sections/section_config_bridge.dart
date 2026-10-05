/// Shared adapter: read [SectionConfigs] by LSection id (via [SectionScope])
/// and apply layout + animation around an existing section widget.
///
/// When there is no override, [child] is returned unchanged — defaults stay
/// pixel-identical. Widgets that already resolve their own [SectionConfig]
/// should keep doing so for media / focal / start / count; use this bridge
/// for older TemplateSection / bare rails that only need outer layout+anim,
/// or pass [onLive] to rebuild from the live config.
library;

import 'package:flutter/widgets.dart';

import 'section_anim_layer.dart';
import 'section_config.dart';
import 'section_configs.dart';

typedef SectionConfigLiveBuilder = Widget Function(
  BuildContext context,
  SectionConfig live,
);

class SectionConfigBridge extends StatelessWidget {
  const SectionConfigBridge({
    super.key,
    required this.child,
    this.fallback,
    this.onLive,
    this.applyLayout = true,
  });

  /// Default body — used when no override exists (or as the wrapped child
  /// when [onLive] is null).
  final Widget child;

  /// Optional bundled [SectionConfig] for id / slot resolve.
  final SectionConfig? fallback;

  /// When an override exists, rebuild the body from it (media, focal, …).
  /// Outer animation (and optional layout) still wrap the result.
  final SectionConfigLiveBuilder? onLive;

  /// When true (default), apply [SectionLayout] around the body. Set false
  /// when the body already consumes height / radius / spacing itself.
  final bool applyLayout;

  @override
  Widget build(BuildContext context) {
    SectionConfigs.watch(context);
    final live = SectionConfigs.instance.resolveOptional(context, fallback);
    if (live == null) return child;
    if (!live.enabled) return const SizedBox.shrink();
    final body = onLive != null ? onLive!(context, live) : child;
    final wrapped = applyLayout ? applySectionLayout(live.layout, body) : body;
    return SectionAnimLayer(animation: live.animation, child: wrapped);
  }
}
