/// Every SVG in the app, as a searchable visual grid: the bundled files
/// (read from the AssetManifest, so a new file shows up by itself) plus the
/// SVGs uploaded to Cloudflare R2 under `ui/` (listed by the admin server)
/// and any SVG already used as a replacement. Returns `asset:<path>` for a
/// bundled file or the https URL for an uploaded one.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../admin_data.dart';
import '../admin_kit.dart';

class SvgChoice {
  const SvgChoice(this.value, this.label, this.group);
  final String value;
  final String label;
  final String group;
  bool get isAsset => value.startsWith('asset:');
}

Future<List<SvgChoice>> loadSvgLibrary() async {
  final out = <SvgChoice>[];
  try {
    final m = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final a in m.listAssets().where((a) => a.toLowerCase().endsWith('.svg'))) {
      final parts = a.split('/');
      out.add(SvgChoice('asset:$a', parts.last.replaceAll('.svg', ''), parts.length > 2 ? parts[1] : 'assets'));
    }
  } catch (_) {}
  try {
    final r = await AdminData.run('ui-assets', {'prefix': 'ui/', 'ext': 'svg'});
    for (final it in ((r['items'] as List?) ?? const []).cast<Map>()) {
      final url = '${it['url'] ?? ''}';
      if (url.isEmpty) continue;
      out.add(SvgChoice(url, '${it['key'] ?? url}'.split('/').last, 'uploaded'));
    }
    for (final u in ((r['overrides'] as List?) ?? const []).map((e) => '$e')) {
      if (u.toLowerCase().contains('.svg') && !out.any((c) => c.value == u)) out.add(SvgChoice(u, u.split('/').last, 'in use'));
    }
  } catch (_) {}
  return out;
}

Future<String?> pickSvg(BuildContext context, {String current = ''}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1120),
    builder: (_) => SizedBox(height: MediaQuery.of(context).size.height * 0.86, child: _SvgPicker(current: current)),
  );
}

class _SvgPicker extends StatefulWidget {
  const _SvgPicker({required this.current});
  final String current;
  @override
  State<_SvgPicker> createState() => _SvgPickerState();
}

class _SvgPickerState extends State<_SvgPicker> {
  List<SvgChoice>? _all;
  final _q = TextEditingController();
  String _group = '';
  bool _dark = true;

  @override
  void initState() {
    super.initState();
    loadSvgLibrary().then((l) {
      if (mounted) setState(() => _all = l);
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final groups = <String>{for (final c in all ?? const <SvgChoice>[]) c.group}.toList()..sort();
    final q = _q.text.trim().toLowerCase();
    final shown = (all ?? const <SvgChoice>[])
        .where((c) => (_group.isEmpty || c.group == _group) && (q.isEmpty || c.label.toLowerCase().contains(q) || c.value.toLowerCase().contains(q)))
        .toList();
    return Theme(
      data: adminTheme(),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SVG LIBRARY', style: TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                Text('Every SVG in the app', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
            ),
            IconButton(
              tooltip: _dark ? 'Light background' : 'Dark background',
              onPressed: () => setState(() => _dark = !_dark),
              icon: Icon(_dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: kGold),
            ),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: kDim)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded, color: kGold), hintText: all == null ? 'Loading…' : 'Search ${all.length} SVGs'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, children: [
            Padding(padding: const EdgeInsets.only(right: 6), child: Pill('All', dense: true, selected: _group.isEmpty, onTap: () => setState(() => _group = ''))),
            for (final g in groups) Padding(padding: const EdgeInsets.only(right: 6), child: Pill(g, dense: true, selected: _group == g, onTap: () => setState(() => _group = g))),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: all == null
              ? const OrbLoading(label: 'Collecting every SVG…', state: OrbState.searching)
              : shown.isEmpty
                  ? const EmptyNote('No SVG matches.')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 110, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final c = shown[i];
                        final sel = c.value == widget.current || (c.isAsset && widget.current == c.value.substring(6));
                        return GestureDetector(
                          onTap: () {
                            actFeel();
                            Navigator.pop(context, c.value);
                          },
                          child: Column(children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _dark ? const Color(0x18FFFFFF) : const Color(0xFFF4F1EA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: sel ? kGold : const Color(0x22FFFFFF), width: sel ? 2 : 1),
                                ),
                                child: c.isAsset
                                    ? SvgPicture.asset(c.value.substring(6), fit: BoxFit.contain, placeholderBuilder: (_) => const SizedBox())
                                    : SvgPicture.network(c.value, fit: BoxFit.contain, placeholderBuilder: (_) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kGold)))),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sel ? kGold : kDim, fontSize: 10)),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
