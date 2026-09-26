const crypto = require('crypto');
const admin = require('firebase-admin');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const rules = require('./economy');
const { verifyPlayProduct } = require('./play');
const { refreshFx } = require('./fx');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
setGlobalOptions({ region: 'europe-west1', maxInstances: 20 });

function uidOf(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  return request.auth.uid;
}

function stamp() {
  return admin.firestore.FieldValue.serverTimestamp();
}

function receiptId(token) {
  return crypto.createHash('sha256').update(String(token)).digest('hex');
}

function activeSub(data, now = Date.now()) {
  if (!data) return false;
  const plan = data.plan;
  return !!(plan && plan !== 'Free' && Number(data.subUntil || 0) > now);
}

async function ensureUser(tx, uid, installId) {
  const walletRef = db.doc(`users/${uid}/wallet/main`);
  const referralRef = db.doc(`users/${uid}/referral/main`);
  const sellerRef = db.doc(`users/${uid}/sellerStats/main`);
  const payoutRef = db.doc(`users/${uid}/payout/main`);
  const profileRef = db.doc(`profiles/${uid}`);
  const [wallet, referral, seller, payout, profile] = await Promise.all([
    tx.get(walletRef),
    tx.get(referralRef),
    tx.get(sellerRef),
    tx.get(payoutRef),
    tx.get(profileRef),
  ]);
  if (!wallet.exists) {
    tx.set(walletRef, {
      coins: 0, streak: 0, longestStreak: 0, plan: 'Free', subUntil: 0,
      freezesLeft: 2, freezeMonth: rules.ymd().slice(0, 6), cosmetics: [],
      practice: 0, playerOpens: 0, purchases: 0, createdAt: stamp(),
    });
  }
  let code = referral.exists ? referral.data().code : '';
  if (!referral.exists) {
    code = rules.makeCode(uid);
    tx.set(referralRef, {
      code, referredBy: '', paidReferralCount: 0, tier: 'Member',
      installId: String(installId || '').slice(0, 80),
      subscriptionActive: false,
      subscriptionLapsedAt: null,
    });
    tx.set(db.doc(`referralCodes/${code}`), { uid, active: false });
  }
  if (!seller.exists) {
    tx.set(sellerRef, { wordsSoldTotal: 0, tier: 'Seller', nextTierTarget: 100 });
  }
  if (!payout.exists) tx.set(payoutRef, { cashBalance: 0, lifetimeCents: 0 });
  if (!profile.exists) {
    tx.set(profileRef, {
      handle: `nowssb_${uid.slice(0, 6)}`,
      avatarUrl: '',
      bio: '',
      featuredBadges: [],
      pinnedPostId: '',
      publicStats: {
        streak: 0, longestStreak: 0, wordsOwned: 0, wordsSold: 0,
        memberSince: Date.now(),
      },
      sellerTier: 'Seller',
      circleTier: 'Member',
      followerCount: 0,
      followingCount: 0,
    });
  }
  if (referral.exists) {
    const open = activeSub(wallet.exists ? wallet.data() : null);
    const flag = referral.data().subscriptionActive === true;
    const code = referral.data().code;
    if (open && !flag) {
      tx.set(referralRef, { subscriptionActive: true, subscriptionLapsedAt: null }, { merge: true });
      if (code) tx.set(db.doc(`referralCodes/${code}`), { uid, active: true }, { merge: true });
    }
    if (!open && flag) {
      tx.set(referralRef, { subscriptionActive: false, subscriptionLapsedAt: Date.now() }, { merge: true });
      if (code) tx.set(db.doc(`referralCodes/${code}`), { uid, active: false }, { merge: true });
    }
  }
  return { walletRef, referralRef, sellerRef, payoutRef, profileRef, wallet, referral };
}

function remember(tx, uid, coins, cash) {
  tx._mem = tx._mem || {};
  if (coins != null) tx._mem[`c:${uid}`] = Number(coins);
  if (cash != null) tx._mem[`h:${uid}`] = Number(cash);
}

function writeCoins(tx, uid, delta, reason, refId) {
  const key = `c:${uid}`;
  if (!tx._mem || tx._mem[key] == null) {
    throw new HttpsError('internal', 'Wallet was not loaded before the coin write.');
  }
  const next = tx._mem[key] + delta;
  if (next < 0) throw new HttpsError('failed-precondition', 'Not enough coins.');
  tx.set(db.collection('coinLedger').doc(), {
    uid, delta, balanceAfter: next, reason, refId: refId || '', at: stamp(),
  });
  tx.set(db.doc(`users/${uid}/wallet/main`), { coins: next, updatedAt: stamp() }, { merge: true });
  tx._mem[key] = next;
  return next;
}

function writeCash(tx, uid, delta, reason, refId) {
  const key = `h:${uid}`;
  if (!tx._mem || tx._mem[key] == null) {
    throw new HttpsError('internal', 'Payout balance was not loaded before the cash write.');
  }
  const next = tx._mem[key] + delta;
  if (next < 0) throw new HttpsError('failed-precondition', 'Not enough payout balance.');
  tx.set(db.collection('cashLedger').doc(), {
    uid, delta, balanceAfter: next, reason, refId: refId || '', at: stamp(),
  });
  tx.set(db.doc(`users/${uid}/payout/main`), {
    cashBalance: next,
    lifetimeCents: admin.firestore.FieldValue.increment(delta > 0 ? delta : 0),
    updatedAt: stamp(),
  }, { merge: true });
  tx._mem[key] = next;
  return next;
}

function queueNotify(tx, uid, title, body, kind, refId) {
  tx.set(db.collection(`users/${uid}/notifications`).doc(), {
    title, body, kind: kind || 'earn', refId: refId || '', read: false, at: stamp(),
  });
}

function bumpPublic(tx, uid, profileSnap, patch) {
  const prev = profileSnap && profileSnap.exists ? profileSnap.data() : {};
  const next = { ...patch };
  if (patch.publicStats) {
    next.publicStats = { ...(prev.publicStats || {}), ...patch.publicStats };
  }
  tx.set(db.doc(`profiles/${uid}`), next, { merge: true });
}

