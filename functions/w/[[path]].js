/* GET /w/<word>?r=<code> — a personal NowssB Reference link.
   Shows a small preview page, counts the open, and sends the visitor to
   Google Play with the code in the install referrer so the app can attach
   it at sign-up (first valid link in 30 days, locked at first purchase). */
import { serviceAccount, sha256Hex } from '../_lib/server.js';
import { FsDb } from '../_lib/economy/fsdb.js';
import { loadEconomy } from '../_lib/economy/config.js';
import { countOpen } from '../_lib/economy/reference.js';

const PKG = 'com.nowssb.app';
const esc = (s) => String(s || '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

export async function onRequestGet({ request, env, params }) {
  const url = new URL(request.url);
  const code = String(url.searchParams.get('r') || '').toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 20);
  const slug = (Array.isArray(params.path) ? params.path : [params.path || '']).join('/').replace(/[^a-z0-9/-]/gi, '').slice(0, 60);
  let title = slug && slug !== 'app' ? slug.replace(/-/g, ' ') : 'NowssB';
  if (code && (serviceAccount(env) || env.FIRESTORE_EMULATOR_HOST)) {
    try {
      const db = await FsDb.fromEnv(env);
      const cfg = await loadEconomy(db);
      const r = await countOpen(db, cfg, code, await sha256Hex('ip|' + (request.headers.get('CF-Connecting-IP') || '')));
      if (r.ok && r.title) title = r.title;
    } catch (e) { /* the page still works */ }
  }
  const referrer = encodeURIComponent(`utm_source=nowssb_ref&utm_medium=link&nwsb_ref=${code}&nwsb_item=${slug}`);
  const play = `https://play.google.com/store/apps/details?id=${PKG}&referrer=${referrer}`;
  const intent = `intent://nowssb.com/w/${esc(slug)}?r=${code}#Intent;scheme=https;package=${PKG};S.browser_fallback_url=${encodeURIComponent(play)};end`;
  const T = esc(title.charAt(0).toUpperCase() + title.slice(1));
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${T} · NowssB</title><meta property="og:title" content="${T} · NowssB"><meta property="og:description" content="A friend shared ${T} with you. Your first three words are 10% off.">
<meta property="og:image" content="https://nowssb.com/assets/icons/app-icon-512.png"><meta name="robots" content="noindex">
<style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:radial-gradient(circle at 50% 20%,#2a2416,#0b0b0d 60%);color:#f5ecd7;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.c{max-width:360px;margin:24px;padding:28px;border-radius:24px;background:rgba(255,255,255,.06);border:1px solid rgba(214,180,106,.35);backdrop-filter:blur(14px);text-align:center}
h1{font-weight:600;letter-spacing:.5px;margin:.2em 0}p{color:#cfc5ae;line-height:1.5}a.b{display:block;margin-top:14px;padding:14px;border-radius:999px;background:linear-gradient(135deg,#f3d58a,#b88a2e);color:#1a1408;text-decoration:none;font-weight:700}
small{display:block;margin-top:16px;color:#8d846f;font-size:11px}</style></head><body><div class="c">
<div style="font-size:12px;letter-spacing:3px;color:#d6b46a">NOWSSB REFERENCE</div><h1>${T}</h1>
<p>A friend shared this with you. Join with their link: your first three words are 10% off, your first plan period 20% off, and a welcome set of 100 coins and a Rare scratch card waits for you.</p>
<a class="b" href="${play}" id="go">Get NowssB on Google Play</a><a class="b" style="background:transparent;color:#f3d58a;border:1px solid #d6b46a" href="${intent}">Open in the app</a>
<small>Code ${esc(code) || '—'} · Rewards follow the NowssB Reference rules. Coins have no cash value.</small></div></body></html>`;
  return new Response(html, { headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' } });
}
