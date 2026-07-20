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

  /* ── "Everything NowssB" features menu — explainer carousel below the
     glass tube. One card visible at a time, auto-cycling with dots: the
     menu itself first ("Quick access to everything on NowssB"), then one
     card per feature row beneath it, one by one. Mirrored from the
     Connect features carousel — icon on the RIGHT (text block first in
     the DOM, icon last), no arrow/button since these aren't links. ── */
  var FEAT_BANNER_CARDS = [
    { name: 'Everything NowssB', sub: 'Quick access to everything on NowssB', img: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779717856/30ebb160-5840-11f1-bb0c-71720609fd8f_g5nmcn.png' },
    { name: 'NowssB Player',    sub: 'Your sound library — listen, heal, repeat',           img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157829/file_0000000039c8720893ebc07bba4d3afd_iq64ts.png' },
    { name: 'NowssB Connect',   sub: 'The social space of NowssB — share your journey',     img: 'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_240/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png' },
    { name: 'NowssB Store',     sub: 'Words & meanings — own the sounds that heal',         img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783160870/file_0000000037547208b91bfd167f401961_eesfpn.png' },
    { name: 'Verification',     sub: 'Earn your NowssB check-mark',                          img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783162597/file_00000000029c71fa8c210e0f09870964_uwh8sc.png' },
    { name: 'Search',           sub: 'Find any word or meaning, instantly',                  img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_00000000029c7208b5e915d9af2c480c_tuccwo.png' },
    { name: 'Daily Practice',   sub: 'Your morning ritual, every day',                        img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157829/file_0000000050d472089de0ad57116dba0f_tht26i.png' },
    { name: 'Word Science',     sub: 'The NOWSBANSIU system, decoded',                        img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783158082/file_0000000086d872089ce376674620d5f3_mtfftb.png' },
    { name: 'My Progress',      sub: 'Track your healing journey',                            img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157829/file_00000000ae607208aa51504989648920_ml2czc.png' },
    { name: 'Wishlist',         sub: 'Words you\'ve saved for later',                         img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_0000000055d8720895f7ba98c4a7bf4a_s2lzab.png' },
    { name: 'Cart',             sub: 'Your bag, ready for checkout',                          img: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_00000000f02c72088cd128f3f4b08af5_vskoom.png' }
  ];
  var _featBannerTimer = null;
  function buildFeatBanner(track, dots) {
    track.innerHTML = FEAT_BANNER_CARDS.map(function (f) {
      return '<div class="feat-banner-slide">' +
        '<span class="feat-banner-txt"><span class="feat-banner-name">' + f.name + '</span><span class="feat-banner-sub">' + f.sub + '</span></span>' +
        '<span class="feat-banner-ico"><img loading="lazy" decoding="async" src="' + f.img + '" alt=""></span>' +
      '</div>';
    }).join('');
    dots.innerHTML = FEAT_BANNER_CARDS.map(function (_, i) { return '<span class="feat-banner-dot' + (i === 0 ? ' on' : '') + '"></span>'; }).join('');
  }
  function startFeatBanner() {
    var car = document.getElementById('featBannerCarousel'); if (!car) return;
    var track = car.querySelector('.feat-banner-track'); var dots = car.querySelector('.feat-banner-dots');
    if (!track || !dots) return;
    if (!track._built) { buildFeatBanner(track, dots); track._built = true; }
    var idx = 0;
    if (_featBannerTimer) clearInterval(_featBannerTimer);
    _featBannerTimer = setInterval(function () {
      if (document.hidden) return;
      var scr = document.getElementById('sub-features');
      if (!scr || !scr.classList.contains('open')) return;
      idx = (idx + 1) % FEAT_BANNER_CARDS.length;
      track.style.transform = 'translateX(-' + (idx * 100) + '%)';
      var ds = dots.querySelectorAll('.feat-banner-dot');
      for (var i = 0; i < ds.length; i++) ds[i].classList.toggle('on', i === idx);
    }, 3200);
  }
  (function watchFeaturesOpen() {
    var scr = document.getElementById('sub-features');
    if (!scr) { setTimeout(watchFeaturesOpen, 300); return; }
    new MutationObserver(function () {
      if (scr.classList.contains('open')) startFeatBanner();
    }).observe(scr, { attributes: true, attributeFilter: ['class'] });
    if (scr.classList.contains('open')) startFeatBanner();
  })();

  /* ── AI PRESCRIPTION PAGE — real data, not a mock. Reuses the exact
     same recommendation engine (window.rxGetData, part037.js: Groq when
     configured, deterministic static fallback otherwise) and the exact
     same practice actions (window.rxStartWord/rxStartAll) as the home
     card, so tapping a word or "Start All Three" here does the real
     thing. ── */
  var _rxPageData = null;
  window.renderAiPrescriptionPage = function () {
    var reasonEl = document.getElementById('rxPageReason');
    var wordsEl  = document.getElementById('rxPageWords');
    var btn      = document.getElementById('rxPageStartAllBtn');
    if (!reasonEl || !wordsEl) return;
    if (typeof window.rxGetData !== 'function') {
      reasonEl.textContent = 'Prescription engine unavailable right now.';
      return;
    }
    reasonEl.textContent = 'Building your ritual…';
    wordsEl.innerHTML = '<div class="bgp-rx-loading">Loading your prescription…</div>';
    if (btn) btn.disabled = true;
    window.rxGetData().then(function (data) {
      _rxPageData = data;
      reasonEl.textContent = data.reason || '';
      wordsEl.innerHTML = (data.words || []).map(function (w) {
        return '<div class="bgp-rx-word-card" onclick="window.rxStartWord(\'' + String(w.word).replace(/'/g, '') + '\')">' +
          '<div>' +
            '<div class="bgp-rx-word-name">' + w.word + '</div>' +
            (w.organ ? '<div class="bgp-rx-word-organ">' + w.organ + '</div>' : '') +
            '<div class="bgp-rx-word-why">' + (w.why || '') + '</div>' +
          '</div>' +
          '<div class="bgp-rx-word-play"><svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M4 3l7 4-7 4V3z" fill="#e8d5a3"/></svg></div>' +
        '</div>';
      }).join('');
      if (btn) btn.disabled = false;
    }).catch(function () {
      reasonEl.textContent = 'Could not load your prescription — pull to retry.';
      wordsEl.innerHTML = '';
    });
  };
  window.rxPageStartAll = function () {
    if (_rxPageData && _rxPageData.words && typeof window.rxStartAll === 'function') {
      window.rxStartAll(_rxPageData.words);
    }
  };

  /* "For Every Organ" — one tile per word in the real library, tap to
     practice that exact word (window.rxStartWord already handles lookup). */
  function renderRxOrganRow() {
    var box = document.getElementById('rxOrganRow');
    if (!box) return;
    var lib = (typeof MASTER_WORD_LIBRARY !== 'undefined' && MASTER_WORD_LIBRARY) || window.MASTER_WORD_LIBRARY || [];
    if (!lib.length) { box.innerHTML = '<div class="bgp-rx-loading">Library unavailable</div>'; return; }
    box.innerHTML = lib.map(function (w) {
      return '<div class="bgp-rx-tile" onclick="window.rxStartWord(\'' + String(w.word).replace(/'/g, '') + '\')">' +
        '<div class="bgp-rx-tile-organ">' + (w.organ || '') + '</div>' +
        '<div class="bgp-rx-tile-word">' + w.word + '</div>' +
        '<div class="bgp-rx-tile-benefit">' + (w.benefit || '') + '</div>' +
      '</div>';
    }).join('');
  }

  /* "Rotating Words" — one word visible at a time, auto-cycling through the
     whole library, tap to practice it directly. */
  var _rxRotatorTimer = null;
  function renderRxRotator() {
    var track = document.getElementById('rxRotatorTrack');
    var dots  = document.getElementById('rxRotatorDots');
    if (!track || !dots) return;
    var lib = (typeof MASTER_WORD_LIBRARY !== 'undefined' && MASTER_WORD_LIBRARY) || window.MASTER_WORD_LIBRARY || [];
    if (!lib.length) return;
    track.innerHTML = lib.map(function (w) {
      return '<div class="bgp-rx-rotator-slide" onclick="window.rxStartWord(\'' + String(w.word).replace(/'/g, '') + '\')">' +
        '<div class="bgp-rx-rotator-organ">' + (w.organ || '') + '</div>' +
        '<div class="bgp-rx-rotator-word">' + w.word + '</div>' +
        '<div class="bgp-rx-rotator-benefit">' + (w.benefit || '') + '</div>' +
      '</div>';
    }).join('');
    dots.innerHTML = lib.map(function (_, i) { return '<span class="bgp-rx-rotator-dot' + (i === 0 ? ' on' : '') + '"></span>'; }).join('');
    var idx = 0;
    if (_rxRotatorTimer) clearInterval(_rxRotatorTimer);
    _rxRotatorTimer = setInterval(function () {
      if (document.hidden) return;
      var scr = document.getElementById('sub-ai-prescription');
      if (!scr || !scr.classList.contains('open')) return;
      idx = (idx + 1) % lib.length;
      track.style.transform = 'translateX(-' + (idx * 100) + '%)';
      var ds = dots.querySelectorAll('.bgp-rx-rotator-dot');
      for (var i = 0; i < ds.length; i++) ds[i].classList.toggle('on', i === idx);
    }, 3200);
  }

  /* "You Might Also Like" — real Meaning Store items, real Buy Now action
     (window.msBuyNow — same function the Meaning Store itself uses). */
  function renderRxMeanings() {
    var box = document.getElementById('rxMeaningRow');
    if (!box) return;
    var lib = window.MS_BASE_MEANINGS || [];
    if (!lib.length) { box.innerHTML = '<div class="bgp-rx-loading">Recommendations unavailable</div>'; return; }
    // Deterministic-but-varied pick so it isn't always the same 6 —
    // rotates by day of year, same pattern used by the static word prescription.
    var doy = Math.floor((Date.now() - new Date(new Date().getFullYear(), 0, 0)) / 86400000);
    var picks = [];
    for (var i = 0; i < 8 && i < lib.length; i++) picks.push(lib[(doy + i * 5) % lib.length]);
    box.innerHTML = picks.map(function (m) {
      var safeName = String(m.word).replace(/'/g, '');
      var safeImg = String(m.img || '').replace(/'/g, '');
      return '<div class="bgp-rx-tile bgp-rx-mtile" onclick="window.msBuyNow(\'ms-' + m.key + '\',\'' + safeName + '\',' + m.price + ',\'' + safeImg + '\')">' +
        '<img class="bgp-rx-mtile-img" loading="lazy" decoding="async" src="' + m.img + '" alt="">' +
        '<div class="bgp-rx-mtile-name">' + m.word + '</div>' +
        '<div class="bgp-rx-mtile-price">$' + (m.price / 100).toFixed(2) + '</div>' +
      '</div>';
    }).join('');
  }

  var _origRenderAiPrescriptionPage = window.renderAiPrescriptionPage;
  window.renderAiPrescriptionPage = function () {
    _origRenderAiPrescriptionPage();
    renderRxOrganRow();
    renderRxRotator();
    renderRxMeanings();
  };

})();
