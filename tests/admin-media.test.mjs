// CA-2 offline tests: media GC, section/page purge, orphan dry run.
import test from 'node:test';
import assert from 'node:assert/strict';
import { memStore } from './admin/memstore.mjs';
import * as M from '../functions/_lib/admin_media.js';
import { ACTIONS } from '../functions/_lib/admin_core.js';

const BASE = 'https://media.nowssb.com';
const U = (k) => BASE + '/' + k;
const admin = { uid: 'boss', email: 'boss@x.com' };
function deps(db, extra = {}) {
  const deleted = [];
  return { db, admin, now: Date.UTC(2026, 9, 12), mediaBase: BASE, deleted,
    r2Del: async (k) => { deleted.push(k); }, r2: async () => [], ...extra };
}

test('mediaKeyOf only accepts our admin prefixes on our host', () => {
  assert.equal(M.mediaKeyOf(U('ui/home.hero/1-a.webp'), BASE), 'ui/home.hero/1-a.webp');
  assert.equal(M.mediaKeyOf(U('audio/om/1.m4a'), BASE), 'audio/om/1.m4a');
  assert.equal(M.mediaKeyOf(U('assets/logo.png'), BASE), '');
  assert.equal(M.mediaKeyOf(U('ui/../secret'), BASE), '');
  assert.equal(M.mediaKeyOf('https://evil.com/ui/x.webp', BASE), '');
  assert.equal(M.mediaKeyOf('assets/anim/x.json', BASE), '');
  assert.equal(M.mediaKeyOf(U('ui/a%2F..%2Fb'), BASE), '');
});

test('media-gc needs confirm, deletes unreferenced, keeps referenced', async () => {
  const db = memStore({
    'ui_overrides/home.hero': { slot: 'home.hero', url: U('ui/home.hero/new.webp') },
    'ui_overrides/store.top': { slot: 'store.top', url: U('ui/shared/both.webp') },
    'ui_history/h1': { target: 'home.hero', kind: 'slot', before: { url: U('ui/home.hero/old.webp') } },
    'ui_history/h2': { target: 'other.slot', kind: 'slot', before: { url: U('ui/x/kept-by-history.webp') } },
  });
  const d = deps(db);
  await assert.rejects(() => M.mediaGc(d, { urls: [U('ui/home.hero/old.webp')] }), /Confirm/);
  const r = await M.mediaGc(d, { confirm: true, targets: ['home.hero'], urls: [
    U('ui/home.hero/old.webp'), U('ui/shared/both.webp'), U('ui/x/kept-by-history.webp'), 'assets/bundled.png'] });
  const by = Object.fromEntries(r.results.map((x) => [x.url, x.status]));
  assert.equal(by[U('ui/home.hero/old.webp')], 'deleted');
  assert.equal(by[U('ui/shared/both.webp')], 'referenced');
  assert.equal(by[U('ui/x/kept-by-history.webp')], 'referenced');
  assert.equal(by['assets/bundled.png'], 'outside');
  assert.deepEqual(d.deleted, ['ui/home.hero/old.webp']);
  assert.ok([...db.store.keys()].some((k) => k.startsWith('adminLog/')));
});

test('word reference blocks delete', async () => {
  const db = memStore({ 'words/om': { audioUrl: U('audio/om/1.m4a') } });
  const d = deps(db);
  const r = await M.mediaGc(d, { confirm: true, urls: [U('audio/om/1.m4a')] });
  assert.equal(r.results[0].status, 'referenced');
  assert.equal(d.deleted.length, 0);
});

test('section-purge removes override docs + template entry, then GCs media', async () => {
  const db = memStore({
    'ui_layouts/home.normal': { page: 'home.normal', sections: [
      { id: 'hero', kind: 'builtin', deleted: true },
      { id: 't1', kind: 'imageBanner', deleted: true, props: { image: U('ui/tpl/t1.webp') } },
    ] },
    'ui_overrides/section.home.normal.t1': { slot: 'section.home.normal.t1', type: 'section', config: { id: 't1', items: [{ imageUrl: U('ui/sec/t1.webp') }] } },
    'ui_overrides/tpl.home.normal.t1.title': { slot: 'tpl.home.normal.t1.title', text: 'Hi' },
    'ui_overrides/section.home.normal.t10': { slot: 'section.home.normal.t10', type: 'section', config: { id: 't10' } },
    'ui_overrides/section.home.normalX.t1': { slot: 'section.home.normalX.t1', config: { id: 't1' } },
  });
  const d = deps(db);
  const r = await M.sectionPurge(d, { pageId: 'home.normal', sectionId: 't1', confirm: true, deleteMedia: true });
  assert.deepEqual(r.removedDocs.sort(), ['section.home.normal.t1', 'tpl.home.normal.t1.title']);
  assert.equal(await db.get('ui_overrides/section.home.normal.t1'), null);
  assert.ok(await db.get('ui_overrides/section.home.normal.t10'));
  assert.ok(await db.get('ui_overrides/section.home.normalX.t1'));
  const l = await db.get('ui_layouts/home.normal');
  assert.deepEqual(l.sections.map((s) => s.id), ['hero']);
  assert.deepEqual(d.deleted.sort(), ['ui/sec/t1.webp', 'ui/tpl/t1.webp']);
});

