/* ══════════════════════════════════════════════════════════════════════
   Every image and every video the app uses, as a list.

   Right now they all live on Cloudinary and arrive over the network. That
   is right for a website and wrong for an app you download once: the ask
   is that after the install, the pictures and the clips are already on the
   phone. Flutter does that by declaring assets in pubspec.yaml and reading
   them from the bundle — but first somebody has to know what they all are,
   and they are currently spread across index.html, seventy JS files and
   three stylesheets as bare URLs.

   This finds them. It is the input to three separate things:

     • pubspec.yaml's asset list, for the Flutter port
     • the download that fetches them all so they can be committed
     • a url → local-path map, so the port can rewrite a remote URL to a
       bundled one without anybody editing seventy files by hand

   Usage
   -----
     node tools/asset-manifest.mjs              write assets/media-manifest.json
     node tools/asset-manifest.mjs --download   also fetch every file into
                                                assets/media/
     node tools/asset-manifest.mjs --dart       also write the Dart map

   Naming is derived from the URL, not from a counter, so running it again
   produces the same names and a file already downloaded is skipped. That
   matters: the download is a few hundred MB and should be resumable.
   ══════════════════════════════════════════════════════════════════════ */
import { readdir, readFile, writeFile, mkdir, stat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { join, relative, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const OUT_DIR = join(ROOT, 'assets');
const MEDIA_DIR = join(OUT_DIR, 'media');

const SKIP_DIRS = new Set(['.git', '.claude', 'node_modules', 'www', 'android', 'ios', 'assets']);
const SCAN_EXT = new Set(['.html', '.js', '.mjs', '.css', '.json']);

/* Bare http(s) URLs, stopped at the first character that cannot be in one.
   Deliberately greedy about hosts — the app uses six Cloudinary clouds and
   may use more tomorrow — and strict about extensions, because a link to a
   documentation page is not an asset. */
const URL_RE = /https?:\/\/[^\s'"`)\\<>]+/g;

const IMAGE_EXT = new Set(['.png', '.jpg', '.jpeg', '.webp', '.gif', '.svg', '.avif']);
const VIDEO_EXT = new Set(['.mp4', '.webm', '.mov', '.m4v']);
const AUDIO_EXT = new Set(['.mp3', '.m4a', '.wav', '.ogg', '.webm']);

function kindOf(url) {
  /* Cloudinary puts the kind in the path, which is more reliable than the
     extension — f_auto URLs often carry the wrong one or none at all. */
  if (/\/video\/upload\//.test(url)) return 'video';
  if (/\/image\/upload\//.test(url)) return 'image';
  const e = extname(new URL(url).pathname).toLowerCase();
  if (VIDEO_EXT.has(e)) return 'video';
  if (IMAGE_EXT.has(e)) return 'image';
  if (AUDIO_EXT.has(e)) return 'audio';
  return null;
}

/* A stable, readable, collision-proof file name: the last meaningful part
   of the URL for a human, plus eight bytes of the whole URL so two clips
   that happen to share a name cannot overwrite each other. */
function localName(url, kind) {
  const p = new URL(url).pathname;
  const base = (p.split('/').pop() || 'asset').replace(/\.[a-z0-9]+$/i, '').replace(/[^a-zA-Z0-9._-]/g, '-').slice(-48);
  const hash = createHash('sha1').update(url).digest('hex').slice(0, 8);
  let ext = extname(p).toLowerCase();
  if (!ext || ext.length > 6) ext = kind === 'video' ? '.mp4' : kind === 'audio' ? '.mp3' : '.jpg';
  return `${kind}/${base}-${hash}${ext}`;
}

async function walk(dir, onFile) {
  for (const e of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, e.name);
    if (e.isDirectory()) {
      if (SKIP_DIRS.has(e.name)) continue;
      await walk(full, onFile);
    } else if (e.isFile() && SCAN_EXT.has(extname(e.name).toLowerCase())) {
      await onFile(full);
    }
  }
}

const found = new Map();   // url -> { kind, local, refs: Set<file> }

await walk(ROOT, async (file) => {
  const text = await readFile(file, 'utf8');
  const rel = relative(ROOT, file);
  for (const raw of text.match(URL_RE) || []) {
    /* Trailing punctuation from the surrounding markup, not the URL. */
    const url = raw.replace(/[.,;:]+$/, '');
    let kind;
    try { kind = kindOf(url); } catch (e) { continue; }
    if (!kind) continue;
    if (!found.has(url)) found.set(url, { kind, local: localName(url, kind), refs: new Set() });
    found.get(url).refs.add(rel);
  }
});

const entries = [...found.entries()]
  .map(([url, v]) => ({ url, kind: v.kind, local: v.local, refs: [...v.refs].sort() }))
  .sort((a, b) => (a.kind + a.local).localeCompare(b.kind + b.local));

const counts = entries.reduce((a, e) => (a[e.kind] = (a[e.kind] || 0) + 1, a), {});

await mkdir(OUT_DIR, { recursive: true });
await writeFile(join(OUT_DIR, 'media-manifest.json'),
  JSON.stringify({ generated: new Date().toISOString(), counts, assets: entries }, null, 2));

console.log('assets/media-manifest.json —',
  Object.entries(counts).map(([k, n]) => `${n} ${k}${n === 1 ? '' : 's'}`).join(', '));

/* ── The Dart map, for the Flutter port ──────────────────────────────
   Every screen in the port that has a URL in it looks it up here and gets
   a bundled path, so the port never has to care which of the six
   Cloudinary clouds something came from. Anything not in the map falls
   through to the network, which is the right behaviour for a URL added
   after the last build. ── */
if (process.argv.includes('--dart')) {
  const lines = entries.map(e => `  ${JSON.stringify(e.url)}: 'assets/media/${e.local}',`);
  await writeFile(join(OUT_DIR, 'media_assets.dart'),
    '// GENERATED by tools/asset-manifest.mjs — do not edit by hand.\n' +
    '//\n' +
    '// Remote URL to the copy bundled inside the app. Use nowssbAsset(url):\n' +
    '// a URL that is bundled is read from the bundle, and one that is not\n' +
    '// falls through to the network rather than failing.\n\n' +
    'const Map<String, String> kNowssbMedia = {\n' + lines.join('\n') + '\n};\n\n' +
    'String? nowssbAsset(String url) => kNowssbMedia[url];\n');
  console.log('assets/media_assets.dart — ' + entries.length + ' entries');
}

/* ── The download ────────────────────────────────────────────────────
   Sequential on purpose. This is a few hundred megabytes off a CDN and
   there is no hurry; hammering it with fifty parallel requests is how you
   get rate-limited halfway through. Already-downloaded files are skipped,
   so stopping it and running it again picks up where it left off. ── */
if (process.argv.includes('--download')) {
  let got = 0, skipped = 0, failed = 0, bytes = 0;
  for (const e of entries) {
    const dest = join(MEDIA_DIR, e.local);
    await mkdir(join(dest, '..'), { recursive: true });
    try { const s = await stat(dest); if (s.size > 0) { skipped++; bytes += s.size; continue; } } catch (err) {}
    try {
      const r = await fetch(e.url);
      if (!r.ok) { console.warn('  ' + r.status + '  ' + e.url); failed++; continue; }
      const buf = Buffer.from(await r.arrayBuffer());
      await writeFile(dest, buf);
      got++; bytes += buf.length;
      if (got % 10 === 0) console.log('  ' + got + ' downloaded…');
    } catch (err) {
      console.warn('  failed  ' + e.url + ' — ' + err.message);
      failed++;
    }
  }
  console.log(`downloaded ${got}, already had ${skipped}, failed ${failed} — ${(bytes / 1048576).toFixed(1)} MB in assets/media/`);
  if (failed) console.log('Run it again to retry the failures; what succeeded is kept.');
}
