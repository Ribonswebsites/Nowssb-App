/// Player-sheet Sound Library — same feed as the website SLM screen.
///
/// Kept as a named entry so practice_player imports stay stable; the body is
/// [SoundLibraryScreen] in embedded mode (no intro gate), with the
/// [SoundLibraryVariant.titleBand] banner so it differs from #14 (BD-1).
library;

import 'package:flutter/material.dart';

import 'sound_library.dart';

class AuraSoundLibraryScreen extends StatelessWidget {
  const AuraSoundLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SoundLibraryScreen(
      embedded: true,
      variant: SoundLibraryVariant.titleBand,
    );
  }
}
