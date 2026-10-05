import { extractPaid, stripPaid, mergePaid, ownedDocId, canAccessWordPaid } from '../../functions/_lib/content_paid.js';

let pass = 0, fail = 0;
async function t(name, fn) {
  try { await fn(); pass++; console.log('ok  ', name); }
  catch (e) { fail++; console.log('FAIL', name, e.message || e); }
}
function eq(a, b, msg) {
  const as = JSON.stringify(a), bs = JSON.stringify(b);
  if (as !== bs) throw new Error((msg || 'eq') + ': ' + as + ' !== ' + bs);
}

await t('ownedDocId colon', () => eq(ownedDocId('word:om'), 'word_om'));
await t('extractPaid pulls meaning+stage media', () => {
  const p = extractPaid({
    word: 'Om', price: 99, meaning: 'sacred', audio: 'https://media.nowssb.com/a.mp3',
    stages: [{ title: '1', text: 'hi', audio: 'https://media.nowssb.com/s.mp3', video: '' }],
    parts: [{ roman: 'om', audio: 'https://media.nowssb.com/p.mp3' }],
  });
  eq(p.meaning, 'sacred');
  eq(p.audio, 'https://media.nowssb.com/a.mp3');
  eq(p.stagesMedia[0].audio, 'https://media.nowssb.com/s.mp3');
  eq(p.partsAudio[0], 'https://media.nowssb.com/p.mp3');
});
await t('stripPaid removes paid URLs', () => {
  const s = stripPaid({
    word: 'Om', price: 99, meaning: 'sacred', audio: 'https://x',
    stages: [{ title: '1', text: 'hi', audio: 'https://x', video: 'https://y' }],
  });
  eq(s.meaning, undefined);
  eq(s.audio, undefined);
  eq(s.stages[0].audio, undefined);
  eq(s.stages[0].title, '1');
});
await t('mergePaid restores', () => {
  const pub = stripPaid({ word: 'Om', meaning: 'sacred', stages: [{ title: '1', text: 'hi', audio: 'a' }] });
  const paid = extractPaid({ meaning: 'sacred', stages: [{ title: '1', text: 'hi', audio: 'a' }] });
  const m = mergePaid(pub, paid);
  eq(m.meaning, 'sacred');
  eq(m.stages[0].audio, 'a');
});
await t('canAccess: free price', async () => {
  const ok = await canAccessWordPaid(async () => null, 'u1', { key: 'om', price: 0 });
  if (!ok) throw new Error('free should pass');
});
await t('canAccess: locked', async () => {
  const ok = await canAccessWordPaid(async () => null, 'u1', { key: 'om', price: 99 });
  if (ok) throw new Error('locked should fail');
});
await t('canAccess: owned', async () => {
  const docs = {
    'users/u1/owned/word_om': { status: 'active', itemId: 'word:om' },
  };
  const ok = await canAccessWordPaid(async (p) => docs[p] || null, 'u1', { key: 'om', wordName: 'Om', price: 99 });
  if (!ok) throw new Error('owner should pass');
});
await t('canAccess: plan', async () => {
  const docs = { 'users/u1': { isPro: true, tier: 'frequency' } };
  const ok = await canAccessWordPaid(async (p) => docs[p] || null, 'u1', { key: 'om', price: 99 });
  if (!ok) throw new Error('plan should pass');
});
await t('canAccess: admin claim', async () => {
  const ok = await canAccessWordPaid(async () => null, 'u1', { key: 'om', price: 99, claims: { admin: true } });
  if (!ok) throw new Error('admin claim should pass');
});

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
