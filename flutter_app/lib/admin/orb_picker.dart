/// Admin thinking-orb picker: every [OrbState] playing live in a grid.
/// Tap one for a full-size preview; Set saves server-side via
/// `/api/admin/orb-set` (and locally into ui_overrides). Undo / Reset
/// call orb-undo / clear. Lottie gallery assets land in a later chunk.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

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

class OrbPickerScreen extends StatefulWidget {
  const OrbPickerScreen({super.key, required this.slot});
  final String slot;

  @override
  State<OrbPickerScreen> createState() => _OrbPickerScreenState();
}

class _OrbPickerScreenState extends State<OrbPickerScreen> {
  OrbState? _preview;
  bool _busy = false;
  String? _msg;

  String get _slot => widget.slot.isEmpty ? 'orb.all' : widget.slot;

  String get _currentName {
    final style = UiOverrides.instance.get(_slot)?.style;
    final v = style == null ? null : style['orb'];
    if (v is String && v.isNotEmpty && v != 'random') return v;
    if (_slot != 'orb.all') {
      final all = UiOverrides.instance.get('orb.all')?.style;
      final a = all == null ? null : all['orb'];
      if (a is String && a.isNotEmpty && a != 'random') return a;
    }
    return '';
  }

  Future<void> _set(OrbState state) async {
    setState(() {
      _busy = true;
      _msg = 'Saving…';
    });
    try {
      await OrbConfig.set(slot: _slot, orb: state.name, note: 'orb.picker');
      // Local mirror so the editor preview updates before Firestore snaps.
      UiOverrides.instance.applyLocal(UiOverride(
        slot: _slot,
        type: SlotType.orb,
        url: '',
        text: '',
        textSet: false,
        style: {'orb': state.name},
      ));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = 'Set for all users — ${orbLabel(state)}.';
        _preview = null;
      });
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
      if (r.orb == null || r.orb!.isEmpty) {
        UiOverrides.instance.removeLocal(_slot);
      } else {
        UiOverrides.instance.applyLocal(UiOverride(
          slot: _slot,
          type: SlotType.orb,
          url: '',
          text: '',
          textSet: false,
          style: {'orb': r.orb},
        ));
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _msg = r.orb == null ? 'Cleared — random until set again.' : 'Restored ${r.orb}.';
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final cur = _currentName;
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
                  const Text('THINKING ORB', style: TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  Text(
                    preview == null ? 'Pick an animation' : orbLabel(preview),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    _slot,
                    style: const TextStyle(color: kDim, fontSize: 11),
                  ),
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
              child: Text(_msg!, style: TextStyle(color: _busy ? kGold : const Color(0xFF81C784), fontSize: 12)),
            ),
          if (preview != null)
            Expanded(
              child: Column(children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: ThinkingOrb(state: preview, size: 180, theme: OrbTheme.dark),
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
                        onPressed: _busy ? null : () => _set(preview),
                        style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: const Color(0xFF060C18)),
                        child: const Text('Set'),
                      ),
                    ),
                  ]),
                ),
              ]),
            )
          else
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  for (final s in OrbState.values)
                    _OrbTile(
                      state: s,
                      selected: cur == s.name,
                      onTap: () => setState(() => _preview = s),
                    ),
                ],
              ),
            ),
        ]),
      ),
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
