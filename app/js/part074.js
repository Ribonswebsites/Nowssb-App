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
  /* For a value going into an onclick="…'here'…" — the attribute is already
     double-quoted, so the single quotes are what need escaping. */
  function jsq(s) { return String(s == null ? '' : s).replace(/\\/g, '\\\\').replace(/'/g, "\\'"); }
  function money(n) {
    return (typeof window.nwsbFormatINR === 'function') ? window.nwsbFormatINR(n) : ('₹' + n);
  }
  /* The two discs the black banners wear. Repo files, not the store's
     product photography: these are the collection's own marks — the gold
     frame for the words, the gold Meanings case for the meanings — and
     they were previously reading whatever the store had set, which on a
     cold load was an empty string and a broken-image glyph. */
  function wordImg() { return 'assets/media/image/sig-words-icon-92721e36.webp'; }
  function meanImg() { return 'assets/media/image/sig-meanings-icon-55f12bc1.webp'; }
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

  /* ── The rows ──────────────────────────────────────────────────────
     Not a grid and not a toggle. The Word Atelier draws a black
     .rm-cat-banner and then a horizontally scrolling .rm-word-row of
     .rm-word-card; the Meaning Store draws the same banner and then an
     .ms-grid of .ms-card, which nowssb-nm.css already turns into the
     same kind of row. This page is both, one after the other, using
     their markup rather than a shape of its own — which is the whole
     point of a shop that is the two of them combined.

     Cards carry the wishlist and cart chips the Meaning Store's cards
     carry, so a signature can go into the basket from the row without
     opening anything. ── */
  function cardActions(it) {
    if (owned(it)) return '';
    var wishIds = (window.nssWishlist || []).map(function (w) { return w.id; });
    var inW = wishIds.indexOf(it.id) >= 0;
    var inC = inCart(it.id);
    var args = "{id:'" + jsq(it.id) + "',name:'" + jsq(it.name) + "',type:'" +
               (it.kind === 'word' ? 'Word' : 'Meaning') + "',price:" + price() +
               ",img:'" + jsq(it.img) + "',sigTag:'signature'}";
    return '<div class="nss-card-actions">' +
      '<div class="nss-card-action' + (inW ? ' wishlisted' : '') + '" data-nss-wish="' + esc(it.id) + '" ' +
        'onclick="event.stopPropagation();nssToggleWishlist(' + args + ')">' +
        '<svg width="11" height="11" viewBox="0 0 16 16" fill="' + (inW ? 'rgba(220,80,80,0.9)' : 'none') + '">' +
          '<path d="M8 13.5S2 9.5 2 5.5A3 3 0 0 1 8 4.1 3 3 0 0 1 14 5.5C14 9.5 8 13.5 8 13.5Z" stroke="rgba(255,255,255,0.6)" stroke-width="1.2" stroke-linejoin="round"/>' +
        '</svg>' +
      '</div>' +
      '<div class="nss-card-action' + (inC ? ' carted' : '') + '" data-nss-cart="' + esc(it.id) + '" ' +
        'onclick="event.stopPropagation();nssAddToCart(' + args + ');sigRenderStore()">' +
        '<svg width="11" height="11" viewBox="0 0 16 16" fill="none">' +
          '<path d="M2 2h1.5l2 8h7l1.5-5.5H4.5" stroke="rgba(232,213,163,0.8)" stroke-width="1.2" stroke-linecap="square"/>' +
          '<circle cx="7" cy="12.5" r="1" fill="rgba(232,213,163,0.7)"/>' +
          '<circle cx="11" cy="12.5" r="1" fill="rgba(232,213,163,0.7)"/>' +
        '</svg>' +
      '</div>' +
    '</div>';
  }

  /* The Word Atelier's card, exactly. */
  function wordCard(it) {
    return '<div class="rm-word-card rm-word-card-signature" onclick="sigOpenDetail(\'' + esc(it.id) + '\')">' +
             '<span class="rm-word-card-signature-tag">Signature</span>' +
             cardActions(it) +
             '<img decoding="async" class="rm-word-card-img" src="' + esc(it.img) + '" alt="" loading="lazy">' +
             '<div class="rm-word-card-overlay"></div>' +
             '<div class="rm-word-card-body">' +
               '<div class="rm-word-card-name">' + esc(it.name) + '</div>' +
               '<div class="rm-word-card-root">' + esc(it.root) + '</div>' +
             '</div>' +
           '</div>';
  }

  /* The Meaning Store's card, exactly. */
  function meaningCard(it) {
    var own = owned(it);
    return '<div class="ms-card ms-card-signature' + (own ? ' unlocked' : '') + '" style="position:relative;" ' +
             'onclick="sigOpenDetail(\'' + esc(it.id) + '\')">' +
             '<span class="ms-card-signature-tag">Signature</span>' +
             cardActions(it) +
             '<div class="ms-card-img" style="background-image:url(\'' + esc(it.img) + '\')"></div>' +
             '<div class="ms-card-overlay"></div>' +
             '<div class="ms-card-body">' +
               '<div class="ms-card-word">' + esc(it.name) + '</div>' +
               '<div class="ms-card-root">' + esc(it.root) + '</div>' +
               (own
                 ? '<div class="ms-card-unlocked-badge"><svg width="8" height="7" viewBox="0 0 10 9" fill="none"><path d="M1 4L3.5 7L9 1" stroke="rgba(232,213,163,0.85)" stroke-width="1.5" stroke-linecap="square"/></svg>Unlocked</div>'
                 : '<div class="ms-card-price">' + money(price()) + '</div>') +
             '</div>' +
           '</div>';
  }

  /* The black section header both stores use. */
  function catBanner(logo, title, sub) {
    return '<div class="rm-cat-banner">' +
             '<div class="rm-cat-banner-logo"><img decoding="async" loading="lazy" src="' + esc(logo) + '" alt=""></div>' +
             '<div class="rm-cat-banner-divider"></div>' +
             '<div class="rm-cat-banner-text">' +
               '<div class="rm-cat-banner-title">' + esc(title) + '</div>' +
               '<div class="rm-cat-banner-sub">' + esc(sub) + '</div>' +
             '</div>' +
           '</div>';
  }
  function rowVid(src) {
    return '<div class="rm-row-vid"><video data-nwsb-auto muted loop playsinline preload="none" src="' + esc(src) + '"></video></div>';
  }

  /* The shop's own clips. Four of them, one above each of the four rows,
     plus a coupon clip taken from the app's rotation so the Signature is
     part of the same run of offers as everywhere else. Local files — they
     ship with the app and warm into the media cache with everything else. */
  var SIG_VIDS = [
    './assets/video/signature-a.mp4',
    './assets/video/signature-b.mp4',
    './assets/video/signature-c.mp4',
    './assets/video/signature-d.mp4',
    './assets/video/signature-e.mp4'
  ];
  /* Only the clips of a screen that has been opened are ever in the DOM, so
     a scan cannot find these until the reader has already been made to wait
     for them. Handed to the warmer directly instead. */
  window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || []).concat(SIG_VIDS);

  /* Fifteen words and five meanings, split in two so each kind gets two
     rows rather than one long one — a single row of fifteen is a scroll
     with no landmarks in it. Split down the middle, larger half first. */
  function halves(a) {
    var cut = Math.ceil(a.length / 2);
    return [a.slice(0, cut), a.slice(cut)];
  }

  function render() {
    var host = document.getElementById('sigSections');
    if (!host) return;
    var w = halves(words()), m = halves(meanings());
    var html = '';

    function wordRow(list, vid, title, sub) {
      if (!list.length) return '';
      return rowVid(vid) + catBanner(wordImg(), title, sub) +
        '<div class="rm-word-row sig-row">' + list.map(wordCard).join('') + '</div>';
    }
    function meaningRow(list, vid, title, sub) {
      if (!list.length) return '';
      return rowVid(vid) + catBanner(meanImg(), title, sub) +
        '<div class="ms-grid sig-row">' + list.map(meaningCard).join('') + '</div>';
    }

    html += wordRow(w[0], SIG_VIDS[0], 'Signature Words',
                    'One per collection — the rarest word each one has');
    /* The coupon clip sits between the two word rows, where the app puts a
       coupon on every other shelf. */
    html += wordRow(w[1], (window.nwsbNextCouponVid ? window.nwsbNextCouponVid() : SIG_VIDS[1]),
                    'Signature Words · II', 'The rest of the collection');
    html += meaningRow(m[0], SIG_VIDS[2], 'Signature Meanings',
                       'The full decoded origin, not the base entry');
    html += meaningRow(m[1], SIG_VIDS[3], 'Signature Meanings · II',
                       'The rest of the collection');

    /* Two clips close the shop, with the request banner between them —
       the same one the Word Atelier carries, because the answer to "the
       signature I want is not here" is the same answer. A line above and a
       line below, the way the store labels its own sections. */
    if (html) {
      html += rowVid(SIG_VIDS[1]);
      html += '<div class="sig-req-lead">Not on the shelf?</div>' +
              '<div class="rm-req-banner sig-req-banner" onclick="rmOpenWordRequest()">' +
                '<div class="rm-req-banner-icon">' +
                  '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>' +
                '</div>' +
                '<div class="rm-req-banner-text">' +
                  '<div class="rm-req-banner-eyebrow">Signature · Words &amp; Meanings</div>' +
                  '<div class="rm-req-banner-title">Request a Signature</div>' +
                  '<div class="rm-req-banner-sub">Personally crafted &amp; delivered within 48 hours.</div>' +
                '</div>' +
                '<button class="rm-req-banner-btn" onclick="event.stopPropagation();rmOpenWordRequest()">Request' +
                  '<svg width="13" height="13" viewBox="0 0 14 14" fill="none"><path d="M3 7H11M7 3L11 7L7 11" stroke="#060c18" stroke-width="1.8" stroke-linecap="square"/></svg>' +
                '</button>' +
              '</div>' +
              '<div class="sig-req-tail">One per collection — when one is gone it is gone.</div>';
      html += rowVid(SIG_VIDS[4]);
    }

    if (!html) html = '<div class="sig-empty">Nothing in the collection yet.</div>';

    host.innerHTML = html;
    syncBadges();
    /* Real <video> tags, so the app's own autoplay handling picks them up
       like every other clip on every other shelf. */
    if (window.nwsbAutoPlayVideos) { try { window.nwsbAutoPlayVideos(); } catch (e) {} }
  }
  window.sigRenderStore = render;

  /* The page has its own cart count in its own nav bar. */
  function syncBadges() {
    var c = document.getElementById('sigCartBadge');
    if (c) c.textContent = (window.nssCart || []).length;
  }

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
    /* Only the doorway in the store hub crossfades now — the page shows
       the two clips one above the other, as .rm-row-vid, the way the Word
       Atelier already breaks its rows up. */
    return [
      [document.getElementById('sigVidWord'), document.getElementById('sigVidMeaning')]
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
