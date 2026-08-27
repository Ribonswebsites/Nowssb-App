/// Personal Coach uses the signed-in Firebase identity and the existing
/// NowssB secure Worker. Provider credentials are never bundled in Flutter.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/content.dart';
import '../data/firebase.dart';
import '../data/models.dart';
import '../data/practice_progress.dart';
import 'practice_player.dart';

const _coachApi = 'https://nowssb-api.ribonpatil2.workers.dev/api/assistant/chat';
const _coachHero = 'assets/coach/personal_coach_hero.jpg';

class PersonalCoachScreen extends StatefulWidget {
  const PersonalCoachScreen({super.key});

  @override
  State<PersonalCoachScreen> createState() => _PersonalCoachScreenState();
}

class _PersonalCoachScreenState extends State<PersonalCoachScreen> {
  final _input = TextEditingController();
  final _google = GoogleSignIn(scopes: const ['email']);
  bool _sending = false;
  bool _signingIn = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_refresh);
    PracticeProgress.instance.start();
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_refresh);
    _input.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _signIn() async {
    if (_signingIn || !NwsbFirebase.ready) {
      if (!NwsbFirebase.ready) setState(() => _notice = 'Personal Coach needs Firebase to save your guidance.');
      return;
    }
    setState(() {
      _signingIn = true;
      _notice = null;
    });
    try {
      final account = await _google.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken));
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _notice = error.message ?? 'Sign-in could not be completed.');
    } catch (_) {
      if (mounted) setState(() => _notice = 'Sign-in could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _send(_CoachData data, [String? preset]) async {
    final message = (preset ?? _input.text).trim();
    if (message.isEmpty || _sending) return;
    if (!NwsbFirebase.ready || FirebaseAuth.instance.currentUser == null) {
      await _signIn();
      return;
    }
    final user = FirebaseAuth.instance.currentUser!;
    final history = List<_CoachMessage>.from(data.messages)..add(_CoachMessage('user', message));
    setState(() {
      _sending = true;
      _notice = null;
      _input.clear();
    });
    try {
      final reply = await _requestCoach(user, history, data);
      history.add(_CoachMessage('assistant', reply));
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'coach': {
          'messages': history.lastItems(24).map((item) => item.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } on _CoachException catch (error) {
      if (mounted) setState(() => _notice = error.message);
    } catch (_) {
      if (mounted) setState(() => _notice = 'Your coach is unavailable right now. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _planDay(_CoachData data) async {
    if (!NwsbFirebase.ready || FirebaseAuth.instance.currentUser == null) {
      await _signIn();
      return;
    }
    final words = ContentStore.instance.library.take(3).toList(growable: false);
    if (words.isNotEmpty && data.tasks.isEmpty) {
      final date = _day(DateTime.now());
      final tasks = words.map((word) => _CoachTask('${date}_${word.word}', 'Practice ${word.word}', date, 'open')).toList();
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
        'coach': {'tasks': tasks.map((task) => task.toMap()).toList(), 'updatedAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    }
    await _send(data, 'Plan my day');
  }

  Future<String> _requestCoach(User user, List<_CoachMessage> history, _CoachData data) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(_coachApi)).timeout(const Duration(seconds: 25));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${await user.getIdToken()}');
      request.headers.set('X-NowssB-Client', 'flutter');
      request.write(jsonEncode({
        'mode': 'coach',
        'messages': history.lastItems(12).map((item) => {'role': item.role, 'content': item.text}).toList(),
        'context': jsonEncode(data.context),
      }));
      final response = await request.close().timeout(const Duration(seconds: 25));
      final raw = await response.transform(utf8.decoder).join();
      final body = _asMap(raw);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _CoachException('${body['error'] ?? 'Your coach is unavailable right now. Please try again.'}');
      }
      final reply = body['message'];
      if (reply is! String || reply.trim().isEmpty) throw const _CoachException('Your coach did not return a response. Please try again.');
      return reply.trim();
    } on SocketException {
      throw const _CoachException('Check your connection and try your coach again.');
    } on HttpException {
      throw const _CoachException('Your coach is unavailable right now. Please try again.');
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!NwsbFirebase.ready) return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: _body(_CoachData.local(), false)));
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (_, auth) {
            final user = auth.data;
            if (user == null) return _body(_CoachData.local(), false);
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (_, document) => _body(_CoachData.profile(document.data?.data() ?? const {}), true),
            );
          },
        ),
      ),
    );
  }

  Widget _body(_CoachData data, bool signedIn) {
    final words = ContentStore.instance.library.take(6).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        Row(children: [
          _topButton(Icons.arrow_back_rounded, 'Back', () => Navigator.of(context).pop(), light: true),
          const Spacer(),
          const _OrbitMark(),
          const SizedBox(width: 12),
          _topButton(signedIn ? Icons.logout_rounded : Icons.person_outline_rounded, signedIn ? 'Sign out' : 'Sign in', signedIn ? () => FirebaseAuth.instance.signOut() : _signIn),
        ]),
        const SizedBox(height: 16),
        _hero(words),
        const SizedBox(height: 16),
        _metrics(data),
        const SizedBox(height: 16),
        const _QuoteCard(),
        const SizedBox(height: 22),
        const Text('Chat with your coach', style: TextStyle(color: Color(0xFFB5B5BA), fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _composer(data, signedIn),
        if (_notice != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_notice!, style: const TextStyle(color: Color(0xFFE2B8BA), height: 1.4))),
        if (data.messages.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...data.messages.lastItems(6).map(_bubble),
        ],
        const SizedBox(height: 12),
        Text(data.streak > 0 ? 'Your ${data.streak}-day streak informs your coach context.' : 'Complete a practice to begin your coach progress history.', style: const TextStyle(color: Color(0xFF7F7F85), fontSize: 13)),
      ],
    );
  }

  Widget _topButton(IconData icon, String label, VoidCallback action, {bool light = false}) => Semantics(
        label: label,
        button: true,
        child: IconButton.filled(
          onPressed: _signingIn ? null : action,
          style: IconButton.styleFrom(backgroundColor: light ? Colors.white : const Color(0xFF17171A), foregroundColor: light ? Colors.black : Colors.white),
          icon: _signingIn && label == 'Sign in' ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon),
        ),
      );

  Widget _hero(List<Word> words) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 260,
          decoration: BoxDecoration(color: const Color(0xFF09090B), border: Border.all(color: Colors.white.withOpacity(.08))),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(_coachHero, fit: BoxFit.cover, alignment: Alignment.topCenter),
            DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.05), Colors.black.withOpacity(.80)], stops: const [.25, 1]))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Personal\nCoach', style: TextStyle(color: Colors.white, fontSize: 36, height: .94, fontWeight: FontWeight.w800, letterSpacing: -.8)),
                const SizedBox(height: 12),
                const SizedBox(width: 46, child: Divider(color: Colors.white54, height: 1)),
                const SizedBox(height: 12),
                const Text('Your goals. My guidance.\nUnstoppable you.', style: TextStyle(color: Color(0xFFC6C6CC), fontSize: 16, height: 1.42)),
                if (words.isNotEmpty) TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(words: words, title: 'Personal Coach Session'))), style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.only(top: 10)), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start focused practice')),
              ]),
            ),
          ]),
        ),
      );

  Widget _metrics(_CoachData data) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _ProgressCard(percent: data.percent, target: data.target)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: [
          _MetricCard(label: 'Focus', title: data.goal, detail: data.target == 0 ? 'No tasks planned yet' : '${data.done} / ${data.target} tasks completed', progress: data.target == 0 ? 0 : data.percent / 100),
          const SizedBox(height: 12),
          _MetricCard(label: 'Mindset', title: data.streak == 0 ? 'Growth\nin progress.' : '${data.streak}-day\nstreak.', detail: data.streak == 0 ? 'Stay patient. Results compound.' : 'Keep your rhythm going.'),
        ])),
      ]);

  Widget _composer(_CoachData data, bool signedIn) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111114),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(.09)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_sending,
                    onSubmitted: (_) => _send(data),
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'How can I help you today?',
                      hintStyle: TextStyle(color: Color(0xFF797980)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: FilledButton(
                    onPressed: _sending ? null : () => _send(data),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: const Color(0xFF242429),
                    ),
                    child: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CoachChip(Icons.chat_bubble_outline_rounded, 'Need clarity', () => _send(data, 'Need clarity')),
                _CoachChip(Icons.gps_fixed_rounded, 'Plan my day', () => _planDay(data)),
                _CoachChip(Icons.star_outline_rounded, 'Stay motivated', () => _send(data, 'Stay motivated')),
                if (!signedIn) _CoachChip(Icons.login_rounded, 'Sign in to save', _signIn),
              ],
            ),
          ],
        ),
      );

  Widget _bubble(_CoachMessage item) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: item.role == 'assistant' ? const Color(0xFF1A1A1F) : const Color(0xFF26262B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(.06))),
        child: Text('${item.role == 'assistant' ? 'Coach' : 'You'}: ${item.text}', style: const TextStyle(color: Color(0xFFEDEDEF), height: 1.42)),
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.percent, required this.target});
  final int percent;
  final int target;
  @override
  Widget build(BuildContext context) => _Panel(height: 286, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Progress'), const Spacer(), Center(child: _Ring(percent)), const Spacer(),
        Text(target == 0 ? 'Choose a practice.\nYour progress will appear here.' : 'Keep showing up.\nYou’re building momentum.', style: const TextStyle(color: Color(0xFFA1A1A7), height: 1.42)),
      ]));
}

