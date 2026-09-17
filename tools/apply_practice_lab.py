# Idempotent Practice Lab materializer used by the verified Flutter build.
# Trigger marker: practice-build-v2
import base64
import gzip
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
      barrierColor: Colors.black.withOpacity(.76),
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

player.write_text(text)
print('Practice Lab UI materialized and wired.')
