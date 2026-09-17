# Idempotent Practice Lab materializer used by the verified Flutter build.
# Trigger marker: practice-build-v4
import base64
import gzip
import re
from pathlib import Path

root = Path('flutter_app')
payload_file = Path('tools/practice_overlay.gz.b64')
overlay_file = root / 'lib/screens/practice_overlay.dart'

if not overlay_file.exists():
    if not payload_file.exists():
        raise SystemExit('Practice Lab payload is missing')
    overlay_file.write_bytes(gzip.decompress(base64.b64decode(payload_file.read_text().strip())))

player = root / 'lib/screens/practice_player.dart'
text = player.read_text()

imp = "import 'practice_overlay.dart';\n"
anchor = "import 'player_dial.dart';\n"
if imp not in text:
    if anchor not in text:
        raise SystemExit('Practice Lab import anchor not found')
    text = text.replace(anchor, anchor + imp, 1)

old = '                        onPractice: _prepareAndPlay,'
if old in text:
    text = text.replace(old, '                        onPractice: _openPracticeLab,', 1)

method = '''  void _openPracticeLab() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (_) => PracticeLabSheet(
        word: _word,
        accent: _theme.accent,
        onSpeak: _prepareAndPlay,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

'''
marker = '  void _openSettings() {'
if '_openPracticeLab()' not in text:
    if marker not in text:
        raise SystemExit('Practice Lab insertion marker not found')
    text = text.replace(marker, method + marker, 1)
else:
    text = re.sub(
        r"  void _openPracticeLab\(\) \{.*?\n  \}\n\n(?=  void _openSettings\(\) \{)",
        method,
        text,
        count=1,
        flags=re.S,
    )

info_replacement = '''  void _openInfo() {
    _openNotes();
  }

'''
text = re.sub(
    r"  void _openInfo\(\) \{.*?\n  \}\n\n(?=  void _openNotes\(\) \{)",
    info_replacement,
    text,
    count=1,
    flags=re.S,
)

notes = '''  void _openNotes() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      builder: (sheetContext) => _PracticeNotesSheet(
        word: _word,
        accent: _theme.accent,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

'''
text = re.sub(
    r"  void _openNotes\(\) \{.*?\n  \}\n\n(?=  void _openAuraClock\(\) \{)",
    notes,
    text,
    count=1,
    flags=re.S,
)

notes_class = r'''
class _PracticeNotesSheet extends StatelessWidget {
  const _PracticeNotesSheet({
    required this.word,
    required this.accent,
    required this.onClose,
  });

  final Word word;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 650),
              decoration: BoxDecoration(
                color: const Color(0xCC080A0E),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: Colors.white.withOpacity(.16)),
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(.16), blurRadius: 70),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.24),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'NOTES',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.word,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.meaning,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    _noteBlock('PRONUNCIATION', word.tip.isEmpty
                        ? 'Follow the reference sound slowly and keep the resonance steady through the hold.'
                        : word.tip),
                    if (word.organ.isNotEmpty)
                      _noteBlock('BODY FOCUS', word.organ),
                    if (word.parts.isNotEmpty)
                      _noteBlock(
                        'SOUND MAP',
                        word.parts.map((p) => p.roman.isNotEmpty ? p.roman : p.deva).join('  ·  '),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.045),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Play the reference. Speak naturally. The practice engine compares your spoken word with the target sound.',
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteBlock(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.035),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.075)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            Text(body, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

'''
if '_PracticeNotesSheet extends StatelessWidget' not in text:
    text += notes_class

# speech_to_text 7.4.0 exposes SpeechListenOptions as a regular constructor;
# remove const so the app remains compatible with the repository's Dart 3.4 floor.
text = text.replace(
    'listenOptions: const stt.SpeechListenOptions(',
    'listenOptions: stt.SpeechListenOptions(',
)

player.write_text(text)
print('Practice Lab UI materialized, wired, notes upgraded, and speech options normalized.')