async function loadCircle(tx, buyerUid) {
  const buyerReferral = await tx.get(db.doc(`users/${buyerUid}/referral/main`));
  const buyerWallet = await tx.get(db.doc(`users/${buyerUid}/wallet/main`));
  const loaded = { buyerReferral, buyerWallet, l1: null, l2: null };
  const code = buyerReferral.exists ? buyerReferral.data().referredBy : '';
  if (!code) return loaded;
  const codeDoc = await tx.get(db.doc(`referralCodes/${code}`));
  if (!codeDoc.exists) return loaded;
  const l1 = codeDoc.data().uid;
  if (!l1 || l1 === buyerUid) return loaded;
  const [l1Wallet, l1Referral, l1Payout] = await Promise.all([
    tx.get(db.doc(`users/${l1}/wallet/main`)),
    tx.get(db.doc(`users/${l1}/referral/main`)),
    tx.get(db.doc(`users/${l1}/payout/main`)),
  ]);
  loaded.l1 = { uid: l1, wallet: l1Wallet, referral: l1Referral, payout: l1Payout };
  const parentCode = l1Referral.exists ? l1Referral.data().referredBy : '';
  if (!parentCode) return loaded;
  const parentDoc = await tx.get(db.doc(`referralCodes/${parentCode}`));
  if (!parentDoc.exists) return loaded;
  const l2 = parentDoc.data().uid;
  if (!l2 || l2 === l1 || l2 === buyerUid) return loaded;
  const [l2Wallet, l2Payout, l2Referral] = await Promise.all([
    tx.get(db.doc(`users/${l2}/wallet/main`)),
    tx.get(db.doc(`users/${l2}/payout/main`)),
    tx.get(db.doc(`users/${l2}/referral/main`)),
  ]);
  loaded.l2 = { uid: l2, wallet: l2Wallet, payout: l2Payout, referral: l2Referral };
  return loaded;
}

function applyCircle(tx, loaded, { buyerUid, price, paymentId, plan }) {
  if (!loaded.l1 || !loaded.l1.referral.exists) return;
  const l1 = loaded.l1;
  const buyerReferral = loaded.buyerReferral;
  const l1Data = l1.referral.data() || {};
  const buyerData = buyerReferral.exists ? buyerReferral.data() : {};
  if (l1Data.installId && buyerData.installId && l1Data.installId === buyerData.installId) return;
  const alreadyCounted = buyerData.paidCounted === true;
  const prevCount = Number(l1Data.paidReferralCount || 0);
  const count = alreadyCounted ? prevCount : prevCount + 1;
  const tier = rules.circleTier(count);
  const l1Active = activeSub(l1.wallet.data());
  const code = String(l1Data.code || '');
  if (!l1Active) {
    tx.set(db.doc(`users/${l1.uid}/referral/main`), {
      subscriptionActive: false,
      subscriptionLapsedAt: Date.now(),
    }, { merge: true });
    if (code) tx.set(db.doc(`referralCodes/${code}`), { uid: l1.uid, active: false }, { merge: true });
    return;
  }
  tx.set(db.doc(`users/${l1.uid}/referral/main`), {
    subscriptionActive: true,
    subscriptionLapsedAt: null,
  }, { merge: true });
  if (code) tx.set(db.doc(`referralCodes/${code}`), { uid: l1.uid, active: true }, { merge: true });
  remember(
    tx,
    l1.uid,
    Number(l1.wallet.data()?.coins || 0),
    Number(l1.payout.data()?.cashBalance || 0),
  );
  if (!alreadyCounted) {
    tx.set(db.doc(`users/${l1.uid}/referral/main`), {
      paidReferralCount: count,
      tier: tier.name,
      subscriptionActive: true,
    }, { merge: true });
    tx.set(db.doc(`users/${buyerUid}/referral/main`), { paidCounted: true }, { merge: true });
    bumpPublic(tx, l1.uid, null, { circleTier: tier.name });
    queueNotify(tx, l1.uid, 'Circle', 'A paid referral landed on your code.', 'circle', paymentId);
  }
  tx.set(db.collection('referralLedger').doc(), {
    referrerUid: l1.uid, referredUid: buyerUid, level: 1, paymentId,
    commissionAmount: 0, amountBase: 0, currency: 'USD', at: stamp(), status: 'recorded',
  });
  if (count < 5) {
    const coins = Math.max(10, Math.round(price * 0.1));
    writeCoins(tx, l1.uid, coins, 'Referral coins', paymentId);
    queueNotify(tx, l1.uid, 'Referral coins', 'Coins were added for a paid referral.', 'circle', paymentId);
    return;
  }
  const cash = Math.round(price * tier.rate);
  if (cash > 0) {
    writeCash(tx, l1.uid, cash, 'Circle commission', paymentId);
    tx.set(db.collection('referralLedger').doc(), {
      referrerUid: l1.uid, referredUid: buyerUid, level: 1, paymentId,
      commissionAmount: cash, amountBase: cash, currency: 'USD', at: stamp(), status: 'paid',
    });
    queueNotify(tx, l1.uid, 'Circle commission', 'A commission was added to your earnings.', 'payout', paymentId);
  }
  const l2 = loaded.l2;
  if (!l2 || !plan) return;
  const l2Count = Number(l2.referral.data()?.paidReferralCount || 0);
  if (l2Count < 5) return;
  if (!activeSub(l2.wallet.data()) || l2.referral.data()?.subscriptionActive === false) return;
  const leg = Math.round(price * 0.05);
  if (leg <= 0) return;
  remember(tx, l2.uid, null, Number(l2.payout.data()?.cashBalance || 0));
  writeCash(tx, l2.uid, leg, 'Circle level 2', paymentId);
  tx.set(db.collection('referralLedger').doc(), {
    referrerUid: l2.uid, referredUid: buyerUid, level: 2, paymentId,
    commissionAmount: leg, amountBase: leg, currency: 'USD', at: stamp(), status: 'paid',
  });
  queueNotify(tx, l2.uid, 'Level 2 commission', 'A second-level commission was added.', 'payout', paymentId);
}

exports.ensureEconomyProfile = onCall(async (request) => {
  const uid = uidOf(request);
  const installId = String(request.data?.installId || '');
  await db.runTransaction(async (tx) => {
    await ensureUser(tx, uid, installId);
  });
  return { ok: true };
});

