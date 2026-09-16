/// Request Words sub-page + admin fulfillment list.
library;

import 'package:flutter/material.dart';

import '../../data/word_requests.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';

void openRequestWords(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const RequestWordsScreen()),
  );
}

void openRequestWordsAdmin(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const RequestWordsAdminScreen()),
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
          content: Text('Request sent — our atelier will fulfill it'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Invalid argument: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Request Words',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => openRequestWordsAdmin(context),
                  child: const Text(
                    'Admin',
                    style: TextStyle(color: NwsbColors.goldLight, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StoreNotifBanner(
              heading: 'BUY REQUEST',
              svgBody: NwsbMarks.word,
              artAsset: kStoreProductArt,
              accent: const Color(0xFFE8D5A3),
              sub: 'Tell us the word you need — we fulfill from the atelier.',
              pillLabel: 'REQUEST',
            ),
            const SizedBox(height: 18),
            StoreGlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
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
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x88E8D5A3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
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
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x88E8D5A3)),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12)),
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
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF060C18)),
                            )
                          : const Text(
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
            const SizedBox(height: 22),
            const Text(
              'Your recent requests',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: WordRequestStore.instance,
              builder: (context, _) {
                final items = WordRequestStore.instance.items;
                if (items.isEmpty) {
                  return const Text(
                    'No requests yet — submit one above.',
                    style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
                  );
                }
                return Column(
                  children: [
                    for (final r in items.take(8))
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                      style: const TextStyle(fontSize: 11, color: Color(0x77FFFFFF)),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ],
        ),
      ),
    );
  }
}

class RequestWordsAdminScreen extends StatefulWidget {
  const RequestWordsAdminScreen({super.key});

  @override
  State<RequestWordsAdminScreen> createState() => _RequestWordsAdminScreenState();
}

class _RequestWordsAdminScreenState extends State<RequestWordsAdminScreen> {
  @override
  void initState() {
    super.initState();
    WordRequestStore.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Fulfill Word Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: WordRequestStore.instance,
                builder: (context, _) {
                  final items = WordRequestStore.instance.items;
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No word requests yet.',
                        style: TextStyle(color: Color(0x66FFFFFF)),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = items[i];
                      return StoreGlassPanel(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.word,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  r.fulfilled ? 'Done' : 'Open',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: r.fulfilled
                                        ? const Color(0xFF81C784)
                                        : NwsbColors.goldLight,
                                  ),
                                ),
                              ],
                            ),
                            if (r.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                r.notes,
                                style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Requested ${_fmt(r.createdAt)}',
                              style: const TextStyle(fontSize: 10, color: Color(0x55FFFFFF)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (r.fulfilled) {
                                        await WordRequestStore.instance.reopen(r.id);
                                      } else {
                                        await WordRequestStore.instance.markFulfilled(r.id);
                                      }
                                    },
                                    child: Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          colors: r.fulfilled
                                              ? const [Color(0xFF37474F), Color(0xFF263238)]
                                              : const [Color(0xFFE8D5A3), Color(0xFFC8A96E)],
                                        ),
                                      ),
                                      child: Text(
                                        r.fulfilled ? 'Reopen' : 'Mark Fulfilled',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: r.fulfilled ? Colors.white : const Color(0xFF060C18),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}
