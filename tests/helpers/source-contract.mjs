// Shared helpers for the source-contract tests in tests/*.test.mjs.
// Not a test file itself (the runner glob is tests/*.test.mjs).
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { inflateSync } from 'node:zlib';

const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** The ?v= cache-buster that `html` uses for `file` (e.g. 'part076.js'). */
export function cacheBustVersion(html, file) {
  const m = html.match(new RegExp(`${escape(file)}\\?v=(\\d+)`));
  assert.ok(m, `${file} must be loaded with a ?v= cache-buster`);
  return Number(m[1]);
}

/**
 * Cache-busters only ever move forward. Pin the version that shipped a fix as
 * a floor rather than an exact value, so later unrelated bumps do not break
 * the contract while a stale-base revert (version going backwards) still does.
 */
export function assertCacheBustAtLeast(html, file, min) {
  const v = cacheBustVersion(html, file);
  assert.ok(v >= min, `${file}?v=${v} must be >= ${min} (a lower value means a stale-base revert)`);
}

/** Text of `class Name` up to the next top-level Dart class. */
export function dartClass(source, name) {
  const start = source.indexOf(`class ${name} `);
  assert.ok(start >= 0, `class ${name} must exist`);
  const next = source.indexOf('\nclass ', start + 1);
  return source.slice(start, next < 0 ? undefined : next);
}

/**
 * sha256 of a non-interlaced 8-bit RGB/RGBA PNG's decoded pixels. Survives
 * lossless recompression (oxipng etc.) but changes on any lossy re-encode,
 * resize or edit — which is what "original artwork bytes" actually means.
 */
export function pngPixelSha256(path) {
  const buf = readFileSync(path);
  assert.equal(buf.toString('latin1', 1, 4), 'PNG', `${path} must be a PNG`);
  let off = 8; let width = 0; let height = 0; let channels = 0; const idat = [];
  while (off < buf.length) {
    const len = buf.readUInt32BE(off);
    const type = buf.toString('latin1', off + 4, off + 8);
    const data = buf.subarray(off + 8, off + 8 + len);
    if (type === 'IHDR') {
      width = data.readUInt32BE(0); height = data.readUInt32BE(4);
      const depth = data[8]; const colour = data[9]; const interlace = data[12];
      assert.equal(depth, 8, `${path}: only 8-bit PNGs supported`);
      assert.equal(interlace, 0, `${path}: interlaced PNGs not supported`);
      channels = { 2: 3, 6: 4 }[colour];
      assert.ok(channels, `${path}: only RGB/RGBA PNGs supported`);
    } else if (type === 'IDAT') idat.push(data);
    else if (type === 'IEND') break;
    off += 12 + len;
  }
  const raw = inflateSync(Buffer.concat(idat));
  const stride = width * channels;
  const out = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const src = y * (stride + 1) + 1;
    const row = y * stride; const prev = row - stride;
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? out[row + x - channels] : 0;
      const b = y > 0 ? out[prev + x] : 0;
      const c = x >= channels && y > 0 ? out[prev + x - channels] : 0;
      let p = raw[src + x];
      if (filter === 1) p += a;
      else if (filter === 2) p += b;
      else if (filter === 3) p += (a + b) >> 1;
      else if (filter === 4) {
        const pa = Math.abs(b - c); const pb = Math.abs(a - c); const pc = Math.abs(a + b - 2 * c);
        p += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
      out[row + x] = p & 0xff;
    }
  }
  return { width, height, sha256: createHash('sha256').update(out).digest('hex') };
}
