import 'package:flutter/material.dart';

class SelectLevelScreen extends StatefulWidget {
  const SelectLevelScreen({super.key, this.initialLevel = 3});
  final int initialLevel;

  @override
  State<SelectLevelScreen> createState() => _SelectLevelScreenState();
}

class _SelectLevelScreenState extends State<SelectLevelScreen> {
  late int _selected;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLevel.clamp(1, 10).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final levels = _expanded ? List.generate(10, (i) => i + 1) : List.generate(6, (i) => i + 1);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                color: const Color(0xFF030303),
                border: Border.all(color: const Color(0x1AFFFFFF)),
                boxShadow: const [BoxShadow(color: Color(0xB3000000), blurRadius: 90, offset: Offset(0, 40))],
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _CircleButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).pop()),
                  _CircleButton(icon: Icons.more_horiz_rounded, onTap: () {}),
                ]),
                const SizedBox(height: 12),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Color(0xFFE7E7E7), Color(0xFF4A4A4A), Color(0xFF050505)], stops: [0.1, 0.42, 1]),
                    boxShadow: const [BoxShadow(color: Color(0x18FFFFFF), blurRadius: 40)],
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: const Icon(Icons.all_inclusive_rounded, color: Colors.black, size: 70),
                ),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  SizedBox(width: 44, child: Divider(color: Color(0x59FFFFFF))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('SELECT LEVEL', style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w500))),
                  SizedBox(width: 44, child: Divider(color: Color(0x59FFFFFF))),
                ]),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: levels.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.85),
                  itemBuilder: (_, i) {
                    final level = levels[i];
                    final selected = _selected == level;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: const LinearGradient(colors: [Color(0x0FFFFFFF), Color(0x05000000)]),
                          border: Border.all(color: selected ? const Color(0x8CFFFFFF) : const Color(0x24FFFFFF)),
                          boxShadow: selected ? const [BoxShadow(color: Color(0x38FFFFFF), blurRadius: 26)] : const [],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(level.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w300, height: 1)),
                            Text('LEVEL ${_words[level - 1]}', style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 9, letterSpacing: 1.5)),
                          ]),
                          Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? const Color(0xB3FFFFFF) : const Color(0x38FFFFFF))), child: selected ? const Center(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: SizedBox(width: 7, height: 7))) : null),
                        ]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ActionRow(icon: Icons.layers_rounded, label: _expanded ? 'COLLAPSE OPTIONS' : 'EXPAND OPTIONS', trailing: _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, onTap: () => setState(() => _expanded = !_expanded)),
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  _ActionRow(icon: Icons.keyboard_arrow_up_rounded, label: 'PREVIOUS LEVELS', trailing: null, onTap: () => setState(() => _expanded = false)),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  static const _words = ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE', 'TEN'];
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x0AFFFFFF), border: Border.all(color: const Color(0x24FFFFFF))), child: Icon(icon, color: Colors.white, size: 20)));
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.trailing, required this.onTap});
  final IconData icon;
  final String label;
  final IconData? trailing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: const Color(0x0AFFFFFF), border: Border.all(color: const Color(0x24FFFFFF))), child: Row(children: [Icon(icon, color: Colors.white70, size: 18), const SizedBox(width: 14), Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2.2))), if (trailing != null) Icon(trailing, color: Colors.white70, size: 18)])));
}
