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
// ── Admin console (activity, config, restrictions, history, broadcasts) ──
await t('self set restrictions denied', assertFails(setDoc(doc(alice, 'users/alice'), { restrictions: {} }, { merge: true })));
await t('self set roles denied', assertFails(setDoc(doc(alice, 'users/alice'), { roles: ['helper'] }, { merge: true })));
await t('self set subscriptionGrantedBy denied', assertFails(setDoc(doc(alice, 'users/alice'), { subscriptionGrantedBy: 'me' }, { merge: true })));
await t('self presence with build ok', assertSucceeds(setDoc(doc(alice, 'users/alice'), { lastSeen: 1, lastSeenAt: serverTimestamp(), lastBuild: '512', lastOs: 'android 14', lastDevice: 'Pixel' }, { merge: true })));
await t('admin sets restrictions', assertSucceeds(setDoc(doc(boss, 'users/alice'), { restrictions: { community: true } }, { merge: true })));
await t('muted user post denied', assertFails(addDoc(collection(alice, 'posts'), { uid: 'alice', visibility: 'public', text: 'x' })));
await t('unmuted user post ok', assertSucceeds(addDoc(collection(pro, 'posts'), { uid: 'pro', visibility: 'public', text: 'x' })));
await t('user without profile posts ok', assertSucceeds(addDoc(collection(env.authenticatedContext('ghost').firestore(), 'posts'), { uid: 'ghost', visibility: 'public' })));
await t('muted user reel denied', assertFails(setDoc(doc(alice, 'reels/r1'), { uid: 'alice' })));
await t('muted user story denied', assertFails(setDoc(doc(alice, 'stories/s1'), { uid: 'alice', visibility: 'public' })));
await t('muted user can still request (community only)', assertSucceeds(addDoc(collection(alice, 'requests'), { kind: 'word', word: 'om', uid: 'alice', status: 'new', at: 1 })));
await t('admin restricts requests', assertSucceeds(setDoc(doc(boss, 'users/alice'), { restrictions: { requests: true } }, { merge: true })));
await t('request-restricted user request denied', assertFails(addDoc(collection(alice, 'requests'), { kind: 'word', word: 'om', uid: 'alice', status: 'new', at: 1 })));
await t('admin blocks', assertSucceeds(setDoc(doc(boss, 'users/pro'), { blocked: true, restrictions: {} }, { merge: true })));
await t('blocked user post denied', assertFails(addDoc(collection(pro, 'posts'), { uid: 'pro', visibility: 'public' })));
await t('admin clears restrictions', assertSucceeds(setDoc(doc(boss, 'users/alice'), { restrictions: {} }, { merge: true })));
await t('cleared user post ok', assertSucceeds(addDoc(collection(alice, 'posts'), { uid: 'alice', visibility: 'public' })));
// activity
await t('own login event ok', assertSucceeds(addDoc(collection(alice, 'activity'), { type: 'login', uid: 'alice', at: serverTimestamp(), platform: 'android', build: '512', app: 'flutter' })));
await t('own signup event ok', assertSucceeds(addDoc(collection(newbie, 'activity'), { type: 'signup', uid: 'newbie', at: serverTimestamp() })));
await t('event for someone else denied', assertFails(addDoc(collection(alice, 'activity'), { type: 'login', uid: 'bob', at: serverTimestamp() })));
await t('event with client time denied', assertFails(addDoc(collection(alice, 'activity'), { type: 'login', uid: 'alice', at: new Date() })));
await t('admin-type event from app denied', assertFails(addDoc(collection(alice, 'activity'), { type: 'admin', uid: 'alice', at: serverTimestamp() })));
await t('purchase event from app denied', assertFails(addDoc(collection(alice, 'activity'), { type: 'purchase', uid: 'alice', at: serverTimestamp() })));
await t('event extra field denied', assertFails(addDoc(collection(alice, 'activity'), { type: 'login', uid: 'alice', at: serverTimestamp(), coins: 5 })));
await t('anon event denied', assertFails(addDoc(collection(anon, 'activity'), { type: 'login', uid: 'x', at: serverTimestamp() })));
await t('user reads activity denied', assertFails(getDocs(collection(alice, 'activity'))));
await t('admin reads activity', assertSucceeds(getDocs(collection(boss, 'activity'))));
await env.withSecurityRulesDisabled(async (c) => setDoc(doc(c.firestore(), 'activity/E1'), { type: 'login', uid: 'alice' }));
await t('admin edit activity denied', assertFails(updateDoc(doc(boss, 'activity/E1'), { type: 'signup' })));
await t('user delete activity denied', assertFails(deleteDoc(doc(alice, 'activity/E1'))));
// config
await t('anon reads config/app', assertSucceeds(getDoc(doc(anon, 'config/app'))));
await t('anon reads config/economy denied', assertFails(getDoc(doc(anon, 'config/economy'))));
await t('user reads config/economy', assertSucceeds(getDoc(doc(alice, 'config/economy'))));
await t('user writes config/app denied', assertFails(setDoc(doc(alice, 'config/app'), { maintenance: { on: true } })));
await t('admin writes config/app', assertSucceeds(setDoc(doc(boss, 'config/app'), { minBuild: 3, maintenance: { on: false }, flags: { a: true } })));
await t('admin writes config/economy', assertSucceeds(setDoc(doc(boss, 'config/economy'), { version: 2, coupons: { odds: [] } })));
await t('admin config history create', assertSucceeds(addDoc(collection(boss, 'configHistory'), { doc: 'config/economy', version: 2, by: 'boss', at: serverTimestamp() })));
await t('user config history denied', assertFails(addDoc(collection(alice, 'configHistory'), { doc: 'x' })));
await env.withSecurityRulesDisabled(async (c) => setDoc(doc(c.firestore(), 'configHistory/H1'), { doc: 'config/app' }));
await t('admin edit config history denied', assertFails(updateDoc(doc(boss, 'configHistory/H1'), { doc: 'y' })));
// announcement banner + broadcasts
await t('anon reads announcement', assertSucceeds(getDoc(doc(anon, 'content/announcement'))));
await t('admin writes announcement', assertSucceeds(setDoc(doc(boss, 'content/announcement'), { on: true, title: 'Hi' })));
await t('user writes announcement denied', assertFails(setDoc(doc(alice, 'content/announcement'), { on: true })));
await t('admin reads broadcasts', assertSucceeds(getDocs(collection(boss, 'broadcasts'))));
await t('admin writes broadcasts denied', assertFails(setDoc(doc(boss, 'broadcasts/b1'), { title: 'x' })));
await t('user reads broadcasts denied', assertFails(getDocs(collection(alice, 'broadcasts'))));
// economy admin (wallet / ledgers / payouts / gifts)
const bossM = env.authenticatedContext('boss', { email: 'boss@x.com' }).firestore();
await t('admin creates wallet coins', assertSucceeds(setDoc(doc(boss, 'users/alice/wallet/main'), { coins: 40, updatedAt: serverTimestamp() })));
await t('admin wallet negative denied', assertFails(setDoc(doc(boss, 'users/alice/wallet/main'), { coins: -1 }, { merge: true })));
await t('admin wallet foreign key denied', assertFails(setDoc(doc(boss, 'users/alice/wallet/main'), { cashCents: 900 }, { merge: true })));
await t('admin wallet other doc denied', assertFails(setDoc(doc(boss, 'users/alice/wallet/x'), { coins: 1 })));
await t('admin resets streak', assertSucceeds(setDoc(doc(boss, 'users/alice/wallet/main'), { streak: 0, streakResetAt: serverTimestamp(), lastBrokenStreak: 4 }, { merge: true })));
await t('self reads wallet', assertSucceeds(getDoc(doc(alice, 'users/alice/wallet/main'))));
await t('self writes wallet denied', assertFails(setDoc(doc(alice, 'users/alice/wallet/main'), { coins: 9999 }, { merge: true })));
await t('other reads wallet denied', assertFails(getDoc(doc(pro, 'users/alice/wallet/main'))));
await t('admin ledger row ok', assertSucceeds(addDoc(collection(bossM, 'coinLedger'), { uid: 'alice', delta: 10, reason: 'support', by: 'boss@x.com', at: serverTimestamp() })));
await t('admin ledger wrong by denied', assertFails(addDoc(collection(bossM, 'coinLedger'), { uid: 'alice', delta: 10, reason: 'x', by: 'other@x.com' })));
await t('admin ledger no reason denied', assertFails(addDoc(collection(bossM, 'coinLedger'), { uid: 'alice', delta: 10, reason: '', by: 'boss@x.com' })));
await t('user ledger create denied', assertFails(addDoc(collection(alice, 'coinLedger'), { uid: 'alice', delta: 10, reason: 'x', by: 'alice' })));
await t('admin lists coinLedger', assertSucceeds(getDocs(collection(boss, 'coinLedger'))));
await t('admin cash ledger row ok', assertSucceeds(addDoc(collection(boss, 'cashLedger'), { uid: 'alice', delta: -1500, kind: 'payout' })));
await t('user cash ledger denied', assertFails(addDoc(collection(alice, 'cashLedger'), { uid: 'alice', delta: 1500 })));
await env.withSecurityRulesDisabled(async (c) => setDoc(doc(c.firestore(), 'payoutRequests/p1'), { uid: 'alice', amountBase: 1500, status: 'pending' }));
await t('admin approves payout', assertSucceeds(updateDoc(doc(boss, 'payoutRequests/p1'), { status: 'approved' })));
await t('admin payout amount change denied', assertFails(updateDoc(doc(boss, 'payoutRequests/p1'), { status: 'paid', amountBase: 99999 })));
await t('admin payout weird status denied', assertFails(updateDoc(doc(boss, 'payoutRequests/p1'), { status: 'pending' })));
await t('user approves own payout denied', assertFails(updateDoc(doc(alice, 'payoutRequests/p1'), { status: 'paid' })));
await t('admin lists payouts', assertSucceeds(getDocs(collection(boss, 'payoutRequests'))));
await t('admin creates gift code', assertSucceeds(setDoc(doc(boss, 'gifts/NWSB-AAAA'), { source: 'admin', status: 'unredeemed', item: 'coins100' })));
await t('admin gift redeemed status denied', assertFails(setDoc(doc(boss, 'gifts/NWSB-BBBB'), { source: 'admin', status: 'redeemed' })));
await t('user gift create denied', assertFails(setDoc(doc(alice, 'gifts/NWSB-CCCC'), { source: 'admin', status: 'unredeemed' })));
await t('user reads gifts denied', assertFails(getDoc(doc(alice, 'gifts/NWSB-AAAA'))));
await t('admin voids gift', assertSucceeds(updateDoc(doc(boss, 'gifts/NWSB-AAAA'), { status: 'void', voidedBy: 'boss', voidedAt: serverTimestamp() })));
await t('admin un-voids gift denied', assertFails(updateDoc(doc(boss, 'gifts/NWSB-AAAA'), { status: 'unredeemed' })));
await t('admin gift ledger ok', assertSucceeds(addDoc(collection(boss, 'giftLedger'), { source: 'admin', code: 'NWSB-AAAA' })));
await t('admin reads couponLedger', assertSucceeds(getDocs(collection(boss, 'couponLedger'))));
await t('admin writes couponLedger denied', assertFails(addDoc(collection(boss, 'couponLedger'), { a: 1 })));
await t('admin reads referrals', assertSucceeds(getDocs(collection(boss, 'referrals'))));
await t('user reads referrals denied', assertFails(getDocs(collection(alice, 'referrals'))));
// untouched areas still behave
await t('publicProfiles unaffected (self create)', assertSucceeds(setDoc(doc(alice, 'publicProfiles/alice'), { uid: 'alice', displayName: 'A' })));
await t('coach goals self', assertSucceeds(setDoc(doc(alice, 'users/alice/goals/g1'), { a: 1 })));
// NowssB programs: server-written, owner-readable, never client-writable
await env.withSecurityRulesDisabled(async (c) => {
  const db = c.firestore();
  await setDoc(doc(db, 'users/alice/scratchCards/s1'), { rarity: 'rare', status: 'sealed' });
  await setDoc(doc(db, 'users/bob/scratchCards/s2'), { rarity: 'rare', status: 'sealed' });
  await setDoc(doc(db, 'commissionLedger/c1'), { uid: 'alice', paise: 100 });
  await setDoc(doc(db, 'commissionLedger/c2'), { uid: 'bob', paise: 100 });
  await setDoc(doc(db, 'giftCards/NWSB-AAAA-BBBB'), { fromUid: 'alice', status: 'active' });
  await setDoc(doc(db, 'giftCards/NWSB-CCCC-DDDD'), { fromUid: 'bob', status: 'active' });
  await setDoc(doc(db, 'refLinks/ABC'), { uid: 'alice', title: 'Om' });
  await setDoc(doc(db, 'sales/o1'), { buyerUid: 'alice', ownerUid: 'bob' });
  await setDoc(doc(db, 'devices/d1'), { uids: ['alice'] });
  await setDoc(doc(db, 'leaderboards/sellers_202610'), { entries: {} });
  await setDoc(doc(db, 'appointments/bob_alice'), { fromUid: 'bob', toUid: 'alice', status: 'invited' });
});
await t('own scratch card readable', assertSucceeds(getDoc(doc(alice, 'users/alice/scratchCards/s1'))));
await t('other scratch card denied', assertFails(getDoc(doc(alice, 'users/bob/scratchCards/s2'))));
await t('scratch card write denied', assertFails(setDoc(doc(alice, 'users/alice/scratchCards/s1'), { status: 'revealed' })));
await t('coupon create denied', assertFails(setDoc(doc(alice, 'users/alice/coupons/x'), { pct: 90 })));
await t('token create denied', assertFails(setDoc(doc(alice, 'users/alice/tokens/x'), { item: 'bundle10' })));
await t('gift box create denied', assertFails(setDoc(doc(alice, 'users/alice/boxes/x'), { box: 'diamond' })));
await t('week doc write denied', assertFails(setDoc(doc(alice, 'users/alice/weeks/W1'), { claimed: [] })));
await t('wallet write denied', assertFails(setDoc(doc(alice, 'users/alice/wallet/main'), { coins: 99999 })));
await t('own commission rows listable', assertSucceeds(getDocs(query(collection(alice, 'commissionLedger'), where('uid', '==', 'alice')))));
await t('all commission rows denied', assertFails(getDocs(collection(alice, 'commissionLedger'))));
await t('commission write denied', assertFails(setDoc(doc(alice, 'commissionLedger/c3'), { uid: 'alice', paise: 1e9 })));
await t('partner ledger write denied', assertFails(setDoc(doc(alice, 'partnerLedger/p1'), { uid: 'alice', points: 5000 })));
await t('own gift card readable', assertSucceeds(getDoc(doc(alice, 'giftCards/NWSB-AAAA-BBBB'))));
await t('someone else gift card denied', assertFails(getDoc(doc(alice, 'giftCards/NWSB-CCCC-DDDD'))));
await t('gift card write denied', assertFails(setDoc(doc(alice, 'giftCards/NWSB-EEEE-FFFF'), { fromUid: 'alice' })));
await t('own ref link readable', assertSucceeds(getDoc(doc(alice, 'refLinks/ABC'))));
await t('ref link write denied', assertFails(setDoc(doc(alice, 'refLinks/ZZZ'), { uid: 'alice' })));
await t('buyer reads own sale', assertSucceeds(getDoc(doc(alice, 'sales/o1'))));
await t('sale write denied', assertFails(setDoc(doc(alice, 'sales/o2'), { buyerUid: 'alice' })));
await t('devices hidden', assertFails(getDoc(doc(alice, 'devices/d1'))));
await t('payout identities hidden', assertFails(getDoc(doc(alice, 'payoutIdentities/x'))));
await t('leaderboard readable signed in', assertSucceeds(getDoc(doc(alice, 'leaderboards/sellers_202610'))));
await t('leaderboard write denied', assertFails(setDoc(doc(alice, 'leaderboards/sellers_202610'), { entries: { alice: { words: 9999 } } })));
await t('appointment invitee reads', assertSucceeds(getDoc(doc(alice, 'appointments/bob_alice'))));
await t('appointment accept by client denied', assertFails(updateDoc(doc(alice, 'appointments/bob_alice'), { status: 'accepted' })));
await t('checkout write denied', assertFails(setDoc(doc(alice, 'checkouts/k1'), { uid: 'alice', payINR: 1 })));
await t('self set ebookPassUntil denied', assertFails(setDoc(doc(alice, 'users/alice'), { ebookPassUntil: '2099-01-01' }, { merge: true })));
await t('config/economy readable signed in', assertSucceeds(getDoc(doc(alice, 'config/economy'))));
await t('config/economy write denied for users', assertFails(setDoc(doc(alice, 'config/economy'), { lock: { payoutCapPct: 99 } })));
await t('config/economy admin write', assertSucceeds(setDoc(doc(boss, 'config/economy'), { version: 2 }, { merge: true })));
// ── Bug-fix pass: wishlist, owned grants, feedback, account deletion, store config ──
await t('self wishlist write ok', assertSucceeds(setDoc(doc(alice, 'users/alice/wishlist/word_om'), { id: 'word:om', title: 'Om', subtitle: '', image: '', price: 99, kind: 'Word', addedAt: 1 })));
await t('self wishlist extra field denied', assertFails(setDoc(doc(alice, 'users/alice/wishlist/word_ra'), { id: 'word:ra', isPro: true })));
await t('self wishlist delete ok', assertSucceeds(deleteDoc(doc(alice, 'users/alice/wishlist/word_om'))));
await t('other wishlist write denied', assertFails(setDoc(doc(alice, 'users/pro/wishlist/x'), { id: 'x' })));
await t('user grants own item denied', assertFails(setDoc(doc(alice, 'users/alice/owned/word_om'), { source: 'admin', status: 'active' })));
await t('admin grants item ok', assertSucceeds(setDoc(doc(boss, 'users/alice/owned/word_om'), { source: 'admin', status: 'active', itemId: 'word:om' })));
await t('admin grant non-admin source denied', assertFails(setDoc(doc(boss, 'users/alice/owned/word_ra'), { source: 'play', status: 'active' })));
await t('admin revokes item ok', assertSucceeds(setDoc(doc(boss, 'users/alice/owned/word_om'), { source: 'admin', status: 'revoked' }, { merge: true })));
await t('user reads own owned ok', assertSucceeds(getDocs(collection(alice, 'users/alice/owned'))));
await t('feedback create ok', assertSucceeds(addDoc(collection(alice, 'feedback'), { uid: 'alice', rating: 4, tags: ['clear'], text: 'Nice', source: 'progress', status: 'new', at: serverTimestamp() })));
await t('feedback for another uid denied', assertFails(addDoc(collection(alice, 'feedback'), { uid: 'pro', text: 'x', status: 'new', at: serverTimestamp() })));
await t('feedback read by user denied', assertFails(getDocs(collection(alice, 'feedback'))));
await t('feedback read by admin ok', assertSucceeds(getDocs(collection(boss, 'feedback'))));
await t('deletion request create ok', assertSucceeds(setDoc(doc(alice, 'accountDeletionRequests/alice'), { uid: 'alice', email: 'a@x', status: 'pending', requestedAt: serverTimestamp(), platform: 'android' })));
await t('deletion request for other denied', assertFails(setDoc(doc(alice, 'accountDeletionRequests/pro'), { uid: 'pro', status: 'pending', requestedAt: serverTimestamp() })));
await t('deletion request list by user denied', assertFails(getDocs(collection(alice, 'accountDeletionRequests'))));
await t('admin lists deletion requests', assertSucceeds(getDocs(collection(boss, 'accountDeletionRequests'))));
await t('user deletes own notification ok', assertSucceeds(env.withSecurityRulesDisabled(async (c) => setDoc(doc(c.firestore(), 'users/alice/notifications/n9'), { title: 'x' })).then(() => deleteDoc(doc(alice, 'users/alice/notifications/n9')))));
await t('anon reads config/store ok', assertSucceeds(getDoc(doc(anon, 'config/store'))));
await t('anon reads config/economy denied', assertFails(getDoc(doc(anon, 'config/economy'))));
await t('user deletes other profile denied', assertFails(deleteDoc(doc(alice, 'users/pro'))));
await t('user deletes own profile ok', assertSucceeds(deleteDoc(doc(alice, 'users/alice'))));
console.log(`\n${pass} passed, ${fail} failed`);
await env.cleanup();
process.exit(fail ? 1 : 0);
