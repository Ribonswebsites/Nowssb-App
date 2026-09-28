/// Admin — Quotes. Writes `content/quotes` (public read, admin write):
/// a line pinned for today, lines for particular dates, and a queue used in
/// turn for every other day. Empty everywhere = the seven built-in lines.
library;

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/quotes_remote.dart';
import '../data/settings.dart';
import 'admin_log.dart';
import 'admin_ui.dart';

class QuotesAdminScreen extends StatefulWidget {
  const QuotesAdminScreen({super.key});

  @override
  State<QuotesAdminScreen> createState() => _QuotesAdminScreenState();
}

class _QuotesAdminScreenState extends State<QuotesAdminScreen> {
  final _doc = FirebaseFirestore.instance.collection('content').doc('quotes');
  final _live = TextEditingController();
  final _queue = TextEditingController();
  Map<String, String> _byDate = {};
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final q = QuoteStore.instance;
    _live.text = q.live;
    _queue.text = q.queue.join('\n');
    _byDate = Map.of(q.byDate);
    _doc.get().then((s) {
      final d = s.data();
      if (!mounted || d == null) return;
      setState(() {
        _live.text = '${d['live'] ?? ''}';
        _queue.text = d['queue'] is List ? (d['queue'] as List).join('\n') : '';
        _byDate = d['byDate'] is Map
            ? {for (final e in (d['byDate'] as Map).entries) '${e.key}': '${e.value}'}
            : {};
      });
    }).whenComplete(() => mounted ? setState(() => _loaded = true) : null);
  }

  @override
  void dispose() {
    _live.dispose();
    _queue.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final queue = _queue.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final u = FirebaseAuth.instance.currentUser;
    try {
      await _doc.set({
        'live': _live.text.trim(),
        'queue': queue,
        'byDate': _byDate,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': u?.email ?? u?.uid ?? '',
      });
      await adminLog('quotes.save', 'content/quotes',
          {'dated': _byDate.length, 'queue': queue.length, 'live': _live.text.trim().isNotEmpty});
      if (mounted) adminToast(context, 'Published — every app shows it now.');
    } catch (e) {
      if (mounted) adminToast(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editDate([String? day]) async {
    DateTime? picked;
    if (day == null) {
      picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 730)),
      );
      if (picked == null || !mounted) return;
    }
    final key = day ?? quoteDayKey(picked!);
    final c = TextEditingController(text: _byDate[key] ?? '');
    final out = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kAdminPanel,
        title: Text(key, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'The line for that day'),
        ),
        actions: [
          if (day != null)
            TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Remove')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    c.dispose();
    if (out == null) return;
    setState(() {
      if (out.isEmpty) {
        _byDate.remove(key);
      } else {
        _byDate[key] = out;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _byDate.keys.toList()..sort();
    final today = DateTime.now();
    return AdminScaffold(
      title: 'Quotes',
      actions: [
        TextButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Publish', style: const TextStyle(color: kAdminGold)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (!_loaded) const LinearProgressIndicator(minHeight: 2),
          Text('Today the app shows: “${Settings.instance.todayQuote}”',
              style: const TextStyle(color: kAdminDim, fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            controller: _live,
            minLines: 1,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Pinned line (over everything, until cleared)',
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(
              child: Text('Lines for particular days',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: () => _editDate(),
              icon: const Icon(Icons.add, color: kAdminGold),
              label: const Text('Add a day', style: TextStyle(color: kAdminGold)),
            ),
          ]),
          if (days.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('None yet.', style: TextStyle(color: kAdminDim, fontSize: 12)),
            ),
          for (final d in days)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_byDate[d]!, style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(d == quoteDayKey(today) ? '$d · today' : d,
                  style: const TextStyle(color: kAdminDim, fontSize: 11)),
              trailing: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18),
              onTap: () => _editDate(d),
            ),
          const SizedBox(height: 20),
          const Text('Queue — one line per row, used in turn on days without their own line',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _queue,
            minLines: 5,
            maxLines: 16,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Empty = the seven built-in lines'),
          ),
        ],
      ),
    );
  }
}
