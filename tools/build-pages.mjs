/**
 * Assemble the static website output for Cloudflare Pages.
 *
 * The repository keeps the original video files for GitHub/archive access, but
 * Cloudflare Pages rejects files larger than 25 MiB. The two oversized web
 * videos are served from the public R2 media domain and are intentionally
 * omitted from this deployment output.
 */
import { cp, mkdir, readdir, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, '.pages-dist');
const omitted = new Set([
  'assets/videos/55c1ef594a28bcc7_grok_video_2026-07-31-20-42-12_lcwctk.mp4',
  'assets/videos/7b89d3bbdf9ef897_grok_video_2026-07-31-22-41-02_fy7mnv.mp4',
]);
const skippedDirectories = new Set([
  '.git',
  '.github',
  '.pages-dist',
  '.wrangler',
  'flutter_app',
  'node_modules',
]);

await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });

async function copyTree(relative) {
  const top = relative.split(path.sep)[0];
  if (skippedDirectories.has(top) || omitted.has(relative)) return 0;

  const source = path.join(root, relative);
  const target = path.join(out, relative);
  const entries = await readdir(source, { withFileTypes: true }).catch(() => null);
  if (!entries) {
    await cp(source, target, { force: true });
    return 1;
  }

  await mkdir(target, { recursive: true });
  let count = 0;
  for (const entry of entries) {
    count += await copyTree(path.join(relative, entry.name));
  }
  return count;
}

const entries = await readdir(root, { withFileTypes: true });
let copied = 0;
for (const entry of entries) copied += await copyTree(entry.name);

console.log(`Cloudflare Pages output ready: ${copied} files copied to ${path.relative(root, out)}`);
console.log(`Omitted oversized R2-served videos: ${omitted.size}`);