exports.claimDailyLogin = onCall(async (request) => {
  const uid = uidOf(request);
  const day = rules.ymd();
  const capRef = db.doc(`users/${uid}/earnCaps/${day}`);
  let granted = 0;
  await db.runTransaction(async (tx) => {
    const walletRef = db.doc(`users/${uid}/wallet/main`);
    const [cap, wallet, config, profile] = await Promise.all([
      tx.get(capRef),
      tx.get(walletRef),
      tx.get(db.doc('config/economy')),
      tx.get(db.doc(`profiles/${uid}`)),
    ]);
    if (cap.exists && cap.data().login) {
      throw new HttpsError('resource-exhausted', 'Daily login coins already claimed.');
    }
    const data = wallet.exists ? wallet.data() : {};
    const last = String(data.lastLoginYmd || '');
    let streak = Number(data.streak || 0);
    const yday = rules.yesterdayKey();
    if (last === day) streak = Math.max(streak, 1);
    else if (last === yday || Number(data.freezeUntil || 0) >= Date.now() - 86400000) streak += 1;
    else streak = 1;
    const mult = rules.loginMultiplier(streak);
    const bonus = rules.streakBonus(streak);
    const promo = config.exists ? Number(config.data().doubleUntil || 0) : 0;
    const base = Math.round(10 * mult) + bonus;
    granted = promo > Date.now() ? base * 2 : base;
    const longest = Math.max(Number(data.longestStreak || 0), streak);
    remember(tx, uid, Number(data.coins || 0));
    tx.set(capRef, { login: true, uid }, { merge: true });
    tx.set(walletRef, { streak, longestStreak: longest, lastLoginYmd: day }, { merge: true });
    writeCoins(tx, uid, granted, 'Daily login', day);
    queueNotify(tx, uid, 'Daily coins', 'Today’s login coins are in your Vault.', 'coins', day);
    bumpPublic(tx, uid, profile, { publicStats: { streak, longestStreak: longest } });
  });
  return { ok: true, coins: granted };
});

exports.verifyPlayPurchase = onCall(async (request) => {
  const uid = uidOf(request);
  const productId = String(request.data?.productId || '');
  const catalogId = String(request.data?.catalogId || '');
  const token = String(request.data?.purchaseToken || '');
  const itemId = String(request.data?.itemId || catalogId || productId);
  const title = String(request.data?.title || productId).slice(0, 80);
  const kindHint = String(request.data?.kind || '');
  const listPrice = Math.round(Number(request.data?.listPrice || 0));
  const coinsRequested = Math.round(Number(request.data?.coins || 0));
  const contentOwnerUid = String(request.data?.contentOwnerUid || '');
  const charged = rules.catalogItem(productId);
  if (!charged) throw new HttpsError('invalid-argument', 'Unknown Play product.');
  const named = catalogId ? rules.catalogItem(catalogId) : null;
  const item = named && named.kind !== 'cash' ? named : charged;
  const play = await verifyPlayProduct(productId, token);
  const id = receiptId(token);
  const receiptRef = db.doc(`playReceipts/${id}`);
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(receiptRef);
    if (existing.exists) return;
    const walletRef = db.doc(`users/${uid}/wallet/main`);
    const capRef = db.doc(`users/${uid}/earnCaps/${rules.ymd()}`);
    const [wallet, cap, profile, config, circle, referral] = await Promise.all([
      tx.get(walletRef),
      tx.get(capRef),
      tx.get(db.doc(`profiles/${uid}`)),
      tx.get(db.doc('config/economy')),
      loadCircle(tx, uid),
      tx.get(db.doc(`users/${uid}/referral/main`)),
    ]);
    const data = wallet.exists ? wallet.data() : {};
    const balance = Number(data.coins || 0);
    const price = item.kind === 'cash' ? (listPrice || charged.price) : item.price;
    const paid = charged.price;
    const ask = paid >= price ? 0 : coinsRequested;
    const cover = charged.kind !== 'cash' && ask === 0
      ? { ok: true, coins: 0, cash: paid, price }
      : rules.coinCoverage(price, balance, ask, paid);
    if (!cover.ok) throw new HttpsError('failed-precondition', cover.error);
    const alreadyBack = cap.exists ? Number(cap.data().coinBack || 0) : 0;
    const promo = config.exists ? Number(config.data().doubleUntil || 0) : 0;
    remember(tx, uid, balance);
    tx.set(receiptRef, { uid, productId, orderId: play.orderId, itemId, at: stamp() });
    if (cover.coins > 0) writeCoins(tx, uid, -cover.coins, 'Coin coverage', id);
    const kind = item.kind !== 'cash' ? item.kind : (kindHint || 'word');
    const purchases = Number(data.purchases || 0) + 1;
    if (kind === 'subscription' && item.plan) {
      tx.set(walletRef, {
        plan: item.plan,
        subUntil: Date.now() + 30 * 86400000,
        purchases,
      }, { merge: true });
      const refData = referral.exists ? referral.data() : {};
      tx.set(db.doc(`users/${uid}/referral/main`), {
        subscriptionActive: true,
        subscriptionLapsedAt: null,
      }, { merge: true });
      if (refData.code) {
        tx.set(db.doc(`referralCodes/${refData.code}`), { uid, active: true }, { merge: true });
      }
    } else if (kind === 'streak') {
      const longest = Math.max(Number(data.longestStreak || 0), Number(data.streak || 0), 1);
      tx.set(walletRef, {
        lastLoginYmd: rules.yesterdayKey(),
        streak: longest,
        longestStreak: longest,
        purchases,
      }, { merge: true });
    } else {
      tx.set(db.doc(`users/${uid}/owned/${itemId}`), {
        title, kind, price, originalPrice: price,
        contentOwnerUid: contentOwnerUid && contentOwnerUid !== uid ? contentOwnerUid : '',
        at: stamp(),
      });
      tx.set(walletRef, { purchases }, { merge: true });
      const owned = Number(profile.data()?.publicStats?.wordsOwned || 0) + 1;
      bumpPublic(tx, uid, profile, { publicStats: { wordsOwned: owned } });
    }
    let back = rules.purchaseCoinBack(price, kind);
    if (promo > Date.now()) back *= 2;
    if (alreadyBack + back > 100) back = Math.max(0, 100 - alreadyBack);
    if (back > 0) {
      writeCoins(tx, uid, back, 'Purchase back', id);
      tx.set(capRef, { coinBack: alreadyBack + back, uid }, { merge: true });
    }
    if (Number(data.purchases || 0) === 0) {
      writeCoins(tx, uid, 30, 'First purchase', id);
    }
    const month = new Date().getUTCMonth() + 1;
    const year = new Date().getUTCFullYear();
    const anniversaryMonth = config.exists ? Number(config.data().anniversaryMonth || 0) : 0;
    if (anniversaryMonth === month && Number(data.anniversaryYear || 0) !== year) {
      writeCoins(tx, uid, 40, 'Anniversary', String(year));
      tx.set(walletRef, { anniversaryYear: year }, { merge: true });
    }
    applyCircle(tx, circle, { buyerUid: uid, price, paymentId: id, plan: item.plan || '' });
  });
  return { ok: true };
});

