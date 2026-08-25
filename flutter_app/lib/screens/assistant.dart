import 'package:flutter/material.dart';

import '../media/nwsb_image.dart';
import '../services/nowssb_api.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';

enum AssistantMode { support, coach }

extension AssistantModeCopy on AssistantMode {
  String get id => this == AssistantMode.coach ? 'coach' : 'support';
  String get eyebrow => this == AssistantMode.coach ? 'Personal guidance' : 'Help & support';
  String get title => this == AssistantMode.coach ? 'Personal Coach' : 'Chat Support';
  String get description => this == AssistantMode.coach
      ? 'A calm NowssB companion for choosing a practice, building a routine, and reflecting on your day.'
      : 'Get clear help with the player, practice, library, routines, account, and every part of NowssB.';
  String get hero => this == AssistantMode.coach
      ? 'assets/assistant/coach-hero.png'
      : 'assets/assistant/support-hero.png';
  String get secondary => this == AssistantMode.coach
      ? 'assets/assistant/coach-practice.png'
      : 'assets/assistant/support-topics.png';
  List<String> get prompts => this == AssistantMode.coach
      ? const [
          'Choose a practice for me today',
          'Help me build a simple routine',
          'I feel stressed right now',
        ]
      : const [
          'How do I use the Word Player?',
          'My video or audio is not playing',
          'Where are my routines and library?',
        ];
  String get welcome => this == AssistantMode.coach
      ? 'I’m your NowssB Personal Coach. Tell me how you feel or what you want to practise, and I’ll help you choose a gentle next step.'
      : 'I’m NowssB Chat Support. Ask me about any app feature, or tell me what is not working and I’ll guide you step by step.';
}

class AssistantHubScreen extends StatelessWidget {
  const AssistantHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: 'NowssB guide replacement',
      title: 'Help & Coach',
      film: 'assets/video/hero-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList.list(children: [
            const _AssistantLogoBadge(),
            const SizedBox(height: 16),
            const Text(
              'One calm place for answers and practice guidance.',
              style: TextStyle(color: Colors.white, fontSize: 17, height: 1.35, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose support for the app, or a coach for your personal practice. Both use the free NowssB Cloudflare assistant and keep provider keys away from the app.',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 22),
            _AssistantModeCard(mode: AssistantMode.support),
            _AssistantModeCard(mode: AssistantMode.coach),
            const SizedBox(height: 10),
            const Text(
              'The assistant can explain NowssB features and offer general wellbeing guidance. It is not a doctor, therapist, emergency service, or billing authority.',
              style: TextStyle(color: Color(0x73FFFFFF), fontSize: 11.5, height: 1.45),
            ),
          ]),
        ),
      ],
    );
  }
}

class _AssistantLogoBadge extends StatelessWidget {
  const _AssistantLogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(13),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const NwsbImage(
        asset: 'assets/icons/logo-disc.webp',
        fit: BoxFit.contain,
        fallback: Icon(Icons.auto_awesome, color: NwsbColors.ink, size: 30),
      ),
    );
  }
}

class _AssistantModeCard extends StatelessWidget {
  const _AssistantModeCard({required this.mode});
  final AssistantMode mode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AssistantChatScreen(mode: mode))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xCC080C16),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x2BFFFFFF)),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: NwsbImage(
                asset: 'assets/icons/logo-disc.webp',
                fit: BoxFit.contain,
                fallback: Icon(mode == AssistantMode.coach ? Icons.self_improvement : Icons.help_outline, color: NwsbColors.ink, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(mode.eyebrow.toUpperCase(), style: const TextStyle(color: NwsbColors.gold, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(mode.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(mode.description, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11.5, height: 1.4)),
              ]),
            ),
            const Icon(Icons.arrow_forward, color: Color(0xB3FFFFFF), size: 18),
          ],
        ),
      ),
    );
  }
}

class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key, required this.mode});
  final AssistantMode mode;

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <Map<String, String>>[];
  bool _loading = false;

  AssistantMode get mode => widget.mode;

  @override
  void initState() {
    super.initState();
    _messages.add({'role': 'assistant', 'content': mode.welcome});
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _appContext() {
    return 'The user is in the ${mode.id} area. They are using the NowssB mobile app. '
        'Available destinations include Normal Home, Fashion Home, Today\'s Practice, Word Player, My Routines, Healing Path, Word Science, Real Meaning, Sound Library, eBooks, Store, Fashion Plus, Connect, Profile, Settings, progress, and streaks.';
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _loading) return;
    _input.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _scrollToEnd();
    try {
      final reply = await NowssbApi.instance.assistantChat(
        mode: mode.id,
        messages: _messages,
        context: _appContext(),
      );
      if (!mounted) return;
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
    } catch (error) {
      if (!mounted) return;
      setState(() => _messages.add({
            'role': 'assistant',
            'content': 'I could not reach the free NowssB assistant right now. Please try again in a moment. If this is an account or billing issue, use human support.',
          }));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      eyebrow: mode.eyebrow,
      title: mode.title,
      film: 'assets/video/hero-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList.list(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(height: 178, child: NwsbImage(asset: mode.hero, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 14),
            Text(mode.description, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5, height: 1.5)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(height: 106, child: NwsbImage(asset: mode.secondary, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mode.prompts.map((prompt) => ActionChip(
                    label: Text(prompt),
                    onPressed: _loading ? null : () => _send(prompt),
                    backgroundColor: const Color(0xD9141822),
                    side: const BorderSide(color: Color(0x2BFFFFFF)),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                  )).toList(),
            ),
            const SizedBox(height: 18),
            Container(
              constraints: const BoxConstraints(minHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xB3080C16),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      controller: _scroll,
                      itemCount: _messages.length,
                      itemBuilder: (_, index) {
                        final message = _messages[index];
                        final user = message['role'] == 'user';
                        return Align(
                          alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            margin: const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                            decoration: BoxDecoration(
                              color: user ? Colors.white : const Color(0xD91B2230),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['content'] ?? '',
                              style: TextStyle(color: user ? NwsbColors.ink : Colors.white, fontSize: 12.5, height: 1.4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: mode == AssistantMode.coach ? 'Tell your coach what you need…' : 'Ask for help…',
                            hintStyle: const TextStyle(color: Color(0x73FFFFFF), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0x99141A26),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loading ? null : _send,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: _loading
                              ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2, color: NwsbColors.ink))
                              : const Icon(Icons.arrow_upward, color: NwsbColors.ink, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