test('section-purge needs confirm; without deleteMedia keeps media', async () => {
  const db = memStore({ 'ui_overrides/section.p.s': { slot: 'section.p.s', config: { id: 's', items: [{ imageUrl: U('ui/a.webp') }] } } });
  const d = deps(db);
  await assert.rejects(() => M.sectionPurge(d, { pageId: 'p', sectionId: 's' }), /Confirm/);
  assert.ok(await db.get('ui_overrides/section.p.s'));
  const r = await M.sectionPurge(d, { pageId: 'p', sectionId: 's', confirm: true });
  assert.deepEqual(r.removedDocs, ['section.p.s']);
  assert.equal(d.deleted.length, 0);
});

test('page-purge removes layout + only this page\'s slots', async () => {
  const db = memStore({
    'ui_layouts/home': { page: 'home', sections: [{ id: 'b1', kind: 'videoBanner', props: { video: U('ui/v/1.mp4') } }] },
    'ui_overrides/section.home.cat': { slot: 'section.home.cat', config: { id: 'cat' } },
    'ui_overrides/tpl.home.b1.title': { slot: 'tpl.home.b1.title', text: 'x' },
    'ui_overrides/section.home.normal.cat': { slot: 'section.home.normal.cat', config: { id: 'cat' } },
  });
  const d = deps(db);
  await assert.rejects(() => M.pagePurge(d, { pageId: 'home', deleteMedia: true }), /Confirm/);
  assert.ok(await db.get('ui_layouts/home'));
  const r = await M.pagePurge(d, { pageId: 'home', confirm: true, deleteMedia: true });
  assert.deepEqual(r.removedDocs.sort(), ['section.home.cat', 'tpl.home.b1.title']);
  assert.equal(await db.get('ui_layouts/home'), null);
  assert.ok(await db.get('ui_overrides/section.home.normal.cat'));
  assert.deepEqual(d.deleted, ['ui/v/1.mp4']);
});

test('media-orphans is a dry run and finds both kinds', async () => {
  const db = memStore({
    'ui_layouts/p': { page: 'p', sections: [{ id: 'gone', kind: 'builtin', deleted: true }] },
    'ui_overrides/section.p.gone': { slot: 'section.p.gone', config: { id: 'gone' } },
    'ui_overrides/x': { slot: 'x', url: U('ui/used.webp') },
  });
  const d = deps(db, { r2: async (p) => (p === 'ui/' ? [{ key: 'ui/used.webp', size: 5 }, { key: 'ui/lost.webp', size: 7 }] : []) });
  const r = await ACTIONS['media-orphans'](d, {});
  assert.equal(r.dryRun, true);
  assert.deepEqual(r.r2Orphans, [{ key: 'ui/lost.webp', size: 7 }]);
  assert.equal(r.firestoreOrphanCount, 1);
  assert.equal(d.deleted.length, 0);
  assert.ok(await db.get('ui_overrides/section.p.gone'));
});

test('section-set purgeMedia deletes the replaced picture only', async () => {
  const db = memStore({ 'ui_overrides/section.p.s': { slot: 'section.p.s', type: 'section', config: { id: 's', items: [{ imageUrl: U('ui/old.webp') }, { imageUrl: U('ui/keep.webp') }] } } });
  const d = deps(db);
  const r = await ACTIONS['section-set'](d, { slot: 'section.p.s', purgeMedia: true, config: { id: 's', items: [{ imageUrl: U('ui/new.webp') }, { imageUrl: U('ui/keep.webp') }] } });
  assert.deepEqual(d.deleted, ['ui/old.webp']);
  assert.equal(r.media[0].status, 'deleted');
});
