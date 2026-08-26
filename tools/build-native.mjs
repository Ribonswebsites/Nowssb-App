/* ══════════════════════════════════════════════════════════════════════
   Assemble www/ — the web files that go inside the Android app.

   Capacitor copies whatever is in webDir into the APK, verbatim, and
   whatever ends up there is shipped to every phone that installs the app
   and is extractable from the APK by anybody who cares to look. So this is
   not a copy step, it is a boundary: the studio must not cross it.

   The studio is protected on the server either way — firestore.rules
   decides every admin write from admins/<uid>, and /api/push checks a real
   Firebase ID token — so a copy of admin.html in an APK would not let
   anybody do anything. It would still be handing out the map, and there is
   no reason to. It stays out, and the check at the bottom of this file
   fails the build rather than trusting the list above it.

   Run with `npm run build:native`. Everything it writes is disposable;
   www/ is regenerated from the repository every time.
   ══════════════════════════════════════════════════════════════════════ */
import { readdir, mkdir, rm, copyFile, stat, readFile, writeFile } from 'node:fs/promises';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const OUT  = join(ROOT, 'www');

/* Never copied. Directories first, then a predicate for the file names. */
/* flutter_app is the native port, not the website. It carries its own copy
   of assets/video — 138 MB put there by tools/flutter-assets.mjs — and
   sweeping that into the web bundle tripled it, from 149 MB to 486 MB, with
   every clip in twice. The Flutter app builds from its own directory and
   nothing in www/ ever reads from it. */
const SKIP_DIRS = new Set(['.git', '.claude', 'node_modules', 'www', 'android', 'ios', 'tools', 'functions', 'flutter_app']);

/* Skipped by path rather than by name, for directories that are fine on the
   website and wrong inside an APK.

   assets/banners is 71 MB of PNG and WebP that nothing in the app actually
   asks for — every banner the app draws comes from Cloudinary, and a search
   across the HTML, CSS and JS finds no reference to this directory at all.
   On a CDN that costs nothing because it is never requested; bundled into an
   app it is 71 MB of the download, which is most of it. If something starts
   using these, take this line out and the build will carry them again. */
const SKIP_PATHS = new Set([join('assets', 'banners')]);

/* The studio, in every form it takes. Matched on the name rather than a
   fixed list so a new admin-something.html cannot be added later and
   quietly ship. */
const isStudio = (name) => /^admin[-.]/i.test(name) || name === 'admin.html';

/* Server-side or repository-side files with nothing to do inside an app. */
const SKIP_FILES = new Set([
  'worker.js',              // Cloudflare worker
  'firestore.rules',        // pasted into the Firebase console, not served
  'GUIDE.md', 'CAPACITOR.md', 'LICENSE', 'README.md',
  'package.json', 'package-lock.json', 'capacitor.config.json',
  'sitemap.xml', 'robots.txt',   // search-engine files; an APK has no crawler
  'fetch-nowssb-v2.html',        // scratch page
  'nowssb-github-upload.zip',
  /* The studio door — five taps on the footer to open admin.html. The page
     it opens is not in the bundle, so the door would only lead somewhere
     broken; and a door nobody can see is still worth not shipping. Its
     <script> tag is taken out of index.html below. */
  'part070.js',
]);

const skipFile = (name) =>
  isStudio(name) || SKIP_FILES.has(name) || name.endsWith('.zip') || name.startsWith('.');

async function walk(dir, onFile) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      if (SKIP_PATHS.has(relative(ROOT, full))) continue;
      await walk(full, onFile);
    } else if (entry.isFile()) {
      if (skipFile(entry.name)) continue;
      await onFile(full);
    }
  }
}

await rm(OUT, { recursive: true, force: true });
await mkdir(OUT, { recursive: true });

let copied = 0, bytes = 0;
await walk(ROOT, async (full) => {
  const rel = relative(ROOT, full);
  const dest = join(OUT, rel);
  await mkdir(join(dest, '..'), { recursive: true });
  await copyFile(full, dest);
  copied++;
  bytes += (await stat(full)).size;
});

/* index.html still asks for the studio door, which reaches for an
   admin.html that is deliberately not in the bundle. Take the tag out here
   rather than from the source, because the website wants it. */
const indexPath = join(OUT, 'index.html');
let html = await readFile(indexPath, 'utf8');
const before = html;
html = html.replace(/^[ \t]*<script src="app\/js\/part070\.js[^"]*"><\/script>.*\r?\n/m,
  '<!-- part070.js (studio door) is not shipped in the Android app. -->\n');
if (html === before) {
  console.warn('! Could not find the part070.js tag to strip — check tools/build-native.mjs.');
}
await writeFile(indexPath, html);

/* The check that actually decides. Walk what was written, not what we
   meant to write. */
const leaked = [];
await (async function verify(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) { await verify(full); continue; }
    if (isStudio(entry.name) || entry.name === 'part070.js') leaked.push(relative(OUT, full));
  }
})(OUT);

if (leaked.length) {
  console.error('\nBUILD FAILED — the studio would have shipped inside the app:');
  for (const f of leaked) console.error('  ' + f);
  process.exit(1);
}
if (/admin\.html/.test(html)) {
  console.error('\nBUILD FAILED — www/index.html still references admin.html.');
  process.exit(1);
}

/* Every <div> must have its </div>. This is here because it has now gone
   wrong twice: an edit that cuts a block out of index.html and leaves one
   stray closer behind does not throw, does not 404 and does not show up in
   the console — the browser silently closes the home's wrapper early and
   every section below it piles on top of the ones above. It is invisible
   until you look at the page, and by then it has shipped. Counting is
   crude (it does not know about comments or strings) but it is exact
   enough to catch the only mistake that actually happens: a missing or
   duplicated closer. */
const divOpen = (html.match(/<div\b/g) || []).length;
const divClose = (html.match(/<\/div>/g) || []).length;
if (divOpen !== divClose) {
  console.error('\nBUILD FAILED — index.html has unbalanced <div> tags: ' +
                divOpen + ' opened, ' + divClose + ' closed (' +
                (divClose > divOpen ? divClose - divOpen + ' too many closers'
                                    : divOpen - divClose + ' never closed') + ').');
  console.error('Sections below the break will render on top of each other.');
  process.exit(1);
}
const cOpen = (html.match(/<!--/g) || []).length;
const cClose = (html.match(/-->/g) || []).length;
if (cOpen !== cClose) {
  console.error('\nBUILD FAILED — index.html has unbalanced HTML comments: ' +
                cOpen + ' <!--, ' + cClose + ' -->.');
  process.exit(1);
}

console.log('www/ built — ' + copied + ' files, ' + (bytes / 1048576).toFixed(1) + ' MB.');
console.log('Studio excluded and verified. Next: npx cap sync   (both platforms)');
