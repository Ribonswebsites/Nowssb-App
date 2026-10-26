/// The normal home's Fashion Plus entry, wired to live data: the card's
/// still is dimmed by the user's saved [FashionBgDim] (updates live) and
/// tapping switches to the Fashion Plus home, as the old switch row did.
library;

import 'package:flutter/material.dart';

import '../../../data/fashion_bg_dim.dart';
import '../../../data/settings.dart';
import 'fashion_plus_entry.dart';

class NFashionPlusEntryLive extends StatelessWidget {
  const NFashionPlusEntryLive({super.key, this.onEnter});

  /// Override for tests; defaults to opening the Fashion Plus home.
  final VoidCallback? onEnter;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: FashionBgDim.instance,
        builder: (_, dim, __) => NFashionPlusEntry(
          bgDim: dim,
          onEnter: onEnter ?? () => Settings.instance.setFashionHome(true),
        ),
      );
}
