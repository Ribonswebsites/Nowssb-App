/** Pure economy rules. Cloud Functions call these; the phone does not. */

const CASH_TIERS = [49, 99, 149, 199, 249, 299, 399, 499, 699, 999];

const CATALOG = {
  nwsb_sub_resonance: { kind: 'subscription', price: 249, plan: 'Resonance' },
  nwsb_sub_frequency: { kind: 'subscription', price: 499, plan: 'Frequency' },
  nwsb_sub_frequency_x: { kind: 'subscription', price: 999, plan: 'Frequency X' },
  nwsb_word: { kind: 'word', price: 49 },
  nwsb_meaning: { kind: 'meaning', price: 49 },
  nwsb_bundle_10: { kind: 'bundle', price: 490, bonus: 50 },
  nwsb_package: { kind: 'package', price: 199, bonus: 40 },
  nwsb_streak_restore: { kind: 'streak', price: 99 },
};

const QUESTS = [
  { id: 'practice5', title: 'Practice 5 words', field: 'practice', goal: 5, reward: 25 },
  { id: 'streak3', title: 'Hold a 3-day streak', field: 'streak', goal: 3, reward: 30 },
  { id: 'listen1', title: 'Open the player', field: 'playerOpens', goal: 1, reward: 15 },
  { id: 'buy1', title: 'Complete one purchase', field: 'purchases', goal: 1, reward: 20 },
];

const BLOCKED = [
  'fuck', 'shit', 'bitch', 'asshole', 'cunt', 'nigger', 'faggot', 'slut',
];

function ymd(date = new Date()) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}${m}${d}`;
}

function yesterdayKey(date = new Date()) {
  const copy = new Date(date.getTime() - 86400000);
  return ymd(copy);
}

function cashSku(amount) {
  const n = Math.round(Number(amount) || 0);
  return `nwsb_cash_${n}`;
}

function cashAmountFromSku(productId) {
  const match = /^nwsb_cash_(\d+)$/.exec(productId || '');
  return match ? Number(match[1]) : null;
}

function catalogItem(productId) {
  if (CATALOG[productId]) return { id: productId, ...CATALOG[productId] };
  const cash = cashAmountFromSku(productId);
  if (cash != null) return { id: productId, kind: 'cash', price: cash };
  return null;
}

/** Coins may cover at most 30%. Cash must be a verified Play price. */
function coinCoverage(listPrice, balance, requested, cashPaid) {
  const price = Math.round(Number(listPrice) || 0);
  const paid = Math.round(Number(cashPaid) || 0);
  const cap = Math.floor(price * 0.3);
  const ask = Math.max(0, Math.round(Number(requested) || 0));
  const coins = Math.min(cap, ask, Math.max(0, Math.round(balance || 0)));
  if (price <= 0) return { ok: false, error: 'Price is missing.' };
  if (coins > cap) return { ok: false, error: 'Coins cannot cover more than 30%.' };
  if (paid < price - cap) return { ok: false, error: 'Cash must cover at least 70%.' };
  if (paid + coins < price) return { ok: false, error: 'Cash plus coins do not cover the price.' };
  if (!CASH_TIERS.includes(paid) && paid !== price) {
    return { ok: false, error: 'That cash amount is not a Play product.' };
  }
  return { ok: true, price, coins, cash: paid, cap };
}

function loginMultiplier(streak) {
  const days = Math.max(1, Math.round(streak || 1));
  const scaled = 1 + Math.min(days, 30) / 30;
  return Math.min(2, Math.round(scaled * 100) / 100);
}

function streakBonus(streak) {
  const days = Math.round(streak || 0);
  if (days < 10 || days % 10 !== 0) return 0;
  return 20 * (days / 10);
}

function sellerTier(sold) {
  const n = Math.round(sold || 0);
  if (n >= 1000) return { name: 'Master Seller', platformCut: 0.1, next: 1000 };
  if (n >= 500) return { name: 'Elite Seller', platformCut: 0.12, next: 1000 };
  if (n >= 300) return { name: 'Pro Seller', platformCut: 0.15, next: 500 };
  if (n >= 100) return { name: 'Rising Seller', platformCut: 0.18, next: 300 };
  return { name: 'Seller', platformCut: 0.2, next: 100 };
}

function circleTier(paid) {
  const n = Math.round(paid || 0);
  if (n >= 100) return { name: 'Platinum', rate: 0.35, next: 100 };
  if (n >= 50) return { name: 'Gold', rate: 0.3, next: 100 };
  if (n >= 20) return { name: 'Silver', rate: 0.25, next: 50 };
  if (n >= 5) return { name: 'Bronze', rate: 0.2, next: 20 };
  return { name: 'Member', rate: 0, next: 5 };
}

function priceBand(original, asked) {
  const base = Math.round(Number(original) || 0);
  const price = Math.round(Number(asked) || 0);
  if (base < 1 || price < 1) return { ok: false, error: 'Set a price.' };
  const low = Math.ceil(base * 0.5);
  const high = Math.floor(base * 1.5);
  if (price < low || price > high) {
    return { ok: false, error: `Price must stay between ₹${low} and ₹${high}.` };
  }
  return { ok: true, price, low, high };
}

function splitSale(price, soldBefore) {
  const tier = sellerTier(soldBefore + 1);
  const gross = Math.round(price);
  const royalty = Math.round(gross * 0.03);
  const platform = Math.max(Math.round(gross * tier.platformCut), Math.round(gross * 0.1));
  const seller = Math.max(0, gross - platform - royalty);
  return { tier, royalty, platform, seller };
}

function purchaseCoinBack(price, kind) {
  const percent = Math.min(100, Math.round(price * 0.08));
  const extra = kind === 'bundle' ? 50 : kind === 'package' ? 40 : 0;
  return percent + extra;
}

function milestoneReward(level) {
  const n = Math.round(level || 0);
  if (n < 1 || n > 10) return null;
  return {
    coins: n * 5,
    cosmetic: n === 10 ? 'frame_level10' : null,
  };
}

function moderateText(raw) {
  const text = String(raw || '').trim();
  if (!text) return { ok: false, error: 'Write something first.' };
  if (text.length > 280) return { ok: false, error: 'Keep it under 280 characters.' };
  const folded = text.toLowerCase();
  if (BLOCKED.some((word) => folded.includes(word))) {
    return { ok: false, error: 'That post was blocked by the filter.' };
  }
  const links = folded.match(/https?:\/\//g) || [];
  if (links.length > 1) return { ok: false, error: 'One link at most.' };
  return { ok: true, text };
}

function makeCode(uid) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let body = '';
  const seed = `${uid}:${Date.now()}`;
  for (let i = 0; i < 6; i += 1) {
    body += alphabet[(seed.charCodeAt(i % seed.length) + i * 17) % alphabet.length];
  }
  return `NSB${body}`;
}

module.exports = {
  CASH_TIERS,
  CATALOG,
  QUESTS,
  ymd,
  yesterdayKey,
  cashSku,
  cashAmountFromSku,
  catalogItem,
  coinCoverage,
  loginMultiplier,
  streakBonus,
  sellerTier,
  circleTier,
  priceBand,
  splitSale,
  purchaseCoinBack,
  milestoneReward,
  moderateText,
  makeCode,
};
