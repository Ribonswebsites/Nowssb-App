/* NowssB Rewards — daily coins, streaks, quests, chests, time ladder,
   mastery, sets, season, leagues, badges, spending. Never ending: every
   loop resets daily / weekly / monthly / per season. */
import { DAY, dayIndex, hourOf, loginCoins, newBadges, seasonReward, seasonTier, stepStreak, weekdayOf, weekKey, monthKey, weeklyChestCoins, drawWeighted, badgeCatalog } from './rules.js';
import { P, bump, fail, grantExtra, grantPrize, inTx, issueScratch, moveCoins, notify, planOf, today, wallet } from './core.js';

/* ── helpers ── */
async function weekDoc(s, uid, key = s.week) {
  const w = await s.edit(P.week(uid, key), { week: key, counts: {}, activeDays: [], minutesByDay: {}, claimed: [] });
  w.counts = w.counts || {}; w.activeDays = w.activeDays || []; w.minutesByDay = w.minutesByDay || {}; w.claimed = w.claimed || [];
  return w;
}
async function monthDoc(s, uid, key = s.month) {
  const m = await s.edit(P.month(uid, key), { month: key, counts: {}, days: [], claimed: [] });
  m.counts = m.counts || {}; m.days = m.days || []; m.claimed = m.claimed || [];
  return m;
}
export async function checkBadges(s, uid) {
  const w = await wallet(s, uid);
  w.stats.streak = Math.max(w.stats.streak || 0, w.streak || 0);
  const fresh = newBadges(w.stats, w.badges, s.cfg);
  for (const b of fresh.slice(0, 5)) {
    w.badges.push(b.id);
    await moveCoins(s, uid, b.coins, 'badge:' + b.id);
    s.effect({ kind: 'badge', id: b.id, title: b.title, line: b.line });
  }
  return fresh.slice(0, 5).map((b) => b.id);
}
function weekMetric(wk, metric) {
  if (metric === 'activeDays') return wk.activeDays.length;
  if (metric === 'minutes') return Math.floor(Object.values(wk.minutesByDay).reduce((a, b) => a + (Number(b) || 0), 0));
  return Number(wk.counts[metric]) || 0;
}

