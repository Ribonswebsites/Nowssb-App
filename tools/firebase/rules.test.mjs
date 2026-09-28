// Emulator tests for firestore.rules — run with tools/firebase/test-rules.sh
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { doc, getDoc, setDoc, updateDoc, addDoc, deleteDoc, collection, getDocs, query, where, serverTimestamp } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'nowssb-34f1b',
  firestore: { rules: readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8089 },
});
await env.withSecurityRulesDisabled(async (c) => {
  const db = c.firestore();
  await setDoc(doc(db, 'admins/boss'), { at: 1 });
  await setDoc(doc(db, 'users/alice'), { uid: 'alice', isPro: false, tier: null, displayName: 'A' });
  await setDoc(doc(db, 'users/pro'), { uid: 'pro', isPro: true, tier: 'gold' });
  await setDoc(doc(db, 'requests/r1'), { uid: 'alice', word: 'om', status: 'new', at: 1 });
  await setDoc(doc(db, 'requests/r2'), { uid: 'bob', word: 'ra', status: 'new', at: 2 });
  await setDoc(doc(db, 'payments/pay_A'), { uid: 'alice', tier: 'frequency', amount: 999 });
  await setDoc(doc(db, 'payments/pay_B'), { uid: 'bob', tier: 'resonance', amount: 499 });
});
const alice = env.authenticatedContext('alice').firestore();
const boss = env.authenticatedContext('boss').firestore();
const claim = env.authenticatedContext('claimer', { admin: true }).firestore();
const anon = env.unauthenticatedContext().firestore();
const newbie = env.authenticatedContext('newbie').firestore();
const pro = env.authenticatedContext('pro').firestore();
let pass = 0, fail = 0;
async function t(name, p) { try { await p; pass++; console.log('ok  ', name); } catch (e) { fail++; console.log('FAIL', name, e.message.split('\n')[0]); } }

