/// Admin thinking-orb picker: every [OrbState] plus the Lottie gallery
/// (assets/anim/thinking + loaders) playing live in a grid.
/// Tap one for a full-size preview; Set saves server-side via
/// `/api/admin/orb-set` (kind/asset for Lottie, orb name for package orbs).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:lottie/lottie.dart';

import 'editor/glass.dart';
import 'orb_config.dart';
import 'template/slot_keys.dart';
import 'template/ui_overrides.dart';

/// Human labels for every OrbState in flutter_thinking_orbs (enumerate
/// [OrbState.values] — never a hand-picked subset).
String orbLabel(OrbState s) {
  switch (s) {
    case OrbState.working:
      return 'Working';
    case OrbState.searching:
      return 'Searching';
    case OrbState.solving:
      return 'Solving';
    case OrbState.listening:
      return 'Listening';
    case OrbState.composing:
      return 'Composing';
    case OrbState.shaping:
      return 'Shaping';
  }
}

/// One entry from assets/anim/orb_gallery.json.
class OrbGalleryItem {
  const OrbGalleryItem({
    required this.id,
    required this.kind,
    required this.asset,
    required this.label,
    required this.group,
  });

  final String id;
  final String kind;
  final String asset;
  final String label;
  final String group;

  factory OrbGalleryItem.from(Map<String, dynamic> m) => OrbGalleryItem(
        id: '${m['id'] ?? ''}',
        kind: '${m['kind'] ?? 'lottie'}',
        asset: '${m['asset'] ?? ''}',
        label: '${m['label'] ?? m['id'] ?? ''}',
        group: '${m['group'] ?? ''}',
      );
}

Future<List<OrbGalleryItem>> loadOrbGallery() async {
  try {
    final raw = await rootBundle.loadString('assets/anim/orb_gallery.json');
    final map = jsonDecode(raw);
    if (map is! Map) return const [];
    final items = map['items'];
    if (items is! List) return const [];
    return [
      for (final e in items)
        if (e is Map) OrbGalleryItem.from(Map<String, dynamic>.from(e)),
    ];
  } catch (_) {
    return const [];
  }
}

