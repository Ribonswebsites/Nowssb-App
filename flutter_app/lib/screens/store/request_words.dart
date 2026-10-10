/// Request Words sub-page. Fulfilling requests lives in admin mode
/// (lib/admin/requests_admin.dart), for server-marked admins only.
library;

import 'package:flutter/material.dart';

import '../../data/word_requests.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../shell/nav_shell.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import '../../widgets/app_thinking_loader.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import '../../admin/layout/layout_sections.dart';
import '../../admin/template/editable.dart';
import '../../widgets/hype_rail.dart';

void openRequestWords(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const RequestWordsScreen()),
  );
}

class RequestWordsScreen extends StatefulWidget {
  const RequestWordsScreen({super.key});

  @override
  State<RequestWordsScreen> createState() => _RequestWordsScreenState();
}

class _RequestWordsScreenState extends State<RequestWordsScreen> {
  final _word = TextEditingController();
  final _notes = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WordRequestStore.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _word.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await WordRequestStore.instance.submit(
        word: _word.text,
        notes: _notes.text,
      );
      if (!mounted) return;
      _word.clear();
      _notes.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: EditableLabel('request_words.RequestWordsScreen',
              'Request sent — our atelier will fulfill it'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Invalid argument: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same store shell as every department (title, film, store picker).
    return PageShell(
      eyebrow: '',
      title: 'NowssB Store',
      subtitle: 'Request Words',
      film: 'assets/video/player-bg-loop.mp4',
      usePageFilm: true,
      onBack: () => Navigator.of(context).pop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          sliver: SliverList(
            // Server-driven order (Admin → UI Editor); bundled order by default.
            delegate: SliverChildListDelegate(layoutIndexed(context, 'store.request', const {
              0: ('banner', 'Request banner'),
              2: ('hype', 'Most hyped'),
              4: ('form', 'Request form'),
              6: ('promo', 'Split promo banner'),
              8: ('recent', 'Your recent requests'),
            }, noCopy: const {'form'}, [
              StoreNotifBanner(
                heading: 'BUY REQUEST',
                svgBody: NwsbMarks.word,
                artAsset: kStoreProductArt,
                accent: const Color(0xFFE8D5A3),
                sub: 'Tell us the word you need — we fulfill from the atelier.',
                pillLabel: 'REQUEST',
              ),
              const SizedBox(height: 16),
              const NowssbHypeRail(),
              const SizedBox(height: 18),
              StoreGlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EditableLabel(
                      'request_words.RequestWordsScreen',
                      'Word',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _word,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      cursorColor: NwsbColors.goldLight,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Serenity, Phoenix, Dharma…',
                        hintStyle: const TextStyle(color: Color(0x55FFFFFF)),
                        filled: true,
                        fillColor: const Color(0x22000000),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x88E8D5A3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const EditableLabel(
                      'request_words.RequestWordsScreen',
                      'Notes (optional)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: NwsbColors.goldLight,
                      decoration: InputDecoration(
                        hintText: 'Language, meaning, why you need it…',
                        hintStyle: const TextStyle(color: Color(0x55FFFFFF)),
                        filled: true,
                        fillColor: const Color(0x22000000),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x33FFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x88E8D5A3)),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFFF8A80), fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _busy ? null : _submit,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8D5A3), Color(0xFFC8A96E)],
                          ),
                        ),
                        child: _busy
                            ? const AppThinkingLoader(
                                size: 28,
                                state: OrbState.composing,
                                circlePad: 6)
                            : const EditableLabel(
                                'request_words.RequestWordsScreen',
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF060C18),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ColoredSplitPromoBanner.forSurface(
                SplitPromoSurface.requestWords,
                onTap: () => NavScope.goTo(context, 1),
              ),
              const SizedBox(height: 8),
              const EditableLabel(
                'request_words.RequestWordsScreen',
                'Your recent requests',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: WordRequestStore.instance,
                builder: (context, _) {
                  final items = WordRequestStore.instance.items;
                  if (items.isEmpty) {
                    return const EditableLabel(
                      'request_words.RequestWordsScreen',
                      'No requests yet — submit one above.',
                      style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
                    );
                  }
                  return Column(
                    children: [
                      for (final r in items.take(8))
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.word,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (r.notes.isNotEmpty)
                                      Text(
                                        r.notes,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0x77FFFFFF)),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: r.fulfilled
                                      ? const Color(0x334CAF50)
                                      : const Color(0x33FFB74D),
                                  border: Border.all(
                                    color: r.fulfilled
                                        ? const Color(0x884CAF50)
                                        : const Color(0x88FFB74D),
                                  ),
                                ),
                                child: Text(
                                  r.fulfilled ? 'Fulfilled' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: r.fulfilled
                                        ? const Color(0xFF81C784)
                                        : const Color(0xFFFFB74D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ])),
          ),
        ),
      ],
    );
  }
}