exports.applyReferralCode = onCall(async (request) => {
  const uid = uidOf(request);
  const code = String(request.data?.code || '').trim().toUpperCase();
  if (code.length < 6) throw new HttpsError('invalid-argument', 'Enter the full code.');
  await db.runTransaction(async (tx) => {
    const mine = await tx.get(db.doc(`users/${uid}/referral/main`));
    if (mine.exists && mine.data().referredBy) {
      throw new HttpsError('already-exists', 'A referral code is already on this profile.');
    }
    const found = await tx.get(db.doc(`referralCodes/${code}`));
    if (!found.exists || found.data().active === false) {
      throw new HttpsError('not-found', 'That code is not active.');
    }
    if (found.data().uid === uid) throw new HttpsError('failed-precondition', 'You cannot use your own code.');
    const owner = found.data().uid;
    const theirs = await tx.get(db.doc(`users/${owner}/referral/main`));
    const ownerWallet = await tx.get(db.doc(`users/${owner}/wallet/main`));
    if (!activeSub(ownerWallet.data()) || (theirs.exists && theirs.data().subscriptionActive === false)) {
      throw new HttpsError('failed-precondition', 'That code is paused until their plan is active again.');
    }
    if (theirs.exists && mine.exists && theirs.data().installId && theirs.data().installId === mine.data().installId) {
      throw new HttpsError('failed-precondition', 'That code is on this device already.');
    }
    tx.set(db.doc(`users/${uid}/referral/main`), { referredBy: code }, { merge: true });
  });
  return { ok: true };
});

exports.spendCoins = onCall(async (request) => {
  const uid = uidOf(request);
  const purpose = String(request.data?.purpose || '');
  const costs = { freeze: 40, cosmetic: 80, boost: 60, early: 50, practice: 15, badge: 30 };
  const cost = costs[purpose];
  if (!cost) throw new HttpsError('invalid-argument', 'Unknown coin spend.');
  await db.runTransaction(async (tx) => {
    const walletRef = db.doc(`users/${uid}/wallet/main`);
    const wallet = await tx.get(walletRef);
    const data = wallet.exists ? wallet.data() : {};
    let listing = null;
    let profile = null;
    if (purpose === 'boost') {
      const listingId = String(request.data?.listingId || '');
      listing = await tx.get(db.doc(`listings/${listingId}`));
      if (!listing.exists || listing.data().sellerUid !== uid) {
        throw new HttpsError('not-found', 'Listing not found.');
      }
    }
    if (purpose === 'badge') profile = await tx.get(db.doc(`profiles/${uid}`));
    const month = rules.ymd().slice(0, 6);
    if (purpose === 'freeze') {
      const left = data.freezeMonth === month ? Number(data.freezesLeft ?? 2) : 2;
      if (left <= 0) throw new HttpsError('resource-exhausted', 'Two freezes a month.');
    }
    remember(tx, uid, Number(data.coins || 0));
    if (purpose === 'freeze') {
      const left = data.freezeMonth === month ? Number(data.freezesLeft ?? 2) : 2;
      tx.set(walletRef, {
        freezesLeft: left - 1,
        freezeMonth: month,
        freezeUntil: Date.now() + 86400000,
      }, { merge: true });
    }
    if (purpose === 'cosmetic') {
      const id = String(request.data?.cosmeticId || 'frame_gold').slice(0, 40);
      const list = Array.isArray(data.cosmetics) ? data.cosmetics : [];
      tx.set(walletRef, { cosmetics: list.concat(id).slice(-24) }, { merge: true });
    }
    if (purpose === 'boost' && listing) {
      tx.set(listing.ref, { boostUntil: Date.now() + 3 * 86400000 }, { merge: true });
    }
    if (purpose === 'practice') {
      tx.set(walletRef, { practiceCredits: Number(data.practiceCredits || 0) + 1 }, { merge: true });
    }
    if (purpose === 'early') {
      tx.set(walletRef, { earlyAccess: true }, { merge: true });
    }
    if (purpose === 'badge' && profile) {
      const badge = String(request.data?.badge || 'verified-buyer').slice(0, 40);
      const badges = profile.exists && Array.isArray(profile.data().earnedBadges)
        ? profile.data().earnedBadges
        : [];
      bumpPublic(tx, uid, profile, { earnedBadges: badges.concat(badge).slice(-12) });
    }
    writeCoins(tx, uid, -cost, `Spend ${purpose}`, purpose);
  });
  return { ok: true, spent: cost };
});

exports.createListing = onCall(async (request) => {
  const uid = uidOf(request);
  const itemId = String(request.data?.itemId || '');
  const asked = Math.round(Number(request.data?.price || 0));
  const ownedRef = db.doc(`users/${uid}/owned/${itemId}`);
  await db.runTransaction(async (tx) => {
    const owned = await tx.get(ownedRef);
    if (!owned.exists) throw new HttpsError('failed-precondition', 'You do not own that.');
    const data = owned.data();
    const band = rules.priceBand(data.originalPrice || data.price, asked);
    if (!band.ok) throw new HttpsError('failed-precondition', band.error);
    const listingId = `${uid}_${itemId}`.replace(/[^\w-]/g, '').slice(0, 80);
    tx.set(db.doc(`listings/${listingId}`), {
      sellerUid: uid,
      itemId,
      title: data.title || itemId,
      kind: data.kind || 'word',
      originalPrice: data.originalPrice || data.price,
      price: band.price,
      contentOwnerUid: data.contentOwnerUid || '',
      status: 'live',
      boostUntil: 0,
      rating: 0,
      ratingCount: 0,
      at: stamp(),
    });
  });
  return { ok: true };
});

