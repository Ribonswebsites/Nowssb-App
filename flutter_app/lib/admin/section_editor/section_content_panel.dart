/// CS-6 content controls: start index, card count, reorder, add/remove media
/// (R2 upload via [uploadToR2]).
library;

import 'package:flutter/material.dart';

import '../../widgets/sections/section_config.dart';
import '../editor/glass.dart';
import '../media_upload.dart';

class SectionContentPanel extends StatelessWidget {
  const SectionContentPanel({
    super.key,
    required this.config,
    required this.onChanged,
    this.busy = false,
  });

  final SectionConfig config;
  final ValueChanged<SectionConfig> onChanged;
  final bool busy;

  SectionBehavior get _b => config.behavior;
  List<SectionMediaItem> get _items => config.items;

  void _setBehavior(SectionBehavior b) => onChanged(config.copyWith(behavior: b));

  void _setItems(List<SectionMediaItem> items) =>
      onChanged(config.copyWith(items: items));

  Future<void> _addMedia(BuildContext context, PickKind kind) async {
    if (busy) return;
    final file = await pickMedia(context, kind);
    if (file == null) return;
    try {
      final up = await uploadToR2(
        file,
        'ui',
        'section/${config.id}/${DateTime.now().millisecondsSinceEpoch}',
        kind,
      );
      final id = 'm${DateTime.now().millisecondsSinceEpoch}';
      final item = kind == PickKind.video
          ? SectionMediaItem(id: id, videoUrl: up.url, title: 'Video')
          : SectionMediaItem(id: id, imageUrl: up.url, title: 'Image');
      _setItems([..._items, item]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _items.length;
    final start = _b.startIndex.clamp(0, n == 0 ? 0 : n - 1);
    return Glass(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Content',
            style: TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _stepper(
            label: 'Start index',
            value: start,
            min: 0,
            max: n == 0 ? 0 : n - 1,
            onChanged: (v) => _setBehavior(_b.copyWith(startIndex: v)),
          ),
          _stepper(
            label: 'Card count',
            value: _b.itemCount ?? n,
            min: 0,
            max: 40,
            onChanged: (v) => _setBehavior(
              _b.copyWith(
                itemCount: v <= 0 ? null : v,
                clearItemCount: v <= 0,
              ),
            ),
            hint: _b.itemCount == null ? 'all' : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Loop', style: TextStyle(color: Colors.white, fontSize: 14)),
            activeTrackColor: kGold,
            value: _b.loop,
            onChanged: busy ? null : (v) => _setBehavior(_b.copyWith(loop: v)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Autoplay', style: TextStyle(color: Colors.white, fontSize: 14)),
            activeTrackColor: kGold,
            value: _b.autoplay,
            onChanged: busy ? null : (v) => _setBehavior(_b.copyWith(autoplay: v)),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _addMedia(context, PickKind.image),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Add image'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _addMedia(context, PickKind.video),
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('Add video'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            const Text('No cards yet — add an image or video.', style: TextStyle(color: kDim, fontSize: 12))
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _items.length,
              onReorderItem: (oldIndex, newIndex) {
                if (busy) return;
                final next = [..._items];
                final item = next.removeAt(oldIndex);
                next.insert(newIndex, item);
                _setItems(next);
              },
              itemBuilder: (context, i) {
                final item = _items[i];
                final media = item.imageUrl ?? item.videoUrl ?? '';
                return ListTile(
                  key: ValueKey(item.id),
                  contentPadding: EdgeInsets.zero,
                  leading: ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_handle_rounded, color: kDim),
                  ),
                  title: Text(
                    item.title ?? item.id,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    media.isEmpty ? 'No media URL' : media,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kDim, fontSize: 10),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    onPressed: busy
                        ? null
                        : () {
                            final next = [..._items]..removeAt(i);
                            _setItems(next);
                          },
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE07070)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        IconButton(
          onPressed: busy || value <= min ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline, color: kGold),
        ),
        Text(
          hint ?? '$value',
          style: const TextStyle(color: kGold, fontWeight: FontWeight.w800),
        ),
        IconButton(
          onPressed: busy || value >= max ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline, color: kGold),
        ),
      ]),
    );
  }
}
