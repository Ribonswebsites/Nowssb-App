/// Undo sits before upload, style and reset. Zoom is a pinch on the section,
/// not a plus/minus button.
library;

import 'package:flutter/material.dart';

class MediaTuneBar extends StatelessWidget {
  const MediaTuneBar({
    super.key,
    required this.canUndo,
    required this.onUndo,
  });

  final bool canUndo;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
        ),
        onPressed: canUndo ? onUndo : null,
        icon: const Icon(Icons.undo_rounded, size: 16),
        label: const Text('Undo'),
      ),
    );
  }
}