exports.setFlashSale = onCall(async (request) => {
  const uid = uidOf(request);
  const listingId = String(request.data?.listingId || '');
  const asked = Math.round(Number(request.data?.price || 0));
  const hours = Math.min(72, Math.max(1, Math.round(Number(request.data?.hours || 24))));
  await db.runTransaction(async (tx) => {
    const listing = await tx.get(db.doc(`listings/${listingId}`));
    if (!listing.exists || listing.data().status !== 'live' || listing.data().sellerUid !== uid) {
      throw new HttpsError('not-found', 'Listing is not yours.');
    }
    const row = listing.data();
    const band = rules.priceBand(row.originalPrice, asked);
    if (!band.ok) throw new HttpsError('failed-precondition', band.error);
    if (asked > row.price) {
      throw new HttpsError('failed-precondition', 'A flash sale lowers the price.');
    }
    const floor = Math.ceil(row.price * 0.7);
    if (asked < floor) {
      throw new HttpsError('failed-precondition', 'A flash sale can cut at most 30% off the live price.');
    }
    tx.set(listing.ref, { price: band.price, flashUntil: Date.now() + hours * 3600000 }, { merge: true });
  });
  return { ok: true };
});

exports.purchaseListing = onCall(async (request) => {
  const uid = uidOf(request);
  const listingId = String(request.data?.listingId || '');
  const productId = String(request.data?.productId || '');
  const token = String(request.data?.purchaseToken || '');
  const coinsRequested = Math.round(Number(request.data?.coins || 0));
  const charged = rules.catalogItem(productId);
  if (!charged || charged.kind !== 'cash') {
    throw new HttpsError('invalid-argument', 'Use a cash Play product.');
  }
  const play = await verifyPlayProduct(productId, token);
  const id = receiptId(token);
  await db.runTransaction(async (tx) => {
    const receiptRef = db.doc(`playReceipts/${id}`);
    if ((await tx.get(receiptRef)).exists) return;
    const listingRef = db.doc(`listings/${listingId}`);
    const listing = await tx.get(listingRef);
    if (!listing.exists || listing.data().status !== 'live') {
      throw new HttpsError('not-found', 'Listing is not for sale.');
    }
    const row = listing.data();
    if (row.sellerUid === uid) throw new HttpsError('failed-precondition', 'You cannot buy your own listing.');
    const wallet = await tx.get(db.doc(`users/${uid}/wallet/main`));
    const sellerStatsRef = db.doc(`users/${row.sellerUid}/sellerStats/main`);
    const sellerPayoutRef = db.doc(`users/${row.sellerUid}/payout/main`);
    const sellerProfileRef = db.doc(`profiles/${row.sellerUid}`);
    const [stats, sellerPayout, sellerProfile] = await Promise.all([
      tx.get(sellerStatsRef),
      tx.get(sellerPayoutRef),
      tx.get(sellerProfileRef),
    ]);
    let ownerPayout = null;
    const ownerUid = row.contentOwnerUid && row.contentOwnerUid !== row.sellerUid ? row.contentOwnerUid : '';
    if (ownerUid) ownerPayout = await tx.get(db.doc(`users/${ownerUid}/payout/main`));
    const cover = rules.coinCoverage(
      row.price,
      wallet.data()?.coins || 0,
      charged.price >= row.price ? 0 : coinsRequested,
      charged.price,
    );
    if (!cover.ok) throw new HttpsError('failed-precondition', cover.error);
    const sold = Number(stats.data()?.wordsSoldTotal || 0);
    const split = rules.splitSale(row.price, sold);
    remember(tx, uid, Number(wallet.data()?.coins || 0));
    remember(tx, row.sellerUid, null, Number(sellerPayout.data()?.cashBalance || 0));
    if (ownerUid) remember(tx, ownerUid, null, Number(ownerPayout.data()?.cashBalance || 0));
    tx.set(receiptRef, { uid, productId, orderId: play.orderId, itemId: listingId, at: stamp() });
    if (cover.coins > 0) writeCoins(tx, uid, -cover.coins, 'Bazaar coins', id);
    tx.set(db.doc(`users/${uid}/owned/${row.itemId}`), {
      title: row.title, kind: row.kind, price: row.price,
      originalPrice: row.originalPrice, contentOwnerUid: row.contentOwnerUid || '',
      at: stamp(),
    });
    tx.delete(db.doc(`users/${row.sellerUid}/owned/${row.itemId}`));
    tx.set(listingRef, { status: 'sold', buyerUid: uid, soldAt: stamp() }, { merge: true });
    const tier = split.tier;
    tx.set(sellerStatsRef, {
      wordsSoldTotal: sold + 1,
      tier: tier.name,
      nextTierTarget: tier.next,
    }, { merge: true });
    writeCash(tx, row.sellerUid, split.seller, 'Bazaar sale', id);
    if (ownerUid && split.royalty > 0) writeCash(tx, ownerUid, split.royalty, 'Resale royalty', id);
    const wordsSold = Number(sellerProfile.data()?.publicStats?.wordsSold || 0) + 1;
    bumpPublic(tx, row.sellerUid, sellerProfile, {
      sellerTier: tier.name,
      publicStats: { wordsSold },
    });
    tx.set(db.doc(`sellerProfiles/${row.sellerUid}`), {
      tier: tier.name, wordsSold,
    }, { merge: true });
  });
  return { ok: true };
});

exports.reviewResale = onCall(async (request) => {
  const uid = uidOf(request);
  const listingId = String(request.data?.listingId || '');
  const up = request.data?.up === true;
  const comment = String(request.data?.comment || '').slice(0, 180);
  const check = rules.moderateText(comment || 'ok');
  if (comment && !check.ok) throw new HttpsError('invalid-argument', check.error);
  await db.runTransaction(async (tx) => {
    const listing = await tx.get(db.doc(`listings/${listingId}`));
    if (!listing.exists || listing.data().buyerUid !== uid || listing.data().status !== 'sold') {
      throw new HttpsError('failed-precondition', 'Only the buyer can review a finished sale.');
    }
    const sellerUid = listing.data().sellerUid;
    const reviewRef = db.doc(`resaleReviews/${listingId}_${uid}`);
    const profileRef = db.doc(`sellerProfiles/${sellerUid}`);
    const [prior, profile] = await Promise.all([tx.get(reviewRef), tx.get(profileRef)]);
    if (prior.exists) throw new HttpsError('already-exists', 'Already reviewed.');
    tx.set(reviewRef, {
      listingId, sellerUid, buyerUid: uid, up, comment, status: 'live', at: stamp(),
    });
    const count = Number(profile.data()?.reviewCount || 0) + 1;
    const prev = Number(profile.data()?.rating || 0);
    const score = up ? 1 : 0;
    tx.set(profileRef, {
      reviewCount: count,
      rating: Math.round(((prev * (count - 1) + score) / count) * 100) / 100,
    }, { merge: true });
  });
  return { ok: true };
});

