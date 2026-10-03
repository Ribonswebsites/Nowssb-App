/* NowssB economy settings — the ONE settings document.

   Every percentage, threshold, odds table and cap in the plan lives here as
   the starting value. The live copy is Firestore `config/economy`; whatever
   an admin saves there is deep-merged over these defaults on the server, so a
   change needs no app update. `version` and `updatedAt/updatedBy` give the
   audit trail (the admin panel appends to `config/economy/history`).

   Sources: "NowssB Plan — Earn · Rewards · Gifts · Coupons · Reference"
   (Sept 2026, 12 pages; "Plan A") and "NowssB Plan … · Partner Program"
   (Sept 2026, 21 pages; "Plan B"). Where the two disagree the 21-page plan
   (the later, fuller one) is the default and the other value is noted next
   to the key, so an admin can switch with one edit.

   Money is in INR at the India price tier (the ratios hold in every market).
   Amounts paid in another currency are converted with `fxToINR` before the
   lock is applied. Coins: 10 coins = ₹1 of catalogue value. */

const pct = (n) => n; // readability: values below are percentages

export const DEFAULT_ECONOMY = {
  version: 1,
  currency: 'INR',
  coinsPerRupee: 10,
  dayOffsetMinutes: 330, // days roll over at midnight IST
  fxToINR: { INR: 1, USD: 84, EUR: 91, GBP: 107, AED: 22.9, SGD: 62, AUD: 55, CAD: 61, JPY: 0.56, BRL: 15, MXN: 4.6, NZD: 50 },

  // ── 2 · How the money works (the money lock) ──
  lock: {
    storeReservePct: pct(20),     // Plan A: 20% of ex-tax held for the store fee, raised to the real fee when higher
    storeFeeWorstCasePct: pct(30), // Plan B checks against 30% worst case
    payoutCapPct: pct(65),        // Plan B: 65% of Net (Plan A: 55)
    companyFloorPct: pct(35),     // NowssB keeps at least this share of Net
    targetBonusReservePct: pct(5),
    floorPerWordINR: 15,          // minimum per word sold, yields when the cap binds
    renewalRateFactor: 0.5,       // Plan A: renewals pay half the direct rate (and half the overrides)
    holdDays: 30,                 // pending → available after the refund window
    refundReverseDays: 30,
    shrinkOrder: ['leg2', 'leg1', 'floor'], // what gives way first when the cap binds; own rate is never cut (Plan B)
  },

  // ── 3 · NowssB Earn ──
  earn: {
    enabled: true,
    // User decision (final): PDF-2 ranks and rates, paid from PDF-1's Net (tax and the
    // Play fee come off first — see lock). Every number here is editable in config/economy.
    // Plan names map to the live tiers (Plan B decision 2): Basic = resonance, Plus/Standard = frequency, Premium/top = frequencyX.
    planMap: { resonance: 'basic', frequency: 'plus', frequencyX: 'premium' },
    topTiers: ['frequencyX'],
    ranks: [
      { id: 'assistant', title: 'Assistant Officer', metal: 'Bronze', minWords: 0, ratePct: 15, plan: 'any', appoints: [], leg: [0, 0], coinsPerSale: 5, keep90: 5, teamMax: 0 },
      { id: 'officer', title: 'Officer', metal: 'Silver', minWords: 100, ratePct: 22, plan: 'any', appoints: ['assistant'], leg: [3, 0], coinsPerSale: 8, keep90: 15, teamMax: 5 },
      { id: 'executive1', title: 'Executive Officer I', metal: 'Gold', minWords: 500, ratePct: 30, plan: 'top', appoints: ['assistant', 'officer'], leg: [5, 1.5], coinsPerSale: 12, keep90: 40, teamMax: 10 },
      { id: 'executive2', title: 'Executive Officer II', metal: 'Gold', minWords: 1000, ratePct: 38, plan: 'top', appoints: ['assistant', 'officer'], leg: [5, 1.5], coinsPerSale: 12, keep90: 40, teamMax: 10 },
      { id: 'partner1', title: 'Diamond I', metal: 'Diamond', minWords: 2000, ratePct: 45, plan: 'top', appoints: ['assistant', 'officer', 'executive1'], leg: [7, 3], coinsPerSale: 20, keep90: 100, teamMax: 25 },
      { id: 'partner2', title: 'Diamond II', metal: 'Diamond', minWords: 3000, ratePct: 50, plan: 'top', appoints: ['assistant', 'officer', 'executive1'], leg: [7, 3], coinsPerSale: 20, keep90: 100, teamMax: 25 },
    ],
    // Target reached → one-time cash bonus (pending like commission) + coins + coupon + extras.
    targets: [
      { words: 100, cashINR: 1000, coins: 300, coupon: 'rare', extras: ['badge:officer'] },
      { words: 500, cashINR: 3500, coins: 1000, coupon: 'epic', extras: ['giftbox:gold'] },
      { words: 1000, cashINR: 4500, coins: 2000, coupon: 'legendary', extras: ['pass:premium:7'] },
      { words: 2000, cashINR: 9000, coins: 4000, coupon: 'legendary', extras: ['badge:priority-support'] },
      { words: 3000, cashINR: 10500, coins: 6000, coupon: 'mythic', extras: ['pass:premium:30', 'early:48'] },
    ],
    wordWeights: { word: 1, meaning: 1, stage: 0.5, bundle: 10, signature: 2, ebook: 0, subscription: 0, giftcard: 0, scratch: 0, restore: 0 },
    provisionalDays: 60,
    provisionalMinWords: 10,
    provisionalRatePct: 100, // Plan B: appointees start at the base rate. Plan A: 60.
    fastStartDays: 30,
    fastStartBonusPct: 5,
    monthlyPoolPct: 1,
    monthlyPoolTop: 20,
    keepWindowDays: 90,
    requirePaidPlanToEarn: true,
    blockTeamPurchases: true,
    payout: {
      minINR: 1250,          // about US$15
      payoutDay: 10,
      launchModeManual: true, // every payout approved by a person
      rails: { IN: 'upi_manual', default: 'wise_manual' }, // PDF: India UPI; elsewhere Wise or PayPal, paid by hand
      withholdingPct: 0,
      requireLegalName: true,
      requireTaxIdIN: true,
    },
  },

  // ── 4 · NowssB Rewards ──
  rewards: {
    dailyCeiling: 250,
    newAccountDays: 3,
    newAccountCeiling: 120,
    expireAfterInactiveDays: 365,
    eventMultiplier: 1,
    events: [], // [{ id, title, multiplier: 2, startsAt: ISO, endsAt: ISO, weekdays: [6,0] }] double-coin weekends etc.
    login: { base: 5, max: 15, perStreakDays: 3 },
    streakMilestones: [
      { day: 1, coins: 10 }, { day: 3, coins: 20 }, { day: 7, coins: 50 }, { day: 10, coins: 60 },
      { day: 20, coins: 100 }, { day: 30, coins: 150, coupon: 'rare', badge: 'streak-30' },
      { day: 60, coins: 250, coupon: 'rare', badge: 'streak-60' }, { day: 100, coins: 400, coupon: 'epic', badge: 'streak-100' },
      { day: 200, coins: 600, coupon: 'epic', badge: 'streak-200' }, { day: 365, coins: 1000, coupon: 'legendary', badge: 'streak-365' },
    ],
    streakHold: { everyDays: 14, max: 2 },
    streakFreezeCoins: 40,
    streakRestore: { coinsPart: 100, productId: 'nowssb_streak_restore', maxMissedDays: 3 },
    comeback: { awayDays: 7, coins: 50, coupon: 'rare', everyDays: 60 },
    // Standing actions. limit = per day unless `per` says otherwise. free = counts toward the daily ceiling.
    actions: {
      open: { title: 'Open the app', coins: 5, limit: 1, free: true },
      ring_listen: { title: 'Practice Ring · listen', coins: 5, limit: 1, free: true },
      ring_say: { title: 'Practice Ring · say it aloud', coins: 8, limit: 1, free: true },
      ring_reflect: { title: 'Practice Ring · save or reflect', coins: 12, limit: 1, free: true },
      word_of_day: { title: 'Word of the day', coins: 10, limit: 1, free: true },
      sound_bath: { title: 'Sound Bath session', coins: 10, limit: 2, free: true },
      pronounce80: { title: 'Pronunciation 80+', coins: 5, limit: 5, free: true },
      quote: { title: 'Read or share the daily quote', coins: 3, limit: 1, free: true },
      read_meaning: { title: 'Read one meaning to the end', coins: 8, limit: 3, free: true },
      explore: { title: 'Visit a program page', coins: 2, limit: 6, free: true },
      // per:'key' actions are also capped per day (dayLimit) and checked on the server.
      first_share: { title: 'First share of a word', coins: 15, per: 'key', dayLimit: 5, free: true },
      close_stage: { title: 'Close a stage', coins: 40, per: 'key', dayLimit: 3, free: true, verify: 'mastery' },
      profile_complete: { title: 'Complete your profile', coins: 50, per: 'once', free: false, verify: 'profile' },
      reminders_on: { title: 'Turn on reminders', coins: 50, per: 'once', free: false, verify: 'reminders' },
      echo_first_post: { title: 'First Echo Wall post', coins: 10, per: 'once', free: true },
      feedback: { title: 'In-app feedback', coins: 10, per: 'month', limit: 1, free: true },
    },
    timeLadder: [
      { minutes: 10, coins: 10, box: 'bronze' },
      { minutes: 20, coins: 20, box: 'silver' },
      { minutes: 40, coins: 40, box: 'gold' },
      { minutes: 60, coins: 70, box: 'diamond' },
    ],
    heartbeatMaxMinutes: 1.5, // farming control: a beat can add at most this much time
    heartbeatMinGapSec: 45,   // beats closer than this add nothing
    maxMinutesPerDay: 120,    // counted app time per day (the ladder tops out at 60)
    weeklyQuests: [
      { id: 'w_practice', title: 'Practise on 4 days', metric: 'activeDays', goal: 4, coins: 30 },
      { id: 'w_minutes', title: 'Spend 60 minutes', metric: 'minutes', goal: 60, coins: 40 },
      { id: 'w_meanings', title: 'Read 5 meanings', metric: 'read_meaning', goal: 5, coins: 25 },
      { id: 'w_bath', title: 'Finish 3 Sound Baths', metric: 'sound_bath', goal: 3, coins: 25 },
      { id: 'w_pron', title: 'Score 80+ ten times', metric: 'pronounce80', goal: 10, coins: 20 },
    ],
    // One-time starter quests (the four on the Vault page).
    starterQuests: [
      { id: 'practice5', title: 'Practise 5 times', metric: 'practice', goal: 5, coins: 25 },
      { id: 'streak3', title: 'Keep a 3-day streak', metric: 'streak', goal: 3, coins: 20 },
      { id: 'listen1', title: 'Open the player', metric: 'playerOpens', goal: 1, coins: 10 },
      { id: 'buy1', title: 'Make a first purchase', metric: 'purchases', goal: 1, coins: 50 },
    ],
    weeklyChest: { minCoins: 100, maxCoins: 200, coupon: 'common' },
    weeklyGift: { activeDays: 5, minutesPerDay: 20, claimDays: 30 },
    monthlyQuest: { id: 'm_master', title: 'Master 3 words to level 5', metric: 'mastered5', goal: 3, coins: 200, coupon: 'epic' },
    monthlyGift: { activeDays: 20, claimDays: 30 },
    monthlyMark: { coins: 150, perFullWeek: 20 },
    mastery: { coinsPerLevel: 5, chestAtLevel: 10, chestCoupon: 'rare', maxLevelUpsPerDay: 10, levelsPerPracticeDay: 1 },
    sets: [
      { id: 'elements', title: 'Elements', words: ['earth', 'water', 'fire', 'sun', 'moon', 'light', 'dark'], coins: 100, badge: 'set-elements' },
      { id: 'human', title: 'Human', words: ['body', 'mind', 'soul', 'blood', 'breath'], coins: 100, badge: 'set-human' },
      { id: 'emotions', title: 'Emotions', words: ['love', 'fear', 'joy'], coins: 100, badge: 'set-emotions' },
    ],
    buying: {
      coinsBackPct: 4,
      renewalBonus: { 3: 100, 6: 250, 12: 600 },
      firstPurchase: { coins: 100, coupon: 'rare' },
      bundleBonusPct: 5,
      freeScratchAfterPurchase: true,
    },
    community: { likeMilestones: [{ likes: 10, coins: 10 }, { likes: 50, coins: 25 }, { likes: 100, coins: 50 }] },
    season: {
      id: 'S1-2026', title: 'Season of Sound', startsAt: '2026-10-01T00:00:00+05:30', endsAt: '2026-12-31T23:59:59+05:30',
      tiers: 30, xpPerTier: 150,
      // reward for tier n is generated: free track coins (20 + 5n), coupon every 5th; premium track double + gift box every 10th.
    },
    leagues: {
      tiers: ['whisper', 'echo', 'harmony', 'zenith'],
      titles: { whisper: 'Whisper', echo: 'Echo', harmony: 'Harmony', zenith: 'Zenith' },
      promoteTop: 10,
      demoteBelowXp: 20,
      prizes: [300, 200, 150, 100, 80, 70, 60, 55, 50, 50],
    },
    spend: {
      streak_freeze: { title: 'Streak Freeze', coins: 40 },
      practice_credit: { title: 'Extra pronunciation checks ×5', coins: 15, grant: { practiceCredits: 5 } },
      early_access: { title: 'Early access to new words', coins: 50, grant: { earlyHours: 24 } },
      frame_gold: { title: 'Gold avatar frame', coins: 80, cosmetic: 'frame_gold' },
      theme_night: { title: 'Night theme', coins: 60, cosmetic: 'theme_night' },
      flair_lotus: { title: 'Lotus profile flair', coins: 40, cosmetic: 'flair_lotus' },
      badge_buyer: { title: 'Verified buyer badge', coins: 30, cosmetic: 'badge_verified_buyer' },
      wrap_gold: { title: 'Gold gift wrap', coins: 30, cosmetic: 'wrap_gold' },
      wrap_lotus: { title: 'Lotus gift wrap', coins: 30, cosmetic: 'wrap_lotus' },
    },
  },

  // Coins and discounts in a cart (Plan B 4.3; Plan A 30/40 split at ₹500).
  cart: {
    coinCapBands: [{ maxINR: 120, pct: 30 }, { maxINR: 220, pct: 35 }, { maxINR: 1e12, pct: 40 }],
    subscriptionCoinPct: 40,
    maxTotalDiscountPct: 50,
    order: ['link', 'coupon', 'coins'],
    checkoutTtlMinutes: 30,
    // Play price-tier SKUs used to charge the remainder after coins/coupons (INR). Create each as a consumable in Play Console.
    payTiersINR: [29, 39, 49, 59, 69, 79, 89, 99, 119, 129, 149, 169, 199, 229, 249, 279, 299, 349, 399, 449, 499, 599, 699, 799, 999, 1199, 1499, 1999],
    // Lowest list price the server accepts per kind (protects against a forged list price).
    priceFloorINR: { word: 49, meaning: 49, stage: 29, bundle: 299, signature: 199, ebook: 49 },
    priceCeilINR: { word: 350, meaning: 350, stage: 150, bundle: 1999, signature: 999, ebook: 999 },
    // Content price points and defaults (mirror of billing_config.dart). The
    // server prices each bag line itself from config/store + these; the
    // phone's price is only checked against it.
    contentTiersINR: {
      word: [79, 99, 149, 199, 249, 299, 349],
      meaning: [79, 99, 149, 199, 249, 299, 349],
      signature: [199, 249, 299, 349, 399, 499, 599, 699, 799, 999],
      ebook: [149, 199, 249, 299, 349, 399, 499, 599, 699, 799, 999],
    },
    contentDefaultINR: { word: 99, meaning: 99, signature: 299, ebook: 399 },
  },

  // ── 5 · NowssB Coupons ──
  coupons: {
    rarities: ['common', 'rare', 'epic', 'legendary', 'mythic'],
    freeExpiryDays: 30,
    percentOffExpiryDays: 30,
    dailyScratch: true,
    // Prize pools by rarity of a FREE scratch (Plan B 5.3).
    freePools: {
      common: [{ w: 70, prize: { type: 'coins', min: 20, max: 80 } }, { w: 30, prize: { type: 'percentOff', pct: 5, capINR: 20, scope: 'word' } }],
      rare: [{ w: 40, prize: { type: 'coins', min: 300, max: 600 } }, { w: 35, prize: { type: 'percentOff', pct: 15, capINR: 50, scope: 'word' } }, { w: 15, prize: { type: 'token', item: 'stage1-signature' } }, { w: 10, prize: { type: 'pass', tier: 'basic', days: 2 } }],
      epic: [{ w: 35, prize: { type: 'coins', min: 1000, max: 1000 } }, { w: 25, prize: { type: 'percentOff', pct: 30, capINR: 300, scope: 'subscription' } }, { w: 25, prize: { type: 'pass', tier: 'plus', days: 7 } }, { w: 15, prize: { type: 'token', item: 'signature-early' } }],
      legendary: [{ w: 40, prize: { type: 'coins', min: 3000, max: 3000 } }, { w: 30, prize: { type: 'pass', tier: 'plus', days: 30 } }, { w: 20, prize: { type: 'token', item: 'bundle10' } }, { w: 10, prize: { type: 'token', item: 'signature-full' } }],
      mythic: [{ w: 70, prize: { type: 'pass', tier: 'premium', days: 60 } }, { w: 30, prize: { type: 'token', item: 'major-2000' } }],
    },
    dailyScratchPool: [{ w: 80, prize: { type: 'coins', min: 5, max: 30 } }, { w: 20, prize: { type: 'percentOff', pct: 5, capINR: 15, scope: 'word' } }],
    // Rarity of the free scratch after a purchase, by what was spent (INR ex-tax); subscriptions use `subscription`.
    afterPurchase: [
      { maxINR: 99, odds: { common: 85, rare: 13, epic: 2 } },
      { maxINR: 299, odds: { common: 65, rare: 28, epic: 6, legendary: 1 } },
      { maxINR: 1e12, odds: { common: 45, rare: 38, epic: 13, legendary: 3.5, mythic: 0.5 } },
    ],
    afterSubscription: { common: 30, rare: 45, epic: 18, legendary: 6, mythic: 1 },
    // Paid cards (Plan A Table 10/11, priced as Plan B Silver/Gold/Platinum).
    paidValueFloorPct: 100, // Plan B 5.4: every paid card returns at least its price as coins or discounts
    paidAdultsOnly: true,
    paidMonthlyLimitINR: 2000,
    paidBlockedCountries: ['BE', 'NL'],
    paid: [
      { id: 'common', title: 'Common · Silver', productId: 'nowssb_scratch_common', priceINR: 49, coinPrice: 490, rarest: 'Signature word', odds: [
        { w: 55, label: 'Coins, small', prize: { type: 'coins', min: 20, max: 60 } },
        { w: 25, label: '10% off, cap ₹35', prize: { type: 'percentOff', pct: 10, capINR: 35, scope: 'word' } },
        { w: 12, label: 'Stage token', prize: { type: 'token', item: 'stage' } },
        { w: 6, label: '7-day Basic or ebook', prize: { type: 'pass', tier: 'basic', days: 7 } },
        { w: 1.8, label: '30-day Standard', prize: { type: 'pass', tier: 'plus', days: 30 } },
        { w: 0.2, label: 'Signature word', prize: { type: 'token', item: 'signature-full' } },
      ] },
      { id: 'rare', title: 'Rare · Gold', productId: 'nowssb_scratch_rare', priceINR: 149, coinPrice: 1490, rarest: '10-word bundle', odds: [
        { w: 30, label: 'Coins, small', prize: { type: 'coins', min: 60, max: 150 } },
        { w: 28, label: '15% off, cap ₹80', prize: { type: 'percentOff', pct: 15, capINR: 80, scope: 'word' } },
        { w: 18, label: 'Stage token', prize: { type: 'token', item: 'stage' } },
        { w: 12, label: '7-day Basic or ebook', prize: { type: 'pass', tier: 'basic', days: 7 } },
        { w: 8, label: '30-day Standard', prize: { type: 'pass', tier: 'plus', days: 30 } },
        { w: 1, label: '10-word bundle', prize: { type: 'token', item: 'bundle10' } },
        { w: 2.5, label: 'Signature word', prize: { type: 'token', item: 'signature-full' } },
        { w: 0.5, label: '2-month Signature', prize: { type: 'pass', tier: 'premium', days: 60 } },
      ] },
      { id: 'epic', title: 'Epic · Platinum', productId: 'nowssb_scratch_epic', priceINR: 399, coinPrice: 3990, rarest: '2-month Signature', odds: [
        { w: 20, label: 'Coins, small', prize: { type: 'coins', min: 150, max: 400 } },
        { w: 24, label: '20% off, cap ₹150', prize: { type: 'percentOff', pct: 20, capINR: 150, scope: 'any' } },
        { w: 18, label: 'Stage token', prize: { type: 'token', item: 'stage' } },
        { w: 14, label: '7-day Basic or ebook', prize: { type: 'pass', tier: 'basic', days: 7 } },
        { w: 12, label: '30-day Standard', prize: { type: 'pass', tier: 'plus', days: 30 } },
        { w: 6, label: '10-word bundle', prize: { type: 'token', item: 'bundle10' } },
        { w: 5.6, label: 'Signature word', prize: { type: 'token', item: 'signature-full' } },
        { w: 0.4, label: '2-month Signature', prize: { type: 'pass', tier: 'premium', days: 60 } },
      ] },
    ],
    // The cut-out tickets on Home and in Coupons. Tap → server claim. `chance` cards draw once a day on the server.
    codes: {
      'NWSB-SAVE20': { type: 'percentOff', pct: 20, capINR: 35, scope: 'word', label: '20% off a word' },
      'NWSB-MEAN10': { type: 'percentOff', pct: 10, capINR: 35, scope: 'meaning', label: '10% off a meaning' },
      'NWSB-MEAN15': { type: 'percentOff', pct: 15, capINR: 80, scope: 'meaning', label: '15% off meanings' },
      'NWSB-SAVE10': { type: 'percentOff', pct: 10, capINR: 35, scope: 'meaning', label: '10% off a meaning' },
      'NWSB-EPIC20': { type: 'percentOff', pct: 20, capINR: 150, scope: 'signature', label: '20% off an Epic word' },
      'NWSB-BASIC7': { type: 'pass', tier: 'basic', days: 7, label: '7-day Basic pass', needsNoPlan: true, onceEveryDays: 30 },
      'NWSB-SUB7': { type: 'pass', tier: 'basic', days: 7, label: '7-day Basic pass', needsNoPlan: true, onceEveryDays: 30 },
      'NWSB-EBOOK7': { type: 'pass', tier: 'ebook', days: 7, label: '7-day ebook pass', needsTrialEnded: true, onceEveryDays: 30 },
      'NWSB-STD30': { type: 'locked', label: '30-day Standard', how: 'Win it in a Rare or Epic card.' },
      'NWSB-SUB30': { type: 'locked', label: '30-day Standard', how: 'Win it in a Rare or Epic card.' },
      'NWSB-PREM7': { type: 'locked', label: '7-day Premium', how: 'A Diamond gift box can hold it.' },
      'NWSB-PREM7F': { type: 'locked', label: '7-day Premium', how: 'A Diamond gift box can hold it.' },
      'NWSB-SIG3': { type: 'locked', label: '3-day Signature', how: 'Send it as a Signature day gift card.' },
      'NWSB-SIG3F': { type: 'locked', label: '3-day Signature', how: 'Send it as a Signature day gift card.' },
      'NWSB-WORD1': { type: 'locked', label: 'One full word', how: 'Earned at streak day 30 and in gift boxes.' },
      'NWSB-FLIPWORD': { type: 'locked', label: 'One full word', how: 'Earned at streak day 30 and in gift boxes.' },
      'NWSB-MEAN1': { type: 'locked', label: 'One meaning', how: 'Earned from the weekly gift.' },
      'NWSB-FLIPMEAN': { type: 'locked', label: 'One meaning', how: 'Earned from the weekly gift.' },
      'NWSB-STAGE': { type: 'locked', label: 'One locked stage', how: 'Inside Gold boxes and Stage cards.' },
      'NWSB-OPEN5': { type: 'action', action: 'open', label: '5 coins today' },
      'NWSB-READ8': { type: 'action', action: 'read_meaning', label: '8 coins a read' },
      'NWSB-HELLO': { type: 'welcome', label: 'Welcome set' },
      'NWSB-CHANCE-WORD': { type: 'chance', winPct: 35, prize: { type: 'token', item: 'stage' }, label: 'One full word stage' },
      'NWSB-CHANCE-MEAN': { type: 'chance', winPct: 40, prize: { type: 'percentOff', pct: 25, capINR: 40, scope: 'meaning' }, label: 'A meaning at 25% off' },
      'NWSB-CHANCE-SUB': { type: 'chance', winPct: 18, prize: { type: 'pass', tier: 'basic', days: 3, needsNoPlan: true }, label: '3-day Basic' },
      'NWSB-CHANCE-EPIC': { type: 'chance', winPct: 8, prize: { type: 'percentOff', pct: 30, capINR: 300, scope: 'subscription' }, label: '30% off a plan' },
      'NWSB-CHANCE-E20': { type: 'chance', winPct: 12, prize: { type: 'percentOff', pct: 20, capINR: 150, scope: 'signature' }, label: '20% off an Epic word' },
      'NWSB-CHANCE-COIN': { type: 'chance', winPct: 25, prize: { type: 'coins', min: 20, max: 20 }, label: '20 coins' },
    },
  },

  // Daily Spin (coins in, catalogue prizes out; odds on the wheel).
  // One free spin a day; after that each spin costs costCoins while the
  // balance allows, up to paidPerDay extra spins (a sanity cap, not a wall).
  spin: {
    costCoins: 15,
    freePerDay: 1,
    paidPerDay: 40,
    perDay: 41, // legacy key read by older builds: free + paid
    slices: [
      { label: 'Ebook', w: 16, prize: { type: 'pass', tier: 'ebook', days: 1 } },
      { label: 'Basic', w: 14, prize: { type: 'pass', tier: 'basic', days: 1, needsNoPlan: true, elseCoins: 30 } },
      { label: 'Premium', w: 8, prize: { type: 'pass', tier: 'premium', days: 1, needsNoPlan: true, elseCoins: 60 } },
      { label: 'Bundle', w: 2, prize: { type: 'percentOff', pct: 25, capINR: 250, scope: 'bundle' } },
      { label: 'Signature', w: 4, prize: { type: 'percentOff', pct: 20, capINR: 150, scope: 'signature' } },
      { label: '15 coins', w: 26, prize: { type: 'coins', min: 15, max: 15 } },
      { label: 'Standard', w: 12, prize: { type: 'pass', tier: 'plus', days: 1, needsNoPlan: true, elseCoins: 40 } },
      { label: 'Stage', w: 18, prize: { type: 'token', item: 'stage-fragment' } },
    ],
  },

  // ── 6 · NowssB Gifts ──
  gifts: {
    boxes: {
      bronze: { title: 'Bronze box', minutes: 10, contents: [{ w: 100, prize: [{ type: 'coins', min: 20, max: 20 }, { type: 'scratch', rarity: 'common' }] }] },
      silver: { title: 'Silver box', minutes: 20, contents: [{ w: 30, prize: [{ type: 'coins', min: 40, max: 40 }, { type: 'scratch', rarity: 'rare' }, { type: 'token', item: 'soundbath-preview' }] }, { w: 70, prize: [{ type: 'coins', min: 40, max: 40 }, { type: 'scratch', rarity: 'common' }, { type: 'token', item: 'soundbath-preview' }] }] },
      gold: { title: 'Gold box', minutes: 40, contents: [{ w: 100, prize: [{ type: 'coins', min: 60, max: 60 }, { type: 'token', item: 'stage1-sample' }, { type: 'scratch', rarity: 'rare' }] }] },
      diamond: { title: 'Diamond box', minutes: 60, contents: [
        { w: 25, prize: [{ type: 'coins', min: 100, max: 100 }, { type: 'scratch', rarity: 'epic' }, { type: 'pass', tier: 'basic', days: 3, needsNoPlan: true, freePlanDays: true }] },
        { w: 75, prize: [{ type: 'coins', min: 100, max: 100 }, { type: 'scratch', rarity: 'rare' }, { type: 'pass', tier: 'basic', days: 3, needsNoPlan: true, freePlanDays: true }] },
      ] },
      weekly: { title: 'Weekly gift', contents: [{ w: 60, prize: [{ type: 'token', item: 'stage1-2' }] }, { w: 40, prize: [{ type: 'pass', tier: 'basic', days: 3, needsNoPlan: true, freePlanDays: true, elseCoins: 60 }] }] },
      monthly: { title: 'Monthly gift', contents: [{ w: 60, prize: [{ type: 'token', item: 'stage1-3' }] }, { w: 40, prize: [{ type: 'pass', tier: 'basic', days: 7, needsNoPlan: true, freePlanDays: true, elseCoins: 150 }] }] },
      fragment25: { title: '25-minute fragment draw', minutes: 25, contents: [{ w: 12.5, prize: [{ type: 'token', item: 'stage-fragment' }] }, { w: 87.5, prize: [{ type: 'coins', min: 5, max: 5 }] }] },
      return30: { title: '30-day return gift', contents: [{ w: 100, prize: [{ type: 'cosmetic', id: 'mark_return30' }, { type: 'token', item: 'stage-fragment' }] }] },
    },
    onePerDay: true,
    freeClaimDays: 7,
    freePlanDaysEvery: 30,
    cardValidityDays: 365, // Plan B 12 months (Plan A 180 days)
    coolingOffDays: 7,
    maxSendPerDay: 5,
    newAccountHoldHours: 24,
    highValueDelayHours: 24, // delayed redemption of high-value gifts (fraud control)
    highValueINR: 999,
    cards: [
      { id: 'stage', title: 'Stage card', productId: 'nowssb_gift_stage', priceINR: 49, item: { type: 'token', item: 'stage' }, earnKind: 'stage' },
      { id: 'word', title: 'Word card', productId: 'nowssb_gift_word', priceINR: 99, item: { type: 'token', item: 'word' }, earnKind: 'word' },
      { id: 'bundle', title: 'Bundle card', productId: 'nowssb_gift_bundle', priceINR: 499, item: { type: 'token', item: 'bundle10' }, earnKind: 'bundle' },
      { id: 'basic7', title: '7-day Basic', productId: 'nowssb_gift_basic7', priceINR: 79, item: { type: 'pass', tier: 'basic', days: 7 }, earnKind: 'giftcard' },
      { id: 'ebook7', title: '7-day ebook', productId: 'nowssb_gift_ebook7', priceINR: 49, item: { type: 'pass', tier: 'ebook', days: 7 }, earnKind: 'giftcard' },
      { id: 'standard30', title: '30-day Standard', productId: 'nowssb_gift_standard30', priceINR: 499, item: { type: 'pass', tier: 'plus', days: 30 }, earnKind: 'giftcard' },
      { id: 'premium30', title: '30-day Premium', productId: 'nowssb_gift_premium30', priceINR: 999, item: { type: 'pass', tier: 'premium', days: 30 }, earnKind: 'giftcard' },
      { id: 'signature3', title: '3-day Signature', productId: 'nowssb_gift_signature3', priceINR: 199, item: { type: 'pass', tier: 'premium', days: 3 }, earnKind: 'giftcard', oncePerQuarter: true },
      { id: 'ebook30', title: '30-day ebook pass', productId: 'nowssb_gift_ebook30', priceINR: 149, item: { type: 'pass', tier: 'ebook', days: 30 }, earnKind: 'giftcard' },
      { id: 'restore', title: 'Streak Restore', productId: 'nowssb_gift_restore', priceINR: 99, item: { type: 'restore' }, earnKind: 'giftcard' },
    ],
  },

  // One-time catalogue products bought for oneself.
  products: {
    nowssb_ebook_pass_30d: { kind: 'ebook', title: 'Ebook pass · 30 days', priceINR: 149, grant: { type: 'pass', tier: 'ebook', days: 30 } },
    nowssb_streak_restore: { kind: 'restore', title: 'Streak Restore', priceINR: 99, grant: { type: 'restore' } },
  },

  // ── 7 · NowssB Reference ──
  reference: {
    linkBase: 'https://nowssb.com/w/',
    holdDays: 30,
    attribution: 'first', // Plan B: first valid link inside 30 days, locked at the first purchase. Plan A: 'last'.
    friendDiscount: { wordPct: 10, wordFirstN: 3, subscriptionPct: 20, subscriptionOfferTag: 'referral' },
    welcome: { coins: 100, scratch: 'rare', ebookDaysIfTrialEnded: 3, oncePerDevice: true },
    activation: { activeDays: 3, coins: 60 },
    sharerLadder: [
      { friends: 3, coins: 300, coupon: 'rare', cosmetic: 'frame_gold_ref' },
      { friends: 5, coins: 600, coupon: 'epic', badge: 'reference-silver' },
      { friends: 10, coins: 1500, coupon: 'epic', passOr: { tier: 'plus', days: 30 } },
      { friends: 25, coins: 4000, coupon: 'legendary', passOr: { tier: 'plus', days: 90 } },
      { friends: 50, coins: 0, coupon: 'mythic', badge: 'reference-gold', early: 48 },
    ],
    circleDays: 30,
    openRatePerIpPerDay: 30,
  },

  // ── 8 · NowssB Partner Program ──
  partner: {
    points: { word: 10, meaning: 10, stage: 5, bundle: 10, signature: 10, basic: 10, plus: 17, premium: 34, giftcard: 10, ebook: 5 },
    levels: [
      { level: 1, id: 'spark', title: 'Spark', points: 500, coins: 500, giftbox: 'gold', coupon: 'epic', badge: 'partner-spark', cosmetic: 'flair_partner', coinsBackPct: 5 },
      { level: 2, id: 'glow', title: 'Glow', points: 1500, coins: 2000, pass: { tier: 'premium', days: 7 }, coupon: 'legendary', cosmetic: 'frame_glow', coinsBackPct: 8, earlyHours: 24 },
      { level: 3, id: 'radiant', title: 'Radiant', points: 3000, coins: 6000, pass: { tier: 'plus', days: 30 }, coupon: 'mythic', badge: 'partner-radiant', coinsBackPct: 10, earlyHours: 48, fastTrack: 'officer' },
    ],
    confirmDays: 30,
  },

  // Program switches (the admin console's earnEnabled / giftsEnabled / couponsEnabled land here and in earn.enabled).
  switches: { gifts: true, coupons: true },

  // Country switches (Plan B 11): paid coupons and Earn open per country after legal review.
  countries: { earnOpen: ['IN'], paidCouponsOpen: ['IN'] },
};

