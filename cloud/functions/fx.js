/** Daily FX cache. Frankfurter needs no key. Fallback rates keep the app usable offline. */

const FALLBACK = {
  USD: 1,
  INR: 83.5,
  EUR: 0.92,
  GBP: 0.78,
  AED: 3.67,
  SGD: 1.35,
  AUD: 1.52,
  CAD: 1.36,
  JPY: 149,
};

async function refreshFx(db, stamp) {
  let rates = { ...FALLBACK };
  let source = 'fallback';
  try {
    const res = await fetch('https://api.frankfurter.app/latest?from=USD');
    if (res.ok) {
      const body = await res.json();
      rates = { USD: 1, ...(body.rates || {}) };
      if (!rates.INR) rates.INR = FALLBACK.INR;
      source = 'frankfurter';
    }
  } catch (_) {
    source = 'fallback';
  }
  await db.doc('config/fx').set({
    base: 'USD',
    rates,
    source,
    updatedAt: stamp(),
  }, { merge: true });
  return rates;
}

module.exports = { refreshFx, FALLBACK };