class _Ring extends StatelessWidget {
  const _Ring(this.percent);
  final int percent;
  @override
  Widget build(BuildContext context) => SizedBox(width: 136, height: 136, child: CustomPaint(painter: _RingPainter(percent / 100), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 35, letterSpacing: -1.2)), Text(percent == 0 ? 'Start' : percent == 100 ? 'Complete' : 'On Track', style: const TextStyle(color: Color(0xFFA0A0A6), fontSize: 13))]))));
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - 10) / 2;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, radius, Paint()..color = Colors.white.withOpacity(.12)..style = PaintingStyle.stroke..strokeWidth = 7);
    if (value > 0) canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 2 * value.clamp(0, 1).toDouble(), false, Paint()..color = const Color(0xFFF2F2F4)..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.title, required this.detail, this.progress});
  final String label, title, detail;
  final double? progress;
  @override
  Widget build(BuildContext context) => _Panel(height: progress == null ? 142 : 132, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label(label), const SizedBox(height: 9), Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.14, fontWeight: FontWeight.w500)), const Spacer(),
        if (progress != null) ...[LinearProgressIndicator(value: progress, minHeight: 2, color: Colors.white, backgroundColor: Colors.white12), const SizedBox(height: 8)],
        Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94949A), fontSize: 12)),
      ]));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.height});
  final Widget child; final double height;
  @override
  Widget build(BuildContext context) => Container(height: height, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF101013), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(.09))), child: child);
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();
  @override
  Widget build(BuildContext context) => Container(height: 176, padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: const Color(0xFF080809), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(.09))), child: Stack(children: [Positioned(right: -22, bottom: -20, child: Icon(Icons.waves_rounded, color: Colors.white.withOpacity(.16), size: 160)), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('“', style: TextStyle(color: Color(0xFFECECEF), fontSize: 44, height: .6, fontWeight: FontWeight.w700)), Spacer(), Text('Discipline today,\nfreedom tomorrow.', style: TextStyle(color: Colors.white, fontSize: 26, height: 1.2, fontWeight: FontWeight.w500))]) ]));
}