exports.toggleWishlist = onCall(async (request) => {
  const uid = uidOf(request);
  const itemId = String(request.data?.itemId || '').slice(0, 80);
  if (!itemId) throw new HttpsError('invalid-argument', 'Missing item.');
  const ref = db.doc(`users/${uid}/wishlist/${itemId}`);
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) tx.delete(ref);
    else tx.set(ref, { itemId, at: stamp() });
  });
  return { ok: true };
});

exports.reportPractice = onCall(async (request) => {
  const uid = uidOf(request);
  await db.runTransaction(async (tx) => {
    const walletRef = db.doc(`users/${uid}/wallet/main`);
    const wallet = await tx.get(walletRef);
    const data = wallet.exists ? wallet.data() : {};
    const now = Date.now();
    if (now - Number(data.lastPracticeAt || 0) < 10 * 60 * 1000) {
      throw new HttpsError('resource-exhausted', 'Practice is counted once every 10 minutes.');
    }
    const day = rules.ymd();
    const capRef = db.doc(`users/${uid}/earnCaps/${day}`);
    const cap = await tx.get(capRef);
    const n = cap.exists ? Number(cap.data().practice || 0) : 0;
    if (n >= 20) throw new HttpsError('resource-exhausted', 'Daily practice cap reached.');
    tx.set(capRef, { practice: n + 1, uid }, { merge: true });
    tx.set(walletRef, {
      practice: Number(data.practice || 0) + 1,
      lastPracticeAt: now,
      playerOpens: Number(data.playerOpens || 0) + (request.data?.openedPlayer ? 1 : 0),
    }, { merge: true });
  });
  return { ok: true };
});

exports.claimQuest = onCall(async (request) => {
  const uid = uidOf(request);
  const quest = rules.QUESTS.find((q) => q.id === request.data?.questId);
  if (!quest) throw new HttpsError('invalid-argument', 'Unknown quest.');
  const week = rules.ymd().slice(0, 6);
  await db.runTransaction(async (tx) => {
    const wallet = await tx.get(db.doc(`users/${uid}/wallet/main`));
    const claimRef = db.doc(`users/${uid}/quests/${quest.id}_${week}`);
    const claim = await tx.get(claimRef);
    const value = Number(wallet.data()?.[quest.field] || 0);
    if (value < quest.goal) throw new HttpsError('failed-precondition', 'Quest is not finished.');
    if (claim.exists) throw new HttpsError('already-exists', 'Quest chest already opened.');
    remember(tx, uid, Number(wallet.data()?.coins || 0));
    tx.set(claimRef, { at: stamp() });
    writeCoins(tx, uid, quest.reward, 'Quest chest', quest.id);
  });
  return { ok: true, coins: quest.reward };
});

exports.claimMilestone = onCall(async (request) => {
  const uid = uidOf(request);
  const wordId = String(request.data?.wordId || '').slice(0, 80);
  const level = Math.round(Number(request.data?.level || 0));
  const reward = rules.milestoneReward(level);
  if (!wordId || !reward) throw new HttpsError('invalid-argument', 'Level must be 1 to 10.');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`users/${uid}/milestones/${wordId}`);
    const walletRef = db.doc(`users/${uid}/wallet/main`);
    const [prev, wallet] = await Promise.all([tx.get(ref), tx.get(walletRef)]);
    const last = prev.exists ? Number(prev.data().level || 0) : 0;
    if (level <= last) throw new HttpsError('already-exists', 'That level was already claimed.');
    remember(tx, uid, Number(wallet.data()?.coins || 0));
    tx.set(ref, { level, at: stamp() });
    writeCoins(tx, uid, reward.coins, 'Milestone chest', `${wordId}:${level}`);
    if (reward.cosmetic) {
      const list = Array.isArray(wallet.data()?.cosmetics) ? wallet.data().cosmetics : [];
      tx.set(walletRef, { cosmetics: list.concat(reward.cosmetic) }, { merge: true });
    }
  });
  return { ok: true, coins: reward.coins, cosmetic: reward.cosmetic };
});

exports.createEchoPost = onCall(async (request) => {
  const uid = uidOf(request);
  const check = rules.moderateText(request.data?.text);
  if (!check.ok) throw new HttpsError('invalid-argument', check.error);
  const imageRef = String(request.data?.imageRef || '');
  if (imageRef && !imageRef.startsWith(`echo/${uid}/`)) {
    throw new HttpsError('invalid-argument', 'Image must be stored on your own echo path.');
  }
  const day = rules.ymd();
  const capRef = db.doc(`users/${uid}/earnCaps/${day}`);
  const postRef = db.collection('echoPosts').doc();
  await db.runTransaction(async (tx) => {
    const cap = await tx.get(capRef);
    const n = cap.exists ? Number(cap.data().posts || 0) : 0;
    if (n >= 5) throw new HttpsError('resource-exhausted', 'Five posts a day.');
    tx.set(capRef, { posts: n + 1, uid }, { merge: true });
    tx.set(postRef, {
      authorUid: uid,
      text: check.text,
      imageRef,
      likeCount: 0,
      commentCount: 0,
      reportCount: 0,
      status: 'live',
      at: stamp(),
    });
  });
  return { ok: true, postId: postRef.id };
});

exports.commentOnPost = onCall(async (request) => {
  const uid = uidOf(request);
  const postId = String(request.data?.postId || '');
  const check = rules.moderateText(request.data?.text);
  if (!check.ok) throw new HttpsError('invalid-argument', check.error);
  const parentId = String(request.data?.parentId || '');
  await db.runTransaction(async (tx) => {
    const postRef = db.doc(`echoPosts/${postId}`);
    const post = await tx.get(postRef);
    let parent = null;
    if (parentId) parent = await tx.get(db.doc(`echoComments/${parentId}`));
    if (!post.exists || post.data().status !== 'live') {
      throw new HttpsError('not-found', 'Post is not live.');
    }
    if (parentId && (!parent || !parent.exists || parent.data().parentId)) {
      throw new HttpsError('failed-precondition', 'Replies only go one level deep.');
    }
    tx.set(db.collection('echoComments').doc(), {
      postId, parentId, authorUid: uid, text: check.text, status: 'live', at: stamp(),
    });
    tx.set(postRef, { commentCount: Number(post.data().commentCount || 0) + 1 }, { merge: true });
  });
  return { ok: true };
});