/* ── daily login + streak ── */
export async function claimDailyLogin(ctx, uid) {
  return inTx(ctx, async (s) => {
    const R = s.cfg.rewards;
    const w = await wallet(s, uid);
    const d = await today(s, uid);
    if (d.login) return { coins: 0, already: true, streak: w.streak };
    d.login = true;
    const todayIdx = dayIndex(s.now, s.cfg);
    const prevIdx = w.lastDayIdx;
    const st = stepStreak({ lastDayIdx: prevIdx, todayIdx, streak: w.streak || 0, holds: w.holds || 0, freezes: w.freezes || 0, cfg: s.cfg });
    if (st.broken) {
      w.brokenStreak = { value: w.streak, dayIdx: todayIdx, missed: st.missed };
      w.milestonesHit = [];
    }
    w.streak = st.streak; w.holds = st.holds; w.freezes = st.freezes; w.freezesLeft = st.freezes + st.holds;
    w.bestStreak = Math.max(w.bestStreak || 0, w.streak);
    w.lastDayIdx = todayIdx;
    const out = { streak: w.streak, holdsUsed: st.used || 0, broken: !!st.broken };
    out.coins = await moveCoins(s, uid, loginCoins(w.streak, s.cfg), 'daily-login', { free: true });
    // Streak milestones (once per run).
    w.milestonesHit = w.milestonesHit || [];
    const ms = R.streakMilestones.find((m) => m.day === w.streak && !w.milestonesHit.includes(m.day));
    if (ms) {
      w.milestonesHit.push(ms.day);
      const got = [];
      got.push({ type: 'coins', coins: await moveCoins(s, uid, ms.coins, 'streak-' + ms.day) });
      if (ms.coupon) got.push(await issueScratch(s, uid, ms.coupon, 'streak-' + ms.day));
      if (ms.badge && !w.badges.includes(ms.badge)) w.badges.push(ms.badge);
      if (ms.day === 30) got.push(await grantPrize(s, uid, { type: 'giftbox', box: 'return30' }, 'streak-30'));
      out.milestone = { day: ms.day, items: got };
      s.effect({ kind: 'milestone', day: ms.day });
    }
    // Comeback gift.
    const away = prevIdx == null ? 0 : todayIdx - prevIdx;
    if (away >= R.comeback.awayDays && s.now - (w.lastComebackAt || 0) > R.comeback.everyDays * DAY) {
      w.lastComebackAt = s.now;
      const c = await moveCoins(s, uid, R.comeback.coins, 'comeback');
      const sc = await issueScratch(s, uid, R.comeback.coupon, 'comeback');
      out.comeback = { coins: c, scratch: sc };
      w.stats.comebacks = (w.stats.comebacks || 0) + 1;
    }
    // Activity marks for weekly/monthly loops and badges.
    const wk = await weekDoc(s, uid);
    if (!wk.activeDays.includes(todayIdx)) wk.activeDays.push(todayIdx);
    const mo = await monthDoc(s, uid);
    if (!mo.days.includes(todayIdx)) mo.days.push(todayIdx);
    w.stats.logins = (w.stats.logins || 0) + 1;
    const h = hourOf(s.now, s.cfg);
    if (h < 7) w.stats.early = 1;
    if (h >= 23) w.stats.night = 1;
    const wd = weekdayOf(s.now, s.cfg);
    if (wd === 0 && wk.activeDays.includes(todayIdx - 1)) w.stats.weekend = 1;
    await checkBadges(s, uid);
    // A referred friend becoming active pays the link holder once (Plan A: referred activates 60).
    await referredActivation(s, uid);
    return out;
  });
}

async function referredActivation(s, uid) {
  const A = s.cfg.reference.activation;
  const ref = await s.doc(P.referral(uid));
  if (!ref || ref.activationPaid) return;
  const holder = (ref.lockedTo && ref.lockedTo.ownerUid) || (ref.hold && ref.hold.ownerUid);
  if (!holder || holder === uid) return;
  const w = await wallet(s, uid);
  if ((w.stats.logins || 0) < A.activeDays) return;
  const r = await s.edit(P.referral(uid));
  r.activationPaid = s.now;
  await moveCoins(s, holder, A.coins, 'friend-active', { ref: uid });
  notify(s, holder, 'A friend is practising', `${A.coins} coins — your friend stayed ${A.activeDays} days.`, 'reference');
}

/** Restore a broken streak with a Restore credit (bought, gifted or won) or coins. */
export async function restoreStreak(ctx, uid, data) {
  return inTx(ctx, async (s) => {
    const w = await wallet(s, uid);
    const R = s.cfg.rewards.streakRestore;
    const b = w.brokenStreak;
    if (!b || !b.value) fail('There is no broken streak to restore.');
    if (dayIndex(s.now, s.cfg) - b.dayIdx > R.maxMissedDays) fail(`A streak can be restored within ${R.maxMissedDays} days of the break.`);
    if ((w.restores || 0) > 0) w.restores -= 1;
    else if (data && data.withCoins) await moveCoins(s, uid, -R.coinsPart, 'spend:streak-restore');
    else fail('You need a Streak Restore. Buy one in the Play Store version or use coins.', 400, 'failed-precondition', { needsProduct: R.productId, coins: R.coinsPart });
    w.streak = b.value + (w.streak || 0);
    w.bestStreak = Math.max(w.bestStreak || 0, w.streak);
    w.brokenStreak = null;
    s.effect({ kind: 'streak', streak: w.streak });
    return { streak: w.streak };
  });
}