// users
await t('self profile update', assertSucceeds(setDoc(doc(alice, 'users/alice'), { displayName: 'Al', prefs: { a: 1 } }, { merge: true })));
await t('self set isPro true denied', assertFails(setDoc(doc(alice, 'users/alice'), { isPro: true }, { merge: true })));
await t('self set tier denied', assertFails(setDoc(doc(alice, 'users/alice'), { tier: 'gold' }, { merge: true })));
await t('self set coins denied', assertFails(setDoc(doc(alice, 'users/alice'), { coins: 999 }, { merge: true })));
await t('self set subscriptionEndDate denied', assertFails(setDoc(doc(alice, 'users/alice'), { subscriptionEndDate: 'x' }, { merge: true })));
await t('self set blocked denied', assertFails(setDoc(doc(alice, 'users/alice'), { blocked: false }, { merge: true })));
await t('self set role denied', assertFails(setDoc(doc(alice, 'users/alice'), { role: 'admin' }, { merge: true })));
await t('self rewrite isPro false unchanged ok', assertSucceeds(setDoc(doc(alice, 'users/alice'), { isPro: false, profileStepDone: true }, { merge: true })));
await t('pro downgrade isPro false ok', assertSucceeds(setDoc(doc(pro, 'users/pro'), { isPro: false }, { merge: true })));
await t('web sign-up create ok', assertSucceeds(setDoc(doc(newbie, 'users/newbie'), { uid: 'newbie', email: 'n@x', displayName: '', photoURL: '', isPro: false, tier: null, createdAt: serverTimestamp(), lastLogin: serverTimestamp() })));
await t('create with isPro true denied', assertFails(setDoc(doc(env.authenticatedContext('n2').firestore(), 'users/n2'), { isPro: true })));
await t('presence merge ok', assertSucceeds(setDoc(doc(alice, 'users/alice'), { lastSeen: Date.now(), lastSeenAt: serverTimestamp(), lastPlatform: 'android', lastApp: 'flutter' }, { merge: true })));
await t('presence create ok', assertSucceeds(setDoc(doc(env.authenticatedContext('n3').firestore(), 'users/n3'), { lastSeen: 1, lastSeenAt: serverTimestamp(), lastPlatform: 'android', lastApp: 'flutter' }, { merge: true })));
await t('lastSeenAt fake denied', assertFails(setDoc(doc(alice, 'users/alice'), { lastSeenAt: new Date(0) }, { merge: true })));
await t('other user write denied', assertFails(setDoc(doc(alice, 'users/pro'), { displayName: 'x' }, { merge: true })));
await t('admin sets isPro', assertSucceeds(setDoc(doc(boss, 'users/alice'), { isPro: true }, { merge: true })));
await t('claim admin sets tier', assertSucceeds(setDoc(doc(claim, 'users/alice'), { tier: 'gold' }, { merge: true })));
// admins
await t('self get admins doc', assertSucceeds(getDoc(doc(boss, 'admins/boss'))));
await t('alice get own (missing) admins doc allowed', assertSucceeds(getDoc(doc(alice, 'admins/alice'))));
await t('alice cannot create admins doc', assertFails(setDoc(doc(alice, 'admins/alice'), { x: 1 })));
// words
await t('anon read words', assertSucceeds(getDoc(doc(anon, 'words/om'))));
await t('anon list words', assertSucceeds(getDocs(collection(anon, 'words'))));
await t('user write words denied', assertFails(setDoc(doc(alice, 'words/om'), { word: 'Om' })));
await t('admin write words', assertSucceeds(setDoc(doc(boss, 'words/om'), { word: 'Om', status: 'published', version: 1 })));
await t('user read drafts denied', assertFails(getDoc(doc(alice, 'word_drafts/om'))));
await t('admin write drafts', assertSucceeds(setDoc(doc(boss, 'word_drafts/om'), { word: 'Om' })));
// ui_overrides
await t('anon list ui_overrides', assertSucceeds(getDocs(collection(anon, 'ui_overrides'))));
await t('user write ui_overrides denied', assertFails(setDoc(doc(alice, 'ui_overrides/x'), { slot: 'x' })));
await t('admin write ui_overrides', assertSucceeds(setDoc(doc(boss, 'ui_overrides/x'), { slot: 'x', type: 'text', text: 'hi' })));
await t('admin delete ui_overrides', assertSucceeds(deleteDoc(doc(boss, 'ui_overrides/x'))));
// ui_layouts (UI Editor page layouts)
await t('anon read ui_layouts', assertSucceeds(getDoc(doc(anon, 'ui_layouts/home.normal'))));
await t('anon list ui_layouts', assertSucceeds(getDocs(collection(anon, 'ui_layouts'))));
await t('user write ui_layouts denied', assertFails(setDoc(doc(alice, 'ui_layouts/home.normal'), { page: 'home.normal', sections: [] })));
await t('anon write ui_layouts denied', assertFails(setDoc(doc(anon, 'ui_layouts/home.normal'), { page: 'home.normal', sections: [] })));
await t('admin write ui_layouts', assertSucceeds(setDoc(doc(boss, 'ui_layouts/home.normal'), { page: 'home.normal', version: 1, sections: [{ id: 'greet', kind: 'builtin', visible: true }] })));
await t('claim admin write ui_layouts', assertSucceeds(setDoc(doc(claim, 'ui_layouts/home.fashion'), { page: 'home.fashion', version: 1, sections: [] })));
await t('user delete ui_layouts denied', assertFails(deleteDoc(doc(alice, 'ui_layouts/home.normal'))));
await t('admin delete ui_layouts', assertSucceeds(deleteDoc(doc(boss, 'ui_layouts/home.fashion'))));
// ui_history (UI Editor version history)
await t('admin create ui_history', assertSucceeds(addDoc(collection(boss, 'ui_history'), { page: 'home.normal', kind: 'layout', target: 'home.normal', before: null, after: { sections: [] }, at: serverTimestamp(), by: 'boss' })));
await t('user create ui_history denied', assertFails(addDoc(collection(alice, 'ui_history'), { page: 'home.normal', kind: 'slot', target: 'x' })));
await t('admin read ui_history', assertSucceeds(getDocs(query(collection(boss, 'ui_history'), where('page', '==', 'home.normal')))));
await t('user read ui_history denied', assertFails(getDocs(collection(alice, 'ui_history'))));
await t('anon read ui_history denied', assertFails(getDocs(collection(anon, 'ui_history'))));
await env.withSecurityRulesDisabled(async (c) => setDoc(doc(c.firestore(), 'ui_history/H1'), { page: 'home.normal', kind: 'slot', target: 'x' }));
await t('admin update ui_history denied', assertFails(updateDoc(doc(boss, 'ui_history/H1'), { target: 'y' })));
await t('admin delete ui_history denied', assertFails(deleteDoc(doc(boss, 'ui_history/H1'))));
// content/quotes
await t('anon read content/quotes', assertSucceeds(getDoc(doc(anon, 'content/quotes'))));
await t('admin write content/quotes', assertSucceeds(setDoc(doc(boss, 'content/quotes'), { byDate: {}, queue: ['a'] })));
await t('user write content/quotes denied', assertFails(setDoc(doc(alice, 'content/quotes'), { queue: ['a'] })));
// adminLog
await t('admin log create', assertSucceeds(addDoc(collection(boss, 'adminLog'), { action: 'a', target: 't', uid: 'boss', at: serverTimestamp() })));
await t('admin log spoof uid denied', assertFails(addDoc(collection(boss, 'adminLog'), { action: 'a', uid: 'alice' })));
await t('user log create denied', assertFails(addDoc(collection(alice, 'adminLog'), { action: 'a', uid: 'alice' })));
await t('admin log read', assertSucceeds(getDocs(collection(boss, 'adminLog'))));
await t('user log read denied', assertFails(getDocs(collection(alice, 'adminLog'))));
await env.withSecurityRulesDisabled(async (c) => setDoc(doc(c.firestore(), 'adminLog/L1'), { action: 'a', uid: 'boss' }));
await t('admin log update denied', assertFails(updateDoc(doc(boss, 'adminLog/L1'), { action: 'b' })));
await t('admin log delete denied', assertFails(deleteDoc(doc(boss, 'adminLog/L1'))));
// requests
const flutterRow = { kind: 'word', word: 'om', notes: 'pls', uid: 'alice', email: 'a@x', name: 'A', status: 'new', at: Date.now(), source: 'flutter' };
await t('flutter request create', assertSucceeds(addDoc(collection(alice, 'requests'), flutterRow)));
await t('web request create', assertSucceeds(addDoc(collection(alice, 'requests'), { kind: 'meaning', word: 'om', price: 2, currency: 'INR', uid: 'alice', email: null, name: null, status: 'new', at: 1 })));
await t('request other uid denied', assertFails(addDoc(collection(alice, 'requests'), { ...flutterRow, uid: 'bob' })));
await t('request status done denied', assertFails(addDoc(collection(alice, 'requests'), { ...flutterRow, status: 'done' })));
await t('request extra field denied', assertFails(addDoc(collection(alice, 'requests'), { ...flutterRow, isPro: true })));
await t('request empty word denied', assertFails(addDoc(collection(alice, 'requests'), { ...flutterRow, word: '' })));
await t('user lists own requests', assertSucceeds(getDocs(query(collection(alice, 'requests'), where('uid', '==', 'alice')))));
await t('user lists all requests denied', assertFails(getDocs(collection(alice, 'requests'))));
await t('admin lists all requests', assertSucceeds(getDocs(collection(boss, 'requests'))));
await t('admin fulfils', assertSucceeds(updateDoc(doc(boss, 'requests/r1'), { status: 'done', doneAt: 1 })));
await t('user update request denied', assertFails(updateDoc(doc(alice, 'requests/r1'), { status: 'new' })));
// notifications / inbox
await t('admin creates notification', assertSucceeds(addDoc(collection(boss, 'users/alice/notifications'), { title: 't', read: false })));
await t('user creates own notification denied', assertFails(addDoc(collection(alice, 'users/alice/notifications'), { title: 't' })));
await t('admin creates inbox', assertSucceeds(addDoc(collection(boss, 'users/alice/inbox'), { title: 't', read: false })));
// payments (server-written receipts) + server-only subscription fields
await t('self set subscriptionSource denied', assertFails(setDoc(doc(alice, 'users/alice'), { subscriptionSource: 'play' }, { merge: true })));
await t('self set subscriptionProductId denied', assertFails(setDoc(doc(alice, 'users/alice'), { subscriptionProductId: 'nowssb_frequency_monthly' }, { merge: true })));
await t('self set subscriptionTokenHash denied', assertFails(setDoc(doc(alice, 'users/alice'), { subscriptionTokenHash: 'x' }, { merge: true })));
await t('self set verifyTier denied', assertFails(setDoc(doc(alice, 'users/alice'), { verifyTier: 'gold' }, { merge: true })));
await t('create with verifyTier denied', assertFails(setDoc(doc(env.authenticatedContext('n3').firestore(), 'users/n3'), { uid: 'n3', verifyTier: 'blue' })));
await t('admin sets verifyTier ok', assertSucceeds(setDoc(doc(boss, 'users/alice'), { verifyTier: 'blue' }, { merge: true })));
await t('self set subscriptionOrderId denied', assertFails(setDoc(doc(alice, 'users/alice'), { subscriptionOrderId: 'order_x' }, { merge: true })));
await t('user reads own payment', assertSucceeds(getDoc(doc(alice, 'payments/pay_A'))));
await t('user lists own payments', assertSucceeds(getDocs(query(collection(alice, 'payments'), where('uid', '==', 'alice')))));
await t('user reads other payment denied', assertFails(getDoc(doc(alice, 'payments/pay_B'))));
await t('user lists all payments denied', assertFails(getDocs(collection(alice, 'payments'))));
await t('user writes payment denied', assertFails(setDoc(doc(alice, 'payments/pay_C'), { uid: 'alice', tier: 'frequencyX' })));
await t('admin reads payments', assertSucceeds(getDocs(collection(boss, 'payments'))));
await t('admin writes payment denied', assertFails(setDoc(doc(boss, 'payments/pay_D'), { uid: 'boss' })));
// untouched areas still behave
await t('publicProfiles unaffected (self create)', assertSucceeds(setDoc(doc(alice, 'publicProfiles/alice'), { uid: 'alice', displayName: 'A' })));
await t('coach goals self', assertSucceeds(setDoc(doc(alice, 'users/alice/goals/g1'), { a: 1 })));
console.log(`\n${pass} passed, ${fail} failed`);
await env.cleanup();
process.exit(fail ? 1 : 0);