/** Deep merge (objects only; arrays and scalars replace). */
export function deepMerge(base, over) {
  if (!over || typeof over !== 'object' || Array.isArray(over)) return over === undefined ? base : over;
  const out = Array.isArray(base) ? [...base] : { ...(base || {}) };
  for (const [k, v] of Object.entries(over)) {
    if (v && typeof v === 'object' && !Array.isArray(v) && base && typeof base[k] === 'object' && !Array.isArray(base[k])) {
      out[k] = deepMerge(base[k], v);
    } else if (v !== undefined) {
      out[k] = v;
    }
  }
  return out;
}

/**
 * The admin console (flutter_app/lib/admin/earn_admin.dart) saves its own
 * flat keys into the same config/economy doc (payouts, coins, ranks,
 * fastStart, topPool, coupons, gifts, *Enabled). Map them onto this schema
 * so a save there changes what the server does. Keys of this schema saved
 * directly in the doc still win (they are merged after).
 */
export function adaptAdminKeys(live, base = DEFAULT_ECONOMY) {
  if (!live || typeof live !== 'object') return {};
  const n = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : (typeof v === 'string' && v.trim() !== '' && Number.isFinite(Number(v)) ? Number(v) : undefined));
  const out = {};
  const set = (path, v) => {
    if (v === undefined) return;
    let o = out;
    const parts = path.split('.');
    for (const k of parts.slice(0, -1)) o = (o[k] = o[k] || {});
    o[parts[parts.length - 1]] = v;
  };
  const pay = live.payouts || {};
  set('lock.payoutCapPct', n(pay.capPct));
  set('lock.holdDays', n(pay.holdDays));
  set('earn.payout.payoutDay', n(pay.payoutDay));
  if (typeof pay.autoApprove === 'boolean') set('earn.payout.launchModeManual', !pay.autoApprove);
  if (n(pay.minINR) !== undefined) set('earn.payout.minINR', n(pay.minINR));
  else if (n(pay.minCents) !== undefined) set('earn.payout.minINR', Math.round((n(pay.minCents) / 100) * ((live.fxToINR && live.fxToINR.USD) || base.fxToINR.USD)));
  const coins = live.coins || {};
  set('rewards.dailyCeiling', n(coins.dailyCeiling));
  if (n(coins.expiryMonths) !== undefined) set('rewards.expireAfterInactiveDays', Math.round(n(coins.expiryMonths) * 30.4));
  set('coinsPerRupee', n(coins.coinsPerRupee));
  if (Array.isArray(live.ranks) && live.ranks.length) {
    const ranks = base.earn.ranks.map((r, i) => {
      const a = live.ranks[i] || {};
      const leg = [n(a.leg1Pct) ?? r.leg[0], n(a.leg2Pct) ?? r.leg[1]];
      return { ...r, title: typeof a.name === 'string' && a.name ? a.name : r.title, minWords: n(a.minUnits) ?? r.minWords, ratePct: n(a.ratePct) ?? r.ratePct, coinsPerSale: n(a.coinsPerSale) ?? r.coinsPerSale, teamMax: n(a.team) ?? r.teamMax, leg };
    });
    set('earn.ranks', ranks);
  }
  const fast = live.fastStart || {};
  set('earn.fastStartBonusPct', n(fast.bonusPct));
  set('earn.fastStartDays', n(fast.days));
  const pool = live.topPool || {};
  set('earn.monthlyPoolPct', n(pool.pct));
  set('earn.monthlyPoolTop', n(pool.top));
  const cp = live.coupons || {};
  set('coupons.freeExpiryDays', n(cp.freeExpiryDays));
  if (cp.paidEnabled === false) set('countries.paidCouponsOpen', []);
  const g = live.gifts || {};
  set('gifts.coolingOffDays', n(g.coolingOffDays));
  set('gifts.maxSendPerDay', n(g.perDayLimit));
  if (n(g.boughtValidMonths) !== undefined) set('gifts.cardValidityDays', Math.round(n(g.boughtValidMonths) * 30.4));
  if (typeof live.earnEnabled === 'boolean') set('earn.enabled', live.earnEnabled);
  if (typeof live.giftsEnabled === 'boolean') set('switches.gifts', live.giftsEnabled);
  if (typeof live.couponsEnabled === 'boolean') set('switches.coupons', live.couponsEnabled);
  return out;
}

