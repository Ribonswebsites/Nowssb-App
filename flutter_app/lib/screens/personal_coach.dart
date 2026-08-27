library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/coach_api.dart';
import '../data/content.dart';
import '../data/practice_progress.dart';
import 'practice_player.dart';

class PersonalCoachScreen extends StatefulWidget {
  const PersonalCoachScreen({super.key, this.api});

  final CoachApi? api;

  @override
  State<PersonalCoachScreen> createState() => _PersonalCoachScreenState();
}

class _PersonalCoachScreenState extends State<PersonalCoachScreen> {
  late final CoachApi _api = widget.api ?? CoachApi();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<CoachMessage> _messages = [];
  String? _conversationId;
  String? _error;
  bool _loadingHistory = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_refresh);
    unawaited(_prepare());
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_refresh);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _prepare() async {
    await PracticeProgress.instance.start();
    try {
      final conversation = await _api.loadHistory();
      if (!mounted) return;
      setState(() {
        _conversationId = conversation.id;
        _messages
          ..clear()
          ..addAll(conversation.messages);
        _loadingHistory = false;
        _error = null;
      });
    } on CoachApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _error = 'Could not load your coach history. Check your connection and retry.';
      });
    }
  }

  Map<String, dynamic> _context(List<Word> words) {
    final progress = PracticeProgress.instance;
    final completed = progress.completedTodayFor(words);
    return {
      'client': 'flutter',
      'timezone': DateTime.now().timeZoneName,
      'progress': {
        'todaySessions': progress.todaySessions,
        'totalSessions': progress.totalSessions,
        'streak': progress.streak,
        'goalPercent': words.isEmpty ? null : (completed / words.length * 100).round().clamp(0, 100),
      },
      'routine': {'name': 'Personal Coach Practice', 'wordCount': words.length},
    };
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty || _sending) return;
    final history = List<CoachMessage>.of(_messages);
    final optimistic = CoachMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: text,
    );
    final words = ContentStore.instance.library.take(6).toList(growable: false);
    setState(() {
      _sending = true;
      _error = null;
      _messageController.clear();
      _messages.add(optimistic);
    });
    _scrollToBottom();
    try {
      final reply = await _api.send(
        message: text,
        history: history,
        conversationId: _conversationId,
        context: _context(words),
      );
      if (!mounted) return;
      setState(() {
        _conversationId = reply.conversationId;
        _messages.add(reply.message);
        _sending = false;
      });
      _scrollToBottom();
    } on CoachApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((message) => message.id == optimistic.id);
        _sending = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((message) => message.id == optimistic.id);
        _sending = false;
        _error = 'The coach is unavailable. Check your connection and retry.';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _runAction(CoachAction action, List<Word> words) {
    if (action.type != 'start_practice' || words.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PracticePlayerScreen(words: words, title: 'Personal Coach Session'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PracticeProgress.instance,
      builder: (context, _) {
        final words = ContentStore.instance.library.take(6).toList(growable: false);
        final progress = PracticeProgress.instance;
        final completed = progress.completedTodayFor(words);
        final percent = words.isEmpty ? 0 : (completed / words.length * 100).round().clamp(0, 100).toInt();
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Personal Coach', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                  const CircleAvatar(backgroundColor: Color(0xFF202024), child: Icon(Icons.person_outline_rounded, color: Colors.white70)),
                ]),
                const SizedBox(height: 22),
                _heroCard(words),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _progressCard(percent, completed, words.length)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(children: [
                    _coachCard('Focus', words.isEmpty ? 'Choose words' : 'Consistency', '${progress.todaySessions} sessions today'),
                    const SizedBox(height: 12),
                    _coachCard('Mindset', progress.streak > 0 ? '${progress.streak} day streak' : 'Start today', 'Small steps compound.'),
                  ])),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF151518), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)),
                  child: const Text('“\nDiscipline today,\nfreedom tomorrow.', style: TextStyle(color: Colors.white, fontSize: 22, height: 1.25, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                const Text('Chat with your coach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (_loadingHistory)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator(minHeight: 2, color: Colors.white, backgroundColor: Colors.white12)),
                if (_error != null) _errorCard(),
                if (!_loadingHistory && _messages.isEmpty && _error == null)
                  const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Ask a real question about your focus, routine, progress, or what to do next.', style: TextStyle(color: Colors.white54, height: 1.45))),
                ..._messages.map((message) => _messageBubble(message, words)),
                if (_sending)
                  const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child: Text('Coach is thinking…', style: TextStyle(color: Colors.white54)))),
                _composer(),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticeProgressScreen(words: words))),
                  icon: const Icon(Icons.insights_outlined),
                  label: Text(progress.streak > 0 ? 'Review progress · ${progress.streak}-day streak' : 'Review progress · start your streak'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _heroCard(List<Word> words) => Container(
        height: 250,
        padding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A1A20), Color(0xFF050505)]),
          border: Border.all(color: Colors.white12),
        ),
        child: Stack(children: [
          Positioned(right: -28, top: -26, child: IgnorePointer(child: Image.asset('assets/coach/coach-orb.png', width: 210, height: 210, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Personal\nCoach', style: TextStyle(color: Colors.white, fontSize: 34, height: 1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('Your goals. My guidance.\nUnstoppable you.', style: TextStyle(color: Colors.white60, height: 1.5)),
            const Spacer(),
            FilledButton.icon(onPressed: words.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(words: words, title: 'Personal Coach Session'))), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start focused practice')),
          ]),
        ]),
      );

  Widget _progressCard(int percent, int completed, int total) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF0E0E10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Progress', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(total == 0 ? 'Choose words for today' : '$completed of $total words today', style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35)),
        ]),
      );

  Widget _coachCard(String label, String title, String detail) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF0E0E10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35)),
        ]),
      );

  Widget _messageBubble(CoachMessage message, List<Word> words) {
    final user = message.role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(crossAxisAlignment: user ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 330),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(color: user ? const Color(0xFF2A2A30) : const Color(0xFF17171B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          child: Text(message.content, style: const TextStyle(color: Colors.white, height: 1.45)),
        ),
        ...message.actions.where((action) => action.type == 'start_practice').map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(onPressed: words.isEmpty ? null : () => _runAction(action, words), child: Text(action.label)),
            )),
      ]),
    );
  }

  Widget _composer() => TextField(
        controller: _messageController,
        enabled: !_sending,
        onSubmitted: (_) => _send(),
        minLines: 1,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'How can I help you today?',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF101013),
          suffixIcon: IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      );

  Widget _errorCard() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF25191B), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withOpacity(.25))),
        child: Row(children: [
          Expanded(child: Text(_error ?? 'The coach could not complete that request.', style: const TextStyle(color: Colors.white70))),
          TextButton(onPressed: _loadingHistory ? null : _prepare, child: const Text('Retry')),
        ]),
      );
}
