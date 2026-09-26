const assert = require('assert');
const e = require('./economy');

const cover = e.coinCoverage(100, 40, 40, 99);
assert.strictEqual(cover.ok, true);
assert.strictEqual(cover.coins, 30);

const notASku = e.coinCoverage(100, 40, 30, 70);
assert.strictEqual(notASku.ok, false);

const band = e.priceBand(100, 160);
assert.strictEqual(band.ok, false);
const okBand = e.priceBand(100, 150);
assert.strictEqual(okBand.ok, true);

const split = e.splitSale(100, 999);
assert.strictEqual(split.platform, 10);
assert.strictEqual(split.royalty, 3);
assert.strictEqual(split.seller, 87);

assert.strictEqual(e.circleTier(5).rate, 0.2);
assert.strictEqual(e.circleTier(100).rate, 0.35);
assert.strictEqual(e.sellerTier(1000).platformCut, 0.1);
assert.ok(e.loginMultiplier(30) <= 2);
assert.strictEqual(e.streakBonus(20), 40);
assert.strictEqual(e.milestoneReward(10).cosmetic, 'frame_level10');
assert.strictEqual(e.moderateText('hello nowssb').ok, true);
assert.strictEqual(e.moderateText('fuck this').ok, false);

console.log('economy rules ok');
