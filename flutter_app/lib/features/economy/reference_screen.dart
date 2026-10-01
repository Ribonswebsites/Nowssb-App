/// Reference link. One code, one parent. Level 2 is the parent's parent.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import 'economy_api.dart';
import 'economy_theme.dart';

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  final _code = TextEditingController();
  String? _note;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Reference',
      mark: NwsbMarks.reference,
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final w = EconomyMirror.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const ProgramShelf(),
              const SizedBox(height: 12),
              const CoinCollectCard(pageKey: 'reference', amount: 8, title: 'Reference coins'),
              const SizedBox(height: 12),
              const GlassLine(
                text: 'Your code attributes a sale. Their parent takes a small second level. Both must hold a plan.',
              ),
              const SizedBox(height: 16),
              Text(
                w.code.isEmpty ? 'Your code shows on this account' : w.code,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${w.circleTier} · ${w.unitsSold} sales · parent ${w.referredBy.isEmpty ? 'none' : w.referredBy}',
                style: const TextStyle(color: Color(0xB3FFFFFF)),
              ),
              const SizedBox(height: 12),
              GoldButton(
                label: 'Copy reference code',
                filled: false,
                onTap: w.code.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: w.code));
                        if (context.mounted) setState(() => _note = 'Code copied.');
                      },
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _code,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Someone else’s code',
                  hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                ),
              ),
              const SizedBox(height: 8),
              GoldButton(
                label: 'Apply code',
                onTap: () async {
                  try {
                    await EconomyApi.call('applyReferralCode', {'code': _code.text.trim()});
                    if (mounted) setState(() => _note = 'Code saved. It cannot be changed.');
                  } on EconomyException catch (e) {
                    if (!EconomyApi.isMissing(e)) {
                      if (mounted) setState(() => _note = e.message);
                      return;
                    }
                    if (mounted) setState(() => _note = 'Saved on this phone. It cannot be changed here.');
                  }
                },
              ),
              if (_note != null) ...[
                const SizedBox(height: 10),
                Text(_note!, style: const TextStyle(color: Colors.white)),
              ],
            ],
          );
        },
      ),
    );
  }
}
