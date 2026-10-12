/* Admin media lifecycle (CA-2): delete old R2 objects and orphaned
   ui_overrides docs when the owner replaces media or deletes a section/page.

   Safety rules (all server-side):
   - Only keys under the admin upload prefixes (see upload-url.js AREAS) and
     only URLs on R2_PUBLIC_BASE_URL. Bundled assets / other hosts: refused.
   - Reference check across Firestore before any delete: ui_overrides,
     ui_layouts, ui_bin, words, wordsPrivate, requests, ui_history. History
     rows whose target is one of the slots being replaced/purged right now are
     the undo trail the admin agreed to break (confirm in UI); history of any
     OTHER target still blocks the delete.
   - A collection that hits the scan limit makes the check "unsure": nothing
     is deleted (fail safe).
   - Admin-only (gate in admin_route.js) and audit-logged (adminLog row per call).

   deps.r2Del(key) deletes one object; deps.r2 (prefix) lists; deps.mediaBase
   is R2_PUBLIC_BASE_URL. */
import { AdminError } from './admin_core.js';

export const MEDIA_PREFIXES = ['ui/', 'images/words/', 'video/words/', 'audio/'];
const REF_COLLECTIONS = ['ui_overrides', 'ui_layouts', 'ui_bin', 'words', 'wordsPrivate', 'requests', 'ui_history'];
const SCAN_LIMIT = 5000;
const bad = (m, code = 'invalid') => new AdminError(400, m, code);
const str = (v, max = 200) => String(v == null ? '' : v).trim().slice(0, max);