class _Label extends StatelessWidget { const _Label(this.text); final String text; @override Widget build(BuildContext context) => Text(text, style: const TextStyle(color: Color(0xFFA2A2A8), fontSize: 16, fontWeight: FontWeight.w600)); }
class _CoachChip extends StatelessWidget { const _CoachChip(this.icon, this.label, this.onTap); final IconData icon; final String label; final VoidCallback onTap; @override Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 17, color: const Color(0xFFD9D9DE)), label: Text(label), labelStyle: const TextStyle(color: Color(0xFFE2E2E5), fontSize: 14, fontWeight: FontWeight.w600), backgroundColor: const Color(0xFF131316), side: BorderSide(color: Colors.white.withOpacity(.12)), shape: const StadiumBorder(), onPressed: onTap); }
class _OrbitMark extends StatelessWidget { const _OrbitMark(); @override Widget build(BuildContext context) => const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 30); }

class _CoachData {
  const _CoachData({required this.goal, required this.tasks, required this.messages, required this.streak, required this.totalSessions});
  final String goal; final List<_CoachTask> tasks; final List<_CoachMessage> messages; final int streak; final int totalSessions;
  int get target => tasks.length;
  int get done => math.min(target, math.max(tasks.where((task) => task.status == 'completed').length, PracticeProgress.instance.todaySessions));
  int get percent => target == 0 ? 0 : ((done / target) * 100).round().clamp(0, 100) as int;
  Map<String, dynamic> get context => {'activeGoal': goal, 'todayCompleted': done, 'todayTarget': target, 'openTasks': tasks.where((task) => task.status != 'completed').length, 'streakDays': streak, 'completedSessions': totalSessions};
  factory _CoachData.local() { final progress = PracticeProgress.instance; return _CoachData(goal: 'Your practice', tasks: const [], messages: const [], streak: progress.streak, totalSessions: progress.totalSessions); }
  factory _CoachData.profile(Map<String, dynamic> profile) {
    final coach = profile['coach'] is Map ? Map<String, dynamic>.from(profile['coach'] as Map) : const <String, dynamic>{};
    final today = _day(DateTime.now());
    final tasks = (coach['tasks'] is List ? (coach['tasks'] as List).whereType<Map>().map((item) => _CoachTask.fromMap(Map<String, dynamic>.from(item))).toList() : <_CoachTask>[]).where((item) => item.date.isEmpty || item.date == today).toList();
    final messages = (coach['messages'] is List ? (coach['messages'] as List).whereType<Map>().map((item) => _CoachMessage.fromMap(Map<String, dynamic>.from(item))).toList() : <_CoachMessage>[]).where((item) => item.text.isNotEmpty).toList().lastItems(24);
    final onboarding = profile['onboardingAnswers'] is Map ? Map<String, dynamic>.from(profile['onboardingAnswers'] as Map) : const <String, dynamic>{};
    final progress = PracticeProgress.instance;
    return _CoachData(goal: '${coach['goal'] ?? onboarding['goal'] ?? 'Your practice'}'.trim(), tasks: tasks, messages: messages, streak: progress.streak, totalSessions: progress.totalSessions);
  }
}

