/// Library → Downloads. Encrypted offline copies on this phone only.
library;

import 'package:flutter/material.dart';

import '../../data/secure_downloads.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static String _size(int b) => b >= 1 << 20 ? '${(b / (1 << 20)).toStringAsFixed(1)} MB' : '${(b / 1024).ceil()} KB';

  @override
  Widget build(BuildContext context) {
    final dl = SecureDownloads.instance;
    dl.load();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('Downloads')),
      body: ListenableBuilder(
        listenable: dl,
        builder: (context, _) {
          final items = dl.items;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Nothing downloaded yet. Tap Download on a word or a session to keep it for offline use.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (_, i) {
              final it = items[i];
              return ListTile(
                key: ValueKey('dl-row-${it.id}'),
                leading: Icon(it.kind == 'word' ? Icons.record_voice_over_rounded : Icons.graphic_eq_rounded, color: Colors.white),
                title: Text(it.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${it.kind == 'word' ? 'Word' : 'Session'} · ${_size(it.bytes)} · encrypted',
                    style: const TextStyle(color: Colors.white54)),
                trailing: IconButton(
                  tooltip: 'Remove download',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                  onPressed: () => dl.remove(it.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Row that opens the Downloads list. With [onlyWhenAny] it stays hidden
/// until something has been downloaded (no empty placeholder row).
class DownloadsEntry extends StatelessWidget {
  const DownloadsEntry({super.key, this.onlyWhenAny = false});
  final bool onlyWhenAny;

  @override
  Widget build(BuildContext context) {
    final dl = SecureDownloads.instance;
    return ListenableBuilder(
      listenable: dl,
      builder: (context, _) {
        final n = dl.items.length;
        if (onlyWhenAny && n == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Material(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Flexible(
                      fit: FlexFit.tight,
                      child: Text('Downloads',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    Text('$n', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
                    const Icon(Icons.chevron_right_rounded, color: Color(0x99FFFFFF)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