Future<void> openOrbPicker(
  BuildContext context, {
  required String slot,
}) {
  return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => OrbPickerScreen(slot: slot),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

enum _PreviewKind { orb, lottie }

class _Preview {
  const _Preview.orb(this.state)
      : kind = _PreviewKind.orb,
        item = null;
  const _Preview.lottie(this.item)
      : kind = _PreviewKind.lottie,
        state = null;

  final _PreviewKind kind;
  final OrbState? state;
  final OrbGalleryItem? item;

  String get title =>
      kind == _PreviewKind.orb ? orbLabel(state!) : _titleCase(item!.label);
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s.split(RegExp(r'[\s_]+')).map((w) {
    if (w.isEmpty) return w;
    return '${w[0].toUpperCase()}${w.substring(1)}';
  }).join(' ');
}

class OrbPickerScreen extends StatefulWidget {
  const OrbPickerScreen({super.key, required this.slot});
  final String slot;

  @override
  State<OrbPickerScreen> createState() => _OrbPickerScreenState();
}

class _OrbPickerScreenState extends State<OrbPickerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  _Preview? _preview;
  bool _busy = false;
  String? _msg;
  List<OrbGalleryItem> _gallery = const [];
  bool _galleryLoaded = false;

  String get _slot => widget.slot.isEmpty ? 'orb.all' : widget.slot;

  Map<String, dynamic>? get _style {
    final local = UiOverrides.instance.get(_slot)?.style;
    if (local != null) return local;
    if (_slot != 'orb.all') return UiOverrides.instance.get('orb.all')?.style;
    return null;
  }

  String get _currentOrb {
    final v = _style?['orb'];
    return v is String && v.isNotEmpty && v != 'random' ? v : '';
  }

  String get _currentAsset {
    final v = _style?['asset'];
    return v is String ? v : '';
  }

  String get _currentKind {
    final v = _style?['kind'];
    if (v is String && v.isNotEmpty) return v;
    if (_currentAsset.isNotEmpty) return 'lottie';
    if (_currentOrb.isNotEmpty) return 'orb';
    return '';
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final items = await loadOrbGallery();
    if (!mounted) return;
    setState(() {
      _gallery = items;
      _galleryLoaded = true;
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _applyChoice(OrbSlotChoice r, {required String msg}) async {
    if (r.orb == null && (r.asset == null || r.asset!.isEmpty) &&
        (r.kind == null || r.kind == 'orb')) {
      UiOverrides.instance.removeLocal(_slot);
    } else {
      UiOverrides.instance.applyLocal(UiOverride(
        slot: _slot,
        type: SlotType.orb,
        url: '',
        text: '',
        textSet: false,
        style: r.toStyle(),
      ));
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _msg = msg;
      _preview = null;
    });
  }

  Future<void> _setOrb(OrbState state) async {
    setState(() {
      _busy = true;
      _msg = 'Saving…';
    });
    try {
      final r = await OrbConfig.set(
        slot: _slot,
        kind: 'orb',
        orb: state.name,
        note: 'orb.picker',
      );
      await _applyChoice(r, msg: 'Set for all users — ${orbLabel(state)}.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Could not save: $e';
      });
    }
  }

  Future<void> _setLottie(OrbGalleryItem item) async {
    setState(() {
      _busy = true;
      _msg = 'Saving…';
    });
    try {
      final r = await OrbConfig.set(
        slot: _slot,
        kind: item.kind,
        asset: item.asset,
        note: 'orb.picker.lottie',
      );
      await _applyChoice(r, msg: 'Set for all users — ${_titleCase(item.label)}.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Could not save: $e';
      });
    }
  }

  Future<void> _undo() async {
    setState(() {
      _busy = true;
      _msg = 'Undoing…';
    });
    try {
      final r = await OrbConfig.undo(slot: _slot);
      final empty = (r.orb == null || r.orb!.isEmpty) &&
          (r.asset == null || r.asset!.isEmpty);
      if (empty) {
        UiOverrides.instance.removeLocal(_slot);
      } else {
        UiOverrides.instance.applyLocal(UiOverride(
          slot: _slot,
          type: SlotType.orb,
          url: '',
          text: '',
          textSet: false,
          style: r.toStyle(),
        ));
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = empty
            ? 'Cleared — random until set again.'
            : 'Restored ${r.token ?? r.orb ?? r.asset}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Nothing to undo (or server said: $e)';
      });
    }
  }

  Future<void> _reset() async {
    setState(() {
      _busy = true;
      _msg = 'Resetting…';
    });
    try {
      await OrbConfig.set(slot: _slot, orb: 'random', note: 'orb.reset');
      UiOverrides.instance.removeLocal(_slot);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Reset — random while unset.';
        _preview = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Could not reset: $e';
      });
    }
  }

  List<OrbGalleryItem> _group(String g) =>
      _gallery.where((e) => e.group == g).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final preview = _preview;
    return Scaffold(
      backgroundColor: const Color(0xF2060C18),
      body: Padding(
        padding: EdgeInsets.only(top: top),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(
                    'THINKING ORB',
                    style: TextStyle(
                      color: kGold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    preview == null ? 'Pick an animation' : preview.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(_slot, style: const TextStyle(color: kDim, fontSize: 11)),
                ]),
              ),
              IconButton(
                onPressed: _busy ? null : _undo,
                tooltip: 'Undo last change',
                icon: const Icon(Icons.undo_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: _busy ? null : _reset,
                tooltip: 'Reset to random',
                icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ]),
          ),
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _msg!,
                style: TextStyle(
                  color: _busy ? kGold : const Color(0xFF81C784),
                  fontSize: 12,
                ),
              ),
            ),
          if (preview != null)
            Expanded(child: _buildPreview(preview))
          else ...[
            TabBar(
              controller: _tabs,
              labelColor: kGold,
              unselectedLabelColor: kDim,
              indicatorColor: kGold,
              tabs: const [
                Tab(text: 'Orbs'),
                Tab(text: 'Thinking'),
                Tab(text: 'Loaders'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _orbGrid(),
                  _lottieGrid(_group('thinking')),
                  _lottieGrid(_group('loaders')),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildPreview(_Preview preview) {
    return Column(children: [
      Expanded(
        child: Center(
          child: Container(
            width: 220,
            height: 220,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            child: preview.kind == _PreviewKind.orb
                ? ThinkingOrb(state: preview.state!, size: 180, theme: OrbTheme.dark)
                : Lottie.asset(
                    preview.item!.asset,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => setState(() => _preview = null),
              child: const Text('Back to grid'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _busy
                  ? null
                  : () {
                      if (preview.kind == _PreviewKind.orb) {
                        _setOrb(preview.state!);
                      } else {
                        _setLottie(preview.item!);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: const Color(0xFF060C18),
              ),
              child: const Text('Set'),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _orbGrid() {
    final cur = _currentOrb;
    final isOrb = _currentKind == 'orb' || _currentKind.isEmpty;
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final s in OrbState.values)
          _OrbTile(
            state: s,
            selected: isOrb && cur == s.name,
            onTap: () => setState(() => _preview = _Preview.orb(s)),
          ),
      ],
    );
  }

  Widget _lottieGrid(List<OrbGalleryItem> items) {
    if (!_galleryLoaded) {
      return const Center(child: CircularProgressIndicator(color: kGold));
    }
    if (items.isEmpty) {
      return const Center(
        child: Text('No Lottie assets bundled.', style: TextStyle(color: kDim)),
      );
    }
    final curAsset = _currentAsset;
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final item in items)
          _LottieTile(
            item: item,
            selected: curAsset == item.asset,
            onTap: () => setState(() => _preview = _Preview.lottie(item)),
          ),
      ],
    );
  }
}

class _OrbTile extends StatelessWidget {
  const _OrbTile({required this.state, required this.selected, required this.onTap});
  final OrbState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(10),
      glow: selected ? kGold.withValues(alpha: 0.35) : null,
      onTap: onTap,
      child: Column(children: [
        Expanded(
          child: Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: ThinkingOrb(state: state, size: 76, theme: OrbTheme.dark),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          orbLabel(state),
          style: TextStyle(
            color: selected ? kGold : Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        if (selected)
          const Text('Current', style: TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _LottieTile extends StatelessWidget {
  const _LottieTile({required this.item, required this.selected, required this.onTap});
  final OrbGalleryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(10),
      glow: selected ? kGold.withValues(alpha: 0.35) : null,
      onTap: onTap,
      child: Column(children: [
        Expanded(
          child: Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: Lottie.asset(
                item.asset,
                width: 76,
                height: 76,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _titleCase(item.label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? kGold : Colors.white,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        if (selected)
          const Text('Current', style: TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
