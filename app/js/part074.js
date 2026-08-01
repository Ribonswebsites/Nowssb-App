/* ══════════════════════════════════════════════════════════
   NOWSSB SIGNATURE — its own store.

   One item in each collection is the signature: the rarest thing that
   collection has, priced above everything else, with its own gold product
   shot rather than the shared card art. Fifteen signature words
   (RM_SIGNATURE_WORDS, part010.js) and five signature meanings
   (MS_SIGNATURE, part026.js).

   They already existed, but they were only ever visible inside somebody
   else's shop — a card in the Word Atelier, a card in the Meaning Store,
   a page behind a coupon. Tapping one dropped you into whichever of those
   two shops it belonged to, which is exactly what a collection that is
   deliberately neither should not do.

   So this is a shop. #sub-signature-store holds only signatures, opens on
   its own banner, and keeps the detail and the buy on its own page: no
   path out of it leads into the Word Atelier or the Meaning Store. The
   look is the two of them combined, because the collection is — the
   Atelier's clip and the Meaning Store's clip behind one gold frame, the
   Meaning Store's grid, the Atelier's card.

   What it does NOT re-implement: the cart. nssAddToCart and the checkout
   are the app's, and a signature is an ordinary line item once it is in
   there — same ids, same badges, same NOWSSB50 bundle rule.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function money(n) {
    return (typeof window.nwsbFormatINR === 'function') ? window.nwsbFormatINR(n) : ('₹' + n);
  }
  function wordImg() { return window.RM_SIGNATURE_IMG || ''; }
  function meanImg() { return window.MS_SIGNATURE_IMG || ''; }
  function price()   { return window.MS_SIGNATURE_PRICE || 299; }

  /* ── What is on the shelf ──────────────────────────────────────────
     Read from the two maps every time rather than cached, so a signature
     added to either collection appears here without this file changing. */
  function words() {
    var m = window.RM_SIGNATURE_WORDS || {};
    return Object.keys(m).map(function (k) {
      var s = m[k] || {};
      return { kind: 'word', id: 'sig-w-' + s.key, key: s.key, name: s.name,
               root: 'Most Exclusive', img: s.img || wordImg() };
    });
  }
  function meanings() {
    var m = window.MS_SIGNATURE || {};
    return Object.keys(m).map(function (k) {
      var s = m[k] || {};
      return { kind: 'meaning', id: 'ms-' + s.key, key: s.key, name: s.word,
               root: s.root || 'Most Exclusive', img: meanImg() };
    });
  }
  function all() { return words().concat(meanings()); }
  function byId(id) {
    var a = all();
    for (var i = 0; i < a.length; i++) if (a[i].id === id) return a[i];
    return null;
  }

  function owned(it) {
    if (it.kind === 'meaning') return !!(window.msIsPurchased && window.msIsPurchased(it.key));
    /* A signature word is owned once it has been unlocked in the Atelier;
       the app tracks that per word key the same way. */
    try {
      var p = JSON.parse(localStorage.getItem('nwsb_word_purchased') || '[]');
      return Array.isArray(p) && p.some(function (x) {
        return String(x && (x.word || x)).toLowerCase() === String(it.key).toLowerCase();
      });
    } catch (e) { return false; }
  }
  function inCart(id) {
    return (window.nssCart || []).some(function (c) { return c.id === id; });
  }

  /* ── The grid ──────────────────────────────────────────────────────
     Same card the collection has always used, so the gold-glass treatment
     and the Signature tag come from the stylesheet rather than from here. */
  function card(it) {
    var own = owned(it);
    return '<div class="sig-card2' + (own ? ' owned' : '') + '" onclick="sigOpenDetail(\'' + esc(it.id) + '\')">' +
             '<span class="sig-card2-tag">Signature</span>' +
             '<div class="sig-card2-img" style="background-image:url(\'' + esc(it.img) + '\')"></div>' +
             '<div class="sig-card2-body">' +
               '<div class="sig-card2-name">' + esc(it.name) + '</div>' +
               '<div class="sig-card2-root">' + esc(it.root) + '</div>' +
               (own ? '<div class="sig-card2-owned">Unlocked</div>'
                    : '<div class="sig-card2-price">' + money(price()) + '</div>') +
             '</div>' +
           '</div>';
  }

  function render() {
    var wg = document.getElementById('sigWordsGrid');
    var mg = document.getElementById('sigMeaningsGrid');
    if (!wg && !mg) return;
    var w = words(), m = meanings();
    if (wg) wg.innerHTML = w.length ? w.map(card).join('') : '<div class="sig-empty">No signature words yet.</div>';
    if (mg) mg.innerHTML = m.length ? m.map(card).join('') : '<div class="sig-empty">No signature meanings yet.</div>';
    syncBadges();
  }
  window.sigRenderStore = render;

  /* The page has its own cart and wishlist counts in its own top bar. */
  function syncBadges() {
    var c = document.getElementById('sigCartBadge');
    var w = document.getElementById('sigWishBadge');
    if (c) c.textContent = (window.nssCart || []).length;
    if (w) w.textContent = (window.nssWishlist || []).length;
  }

  window.sigTab = function (which) {
    var onWords = which !== 'meanings';
    var w = document.getElementById('sigWordsGrid');
    var m = document.getElementById('sigMeaningsGrid');
    var wb = document.getElementById('sigToggleWords');
    var mb = document.getElementById('sigToggleMeanings');
    if (w) w.style.display = onWords ? '' : 'none';
    if (m) m.style.display = onWords ? 'none' : '';
    if (wb) wb.classList.toggle('active', onWords);
    if (mb) mb.classList.toggle('active', !onWords);
    try { if (navigator.vibrate) navigator.vibrate(16); } catch (e) {}
  };

  /* ── The detail, on this page ──────────────────────────────────────
     The one thing that had to be built rather than borrowed: the Meaning
     Store's detail belongs to the Meaning Store and opening it would be
     leaving. This is the same information in the same order — the piece,
     what it is, what it costs, and the two buttons. ── */
  window.sigOpenDetail = function (id) {
    var it = byId(id);
    var panel = document.getElementById('sigDetail');
    var body = document.getElementById('sigDetailBody');
    var head = document.getElementById('sigDetailHead');
    if (!it || !panel || !body) return;

    var own = owned(it), has = inCart(it.id);
    if (head) head.textContent = it.name;

    body.innerHTML =
      '<div class="sig-detail-art">' +
        '<img loading="lazy" decoding="async" src="' + esc(it.img) + '" alt="">' +
        '<span class="sig-detail-badge">Signature · ' + (it.kind === 'word' ? 'Word' : 'Meaning') + '</span>' +
      '</div>' +
      '<div class="sig-detail-name">' + esc(it.name) + '</div>' +
      '<div class="sig-detail-root">' + esc(it.root) + '</div>' +
      '<div class="sig-detail-copy">' +
        (it.kind === 'word'
          ? 'The rarest word in its collection. One signature exists per collection, it is never discounted on its own, and it is never restocked.'
          : 'The rarest meaning in its collection — the full decoded origin, not the base entry. One per collection, never restocked.') +
      '</div>' +
      '<div class="sig-detail-price">' + (own ? 'Unlocked' : money(price())) + '</div>' +
      (own
        ? '<div class="sig-detail-owned">This one is already yours.</div>'
        : '<div class="sig-detail-btns">' +
            '<button class="sig-btn-ghost" id="sigAddBtn" onclick="sigAdd(\'' + esc(it.id) + '\')">' +
              (has ? 'In your cart' : 'Add to cart') + '</button>' +
            '<button class="sig-btn-gold" onclick="sigBuy(\'' + esc(it.id) + '\')">Buy now</button>' +
          '</div>') +
      '<div class="sig-detail-note">Buy any five signatures and NOWSSB50 takes 50% off at checkout.</div>';

    panel.classList.add('open');
  };
  window.sigCloseDetail = function () {
    var p = document.getElementById('sigDetail');
    if (p) p.classList.remove('open');
    render();
  };

  function cartItem(it) {
    return { id: it.id, name: it.name, type: it.kind === 'word' ? 'Word' : 'Meaning',
             price: price(), img: it.img,
             /* Tags this as a real signature purchase so the NOWSSB50
                bundle counts it — same flag part055.js sets. */
             sigTag: 'signature' };
  }

  window.sigAdd = function (id) {
    var it = byId(id);
    if (!it || typeof nssAddToCart !== 'function') return;
    nssAddToCart(cartItem(it));
    var b = document.getElementById('sigAddBtn');
    if (b) b.textContent = 'In your cart';
    syncBadges();
  };

  window.sigBuy = function (id) {
    var it = byId(id);
    if (!it) return;
    if (typeof nssAddToCart === 'function' && !inCart(it.id)) nssAddToCart(cartItem(it));
    syncBadges();
    /* Checkout is the app's, and is not another store. */
    if (typeof window.nssOpenCart === 'function') window.nssOpenCart();
    else if (typeof openSub === 'function') openSub('checkout');
  };

  /* ── Opening and closing the shop ──────────────────────────────────
     It opens on its intro, like the Word Atelier and the Meaning Store
     do, and the intro is shown again on every visit rather than once —
     it is the shop's cover, not an onboarding step. ── */
  window.sigOpenStore = function () {
    var s = document.getElementById('sub-signature-store');
    if (!s) return;
    render();
    window.sigTab('words');
    var intro = document.getElementById('sigIntroPage');
    if (intro) intro.classList.remove('sig-intro-hidden');
    s.classList.add('open');
    crossfade(true);
    try { if (navigator.vibrate) navigator.vibrate(22); } catch (e) {}
  };
  window.sigEnterStore = function () {
    var intro = document.getElementById('sigIntroPage');
    if (intro) intro.classList.add('sig-intro-hidden');
    try { if (navigator.vibrate) navigator.vibrate(30); } catch (e) {}
  };
  window.sigCloseStore = function () {
    var s = document.getElementById('sub-signature-store');
    window.sigCloseDetail();
    if (s) s.classList.remove('open');
    crossfade(false);
  };

  /* ── Both clips, one frame ─────────────────────────────────────────
     Runs only while something using it is on screen; a timer behind a
     closed screen is a wakelock nobody asked for. ── */
  var flip = null, showB = false;
  function pairs() {
    return [
      [document.getElementById('sigVidWord'), document.getElementById('sigVidMeaning')],
      [document.getElementById('sigPageVidA'), document.getElementById('sigPageVidB')]
    ].filter(function (p) { return p[0] && p[1]; });
  }
  function crossfade(on) {
    if (!on) {
      /* Only stop once nothing that uses it is open. */
      var hub = document.getElementById('sub-nowssb-store');
      var page = document.getElementById('sub-signature-store');
      if ((hub && hub.classList.contains('open')) || (page && page.classList.contains('open'))) return;
      if (flip) { clearInterval(flip); flip = null; }
      return;
    }
    if (flip) return;
    flip = setInterval(function () {
      showB = !showB;
      pairs().forEach(function (p) {
        p[1].classList.toggle('on', showB);
        var vis = showB ? p[1] : p[0], hid = showB ? p[0] : p[1];
        try { vis.muted = true; vis.play().catch(function () {}); } catch (e) {}
        try { hid.pause(); } catch (e) {}
      });
    }, 6000);
  }

  /* ── Wiring ────────────────────────────────────────────────────────
     The store hub is opened in a dozen places by adding .open to the
     element rather than through openSub, so watch the element itself. */
  function watchScreen(id, onOpen, onClose) {
    var el = document.getElementById(id);
    if (!el) return false;
    var was = el.classList.contains('open');
    if (was) onOpen();
    try {
      new MutationObserver(function () {
        var now = el.classList.contains('open');
        if (now === was) return;
        was = now;
        if (now) onOpen(); else onClose();
      }).observe(el, { attributes: true, attributeFilter: ['class'] });
    } catch (e) {}
    return true;
  }

  function boot() {
    var ok = watchScreen('sub-nowssb-store',
      function () { crossfade(true); },
      function () { crossfade(false); });
    watchScreen('sub-signature-store',
      function () { render(); crossfade(true); },
      function () { crossfade(false); });
    return ok;
  }
  if (!boot()) {
    var n = 0;
    var t = setInterval(function () { if (boot() || ++n > 60) clearInterval(t); }, 250);
  }

  /* The hardware/browser back button should close this like any other
     screen — part049.js's trap closes the topmost .sub-screen.open, which
     this is, so only the detail panel needs saying. */
  var prevCloseSub = window.closeSub;
  window.closeSub = function (id) {
    if (id === 'signature-store') { window.sigCloseStore(); return; }
    if (typeof prevCloseSub === 'function') return prevCloseSub.apply(this, arguments);
  };

})();
