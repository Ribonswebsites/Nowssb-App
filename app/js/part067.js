/* ══════════════════════════════════════════════════════════
   VIDEO BANNERS — one place that says which clip goes above what.

   Placing these by hand would have meant editing a dozen spots across a
   9k-line document and then finding them all again next time one moves.
   The table below is the whole feature: a selector, a clip, and whether
   the banner goes before that element or at the top of it.

   Everything is injected once and guarded by a marker class, so a section
   that gets re-rendered by its own file does not end up with two banners.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var V = 'https://res.cloudinary.com/eenvubod/video/upload/';

  /* before: the banner is inserted as the element's previous sibling.
     top:    the banner is inserted as the element's first child.
     bottom: the banner is appended as the element's last child.
     after:  the banner is inserted as the element's next sibling. */
  var PLACE = [
    // Above the NowssB Store section, on both homes
    { top:    '#home-nm .nmh-store-wrap',          vid: V + 'v1785402930/grok_video_2026-07-30-14-43-38_olejrw.mp4' },
    { before: '#home .nss-store-trigger',          vid: V + 'v1785402930/grok_video_2026-07-30-14-43-38_olejrw.mp4' },

    // Above Personalised Healing — the clip's subject sits left, so the
    // copy and the arrow go right, the same way the Reader section reads.
    { bottom: '#home-nm .nmh-healing-wrap',        vid: V + 'v1785402957/grok_video_2026-07-30-14-42-14_ihmhi7.mp4', gender: 1 },
    { bottom: '#home .fash-healing-wrap',          vid: V + 'v1785402957/grok_video_2026-07-30-14-42-14_ihmhi7.mp4', gender: 1 },

    // Above NowssB Connect
    { before: '#home-nm .nmh-connect-sec',         vid: V + 'v1785402935/grok_video_2026-07-30-14-43-48_lfrvok.mp4' },
    { before: '#home .fash-connect-wrap',          vid: V + 'v1785402935/grok_video_2026-07-30-14-43-48_lfrvok.mp4' },

    // Trending
    { top:    '#home-nm .nmh-trend-shop-wrap',     vid: V + 'v1785402931/grok_video_2026-07-30-14-43-11_gjhfww.mp4' },
    { top:    '#home .fash-storevid-wrap',         vid: V + 'v1785402931/grok_video_2026-07-30-14-43-11_gjhfww.mp4' },

    // Meaning — a different clip in each place it appears
    { before: '#home-nm .krm-section',             vid: V + 'v1785402917/grok_video_2026-07-30-14-44-14_cqj4qc.mp4' },
    { before: '#home #fashMeaningSearchWrap',      vid: V + 'v1785406062/grok_video_2026-07-30-15-36-37_mrnmll.mp4' },
    /* Below the store's own cinematic hero (#msBanner), not above it — a
       `top` placement into #msMeaningBody had been landing it before the
       hero as that host's first child instead. */
    { after:  '#msBanner',                         vid: V + 'v1785406069/grok_video_2026-07-30-15-36-38_uq9l5d.mp4' },

    /* These two pages hang their scroller off `position: absolute; inset: 0`,
       so a banner at the top of the page box sits behind it. It goes at the
       top of the scrolling content instead, below the hero and clear of the
       fixed header. */
    { top:    '#sub-offers .bgp-content',          vid: V + 'v1785402975/grok_video_2026-07-30-14-43-34_lqppzd.mp4' },
    { top:    '#sub-quick-access .bgp-content',    vid: V + 'v1785402945/grok_video_2026-07-30-14-43-00_ft8o8u.mp4' },

    // Every word's own page, above About This Word — a player banner, so it
    // carries the player mark on the right and opens the practice.
    { before: '.rmd-desc-block',                   vid: 'https://res.cloudinary.com/yvi3d7ov/video/upload/v1785438349/grok_video_2026-07-31-00-34-23_ouxhic.mp4',
      player: 1, go: 'openPracticeIntro()' }
  ];

  /* The coupon art is a clip now. The rotators keep swapping the <img> they
     have always swapped; it is simply hidden underneath, so nothing has to be
     unpicked and every surface changes at once. */
  var COUPON_VID = 'https://res.cloudinary.com/yvi3d7ov/video/upload/v1785438343/grok_video_2026-07-31-00-34-06_c2fuko.mp4';
  var COUPON_HOSTS = '#nmhGreetImg, #fashCouponImg, #rmdCouponBanner, #msdCouponBanner';
  var PLAYER_ICON = 'https://res.cloudinary.com/eenvubod/image/upload/e_trim,f_auto,q_auto,w_180/v1784130176/file_000000003254720aab81c7118e7cc24a_ohsba3.png';

  /* The eBooks clip is not a plain banner — it carries its own black banner
     underneath it inside one glass wrapper, and it goes in three places: the
     home sections, above the shelf on the store page, and above the copy on
     every book's own page. */
  var EB_VID  = V + 'v1785406073/grok_video_2026-07-30-15-35-40_xwm1ei.mp4';
  var EB_ICON = 'https://res.cloudinary.com/eenvubod/image/upload/v1784974211/file_00000000ae5882089bc97a56b7368777_l4cq7e.png';

  /* The subscription clip was the same one in several places. The two home
     banners keep a clip of their own; the plan banner on the subscription
     page and the Edition cards each get their own. */
  var SWAP = [
    /* The main subscription banner on both homes — a different cloud from
       the rest, so the full URL rather than the V prefix. */
    { sel: '#home-nm .nmh-vb-tall video, #home .fash-vb-tall video',
      vid: 'https://res.cloudinary.com/dkzxw33ln/video/upload/v1785518003/grok_video_2026-07-31-22-26-26_xiytvf.mp4' },
    { sel: '.ss-plan-banner-vid',
      vid: V + 'v1785406071/grok_video_2026-07-30-15-36-45_ihftsp.mp4' },
    { sel: '.fsec-video',
      vid: V + 'v1785407198/grok_video_2026-07-30-15-55-42_onadht.mp4' }
  ];

  /* ── What a banner leads to, named down its right-hand side ────────
     Every icon here is a file the app already ships and already uses for
     that section — the Quick Links rail's own map — so a chip reads as the
     same thing the user taps elsewhere. ── */
  var I = 'https://res.cloudinary.com/';
  var CHIP_IC = {
    meaning: I + 'eenvubod/image/upload/v1784460474/file_00000000854881fa9a548a68fae59c15_w1utya.png',
    words:   I + 'ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png',
    ebooks:  I + 'eenvubod/image/upload/v1784974211/file_00000000ae5882089bc97a56b7368777_l4cq7e.png',
    connect: I + 'eenvubod/image/upload/f_auto,q_auto,w_120/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png',
    chat:    I + 'ds6duqabl/image/upload/f_auto,q_auto/v1780123160/1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png',
    profile: I + 'ds6duqabl/image/upload/f_auto,q_auto/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png',
    offer:   I + 'eenvubod/image/upload/v1784915420/file_000000006b20820b84961321dcdcaaa8_be9meu.png'
  };
  var STORE_CHIPS = [
    ['meaning', 'Meanings', 'The origin behind any word'],
    ['words',   'Words',    'Own the sounds that heal'],
    ['ebooks',  'eBooks',   'Deep-dive guides, yours to keep']
  ];
  var CONNECT_CHIPS = [
    ['connect', 'Community', 'See what others are practising'],
    ['chat',    'Chat',      'Your conversations, in one place'],
    ['profile', 'Profile',   'Your space on NowssB']
  ];
  var TREND_CHIPS = [
    ['words',   'Trending Word', 'What is healing the most today'],
    ['meaning', 'Meanings',      'The origin behind any word'],
    ['offer',   "Today's Offer", 'Rotating store coupons']
  ];
  var READER_CHIPS = [
    ['meaning', 'Meanings', 'Read every meaning as a book'],
    ['ebooks',  'eBooks',   'Every guide, page by page']
  ];

  var CHIPS = [
    { sel: '#home-nm .vb-banner[data-vb="vb0"], #home .vb-banner[data-vb="vb1"]', items: STORE_CHIPS },
    { sel: '#home-nm .vb-banner[data-vb="vb4"], #home .vb-banner[data-vb="vb5"]', items: CONNECT_CHIPS },
    { sel: '#home-nm .vb-banner[data-vb="vb6"], #home .vb-banner[data-vb="vb7"]', items: TREND_CHIPS },
    { sel: '#home-nm .nmh-rdsec-wrap .reader-sec, #home .fash-rdsec-wrap .reader-sec', items: READER_CHIPS }
  ];

  /* One at a time: the chip dashes in from the right, holds, and the next
     one replaces it. Stacked they covered the whole right half of the clip;
     a single row leaves the artwork alone and still names everything. The
     dash is the app's own nmhTrendWordDash, the same move the trending word
     and the store pills already make. */
  var chipRails = [];

  function chipsHtml(items) {
    return '<div class="vb-chips"><span class="vb-chip dash-in">' +
      '<span class="vb-chip-ic"><img loading="lazy" decoding="async" alt="" src="' + CHIP_IC[items[0][0]] + '"></span>' +
      '<span class="vb-chip-txt">' +
        '<span class="vb-chip-t">' + esc(items[0][1]) + '</span>' +
        '<span class="vb-chip-s">' + esc(items[0][2]) + '</span>' +
      '</span></span></div>';
  }

  function paintChips() {
    CHIPS.forEach(function (c) {
      document.querySelectorAll(c.sel).forEach(function (host) {
        if (host.querySelector(':scope > .vb-chips')) return;
        host.insertAdjacentHTML('beforeend', chipsHtml(c.items));
        chipRails.push({ el: host.querySelector(':scope > .vb-chips'), items: c.items, i: 0 });
      });
    });
  }

  function tickChips() {
    for (var n = chipRails.length - 1; n >= 0; n--) {
      var r = chipRails[n];
      if (!r.el || !r.el.isConnected) { chipRails.splice(n, 1); continue; }
      if (r.items.length < 2) continue;
      r.i = (r.i + 1) % r.items.length;
      var chip = r.el.firstChild;
      var it = r.items[r.i];
      chip.querySelector('.vb-chip-ic img').setAttribute('src', CHIP_IC[it[0]]);
      chip.querySelector('.vb-chip-t').textContent = it[1];
      chip.querySelector('.vb-chip-s').textContent = it[2];
      /* Removing the class is not enough on its own — the animation only
         restarts once the element has been reflowed without it. */
      chip.classList.remove('dash-in');
      void chip.offsetWidth;
      chip.classList.add('dash-in');
    }
  }
  setInterval(tickChips, 2600);

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  function makeBanner(spec) {
    var d = document.createElement('div');
    d.className = 'vb-banner' + (spec.player ? ' vb-banner-player' : '');
    var html = '<video data-nwsb-auto muted loop playsinline preload="none" src="' + spec.vid + '"></video>';
    if (spec.gender) {
      /* Two words over their own halves of the clip, each with its own
         Enter to the right of it — no panel behind any of it, so the video
         is not covered. Each side opens Personalised Healing already
         highlighted, using the page's own applyHealthGenderHighlight. */
      var go = '<span class="vb-cta vb-g-cta">' +
          '<span class="vb-cta-lbl">Enter</span>' +
          '<span class="vb-go"><svg viewBox="0 0 12 12" fill="none">' +
            '<path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/>' +
          '</svg></span>' +
        '</span>';
      html +=
        '<button class="vb-g vb-g-f" onclick="event.stopPropagation();vbGender(\'female\')">' +
          '<span class="vb-g-lbl">Female</span>' + go + '</button>' +
        '<button class="vb-g vb-g-m" onclick="event.stopPropagation();vbGender(\'male\')">' +
          '<span class="vb-g-lbl">Male</span>' + go + '</button>';
    } else if (spec.player) {
      /* Just the mark, at the middle of the right edge — the clip's own
         artwork already carries "NowssB Player" burned in, so a second,
         separate line of copy over it only doubled up and overlapped. */
      html +=
        '<div class="vb-player">' +
          '<span class="vb-player-ic"><img loading="lazy" decoding="async" alt="" src="' + PLAYER_ICON + '"></span>' +
        '</div>';
    } else if (spec.cta) {
      html += '<span class="vb-rule"></span>' +
        '<div class="vb-txt">' +
          '<span class="vb-hello">' + esc(spec.cta.hello) + '</span>' +
          '<span class="vb-name">' + esc(spec.cta.name) + '</span>' +
          (spec.cta.sub ? '<span class="vb-sub">' + esc(spec.cta.sub) + '</span>' : '') +
          '<span class="vb-cta"><span class="vb-cta-lbl">Enter</span>' +
            '<span class="vb-go"><svg viewBox="0 0 12 12" fill="none">' +
              '<path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/>' +
            '</svg></span>' +
          '</span>' +
        '</div>';
    }
    d.innerHTML = html;
    if (spec.go) { d.setAttribute('onclick', spec.go); d.style.cursor = 'pointer'; }
    return d;
  }

  function couponVideo() {
    document.querySelectorAll(COUPON_HOSTS).forEach(function (img) {
      if (img.tagName !== 'IMG' || img.getAttribute('data-vb-coupon')) return;
      img.setAttribute('data-vb-coupon', '1');
      var v = document.createElement('video');
      v.className = 'vb-coupon-vid ' + img.className;
      /* .nmh-greet-img and .fash-coupon-img size themselves through their own
         CSS class, but .rmd-coupon-banner (the word/meaning detail pages)
         carries no CSS at all — every dimension it had lived only in this
         img's inline style. Without copying that over too, the clip had no
         width or height anywhere and rendered at a huge, unconstrained
         default box. */
      var style = img.getAttribute('style');
      if (style) v.setAttribute('style', style);
      v.muted = true; v.loop = true; v.playsInline = true;
      v.setAttribute('data-nwsb-auto', '');
      v.setAttribute('playsinline', '');
      v.setAttribute('preload', 'none');
      v.src = COUPON_VID;
      var go = img.getAttribute('onclick');
      if (go) { v.setAttribute('onclick', go); v.style.cursor = 'pointer'; }
      /* The hosts carry `display: block !important`, so hiding the original
         needs a class of equal weight rather than an inline style. */
      img.classList.add('vb-coupon-hidden');
      img.parentNode.insertBefore(v, img);
    });
    /* Shop Now used to hide on the one coupon image that carried its own
       button; the rotators still toggle that class on their own timer, so a
       stylesheet rule keeps it shown rather than a one-off removal here. */
  }

  /* Video on top, black banner under it, one wrapper around both. */
  function ebBlock(sub) {
    var d = document.createElement('div');
    d.className = 'ebvb-wrap';
    d.innerHTML =
      '<div class="ebvb-vid">' +
        '<video data-nwsb-auto muted loop playsinline preload="none" src="' + EB_VID + '"></video>' +
      '</div>' +
      '<div class="nmh-sec-banner">' +
        '<div class="nmh-sec-banner-icon"><img loading="lazy" decoding="async" src="' + EB_ICON + '" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;"></div>' +
        '<div class="nmh-sec-banner-divider"></div>' +
        '<div class="nmh-sec-banner-txt">' +
          '<div class="nmh-sec-banner-title">The NowssB Ebooks</div>' +
          '<div class="nmh-sec-banner-sub">' + esc(sub) + '</div>' +
        '</div>' +
      '</div>';
    return d;
  }

  /* The home eBook sections open the store the long way round, through
     openSub — that is the call that renders the shelf. */
  window.ebSecOpen = function () {
    if (window.openSub) window.openSub('ebooks-store');
    else if (window.nssOpenSub) window.nssOpenSub('ebooks-store');
    try { if (navigator.vibrate) navigator.vibrate(18); } catch (e) {}
  };

  /* ebOpenBook rewrites #ebdBody wholesale, so the block has to go back in
     after every render rather than once at boot. */
  function wrapBookDetail() {
    if (!window.ebOpenBook || window.ebOpenBook.__vb) return;
    var inner = window.ebOpenBook;
    var wrapped = function (key) {
      var r = inner.apply(this, arguments);
      var body = document.getElementById('ebdBody');
      if (body && !body.querySelector(':scope > .ebvb-wrap')) {
        body.insertBefore(ebBlock('Read · Learn · Practice'), body.firstChild);
        if (window.nwsbVideoRefresh) window.nwsbVideoRefresh();
      }
      return r;
    };
    wrapped.__vb = 1;
    window.ebOpenBook = wrapped;
  }

  window.vbGender = function (g) {
    try { if (g) window._userGender = g; } catch (e) {}
    if (window.openSub) window.openSub('health-journey');
    if (g && window.applyHealthGenderHighlight) {
      setTimeout(function () { window.applyHealthGenderHighlight(g); }, 220);
    }
    try { if (navigator.vibrate) navigator.vibrate(28); } catch (e) {}
  };

  function place() {
    var added = false;
    PLACE.forEach(function (spec, i) {
      var key = 'vb' + i;
      var sel = spec.before || spec.top || spec.bottom || spec.after;
      var host = document.querySelector(sel);
      if (!host) return;
      /* One banner per target, however many times this runs. */
      var scope = (spec.before || spec.after) ? host.parentNode : host;
      if (!scope || scope.querySelector(':scope > .vb-banner[data-vb="' + key + '"]')) return;
      var el = makeBanner(spec);
      el.setAttribute('data-vb', key);
      if (spec.before) host.parentNode.insertBefore(el, host);
      else if (spec.bottom) host.appendChild(el);
      else if (spec.after) host.parentNode.insertBefore(el, host.nextSibling);
      else host.insertBefore(el, host.firstChild);
      added = true;
    });
    /* The layout editor reorders the registered children of each home, and
       every banner is registered alongside the section it introduces — so a
       newly injected one has to be run through that pass or it stays where
       it landed while its section moves away. */
    if (added && window.hlApplyLayout) { try { window.hlApplyLayout(); } catch (e) {} }

    /* Store page: the block introduces the shelf, so it sits directly above
       #ebGrid rather than at the top of the page above the hero. */
    var grid = document.getElementById('ebGrid');
    if (grid && grid.parentNode && !grid.parentNode.querySelector(':scope > .ebvb-wrap')) {
      grid.parentNode.insertBefore(ebBlock('Deep-dive guides on word science and sound healing'), grid);
    }
    wrapBookDetail();
    paintChips();
    couponVideo();

    SWAP.forEach(function (s) {
      document.querySelectorAll(s.sel).forEach(function (v) {
        if (v.tagName !== 'VIDEO') return;
        if (v.getAttribute('src') === s.vid) return;
        v.setAttribute('src', s.vid);
        try { v.load(); } catch (e) {}
      });
    });
  }
  window.vbPlace = place;

  function boot() {
    place();
    /* Several of these sections are rendered by their own files after first
       paint; a couple of late passes catch the ones that were not there yet. */
    setTimeout(place, 1500);
    setTimeout(place, 3500);
    setTimeout(place, 6000);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