/* ── standing actions (Practice Ring, word of the day, sound bath, …) ── */
export async function reportAction(ctx, uid, data) {
  const action = String((data && data.action) || '');
  const key = String((data && data.key) || '').slice(0, 80);
  return inTx(ctx, async (s) => {
    const A = s.cfg.rewards.actions[action];
    if (!A) fail('Unknown activity.', 400, 'invalid-argument');
    const w = await wallet(s, uid);
    const d = await today(s, uid);
    w.done = w.done || {};
    if (A.per === 'once') {
      if (w.done[action]) return { coins: 0, already: true };
      w.done[action] = s.now;
    } else if (A.per === 'key') {
      if (!key) fail('Missing item.', 400, 'invalid-argument');
      const k = action + ':' + key;
      w.doneKeys = w.doneKeys || {};
      if (w.doneKeys[k]) return { coins: 0, already: true };
      w.doneKeys[k] = s.now;
    } else if (A.per === 'month') {
      const mo = await monthDoc(s, uid);
      if ((mo.counts['act_' + action] || 0) >= (A.limit || 1)) return { coins: 0, already: true };
      mo.counts['act_' + action] = (mo.counts['act_' + action] || 0) + 1;
    } else {
      if ((d.counts[action] || 0) >= (A.limit || 1)) return { coins: 0, already: true, limit: A.limit };
      if (key && d.keys[action + ':' + key]) return { coins: 0, already: true };
      if (key) d.keys[action + ':' + key] = 1;
    }
    d.counts[action] = (d.counts[action] || 0) + 1;
    const metric = action === 'first_share' ? 'shares' : action === 'explore' ? 'explore_visits' : action;
    await bump(s, uid, metric, 1);
    if (action === 'explore' && d.counts.explore >= 6) w.stats.explorer = 1;
    if (action === 'echo_first_post') w.stats.echo_posts = (w.stats.echo_posts || 0) + 1;
    const coins = await moveCoins(s, uid, A.coins, 'act:' + action, { free: !!A.free, ref: key });
    await checkBadges(s, uid);
    return { coins, action, left: A.limit ? Math.max(0, A.limit - d.counts[action]) : 0 };
  });
}

/** Legacy practice report from the player (opens + practice counts). */
export async function reportPractice(ctx, uid, data) {
  return inTx(ctx, async (s) => {
    const w = await wallet(s, uid);
    if (data && data.openedPlayer) w.playerOpens = (w.playerOpens || 0) + 1;
    if (data && data.practiced) w.practice = (w.practice || 0) + 1;
    // Mastery is earned by practising a word on separate days (one level per
    // practice day by default), so a typed-in level can't mint coins.
    const wordId = String((data && data.wordId) || '').toLowerCase().replace(/[^a-z0-9_-]/g, '').slice(0, 60);
    if (data && data.practiced && wordId) {
      const m = await s.edit(`users/${uid}/mastery/${wordId}`, { word: wordId, level: 0 });
      if (m.lastPracticeDay !== s.day) { m.lastPracticeDay = s.day; m.practiceDays = (m.practiceDays || 0) + 1; m.updatedAt = s.now; }
    }
    if (data && data.score >= 80) {
      const d = await today(s, uid);
      const A = s.cfg.rewards.actions.pronounce80;
      if ((d.counts.pronounce80 || 0) < A.limit) {
        d.counts.pronounce80 = (d.counts.pronounce80 || 0) + 1;
        await bump(s, uid, 'pronounce80');
        await moveCoins(s, uid, A.coins, 'act:pronounce80', { free: true });
      }
    }
    return { playerOpens: w.playerOpens, practice: w.practice };
  });
}

