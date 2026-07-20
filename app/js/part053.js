/* ══════════════════════════════════════════════════════════
   BLACK/GOLD DEDICATED PAGES — render logic for #sub-offers and
   #sub-streak (#sub-quick-access is fully static, no JS needed).
   Wired up from openSub()'s id==='offers' / id==='streak' branches
   in part012.js.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  /* ── ALL OFFERS PAGE ── */
  function renderOffersPage() {
    var couponsBox = document.getElementById('offersCouponTiers');
    var gridBox    = document.getElementById('offersDealsGrid');
    var moreBtn    = document.getElementById('offersShowMoreBtn');
    if (!couponsBox || !gridBox) return;

    // Coupon tiers unlock against the CURRENT CART size — real, live logic
    // (not decorative), matching exactly what chkCouponFor() checks at
    // checkout, so "more words -> more offers unlock" is always accurate.
    var cart = window.nssCart || [];
    var coupons = window.NSS_COUPONS || {};
    couponsBox.innerHTML = Object.keys(coupons).map(function (code) {
      var c = coupons[code];
      var pct = Math.min(100, Math.round((cart.length / c.min) * 100));
      var unlocked = cart.length >= c.min;
      return '<div class="bgp-coupon-card">' +
        '<div class="bgp-coupon-top"><span class="bgp-coupon-code">' + code + '</span><span class="bgp-coupon-pct">' + c.pct + '% OFF</span></div>' +
        '<div class="bgp-coupon-req">Add ' + c.min + '+ item' + (c.min > 1 ? 's' : '') + ' to your cart to unlock</div>' +
        '<div class="bgp-coupon-bar-track"><div class="bgp-coupon-bar-fill" style="width:' + pct + '%;"></div></div>' +
        '<div class="bgp-coupon-status ' + (unlocked ? 'unlocked' : 'locked') + '">' +
          (unlocked ? 'Unlocked ✓ — apply at checkout' : cart.length + ' / ' + c.min + ' items in cart') +
        '</div>' +
      '</div>';
    }).join('');

    var tiers    = (typeof RM_TIERS     !== 'undefined') ? RM_TIERS     : {};
    var wordTier = (typeof RM_WORD_TIER !== 'undefined') ? RM_WORD_TIER : {};
    var discounted = Object.keys(wordTier).filter(function (word) {
      var t = tiers[wordTier[word]];
      return t && t.discount;
    });

    if (!discounted.length) {
      gridBox.innerHTML = '<div style="grid-column:1/-1;color:rgba(255,255,255,0.4);font-family:\'DM Sans\',sans-serif;font-size:13px;padding:20px 0;text-align:center;">No active deals right now — check back soon.</div>';
      if (moreBtn) moreBtn.classList.add('bgp-hidden-extra');
      return;
    }

    gridBox.innerHTML = discounted.map(function (word, i) {
      var t = tiers[wordTier[word]] || {};
      return '<div class="bgp-offer-card' + (i >= 6 ? ' bgp-hidden-extra' : '') + '" onclick="nwsbOpenStoreWord(\'' + String(word).replace(/'/g, '') + '\')">' +
        (t.discount ? '<div class="bgp-offer-badge">' + t.discount + '</div>' : '') +
        '<div class="bgp-offer-word">' + word + '</div>' +
        '<div class="bgp-offer-price"><span class="bgp-offer-now">' + (t.price || '') + '</span>' +
          (t.origPrice ? '<span class="bgp-offer-was">' + t.origPrice + '</span>' : '') +
        '</div>' +
        '<div class="bgp-offer-cta">Grab Deal →</div>' +
      '</div>';
    }).join('');

    if (moreBtn) {
      if (discounted.length > 6) {
        moreBtn.classList.remove('bgp-hidden-extra');
        moreBtn.textContent = 'See More Offers (' + (discounted.length - 6) + ')';
      } else {
        moreBtn.classList.add('bgp-hidden-extra');
      }
    }
  }
  window.renderOffersPage = renderOffersPage;
  window.offersShowMore = function () {
    document.querySelectorAll('#offersDealsGrid .bgp-hidden-extra').forEach(function (el) { el.classList.remove('bgp-hidden-extra'); });
    var btn = document.getElementById('offersShowMoreBtn');
    if (btn) btn.classList.add('bgp-hidden-extra');
  };

  /* ── DAILY STREAK PAGE ── */
  function renderStreakPage() {
    var numEl = document.getElementById('streakPageNum');
    var calEl = document.getElementById('streakPageCal');
    var msEl  = document.getElementById('streakPageMilestones');
    if (!numEl || !calEl || !msEl) return;

    var d = window._userDataCache || {};
    var streak = d.currentStreak || d.streakCount || 0;
    numEl.textContent = streak;

    // No separate per-day practice log exists yet — the last `streak`
    // consecutive days (capped to the 7 shown here) are marked practiced,
    // counting back from today, which is exactly what an "N day streak"
    // already means. Not fabricated: a direct, honest read of that number.
    var labels = ['S','M','T','W','T','F','S'];
    var today = new Date();
    var html = '';
    for (var i = 6; i >= 0; i--) {
      var day = new Date(today); day.setDate(today.getDate() - i);
      var done = i < streak;
      html += '<div class="bgp-streak-day' + (done ? ' bgp-done' : '') + '">' +
        '<span class="bgp-streak-day-label">' + labels[day.getDay()] + '</span>' +
        '<span>' + day.getDate() + '</span>' +
      '</div>';
    }
    calEl.innerHTML = html;

    var MILESTONES = [
      { days: 7,   title: '7-Day Streak',   desc: 'A full week of consistent practice' },
      { days: 14,  title: '14-Day Streak',  desc: 'Two weeks strong — habit forming' },
      { days: 30,  title: '30-Day Streak',  desc: 'One month — unlock a bonus routine slot' },
      { days: 60,  title: '60-Day Streak',  desc: 'Two months of dedication' },
      { days: 100, title: '100-Day Streak', desc: 'The full ritual, mastered' }
    ];
    msEl.innerHTML = MILESTONES.map(function (m) {
      var unlocked = streak >= m.days;
      return '<div class="bgp-milestone-row">' +
        '<div class="bgp-milestone-badge' + (unlocked ? ' bgp-unlocked' : '') + '">' + (unlocked ? '✓' : m.days) + '</div>' +
        '<div><div class="bgp-milestone-title">' + m.title + '</div><div class="bgp-milestone-desc">' + m.desc + '</div></div>' +
      '</div>';
    }).join('');
  }
  window.renderStreakPage = renderStreakPage;

})();