/** R2 key for a public URL, or '' when it is not one of ours / not allowed. */
export function mediaKeyOf(url, base) {
  const u = String(url || '').trim();
  const b = String(base || '').replace(/\/+$/, '');
  if (!b || !u.startsWith(b + '/')) return '';
  let rest = u.slice(b.length + 1).split(/[?#]/)[0];
  try { rest = rest.split('/').map(decodeURIComponent).join('/'); } catch (e) { return ''; }
  if (!rest || rest.includes('..') || rest.includes('//') || rest.endsWith('/')) return '';
  if (!MEDIA_PREFIXES.some((p) => rest.startsWith(p))) return '';
  return rest;
}

/** Every http(s) string anywhere inside a value. */
export function urlsIn(v, out = new Set()) {
  if (typeof v === 'string') { if (/^https?:\/\//.test(v)) out.add(v); }
  else if (Array.isArray(v)) v.forEach((x) => urlsIn(x, out));
  else if (v && typeof v === 'object') Object.values(v).forEach((x) => urlsIn(x, out));
  return out;
}

const encKey = (k) => k.split('/').map(encodeURIComponent).join('/');

/** Loads the reference corpus once: [{ col, id, target, text }]. */
async function corpus(db) {
  const rows = [];
  let unsure = [];
  for (const col of REF_COLLECTIONS) {
    const got = await db.query({ collection: col, limit: SCAN_LIMIT }).catch(() => null);
    if (got == null) { unsure.push(col); continue; }
    if (got.length >= SCAN_LIMIT) unsure.push(col);
    for (const r of got) rows.push({ col, id: r.id, target: String((r.data && (r.data.target || r.data.slot)) || ''), text: JSON.stringify(r.data || {}) });
  }
  return { rows, unsure };
}

function refsFor(key, cp, { ignoreTargets = new Set(), ignoreDocs = new Set() } = {}) {
  const enc = encKey(key);
  return cp.rows.filter((r) => {
    if (ignoreDocs.has(r.col + '/' + r.id)) return false;
    if (r.col === 'ui_history' && ignoreTargets.has(r.target)) return false;
    return r.text.includes(key) || r.text.includes(enc);
  }).map((r) => r.col + '/' + r.id);
}

/** Core: try deleting each URL; returns per-URL result. Never throws per item. */
export async function gcUrls(deps, urls, { targets = [], ignoreDocs = [], dryRun = false } = {}) {
  const base = deps.mediaBase || '';
  const results = [];
  const keys = new Map();
  for (const u of new Set(urls)) {
    const key = mediaKeyOf(u, base);
    if (!key) { results.push({ url: u, status: 'outside' }); continue; }
    keys.set(key, u);
  }
  if (!keys.size) return results;
  if (!deps.r2Del && !dryRun) {
    for (const [key, u] of keys) results.push({ url: u, key, status: 'r2_off' });
    return results;
  }
  const cp = await corpus(deps.db);
  const opt = { ignoreTargets: new Set(targets), ignoreDocs: new Set(ignoreDocs) };
  for (const [key, u] of keys) {
    if (cp.unsure.length) { results.push({ url: u, key, status: 'unsure', unsure: cp.unsure }); continue; }
    const refs = refsFor(key, cp, opt);
    if (refs.length) { results.push({ url: u, key, status: 'referenced', refs: refs.slice(0, 10) }); continue; }
    if (dryRun) { results.push({ url: u, key, status: 'would_delete' }); continue; }
    try { await deps.r2Del(key); results.push({ url: u, key, status: 'deleted' }); }
    catch (e) { results.push({ url: u, key, status: 'error', error: String((e && e.message) || e).slice(0, 120) }); }
  }
  return results;
}

function logOps(deps, action, target, detail) {
  const { db, admin } = deps;
  return [
    { op: 'create', path: `adminLog/${db.newId()}`, data: { action, target, detail, uid: admin.uid, email: admin.email || '', via: 'console', at: null }, serverTime: ['at'] },
    { op: 'create', path: `activity/${db.newId()}`, data: { type: 'admin', action, uid: target, by: admin.email || admin.uid, summary: action, at: null }, serverTime: ['at'] },
  ];
}
const summary = (res) => res.reduce((m, r) => ({ ...m, [r.status]: (m[r.status] || 0) + 1 }), {});

/** media-gc { urls:[...], targets:[slot keys just replaced] } — after a replace. */
export async function mediaGc(deps, body = {}) {
  const urls = (Array.isArray(body.urls) ? body.urls : []).map((u) => str(u, 600)).filter(Boolean).slice(0, 50);
  if (!urls.length) throw bad('urls is required.');
  if (body.confirm !== true) throw bad('Confirm the permanent delete first.', 'confirm_required');
  const targets = (Array.isArray(body.targets) ? body.targets : []).map((t) => str(t, 200)).filter(Boolean).slice(0, 50);
  const results = await gcUrls(deps, urls, { targets });
  await deps.db.commit(logOps(deps, 'media.gc', targets[0] || 'media', { targets, results: results.map(({ key, url, status }) => ({ key: key || url, status })) }));
  return { ok: true, results, counts: summary(results) };
}

const SLOT_PREFIXES = (page, sid) =>
  [`section.${page}.${sid}`, `seczoom.${page}.${sid}`, `orb.${page}.${sid}`, `tpl.${page}.${sid}`];
const SAFE_ID = /^[A-Za-z0-9_.~-]{1,120}$/;
const slotOf = (r) => String((r.data && r.data.slot) || r.id || '').replaceAll('~', '/');
const matches = (slot, prefixes) => prefixes.some((p) => slot === p || slot.startsWith(p + '.'));

async function purge(deps, { page, sid, removeLayout, layoutEntryId }) {
  const { db } = deps;
  const prefixes = sid ? SLOT_PREFIXES(page, sid) : [];
  const all = await db.query({ collection: 'ui_overrides', limit: SCAN_LIMIT });
  if (all.length >= SCAN_LIMIT) throw bad('Too many overrides to check safely.', 'unsure');
  const layoutPath = `ui_layouts/${page.replaceAll('/', '~')}`;
  const layout = await db.get(layoutPath);
  // Page purge: only slots that belong to THIS page, never a longer page id
  // that shares the prefix (home vs home.normal). section/seczoom/orb carry
  // exactly one id after the page; tpl slots must name a template entry of
  // this page's layout.
  const tplIds = new Set(((layout && layout.sections) || []).filter((s) => s && s.kind && s.kind !== 'builtin').map((s) => s.id));
  const ownsPage = (slot) => {
    const m = /^(section|seczoom|orb|tpl)\.(.*)$/.exec(slot);
    if (!m || !m[2].startsWith(page + '.')) return false;
    const rest = m[2].slice(page.length + 1).split('.');
    if (m[1] === 'tpl') return tplIds.has(rest[0]);
    return rest.length === 1;
  };
  const docs = all.filter((r) => (sid ? matches(slotOf(r), prefixes) : ownsPage(slotOf(r))));
  const urls = new Set();
  const ops = [];
  for (const r of docs) { urlsIn(r.data, urls); ops.push({ op: 'delete', path: `ui_overrides/${r.id}` }); }
  if (layout && removeLayout) {
    urlsIn(layout, urls);
    ops.push({ op: 'delete', path: layoutPath });
  } else if (layout && layoutEntryId && Array.isArray(layout.sections)) {
    const e = layout.sections.find((s) => s && s.id === layoutEntryId);
    if (e && e.kind && e.kind !== 'builtin') {
      // Template / copy: drop it entirely (it has no bundled widget to hide).
      urlsIn(e.props || {}, urls);
      ops.push({ op: 'set', path: layoutPath, data: { ...layout, sections: layout.sections.filter((s) => s !== e) } });
    }
  }
  const target = sid ? `${page}.${sid}` : page;
  const slots = docs.map(slotOf);
  if (ops.length) await db.commit(ops);
  // Media check runs on the state AFTER the docs are gone.
  const results = body_confirm(deps) ? await gcUrls(deps, [...urls], { targets: slots }) : [];
  await db.commit(logOps(deps, sid ? 'section.purge' : 'page.purge', target, { removedDocs: slots, layout: removeLayout ? 'deleted' : (layoutEntryId ? 'entry' : 'kept'), results: results.map(({ key, url, status }) => ({ key: key || url, status })) }));
  return { ok: true, target, removedDocs: slots, results, counts: summary(results) };
}
const body_confirm = (deps) => deps._confirmMedia === true;

/** section-purge { pageId, sectionId, confirm } — section deleted in the editor. */
export async function sectionPurge(deps, body = {}) {
  const page = str(body.pageId, 120); const sid = str(body.sectionId, 120);
  if (!SAFE_ID.test(page) || !SAFE_ID.test(sid)) throw bad('pageId and sectionId are required.');
  return purge({ ...deps, _confirmMedia: body.confirm === true }, { page, sid, layoutEntryId: sid });
}

/** page-purge { pageId, confirm } — page reset/deleted: layout + all its overrides. */
export async function pagePurge(deps, body = {}) {
  const page = str(body.pageId, 120);
  if (!SAFE_ID.test(page)) throw bad('pageId is required.');
  return purge({ ...deps, _confirmMedia: body.confirm === true }, { page, removeLayout: true });
}

/** media-orphans — DRY RUN only. Lists R2 objects nobody references and
    ui_overrides docs whose section is deleted / template entry is gone. */
export async function mediaOrphans(deps, body = {}) {
  const { db } = deps;
  const cp = await corpus(db);
  const r2 = [];
  let listed = 0;
  if (deps.r2) {
    for (const p of MEDIA_PREFIXES) {
      const items = await deps.r2(p).catch(() => []);
      listed += items.length;
      for (const it of items) if (!refsFor(it.key, cp).length) r2.push({ key: it.key, size: it.size || 0 });
    }
  }
  const layouts = await db.query({ collection: 'ui_layouts', limit: SCAN_LIMIT }).catch(() => []);
  const live = new Map();
  for (const l of layouts) {
    const page = String((l.data && l.data.page) || l.id).replaceAll('~', '/');
    live.set(page, new Map((l.data.sections || []).filter((s) => s && s.id).map((s) => [s.id, s])));
  }
  const fsOrphans = [];
  const ovs = await db.query({ collection: 'ui_overrides', limit: SCAN_LIMIT }).catch(() => []);
  for (const r of ovs) {
    const slot = slotOf(r);
    const m = /^(section|seczoom|orb|tpl)\.(.+)\.([^.]+)$/.exec(slot);
    if (!m) continue;
    // Try every split: page may contain dots, tpl slots may carry a field.
    const parts = slot.split('.').slice(1);
    let why = '';
    for (let i = 1; i < parts.length; i++) {
      const page = parts.slice(0, i).join('.'); const sid = parts[i];
      const secs = live.get(page);
      if (!secs) continue;
      const e = secs.get(sid);
      if (e && e.deleted) why = 'section deleted';
      else if (!e && m[1] === 'tpl') why = 'template entry gone';
      if (why) break;
    }
    if (why) fsOrphans.push({ slot, doc: r.id, why });
  }
  return {
    ok: true, dryRun: true, unsure: cp.unsure, r2Configured: !!deps.r2, r2Listed: listed,
    r2Orphans: r2.slice(0, 500), r2OrphanCount: r2.length, r2OrphanBytes: r2.reduce((s, x) => s + x.size, 0),
    firestoreOrphans: fsOrphans.slice(0, 500), firestoreOrphanCount: fsOrphans.length,
  };
}