/* ── time in the app: heartbeat, ladder, daily box ── */
export async function heartbeat(ctx, uid) {
  return inTx(ctx, async (s) => {
    const R = s.cfg.rewards;
    const d = await today(s, uid);
    const w = await wallet(s, uid);
    const last = d.lastBeatAt || 0;
    let add = 0;
    if (last && s.now - last <= 3 * 60e3) add = Math.min((s.now - last) / 60e3, R.heartbeatMaxMinutes);
    d.lastBeatAt = s.now;
    if (add > 0) {
      d.minutes = Math.round(((d.minutes || 0) + add) * 100) / 100;
      const wk = await weekDoc(s, uid);
      wk.minutesByDay[s.day] = d.minutes;
      w.stats.minutes = Math.round(((w.stats.minutes || 0) + add) * 100) / 100;
      await checkBadges(s, uid);
    }
    // 25-minute fragment draw (Plan A: one chance in eight), once a day.
    const fr = s.cfg.gifts.boxes.fragment25;
    let fragment = null;
    if (fr && d.minutes >= fr.minutes && !d.keys.fragment25) {
      d.keys.fragment25 = 1;
      const pick = drawWeighted(fr.contents).item;
      fragment = [];
      for (const p of pick.prize) fragment.push(await grantPrize(s, uid, p, 'fragment25'));
    }
    return { minutes: Math.floor(d.minutes || 0), ladder: ladderState(d, s.cfg), fragment };
  });
}
export function ladderState(d, cfg) {
  const m = (d && d.minutes) || 0;
  return cfg.rewards.timeLadder.map((st) => ({ ...st, reached: m >= st.minutes, claimed: ((d && d.ladder) || []).includes(st.minutes) }));
}
export async function claimTimeStep(ctx, uid, data) {
  const minutes = Number(data && data.minutes);
  return inTx(ctx, async (s) => {
    const st = s.cfg.rewards.timeLadder.find((x) => x.minutes === minutes);
    if (!st) fail('Unknown step.', 400, 'invalid-argument');
    const d = await today(s, uid);
    if ((d.minutes || 0) < st.minutes) fail(`Spend ${st.minutes} minutes today to open this step.`);
    if (d.ladder.includes(st.minutes)) return { coins: 0, already: true };
    d.ladder.push(st.minutes);
    const coins = await moveCoins(s, uid, st.coins, 'time-' + st.minutes, { free: true });
    return { coins, box: st.box, ladder: ladderState(d, s.cfg) };
  });
}
async function openContents(s, uid, boxId, source) {
  const B = s.cfg.gifts.boxes[boxId];
  if (!B) fail('Unknown box.', 400, 'invalid-argument');
  const pick = drawWeighted(B.contents).item;
  const items = [];
  for (const p of [].concat(pick.prize)) items.push(await grantPrize(s, uid, p, source));
  const w = await wallet(s, uid);
  w.stats.boxes = (w.stats.boxes || 0) + 1;
  s.effect({ kind: 'giftbox', box: boxId, items });
  return { box: boxId, title: B.title, items };
}
/** One free gift box a day: the best box the day's minutes have reached (or a lower one if asked). */
export async function openDailyBox(ctx, uid, data) {
  return inTx(ctx, async (s) => {
    const d = await today(s, uid);
    if (s.cfg.gifts.onePerDay && d.boxOpened) fail('Today’s gift box is open. A new one comes tomorrow.', 400, 'already-exists');
    const reached = s.cfg.rewards.timeLadder.filter((st) => (d.minutes || 0) >= st.minutes && st.box);
    if (!reached.length) fail(`Spend ${s.cfg.rewards.timeLadder[0].minutes} minutes today to earn a box.`);
    let step = reached[reached.length - 1];
    if (data && data.box) step = reached.find((x) => x.box === data.box) || step;
    d.boxOpened = step.box;
    const out = await openContents(s, uid, step.box, 'box-' + step.box);
    await checkBadges(s, uid);
    return out;
  });
}
/** A sealed box won elsewhere (prize, target, milestone). */
export async function openBox(ctx, uid, data) {
  const id = String((data && data.id) || '');
  return inTx(ctx, async (s) => {
    const path = `users/${uid}/boxes/${id}`;
    const b = await s.doc(path);
    if (!b) fail('Gift box not found.', 404, 'not-found');
    if (b.status !== 'sealed') fail('This box is already open.', 400, 'already-exists');
    if (b.expiresAt && b.expiresAt < s.now) fail('This box expired.');
    const e = await s.edit(path);
    e.status = 'opened'; e.openedAt = s.now;
    const out = await openContents(s, uid, b.box, 'box-' + b.box);
    e.items = out.items.map((x) => x.label);
    return out;
  });
}