exports.toggleEchoLike = onCall(async (request) => {
  const uid = uidOf(request);
  const postId = String(request.data?.postId || '');
  const likeRef = db.doc(`echoPosts/${postId}/likes/${uid}`);
  await db.runTransaction(async (tx) => {
    const postRef = db.doc(`echoPosts/${postId}`);
    const [post, like] = await Promise.all([tx.get(postRef), tx.get(likeRef)]);
    if (!post.exists || post.data().status !== 'live') {
      throw new HttpsError('not-found', 'Post is not live.');
    }
    const count = Number(post.data().likeCount || 0);
    if (like.exists) {
      tx.delete(likeRef);
      tx.set(postRef, { likeCount: Math.max(0, count - 1) }, { merge: true });
    } else {
      tx.set(likeRef, { at: stamp() });
      tx.set(postRef, { likeCount: count + 1 }, { merge: true });
    }
  });
  return { ok: true };
});

exports.reportEcho = onCall(async (request) => {
  const uid = uidOf(request);
  const targetType = request.data?.targetType === 'comment' ? 'comment' : 'post';
  const targetId = String(request.data?.targetId || '');
  const reason = String(request.data?.reason || 'other').slice(0, 80);
  const reportRef = db.collection('echoReports').doc();
  await db.runTransaction(async (tx) => {
    const prior = await tx.get(
      db.collection('echoReports').where('targetId', '==', targetId).where('reporterUid', '==', uid).limit(1),
    );
    const targetRef = db.doc(`${targetType === 'comment' ? 'echoComments' : 'echoPosts'}/${targetId}`);
    const target = await tx.get(targetRef);
    if (!prior.empty) throw new HttpsError('already-exists', 'You already reported this.');
    if (!target.exists) throw new HttpsError('not-found', 'Nothing to report.');
    const count = Number(target.data().reportCount || 0) + 1;
    tx.set(reportRef, {
      targetType, targetId, reporterUid: uid, reason, status: 'pending', at: stamp(),
    });
    tx.set(targetRef, {
      reportCount: count,
      status: count >= 3 ? 'hidden' : target.data().status,
    }, { merge: true });
  });
  return { ok: true };
});

exports.reviewEchoReport = onCall(async (request) => {
  const uid = uidOf(request);
  const adminDoc = await db.doc(`admins/${uid}`).get();
  if (!adminDoc.exists) throw new HttpsError('permission-denied', 'Admins only.');
  const reportId = String(request.data?.reportId || '');
  const remove = request.data?.remove === true;
  const reportRef = db.doc(`echoReports/${reportId}`);
  await db.runTransaction(async (tx) => {
    const report = await tx.get(reportRef);
    if (!report.exists) throw new HttpsError('not-found', 'Report missing.');
    const data = report.data();
    const targetRef = db.doc(`${data.targetType === 'comment' ? 'echoComments' : 'echoPosts'}/${data.targetId}`);
    tx.set(reportRef, { status: 'reviewed', reviewedBy: uid }, { merge: true });
    tx.set(targetRef, { status: remove ? 'removed' : 'live' }, { merge: true });
  });
  return { ok: true };
});

exports.updateWordPrint = onCall(async (request) => {
  const uid = uidOf(request);
  const handle = String(request.data?.handle || '').trim().slice(0, 24);
  const bio = String(request.data?.bio || '').trim().slice(0, 140);
  const badges = Array.isArray(request.data?.featuredBadges)
    ? request.data.featuredBadges.map((b) => String(b).slice(0, 40)).slice(0, 6)
    : null;
  const patch = {};
  if (handle) patch.handle = handle;
  if (request.data?.bio != null) patch.bio = bio;
  if (badges) patch.featuredBadges = badges;
  if (request.data?.pinnedPostId != null) patch.pinnedPostId = String(request.data.pinnedPostId).slice(0, 80);
  await db.doc(`profiles/${uid}`).set(patch, { merge: true });
  return { ok: true };
});

exports.setFollow = onCall(async (request) => {
  const uid = uidOf(request);
  const target = String(request.data?.targetUid || '');
  const follow = request.data?.follow !== false;
  if (!target || target === uid) throw new HttpsError('invalid-argument', 'Pick someone else.');
  const followingRef = db.doc(`follows/${uid}/following/${target}`);
  const followerRef = db.doc(`follows/${target}/followers/${uid}`);
  await db.runTransaction(async (tx) => {
    const existing = await tx.get(followingRef);
    const mine = await tx.get(db.doc(`profiles/${uid}`));
    const theirs = await tx.get(db.doc(`profiles/${target}`));
    if (follow && !existing.exists) {
      tx.set(followingRef, { at: stamp() });
      tx.set(followerRef, { at: stamp() });
      bumpPublic(tx, uid, mine, { followingCount: Number(mine.data()?.followingCount || 0) + 1 });
      bumpPublic(tx, target, theirs, { followerCount: Number(theirs.data()?.followerCount || 0) + 1 });
    }
    if (!follow && existing.exists) {
      tx.delete(followingRef);
      tx.delete(followerRef);
      bumpPublic(tx, uid, mine, { followingCount: Math.max(0, Number(mine.data()?.followingCount || 0) - 1) });
      bumpPublic(tx, target, theirs, { followerCount: Math.max(0, Number(theirs.data()?.followerCount || 0) - 1) });
    }
  });
  return { ok: true };
});

