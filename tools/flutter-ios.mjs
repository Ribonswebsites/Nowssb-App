import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const plist = join(root, 'flutter_app', 'ios', 'Runner', 'Info.plist');
if (!existsSync(plist)) {
  console.error(`missing ${plist} — run flutter create first`);
  process.exit(1);
}

let content = readFileSync(plist, 'utf8');
const key = '<key>NSMicrophoneUsageDescription</key>';
if (!content.includes(key)) {
  const marker = '</dict>';
  const at = content.lastIndexOf(marker);
  if (at < 0) throw new Error('Info.plist: no closing dict element');
  content = content.slice(0, at) +
    `\t${key}\n\t<string>NowssB uses the microphone to score your pronunciation.</string>\n` +
    content.slice(at);
  writeFileSync(plist, content);
  console.log('added iOS microphone permission');
} else {
  console.log('iOS microphone permission already present');
}