/* ── quests: starter, weekly (+chest), monthly ── */
export async function claimQuest(ctx, uid, data) {
  const id = String((data && (data.questId || data.id)) || '');
  return inTx(ctx, async (s) => {
    const R = s.cfg.rewards;
    const w = await wallet(s, uid);
    const starter = (R.starterQuests || []).find((q) => q.id === id);
    if (starter) {
      w.done = w.done || {};
      if (w.done['q:' + id]) return { coins: 0, already: true };
      if ((Number(w[starter.metric]) || Number(w.stats[starter.metric]) || 0) < starter.goal) fail('Finish the quest first.');
      w.done['q:' + id] = s.now;
      w.stats.quests = (w.stats.quests || 0) + 1;
      const coins = await moveCoins(s, uid, starter.coins, 'quest:' + id);
      await checkBadges(s, uid);
      return { coins };
    }
    const q = R.weeklyQuests.find((x) => x.id === id);
    if (q) {
      const wk = await weekDoc(s, uid);
      if (wk.claimed.includes(id)) return { coins: 0, already: true };
      if (weekMetric(wk, q.metric) < q.goal) fail(`${q.title}: ${weekMetric(wk, q.metric)} of ${q.goal} so far.`);
      wk.claimed.push(id);
      w.stats.quests = (w.stats.quests || 0) + 1;
      const coins = await moveCoins(s, uid, q.coins, 'quest:' + id);
      await checkBadges(s, uid);
      return { coins };
    }
    if (id === R.monthlyQuest.id) {
      const mo = await monthDoc(s, uid);
      if (mo.claimed.includes(id)) return { coins: 0, already: true };
      if ((mo.counts[R.monthlyQuest.metric] || 0) < R.monthlyQuest.goal) fail(`${R.monthlyQuest.title}: ${mo.counts[R.monthlyQuest.metric] || 0} of ${R.monthlyQuest.goal}.`);
      mo.claimed.push(id);
      const coins = await moveCoins(s, uid, R.monthlyQuest.coins, 'quest:' + id);
      const sc = await issueScratch(s, uid, R.monthlyQuest.coupon, 'monthly-quest');
      return { coins, scratch: sc };
    }
    fail('Unknown quest.', 400, 'invalid-argument');
  });
}
export async function claimWeeklyChest(ctx, uid) {
  return inTx(ctx, async (s) => {
    const R = s.cfg.rewards;
    const wk = await weekDoc(s, uid);
    if (wk.claimed.includes('chest')) fail('This week’s chest is open. A new one comes Monday.', 400, 'already-exists');
    const left = R.weeklyQuests.filter((q) => !wk.claimed.includes(q.id));
    if (left.length) fail(`Claim all ${R.weeklyQuests.length} weekly quests to open the chest (${left.length} left).`);
    wk.claimed.push('chest');
    const coins = await moveCoins(s, uid, weeklyChestCoins(wk.activeDays.length, s.cfg), 'weekly-chest');
    const sc = await issueScratch(s, uid, R.weeklyChest.coupon, 'weekly-chest');
    s.effect({ kind: 'chest', coins });
    return { coins, items: [{ type: 'coins', coins, label: `${coins} coins` }, sc] };
  });
}
async function previousOrCurrent(s, uid, kind) {
  // Current period first, then the one before (claim window).
  if (kind === 'week') {
    const cur = await weekDoc(s, uid);
    const prevKey = weekKey(s.now - 7 * DAY, s.cfg);
    return [cur, await weekDoc(s, uid, prevKey)];
  }
  const cur = await monthDoc(s, uid);
  const prevKey = monthKey(s.now - Number(s.day.slice(6)) * DAY, s.cfg);
  return [cur, await monthDoc(s, uid, prevKey)];
}
export async function claimWeeklyGift(ctx, uid) {
  return inTx(ctx, async (s) => {
    const G = s.cfg.rewards.weeklyGift;
    const docs = await previousOrCurrent(s, uid, 'week');
    const ok = docs.find((wk) => !wk.claimed.includes('gift') && Object.values(wk.minutesByDay).filter((m) => m >= G.minutesPerDay).length >= G.activeDays);
    if (!ok) fail(`Practise ${G.minutesPerDay}+ minutes on ${G.activeDays} days in a week to earn the weekly gift.`);
    ok.claimed.push('gift');
    return openContents(s, uid, 'weekly', 'weekly-gift');
  });
}
export async function claimMonthlyGift(ctx, uid) {
  return inTx(ctx, async (s) => {
    const G = s.cfg.rewards.monthlyGift;
    const docs = await previousOrCurrent(s, uid, 'month');
    const ok = docs.find((mo) => !mo.claimed.includes('gift') && mo.days.length >= G.activeDays);
    if (!ok) fail(`Be active on ${G.activeDays} days in a month to earn the monthly gift.`);
    ok.claimed.push('gift');
    return openContents(s, uid, 'monthly', 'monthly-gift');
  });
}
export async function claimMonthlyMark(ctx, uid) {
  return inTx(ctx, async (s) => {
    const M = s.cfg.rewards.monthlyMark;
    const [, prev] = await previousOrCurrent(s, uid, 'month');
    if (prev.claimed.includes('mark')) fail('Last month’s mark is claimed.', 400, 'already-exists');
    if (prev.days.length < s.cfg.rewards.monthlyGift.activeDays) fail('The monthly mark needs 20 active days last month.');
    prev.claimed.push('mark');
    const coins = await moveCoins(s, uid, M.coins + M.perFullWeek * Math.floor(prev.days.length / 7), 'monthly-mark');
    return { coins };
  });
}

