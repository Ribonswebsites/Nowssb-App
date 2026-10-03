/// Undo, zoom out, zoom in — always the first controls on a picture or clip.
library;

import 'package:flutter/material.dart';

class MediaTuneBar extends StatelessWidget {
  const MediaTuneBar({
    super.key,
    required this.zoom,
    required this.canUndo,
    required this.onUndo,
    required this.onZoomOut,
    required this.onZoomIn,
  });

  final double zoom;
  final bool canUndo;
  final VoidCallback? onUndo;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: canUndo ? onUndo : null,
          icon: const Icon(Icons.undo_rounded, size: 16),
          label: const Text('Undo'),
        ),
        const SizedBox(width: 8),
        _round(Icons.zoom_out_rounded, onZoomOut),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${zoom.toStringAsFixed(1)}×',
            style: const TextStyle(color: Color(0xFFE8D5A3), fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
        _round(Icons.zoom_in_rounded, onZoomIn),
      ],
    );
  }

  Widget _round(IconData icon, VoidCallback? onTap) {
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: const Color(0xFFE8D5A3)),
    );
  }
}
