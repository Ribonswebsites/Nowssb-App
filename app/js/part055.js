/* ══════════════════════════════════════════════════════════
   COUPON / BUNDLE SHOP PAGES — 4 dedicated pages reached from the
   "Today's Offer" hub (#sub-offers, app/js/part053.js) and the rotating
   coupon banner on Home, instead of dumping straight into the plain
   NowssB Store. Each page is a real shop page — same product-card
   markup/classes as the Word Atelier (.rm-word-card) / Meaning Store
   (.ms-card) — over a curated word/meaning pool, not the whole catalog.
   Tapping any word/meaning opens the REAL detail/buy view, exactly like
   tapping it inside the real store.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var PAGE_COUPON = {
    'coupon-individual': 'NOWSSB10',
    'coupon-bundle5':    'NOWSSB30',
    'coupon-signature':  'NOWSSB50',
    'coupon-bundle20':   'NOWSSB60'
  };

  /* ── Bridge into the REAL store screens/detail views — tapping a card
     here behaves exactly like tapping it inside the real Word Atelier /
     Meaning Store, not a simplified copy. ── */
  var _sigBundleBridge = false; // true only for the one add-to-cart right after leaving the Signature page

  window.couponOpenWordDetail = function (key) {
    if (window._nssActiveCouponPage === 'coupon-signature') _sigBundleBridge = true;
    if (window._nssActiveCouponPage && typeof closeSub === 'function') closeSub(window._nssActiveCouponPage);
    if (typeof nssOpenSub === 'function') nssOpenSub('real-meaning');
    if (typeof rmSkipIntro === 'function') rmSkipIntro();
    if (typeof loadWordOrigin === 'function') loadWordOrigin(key);
  };

  window.couponOpenMeaningDetail = function (key, name, price, img) {
    if (window._nssActiveCouponPage === 'coupon-signature') _sigBundleBridge = true;
    if (window._nssActiveCouponPage && typeof closeSub === 'function') closeSub(window._nssActiveCouponPage);
    if (typeof nssOpenSub === 'function') nssOpenSub('meaning-store');
    if (typeof window.msEnterFromIntro === 'function') window.msEnterFromIntro();
    if (window.msIsPurchased && window.msIsPurchased(key)) {
      window.msShowDetail(key, name);
    } else if (typeof window.msBuy === 'function') {
      window.msBuy(key, name, price, img);
    }
  };

  // Tag the very next cart-add as a Signature Bundle item when it follows
  // a tap from the Signature coupon page — lets NOWSSB50 (requireTag:
  // 'signature', part029.js) count only real signature purchases.
  var _origAddToCart = window.nssAddToCart;
  if (typeof _origAddToCart === 'function') {
    window.nssAddToCart = function (item) {
      if (_sigBundleBridge && item && !item.sigTag) item.sigTag = 'signature';
      _sigBundleBridge = false;
      return _origAddToCart.apply(this, arguments);
    };
  }

  window.couponProceedCheckout = function (code) {
    window._nssCoupon = code;
    if (typeof openSub === 'function') openSub('checkout');
  };

  /* ── Shared markup helpers ── */
  function cap(w) { return w.charAt(0).toUpperCase() + w.slice(1); }

  function wordCardHtml(pair) {
    var img = window.RM_WORD_IMG || '';
    return '<div class="rm-word-card" onclick="couponOpenWordDetail(\'' + pair[0] + '\')">' +
      '<img decoding="async" class="rm-word-card-img" src="' + img + '" alt="" loading="lazy">' +
      '<div class="rm-word-card-overlay"></div>' +
      '<div class="rm-word-card-body"><div class="rm-word-card-name">' + cap(pair[0]) + '</div><div class="rm-word-card-root">' + pair[1] + '</div></div>' +
    '</div>';
  }

  function signatureWordCardHtml(sig) {
    return '<div class="rm-word-card rm-word-card-signature" onclick="couponOpenWordDetail(\'' + sig.key + '\')">' +
      '<span class="rm-word-card-signature-tag">Signature</span>' +
      '<img decoding="async" class="rm-word-card-img" src="' + sig.img + '" alt="" loading="lazy">' +
      '<div class="rm-word-card-overlay"></div>' +
      '<div class="rm-word-card-body"><div class="rm-word-card-name">' + sig.name + '</div><div class="rm-word-card-root">Most Exclusive</div></div>' +
    '</div>';
  }

  function signatureMeaningCardHtml(m) {
    var price = window.MS_SIGNATURE_PRICE || 299;
    var img = window.MS_SIGNATURE_IMG || '';
    var owned = window.msIsPurchased && window.msIsPurchased(m.key);
    var moneyLabel = (typeof window.nwsbFormatINR === 'function') ? window.nwsbFormatINR(price) : ('₹' + price);
    return '<div class="ms-card ms-card-signature' + (owned ? ' unlocked' : '') + '" onclick="couponOpenMeaningDetail(\'' + m.key + '\',\'' + m.word.replace(/'/g, '') + '\',' + price + ',\'' + img + '\')">' +
      '<span class="ms-card-signature-tag">Signature</span>' +
      '<div class="ms-card-img" style="background-image:url(\'' + img + '\')"></div>' +
      '<div class="ms-card-overlay"></div>' +
      '<div class="ms-card-body"><div class="ms-card-word">' + m.word + '</div><div class="ms-card-root">' + m.root + '</div>' +
        (owned ? '<div class="ms-card-unlocked-badge">Unlocked</div>' : '<div class="ms-card-price">' + moneyLabel + '</div>') +
      '</div>' +
    '</div>';
  }

  /* Live progress banner toward a coupon's unlock threshold — same
     bgp-coupon-card component the hub uses (part053.js), non-clickable
     here since we're already on that coupon's own page. */
  function progressBannerHtml(code) {
    var c = (window.NSS_COUPONS || {})[code];
    if (!c) return '';
    var cart = window.nssCart || [];
    var qualifyFn = window.chkQualifyingItems || function (cartArr) { return cartArr; };
    var qualifying = qualifyFn(cart, c);
    var pct = Math.min(100, Math.round((qualifying.length / c.min) * 100));
    var unlocked = qualifying.length >= c.min;
    var reqNoun = c.requireTag ? 'signature word' : 'word';
    return '<div class="bgp-coupon-card" style="margin:0 20px 18px;">' +
      '<div class="bgp-coupon-top"><span class="bgp-coupon-code">' + code + '</span><span class="bgp-coupon-pct">' + c.pct + '% OFF</span></div>' +
      '<div class="bgp-coupon-req">' + c.label + '</div>' +
      '<div class="bgp-coupon-bar-track"><div class="bgp-coupon-bar-fill" style="width:' + pct + '%;"></div></div>' +
      '<div class="bgp-coupon-status ' + (unlocked ? 'unlocked' : 'locked') + '">' +
        (unlocked ? 'Unlocked ✓ — apply at checkout' : qualifying.length + ' / ' + c.min + ' ' + reqNoun + (c.min > 1 ? 's' : '') + ' in cart') +
      '</div>' +
    '</div>';
  }

  /* ── Page 1 — Individual Coupon, 10% off any word in the Sale pool ── */
  function renderCouponIndividual() {
    var box = document.getElementById('couponIndividualGrid');
    if (!box) return;
    var pool = window.RM_SALE_WORDS || [];
    box.innerHTML = pool.map(wordCardHtml).join('');
  }

  /* ── Page 2 — Bundle, buy 5 get 30% off ── */
  function renderCouponBundle5() {
    var prog = document.getElementById('couponBundle5Progress');
    var box  = document.getElementById('couponBundle5Grid');
    if (prog) prog.innerHTML = progressBannerHtml('NOWSSB30');
    if (!box) return;
    var pool = window.RM_SALE_WORDS || [];
    box.innerHTML = pool.map(wordCardHtml).join('');
  }

  /* ── Page 3 — Signature Bundle, buy 5 signature words/meanings get 50% off ── */
  window._nssSigToggle = window._nssSigToggle || 'words';
  window.couponSigToggle = function (which) {
    window._nssSigToggle = which;
    var wordsBtn = document.getElementById('couponSigToggleWords');
    var meanBtn  = document.getElementById('couponSigToggleMeanings');
    var wordsBox = document.getElementById('couponSigWordsGrid');
    var meanBox  = document.getElementById('couponSigMeaningsGrid');
    if (wordsBtn) wordsBtn.classList.toggle('active', which === 'words');
    if (meanBtn)  meanBtn.classList.toggle('active', which === 'meanings');
    if (wordsBox) wordsBox.style.display = which === 'words' ? '' : 'none';
    if (meanBox)  meanBox.style.display  = which === 'meanings' ? '' : 'none';
  };
  function renderCouponSignature() {
    var prog = document.getElementById('couponSigProgress');
    var wordsBox = document.getElementById('couponSigWordsGrid');
    var meanBox  = document.getElementById('couponSigMeaningsGrid');
    if (prog) prog.innerHTML = progressBannerHtml('NOWSSB50');
    var sigWords = window.RM_SIGNATURE_WORDS || {};
    if (wordsBox) wordsBox.innerHTML = Object.keys(sigWords).map(function (k) { return signatureWordCardHtml(sigWords[k]); }).join('');
    var sigMeanings = window.MS_SIGNATURE || {};
    if (meanBox) meanBox.innerHTML = Object.keys(sigMeanings).map(function (k) { return signatureMeaningCardHtml(sigMeanings[k]); }).join('');
    window.couponSigToggle(window._nssSigToggle);
  }

  /* ── Page 4 — Bundle, buy 20 get 60% off ── */
  function renderCouponBundle20() {
    var prog = document.getElementById('couponBundle20Progress');
    var box  = document.getElementById('couponBundle20Grid');
    if (prog) prog.innerHTML = progressBannerHtml('NOWSSB60');
    if (!box) return;
    var pool = window.RM_SALE_WORDS || [];
    box.innerHTML = pool.map(wordCardHtml).join('');
  }

  var RENDER = {
    'coupon-individual': renderCouponIndividual,
    'coupon-bundle5':    renderCouponBundle5,
    'coupon-signature':  renderCouponSignature,
    'coupon-bundle20':   renderCouponBundle20
  };

  /* ── Register the 4 pages — non-invasive wrap, same pattern part017.js
     already uses for 'nowssb-store'. ── */
  var _prevOpen = window.openSub;
  window.openSub = function (id) {
    if (RENDER[id]) {
      var scr = document.getElementById('sub-' + id);
      if (scr) scr.classList.add('open');
      window._nssActiveCouponPage = id;
      RENDER[id]();
      return;
    }
    if (typeof _prevOpen === 'function') _prevOpen.apply(this, arguments);
  };
  var _prevClose = window.closeSub;
  window.closeSub = function (id) {
    if (RENDER[id]) {
      var scr = document.getElementById('sub-' + id);
      if (scr) scr.classList.remove('open');
      if (window._nssActiveCouponPage === id) window._nssActiveCouponPage = null;
      return;
    }
    if (typeof _prevClose === 'function') _prevClose.apply(this, arguments);
  };

})();