/* ── mastery and sets ── */
export async function reportMastery(ctx, uid, data) {
  const wordId = String((data && (data.wordId || data.word)) || '').toLowerCase().replace(/[^a-z0-9_-]/g, '').slice(0, 60);
  const level = Math.max(0, Math.min(50, Math.floor(Number(data && data.level) || 0)));
  if (!wordId) fail('Pick a word.', 400, 'invalid-argument');
  return inTx(ctx, async (s) => {
    const M = s.cfg.rewards.mastery;
    const path = `users/${uid}/mastery/${wordId}`;
    const m = await s.edit(path, { word: wordId, level: 0 });
    if (level <= m.level) return { coins: 0, level: m.level, already: true };
    const earned = Math.floor((m.practiceDays || 0) * (M.levelsPerPracticeDay ?? 1));
    if (earned <= m.level) fail(`Practise ${wordId} in the player on another day to reach the next level (${m.practiceDays || 0} practice day${(m.practiceDays || 0) === 1 ? '' : 's'} so far).`, 400, 'failed-precondition');
    const d = await today(s, uid);
    const room = Math.max(0, M.maxLevelUpsPerDay - (d.counts.mastery || 0));
    const ups = Math.min(level - m.level, room, earned - m.level);
    if (!ups) fail('That is all the mastery for today. Come back tomorrow.', 429, 'resource-exhausted');
    const before = m.level;
    m.level += ups; m.updatedAt = s.now;
    d.counts.mastery = (d.counts.mastery || 0) + ups;
    await bump(s, uid, 'mastery', ups);
    const coins = await moveCoins(s, uid, ups * M.coinsPerLevel, 'mastery:' + wordId, { free: true });
    const out = { coins, level: m.level };
    if (before < 5 && m.level >= 5) { const mo = await monthDoc(s, uid); mo.counts.mastered5 = (mo.counts.mastered5 || 0) + 1; }
    if (before < M.chestAtLevel && m.level >= M.chestAtLevel) out.chest = await issueScratch(s, uid, M.chestCoupon, 'mastery-chest');
    // Sets: every word of the set at level 5.
    const w = await wallet(s, uid);
    w.setsDone = w.setsDone || [];
    for (const set of s.cfg.rewards.sets) {
      if (w.setsDone.includes(set.id) || !set.words.includes(wordId)) continue;
      let all = true;
      for (const wd of set.words) {
        const md = wd === wordId ? m : await s.doc(`users/${uid}/mastery/${wd}`);
        if (!md || md.level < 5) { all = false; break; }
      }
      if (all) {
        w.setsDone.push(set.id);
        await moveCoins(s, uid, set.coins, 'set:' + set.id);
        if (set.badge && !w.badges.includes(set.badge)) w.badges.push(set.badge);
        out.set = set.id;
        s.effect({ kind: 'set', id: set.id, title: set.title });
      }
    }
    await checkBadges(s, uid);
    return out;
  });
}

