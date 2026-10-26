/// DOOR SCREENS — Access (QuickAccessScreen, the bottom nav bar).
/// Signature move: THE SOCKET BAR + ROLODEX — the real five-slot nav bar
/// sits live at the top as torn sockets; pick a socket, then spin a
/// rolodex of feature posters (giant serif names on their own art) and
/// tap one to drop it into the socket. The bar re-renders instantly.
/// Writes (via Builder): nwsb_nav_slots (List<String> of 5 ids).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'door_kit.dart';

const _slot = 'concept.Doors.Access';

class DoorFeature {
  const DoorFeature({required this.id, required this.label, required this.icon, this.art, this.image});
  final String id, label;
  final IconData icon;
  final String? art; // local banner art for the rolodex card
  final String? image; // QuickAccessScreen.features img (network), Builder
}

class DoorAccessPicker extends StatefulWidget {
  const DoorAccessPicker({
    super.key,
    required this.features,
    required this.slots,
    this.onSetSlot,
    this.onBack,
    this.debugPhase,
    this.debugSocket,
  });
  final List<DoorFeature> features;
  final List<String> slots; // 5 ids
  final void Function(int index, String id)? onSetSlot;
  final VoidCallback? onBack;
  final double? debugPhase;
  final int? debugSocket;

  @override
  State<DoorAccessPicker> createState() => _S();
}

class _S extends State<DoorAccessPicker> with TickerProviderStateMixin, DoorPhase {
  late int _socket = widget.debugSocket ?? 0;
  late final _wheel = FixedExtentScrollController(initialItem: 2);

  @override
  double? get debugPhaseValue => widget.debugPhase;

  @override
  void initState() {
    super.initState();
    startPhase();
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  DoorFeature _f(String id) => widget.features.firstWhere((f) => f.id == id, orElse: () => widget.features.first);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doorDeep,
      body: AnimatedBuilder(
        animation: phase,
        builder: (context, _) {
          final t = phase.value;
          final current = _f(widget.slots[_socket]);
          return Stack(fit: StackFit.expand, children: [
            DoorLiquid(t: t),
            SafeArea(
              child: Column(children: [
                DoorTopBar(slot: _slot, sub: 'Access', onBack: widget.onBack),
                Expanded(
                  child: CustomScrollView(slivers: [
                    SliverList.list(children: [
                      // HERO: the nav bar itself, large, on its own clean stage
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('YOUR BAR', style: doorDisplay(44, ls: 0)),
                          const SizedBox(height: 2),
                          Text('Five doors on your bottom bar · tap a socket to change it', style: doorSub()),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      _SocketBar(
                        big: true,
                        slots: [for (final id in widget.slots) _f(id)],
                        active: _socket,
                        t: t,
                        onTap: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _socket = i);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                        child: Text.rich(TextSpan(children: [
                          TextSpan(text: 'Socket ${_socket + 1}  ', style: doorBody(13, color: doorGoldSoft, w: FontWeight.w800, ls: 1.5)),
                          TextSpan(text: current.label, style: doorTitle()),
                        ])),
                      ),
                      const DoorKicker('$_slot.k2', 'Spin the rolodex · tap to drop in'),
                    ]),
                    SliverToBoxAdapter(
                        child: SizedBox(
                      height: 336,
                      child: ListWheelScrollView.useDelegate(
                        controller: _wheel,
                        itemExtent: 112,
                        diameterRatio: 1.9,
                        perspective: .004,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (_) => HapticFeedback.selectionClick(),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: widget.features.length,
                          builder: (context, i) {
                            final f = widget.features[i];
                            final inBar = widget.slots.indexOf(f.id);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                widget.onSetSlot?.call(_socket, f.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
                                child: Transform.rotate(
                                  angle: (i.isEven ? -1 : 1) * .02,
                                  child: DoorTornTile(
                                    slot: '$_slot.card.${f.id}',
                                    asset: f.art,
                                    seed: 70 + i,
                                    t: (t + i * .1) % 1,
                                    selected: inBar == _socket,
                                    sticker: inBar >= 0 ? 'In socket ${inBar + 1}' : null,
                                    word: f.label,
                                    wordSize: 52,
                                    child: f.art == null ? _IconPlate(icon: f.icon) : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )),
                    // Below the rolodex: every door at a glance, so the page ends in content.
                    const SliverToBoxAdapter(child: DoorKicker('$_slot.k3', 'Every door · tap to drop in')),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                      sliver: SliverGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.45,
                        children: [
                          for (var i = 0; i < widget.features.length; i++) _gridCard(widget.features[i], i, t),
                        ],
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _gridCard(DoorFeature f, int i, double t) {
    final inBar = widget.slots.indexOf(f.id);
    return Semantics(
      button: true,
      selected: inBar == _socket,
      label: 'Put ${f.label} in socket ${_socket + 1}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onSetSlot?.call(_socket, f.id);
        },
        child: DoorTornTile(
          slot: '$_slot.grid.${f.id}',
          asset: f.art,
          seed: 90 + i,
          t: 0,
          selected: inBar == _socket,
          sticker: inBar >= 0 ? 'S${inBar + 1}' : null,
          word: f.label.replaceFirst(' ', '\n'), // full label, 2 lines
          wordSize: 24,
          child: f.art == null ? _IconPlate(icon: f.icon) : null,
        ),
      ),
    );
  }
}

class _IconPlate extends StatelessWidget {
  const _IconPlate({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1B1430),
        alignment: const Alignment(.8, -.3),
        child: Icon(icon, size: 64, color: doorGold),
      );
}

class _SocketBar extends StatelessWidget {
  const _SocketBar({required this.slots, required this.active, required this.t, required this.onTap, this.big = false});
  final bool big;
  final List<DoorFeature> slots;
  final int active;
  final double t;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        // Narrow (e.g. 320 @1.3×): only the selected socket keeps its label.
        final narrow = (c.maxWidth - 36) / slots.length < MediaQuery.textScalerOf(context).scale(62);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: big ? 18 : 10),
          decoration: BoxDecoration(
            color: const Color(0xF2120C22),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: doorGold.withValues(alpha: .55)),
            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)],
          ),
          child: Row(children: [
            for (var i = 0; i < slots.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == active,
                  label: 'Socket ${i + 1}: ${slots[i].label}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Transform.translate(
                        offset: Offset(0, i == active ? -4 + math.sin(t * math.pi * 4) * 2 : 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: big ? 54 : 44,
                          height: big ? 54 : 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == active ? doorGold : Colors.black,
                            border: Border.all(color: i == active ? doorGoldSoft : Colors.white24, width: 1.4),
                          ),
                          child: Icon(slots[i].icon, size: big ? 26 : 22, color: i == active ? doorInk : Colors.white),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (narrow && i != active)
                        Text(' ', maxLines: 1, style: doorBody(big ? 13 : 11.5))
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(slots[i].label,
                              maxLines: 1,
                              style: doorBody(big ? 13 : 11.5, color: i == active ? doorGoldSoft : Colors.white, w: FontWeight.w700)),
                        ),
                    ]),
                  ),
                ),
              ),
          ]),
        );
      });
}
