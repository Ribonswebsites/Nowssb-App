/// Download / Downloaded control for a word or a session recording.
/// Renders nothing when the item has no real recording.
library;

import 'package:flutter/material.dart';

import '../../data/secure_downloads.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.id,
    required this.title,
    required this.kind,
    required this.url,
    this.color = Colors.white,
    this.compact = false,
  });

  final String id;
  final String title;
  final String kind;
  final String url;
  final Color color;

  /// Icon only (lists). Otherwise icon + label.
  final bool compact;

  Future<void> _tap(BuildContext context) async {
    final dl = SecureDownloads.instance;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (dl.isDownloaded(id)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Remove download?'),
          content: Text('"$title" will need the internet again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
          ],
        ),
      );
      if (ok == true) await dl.remove(id);
      return;
    }
    final ok = await dl.download(id: id, title: title, kind: kind, url: url);
    messenger?.showSnackBar(SnackBar(content: Text(ok ? 'Downloaded for offline use' : 'Download failed. Try again.')));
  }

  @override
  Widget build(BuildContext context) {
    if (!SecureDownloads.canDownload(url)) return const SizedBox.shrink();
    final dl = SecureDownloads.instance;
    dl.load();
    return ListenableBuilder(
      listenable: dl,
      builder: (context, _) {
        final p = dl.progressOf(id);
        final done = dl.isDownloaded(id);
        final label = p != null ? 'Downloading' : (done ? 'Downloaded' : 'Download');
        final icon = p != null
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, value: p == 0 ? null : p, color: color),
              )
            : Icon(done ? Icons.download_done_rounded : Icons.download_rounded, size: 20, color: color);
        return Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('download-$id'),
            borderRadius: BorderRadius.circular(99),
            onTap: p != null ? null : () => _tap(context),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
              child: compact
                  ? icon
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      icon,
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ]),
            ),
          ),
        );
      },
    );
  }
}