/* ── season pass ── */
export async function claimSeason(ctx, uid, data) {
  const n = Math.floor(Number(data && data.tier));
  const premium = !!(data && data.premium);
  return inTx(ctx, async (s) => {
    const S = s.cfg.rewards.season;
    if (s.now < Date.parse(S.startsAt) || s.now > Date.parse(S.endsAt)) fail('The season is not running.');
    const w = await wallet(s, uid);
    const reached = seasonTier(w.seasonXp[S.id] || 0, s.cfg);
    if (!(n >= 1 && n <= reached)) fail(`Reach tier ${n} first.`);
    if (premium && !planOf(await s.doc(P.user(uid)), s.now).active) fail('The premium track is for plan holders.');
    const key = `${S.id}:${premium ? 'p' : 'f'}:${n}`;
    const claimed = w.seasonClaimed[S.id] || [];
    if (claimed.includes(key)) return { coins: 0, already: true };
    claimed.push(key); w.seasonClaimed[S.id] = claimed;
    const r = seasonReward(n, premium);
    const items = [{ type: 'coins', coins: await moveCoins(s, uid, r.coins, 'season:' + key), label: `${r.coins} coins` }];
    if (r.scratch) items.push(await issueScratch(s, uid, r.scratch, 'season'));
    if (r.giftbox) items.push(await grantPrize(s, uid, { type: 'giftbox', box: r.giftbox }, 'season'));
    return { items };
  });
}

