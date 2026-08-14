// Writes the content the Flutter app ships with.
//
// The four Firestore documents are the live source of truth, but an app has
// to draw something on its very first launch — before Firestore has
// answered, on a phone with no signal, in the seconds after install. The
// website solves this with a shipped list in JavaScript; this script turns
// that same list into JSON the Flutter bundle can read.
//
// It EVALUATES the declarations out of the web app rather than restating
// them, which is the whole point: there is one list of words in this
// repository and it is the one in app/js/part004.js. Retyping it into Dart
// would mean two, and two lists drift.
//
//   node tools/export-content.mjs
//
// Run it after changing the shipped words or books. The Firestore documents
// are unaffected — a published edit still overrides all of this at runtime.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = join(root, 'flutter_app', 'assets', 'content');

/** Pull one top-level array literal out of a file and evaluate it.
 *  Brace-matched rather than regex-matched, because these entries contain
 *  apostrophes, brackets and commas inside their strings. */
function arrayFrom(file, decl) {
  const src = readFileSync(join(root, file), 'utf8');
  const at = src.indexOf(decl);
  if (at < 0) throw new Error(`${decl} not found in ${file}`);
  const open = src.indexOf('[', at);
  if (open < 0) throw new Error(`no array after ${decl} in ${file}`);

  let depth = 0, i = open, inStr = null, esc = false;
  for (; i < src.length; i++) {
    const c = src[i];
    if (inStr) {
      if (esc) esc = false;
      else if (c === '\\') esc = true;
      else if (c === inStr) inStr = null;
      continue;
    }
    if (c === '"' || c === "'" || c === '`') { inStr = c; continue; }
    if (c === '[') depth++;
    else if (c === ']') { depth--; if (depth === 0) break; }
  }
  if (depth !== 0) throw new Error(`unbalanced array after ${decl} in ${file}`);

  return vm.runInNewContext('(' + src.slice(open, i + 1) + ')');
}

/** The normaliser from app/js/part073.js, applied here so what ships is
 *  already in the shape the Dart model expects. Same rules, same order —
 *  if this and Word.from ever disagree, this is the one that is wrong. */
function normWord(w) {
  if (!w || typeof w.word !== 'string' || !w.word.trim()) return null;

  let parts = Array.isArray(w.parts)
    ? w.parts.filter(Boolean).slice(0, 5).map((p) => {
        if (typeof p === 'string') p = { roman: p };
        return {
          roman: String(p.roman || '').trim(),
          deva: String(p.deva || '').trim(),
          hold: Number(p.hold) > 0 ? Number(p.hold) : 1.5,
          say: String(p.say || '').trim(),
          audio: String(p.audio || '').trim(),
        };
      }).filter((p) => p.roman || p.deva)
    : [];

  if (!parts.length && Array.isArray(w.syllables)) {
    parts = w.syllables.slice(0, 5).map((s) => ({
      roman: String(s), deva: '', hold: 1.5, say: '', audio: '',
    }));
  }

  return {
    key: String(w.key || w.word).trim().toLowerCase().replace(/\s+/g, '-'),
    word: String(w.word).trim(),
    deva: String(w.deva || '').trim(),
    translit: String(w.translit || '').trim(),
    phonetic: String(w.phonetic || parts.map((p) => p.roman).join(' · ')).trim(),
    parts,
    syllables: parts.map((p) => p.roman || p.deva),
    audioMale: String(w.audioMale || '').trim(),
    audioFemale: String(w.audioFemale || '').trim(),
    organ: String(w.organ || '').trim(),
    origin: String(w.origin || 'Natural Origin').trim(),
    benefit: String(w.benefit || '').trim(),
    meaning: String(w.meaning || '').trim(),
    mouthPos: String(w.mouthPos || '').trim(),
    resonance: String(w.resonance || '').trim(),
    mistake: String(w.mistake || '').trim(),
    tip: String(w.tip || '').trim(),
    categories: Array.isArray(w.categories) ? w.categories.map(String) : [],
    gender: ['M', 'F', 'both'].includes(w.gender) ? w.gender : 'both',
    time: ['morning', 'evening', 'night', 'any'].includes(w.time) ? w.time : 'any',
    price: Number(w.price) || 0,
    img: String(w.img || '').trim(),
  };
}

mkdirSync(out, { recursive: true });

const library = arrayFrom('app/js/part004.js', 'const MASTER_WORD_LIBRARY')
  .map(normWord)
  .filter(Boolean);

const books = arrayFrom('app/js/part017.js', 'var EB_BOOKS')
  .filter((b) => b && typeof b.key === 'string' && typeof b.title === 'string' && b.key && b.title);

function write(name, items) {
  writeFileSync(join(out, name), JSON.stringify({ items }, null, 1) + '\n');
  console.log(`  ${name.padEnd(16)} ${String(items.length).padStart(4)} items`);
}

console.log('flutter_app/assets/content/');
write('library.json', library);
write('books.json', books);
// The shelves and the Meaning Store catalogue are studio-authored from the
// start — nothing is hardcoded for them on the web either — so what ships
// is empty and Firestore fills it. Written anyway: ContentStore reads four
// files and a missing one is a log line on every launch.
write('words.json', []);
write('meanings.json', []);
