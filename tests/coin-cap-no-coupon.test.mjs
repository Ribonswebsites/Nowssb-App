import test from 'node:test';
import assert from 'node:assert/strict';
import { quoteCheckout } from '../functions/_lib/economy/rules.js';
import { DEFAULT_ECONOMY } from '../functions/_lib/economy/config.js';

const cfg = DEFAULT_ECONOMY;
test('coins cover at most 30% of a Store price without a coupon', () => {
  for (const list of [99, 199, 499, 999]) {
    const q = quoteCheckout({ listINR: list, kind: 'word', coinsBalance: 1e9, cfg });
    assert.equal(q.coinCapPct, 30);
    assert.ok(q.coinsINR <= list * 0.3 + 1e-6, `${list}: ${q.coinsINR}`);
  }
});
test('a fitting coupon unlocks the band cap', () => {
  const q = quoteCheckout({ listINR: 999, kind: 'word', coinsBalance: 1e9, coupon: { type: 'percentOff', pct: 5, scope: 'any' }, cfg });
  assert.equal(q.coinCapPct, 40);
});