let _cache = { at: 0, value: null, project: '' };
/** Live settings: config/economy over the defaults. Cached for 60 s per isolate. */
export async function loadEconomy(db, { force = false } = {}) {
  if (!force && _cache.value && Date.now() - _cache.at < 60e3 && _cache.project === db.project) return _cache.value;
  let live = null;
  try { live = (await db.get('config/economy')).data; } catch (e) { live = null; }
  // Admin-console keys first, then this schema's own keys (they win).
  const own = { ...(live || {}) };
  for (const k of ['payouts', 'ranks', 'fastStart', 'topPool', 'scratch', 'earnEnabled', 'giftsEnabled', 'couponsEnabled', 'updatedAt', 'updatedBy']) delete own[k];
  if (own.coins && typeof own.coins === 'object') delete own.coins;
  const value = deepMerge(deepMerge(DEFAULT_ECONOMY, adaptAdminKeys(live || {})), stripAdminLeaf(own));
  _cache = { at: Date.now(), value, project: db.project };
  return value;
}
/** coupons/gifts objects from the console carry its own leaf names; drop those so only this schema's keys merge. */
function stripAdminLeaf(own) {
  const out = { ...own };
  const drop = { coupons: ['paidEnabled', 'paidMinAge'], gifts: ['codeExpiryDays', 'boughtValidMonths', 'perDayLimit'] };
  for (const [k, keys] of Object.entries(drop)) {
    if (out[k] && typeof out[k] === 'object') { out[k] = { ...out[k] }; for (const x of keys) delete out[k][x]; }
  }
  return out;
}
export function resetEconomyCache() { _cache = { at: 0, value: null, project: '' }; }