/* ── leagues (weekly, by free coins earned that week) ── */
function boardPath(week, tier) { return `leagues/${week}_${tier}`; }
export async function leagueView(ctx, uid, name = '') {
  return inTx(ctx, async (s) => {
    const L = s.cfg.rewards.leagues;
    const w = await wallet(s, uid);
    const tier = L.tiers.includes(w.leagueTier) ? w.leagueTier : L.tiers[0];
    const d = await s.doc(P.day(uid, s.day));
    const wk = await weekDoc(s, uid);
    wk.xp = Math.max(wk.xp || 0, 0) + 0;
    // Weekly XP = free coins earned this week (recorded per day).
    wk.xpByDay = wk.xpByDay || {};
    wk.xpByDay[s.day] = (d && d.freeCoins) || 0;
    const xp = Object.values(wk.xpByDay).reduce((a, b) => a + b, 0);
    const b = await s.edit(boardPath(s.week, tier), { week: s.week, tier, entries: {} });
    b.entries = b.entries || {};
    b.entries[uid] = { xp, name: String(name || '').slice(0, 40) };
    const rows = Object.entries(b.entries).map(([id, e]) => ({ uid: id, xp: e.xp, name: e.name })).sort((x, y) => y.xp - x.xp);
    const me = rows.findIndex((r) => r.uid === uid);
    return { tier, title: L.titles[tier], xp, rank: me + 1, size: rows.length, top: rows.slice(0, 20).map((r, i) => ({ rank: i + 1, xp: r.xp, name: r.name || 'Listener', me: r.uid === uid })) };
  });
}
export async function claimLeague(ctx, uid) {
  return inTx(ctx, async (s) => {
    const L = s.cfg.rewards.leagues;
    const w = await wallet(s, uid);
    const prevWeek = weekKey(s.now - 7 * DAY, s.cfg);
    if (w.leagueClaimed === prevWeek) fail('Last week’s league prize is claimed.', 400, 'already-exists');
    const tier = L.tiers.includes(w.leagueTier) ? w.leagueTier : L.tiers[0];
    const b = await s.doc(boardPath(prevWeek, tier));
    if (!b || !b.entries || !b.entries[uid]) fail('You were not in a league last week.');
    const rows = Object.entries(b.entries).sort((x, y) => y[1].xp - x[1].xp);
    const rank = rows.findIndex(([id]) => id === uid) + 1;
    w.leagueClaimed = prevWeek;
    const prize = L.prizes[rank - 1] || 0;
    const coins = prize ? await moveCoins(s, uid, prize, 'league:' + prevWeek) : 0;
    const ti = L.tiers.indexOf(tier);
    let next = tier;
    if (rank <= L.promoteTop && ti < L.tiers.length - 1) next = L.tiers[ti + 1];
    else if (b.entries[uid].xp < L.demoteBelowXp && ti > 0) next = L.tiers[ti - 1];
    w.leagueTier = next;
    return { rank, coins, tier: next, promoted: L.tiers.indexOf(next) > ti };
  });
}

/* ── spending coins (never on cash) ── */
export async function spendCoins(ctx, uid, data) {
  const LEGACY = { freeze: 'streak_freeze', practice: 'practice_credit', early: 'early_access', cosmetic: null, badge: 'badge_buyer', boost: null };
  let item = String((data && (data.item || data.purpose)) || '');
  if (item === 'cosmetic') item = data.cosmeticId === 'frame_gold' ? 'frame_gold' : String(data.cosmeticId || '');
  else if (item in LEGACY && LEGACY[item]) item = LEGACY[item];
  if (item === 'boost') fail('Resale listings are paused (Play policy). Nothing was spent.', 400, 'failed-precondition');
  return inTx(ctx, async (s) => {
    const it = s.cfg.rewards.spend[item];
    if (!it) fail('Unknown item.', 400, 'invalid-argument');
    const w = await wallet(s, uid);
    if (it.cosmetic && w.cosmetics.includes(it.cosmetic)) fail('You already have this.', 400, 'already-exists');
    if (item === 'streak_freeze' && (w.freezes || 0) + (w.holds || 0) >= s.cfg.rewards.streakHold.max + 1) fail('You hold the most freezes allowed.');
    await moveCoins(s, uid, -it.coins, 'spend:' + item);
    if (item === 'streak_freeze') { w.freezes = (w.freezes || 0) + 1; w.freezesLeft = w.freezes + (w.holds || 0); }
    if (it.cosmetic) w.cosmetics.push(it.cosmetic);
    if (it.grant && it.grant.practiceCredits) w.practiceCredits = (w.practiceCredits || 0) + it.grant.practiceCredits;
    if (it.grant && it.grant.earlyHours) w.earlyUntil = Math.max(w.earlyUntil || 0, s.now) + it.grant.earlyHours * 3600e3;
    return { spent: it.coins, coins: w.coins, item };
  });
}

/** For the Badges tab. */
export function badgeList(walletDoc) {
  const have = new Set((walletDoc && walletDoc.badges) || []);
  const stats = (walletDoc && walletDoc.stats) || {};
  return badgeCatalog().map((b) => ({ ...b, have: have.has(b.id), value: Number(stats[b.metric]) || 0 }));
}
export { grantExtra };
