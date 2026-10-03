/* Personal Coach quota: every coach call costs a paid AI request, so each
   account gets a short burst limit and a daily allowance by plan. Counted
   server-side in coachQuota/{uid} (no client access: firestore.rules default
   deny), inside a transaction so parallel calls can't slip past. */
import { FsDb } from './economy/fsdb.js';
import { serviceAccount } from './server.js';
import { planOf } from './economy/core.js';

export const COACH_LIMITS = {
  perMinute: 5,
  perDay: { free: 10, plan: 60, top: 150 },
  topTiers: ['frequencyX'],
};

const istDay = (now) => new Date(now + 330 * 60e3).toISOString().slice(0, 10);

export function coachAllowance(user, now) {
  const plan = planOf(user, now);
  if (!plan.active) return COACH_LIMITS.perDay.free;
  return COACH_LIMITS.topTiers.includes(plan.tier) ? COACH_LIMITS.perDay.top : COACH_LIMITS.perDay.plan;
}

/** Takes one coach turn. { ok, left } or { ok:false, error, status }. */
export async function takeCoachTurn(env, uid, now = Date.now(), projectId = '') {
  if (!env.FIRESTORE_EMULATOR_HOST && !serviceAccount(env)) {
    return { ok: false, status: 503, error: 'The coach is switching on. Please try again soon.' };
  }
  const db = await FsDb.fromEnv({ ...env, FIREBASE_PROJECT_ID: env.FIREBASE_PROJECT_ID || projectId });
  return db.tx(async (t) => {
    const user = (await t.get(`users/${uid}`)).data || {};
    const q = (await t.get(`coachQuota/${uid}`)).data || {};
    const day = istDay(now);
    const used = q.day === day ? q.used || 0 : 0;
    const allow = coachAllowance(user, now);
    if (used >= allow) {
      return { ok: false, status: 429, error: planOf(user, now).active ? 'That\u2019s today\u2019s coach messages. More tomorrow.' : `That\u2019s today\u2019s ${allow} free coach messages. A plan gives you more.` };
    }
    const winStart = q.minuteAt && now - q.minuteAt < 60e3 ? q.minuteAt : now;
    const inWin = winStart === q.minuteAt ? q.minuteN || 0 : 0;
    if (inWin >= COACH_LIMITS.perMinute) return { ok: false, status: 429, error: 'One moment — the coach needs a short pause between messages.' };
    t.set(`coachQuota/${uid}`, { uid, day, used: used + 1, minuteAt: winStart, minuteN: inWin + 1, at: now });
    return { ok: true, left: allow - used - 1 };
  });
}