exports.requestPayout = onCall(async (request) => {
  const uid = uidOf(request);
  const requestRef = db.collection('payoutRequests').doc();
  let amount = 0;
  let vpa = '';
  await db.runTransaction(async (tx) => {
    const payout = await tx.get(db.doc(`users/${uid}/payout/main`));
    amount = Number(payout.data()?.cashBalance || 0);
    vpa = String(payout.data()?.upi || '').trim().toLowerCase();
    if (amount < 500) {
      throw new HttpsError('failed-precondition', 'Payout opens once your earnings reach the minimum.');
    }
    if (!/^[\w.\-]{2,}@[\w.\-]{2,}$/.test(vpa)) {
      throw new HttpsError('failed-precondition', 'Add a UPI id before requesting a payout.');
    }
    remember(tx, uid, null, amount);
    writeCash(tx, uid, -amount, 'Payout request', requestRef.id);
    tx.set(requestRef, {
      uid,
      amountBase: amount,
      currency: 'USD',
      settlementCurrency: 'INR',
      status: 'pending',
      at: stamp(),
    });
  });
  const key = process.env.RAZORPAYX_KEY_ID;
  const secret = process.env.RAZORPAYX_KEY_SECRET;
  const account = process.env.RAZORPAYX_ACCOUNT_NUMBER;
  if (!key || !secret || !account) {
    await requestRef.set({ status: 'queued' }, { merge: true });
    queueNotifyOutside(uid, 'Payout queued', 'Your payout is waiting for the settlement rail.');
    return { ok: true, status: 'queued' };
  }
  try {
    const fx = await db.doc('config/fx').get();
    const inr = Number(fx.data()?.rates?.INR || 83.5);
    const paise = Math.max(100, Math.round((amount / 100) * inr * 100));
    const razorpayId = await sendRazorpayPayout({ key, secret, account, vpa, paise, reference: requestRef.id, uid });
    await requestRef.set({
      status: 'processing',
      razorpayPayoutId: razorpayId,
      settlementAmount: paise,
    }, { merge: true });
    return { ok: true, status: 'processing' };
  } catch (err) {
    await db.runTransaction(async (tx) => {
      const payout = await tx.get(db.doc(`users/${uid}/payout/main`));
      remember(tx, uid, null, Number(payout.data()?.cashBalance || 0));
      writeCash(tx, uid, amount, 'Payout returned', requestRef.id);
    });
    await requestRef.set({ status: 'failed' }, { merge: true });
    throw new HttpsError('failed-precondition', 'The payout could not be sent. Your balance was returned.');
  }
});

function queueNotifyOutside(uid, title, body) {
  return db.collection(`users/${uid}/notifications`).add({
    title, body, kind: 'payout', refId: '', read: false, at: stamp(),
  });
}

async function sendRazorpayPayout({ key, secret, account, vpa, paise, reference, uid }) {
  const auth = Buffer.from(`${key}:${secret}`).toString('base64');
  const headers = { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' };
  const contactRes = await fetch('https://api.razorpay.com/v1/contacts', {
    method: 'POST',
    headers,
    body: JSON.stringify({ name: 'NowssB member', type: 'customer', reference_id: uid.slice(0, 20) }),
  });
  const contact = await contactRes.json();
  if (!contactRes.ok) throw new Error(contact.error?.description || 'contact');
  const fundRes = await fetch('https://api.razorpay.com/v1/fund_accounts', {
    method: 'POST',
    headers,
    body: JSON.stringify({
      contact_id: contact.id,
      account_type: 'vpa',
      vpa: { address: vpa },
    }),
  });
  const fund = await fundRes.json();
  if (!fundRes.ok) throw new Error(fund.error?.description || 'fund');
  const payRes = await fetch('https://api.razorpay.com/v1/payouts', {
    method: 'POST',
    headers,
    body: JSON.stringify({
      account_number: account,
      fund_account_id: fund.id,
      amount: paise,
      currency: 'INR',
      mode: 'UPI',
      purpose: 'payout',
      queue_if_low_balance: true,
      reference_id: reference.slice(0, 40),
    }),
  });
  const payout = await payRes.json();
  if (!payRes.ok) throw new Error(payout.error?.description || 'payout');
  return payout.id || '';
}

exports.razorpayPayoutWebhook = onRequest(async (req, res) => {
  const secret = process.env.RAZORPAYX_WEBHOOK_SECRET;
  if (!secret) {
    res.status(503).send('unconfigured');
    return;
  }
  const expected = crypto.createHmac('sha256', secret).update(req.rawBody || '').digest('hex');
  const got = String(req.get('x-razorpay-signature') || '');
  if (expected !== got) {
    res.status(401).send('bad signature');
    return;
  }
  const event = String(req.body?.event || '');
  const entity = req.body?.payload?.payout?.entity || {};
  const id = entity.id;
  if (!id) {
    res.status(200).send('ok');
    return;
  }
  const found = await db.collection('payoutRequests').where('razorpayPayoutId', '==', id).limit(1).get();
  if (!found.empty) {
    const status = event.includes('processed') ? 'paid' : event.includes('failed') || event.includes('reversed') ? 'failed' : 'processing';
    const row = found.docs[0].data();
    const prev = String(row.status || '');
    await found.docs[0].ref.set({ status }, { merge: true });
    if (status === 'paid' && prev !== 'paid') {
      await db.collection(`users/${row.uid}/notifications`).add({
        title: 'Payout sent', body: 'Your earnings payout was processed.', kind: 'payout', refId: id, read: false, at: stamp(),
      });
    }
    if (status === 'failed' && prev !== 'failed' && prev !== 'paid') {
      await db.runTransaction(async (tx) => {
        const payout = await tx.get(db.doc(`users/${row.uid}/payout/main`));
        remember(tx, row.uid, null, Number(payout.data()?.cashBalance || 0));
        writeCash(tx, row.uid, Number(row.amountBase || 0), 'Payout failed', id);
      });
    }
  }
  res.status(200).send('ok');
});

exports.refreshFxRates = onSchedule('every 24 hours', async () => {
  await refreshFx(db, stamp);
});

exports.savePayoutAccount = onCall(async (request) => {
  const uid = uidOf(request);
  const upi = String(request.data?.upi || '').trim().toLowerCase();
  if (!/^[\w.\-]{2,}@[\w.\-]{2,}$/.test(upi)) {
    throw new HttpsError('invalid-argument', 'Enter a UPI id like name@bank.');
  }
  await db.doc(`users/${uid}/payout/main`).set({ upi }, { merge: true });
  return { ok: true };
});

exports.dismissEarnCard = onCall(async (request) => {
  const uid = uidOf(request);
  await db.doc(`users/${uid}/prefs/earn`).set({
    hasSeenEarnCard: true,
    earnCardLastShownAt: Date.now(),
  }, { merge: true });
  return { ok: true };
});

exports.blockEchoUser = onCall(async (request) => {
  const uid = uidOf(request);
  const target = String(request.data?.targetUid || '');
  if (!target || target === uid) throw new HttpsError('invalid-argument', 'Pick someone else.');
  await db.doc(`blocks/${uid}/blocked/${target}`).set({ at: stamp() });
  return { ok: true };
});