class _CoachTask { const _CoachTask(this.id, this.title, this.date, this.status); final String id, title, date, status; factory _CoachTask.fromMap(Map<String, dynamic> map) => _CoachTask('${map['id'] ?? ''}', '${map['title'] ?? ''}', '${map['date'] ?? ''}', '${map['status'] ?? 'open'}'); Map<String, dynamic> toMap() => {'id': id, 'title': title, 'date': date, 'status': status}; }
class _CoachMessage { const _CoachMessage(this.role, this.text, [String? at]) : at = at ?? ''; final String role, text, at; factory _CoachMessage.fromMap(Map<String, dynamic> map) => _CoachMessage(map['role'] == 'assistant' ? 'assistant' : 'user', '${map['text'] ?? ''}', '${map['at'] ?? ''}'); Map<String, dynamic> toMap() => {'role': role, 'text': text, 'at': at.isEmpty ? DateTime.now().toUtc().toIso8601String() : at}; }
class _CoachException implements Exception { const _CoachException(this.message); final String message; }
Map<String, dynamic> _asMap(String raw) { try { final value = jsonDecode(raw); return value is Map ? Map<String, dynamic>.from(value) : const {}; } catch (_) { return const {}; } }
String _day(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
extension _LastItems<T> on List<T> { List<T> lastItems(int max) => length <= max ? List<T>.from(this) : sublist(length - max); }
