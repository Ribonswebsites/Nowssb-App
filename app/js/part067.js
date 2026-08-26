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
    /* Above the NowssB Store section, on both homes. In the repo rather
       than on a CDN — the store is the thing the app sells from, and its
       banner should not be one network hop away from not being there. */
    /* The Fashion store's own clip, not the one the Normal home uses. It
       lands INSIDE .fash-store-wrap because `before` inserts into the
       trigger's parent, which is that wrapper now — between the head and
       the card, which is where a section's banner goes. */
    /* The banner has a block of its own now, further down the page, and its
       own landscape clip. It used to be injected on top of the store card
       carrying the TALL render — a portrait film in a landscape banner,
       which is what made both of them look wrong. */
    { before: '#home .fash-storeban-slot',        vid: './assets/video/store-banner-fash.mp4?v=1' },

    /* Choose Your Path, on the laptop, in a section of its own. On the Normal
       home it is inserted directly below the Experience · Fashion Mode
       switch, so the same order survives a fresh HTML/WebView load before the
       layout manager applies any saved custom arrangement. The wrapper is
       registered in app/js/part062.js as 'genderpath'; a direct child of the
       home wrap that the registry does not know about gets stranded at the top
       of the page while everything registered is re-appended around it. */
    { after: '#home-nm #nmhFashSwitch',             vid: "", gender: 1, frame: 'dev-laptop', wrap: 'nwsb-vbwrap',
      head: { hello:'Body, organ and mind', name:'Choose Your Path',
              icon:"<svg viewBox=\"0 0 24 24\" fill=\"none\"><path d=\"M12 3.2v17.6\" stroke=\"#fff\" stroke-width=\"1.5\" stroke-linecap=\"round\"/><circle cx=\"7\" cy=\"8.4\" r=\"2.6\" stroke=\"#fff\" stroke-width=\"1.5\"/><circle cx=\"17\" cy=\"8.4\" r=\"2.6\" stroke=\"#fff\" stroke-width=\"1.5\"/><path d=\"M3 17.4v-.8a4 4 0 018 0v.8M13 17.4v-.8a4 4 0 018 0v.8\" stroke=\"#fff\" stroke-width=\"1.5\" stroke-linecap=\"round\"/></svg>",
              banName:'Female or Male', banSub:'Your wellness, decoded for your body',
              banGo: function () { if (typeof openHealingIntro === 'function') openHealingIntro();
                                   else if (typeof openSub === 'function') openSub('health-category'); } } },
    /* The Connect banner — the clip that introduces the section, not the
       section's own background clip (.nmh-connect-vid, which is untouched).
       On the landscape tablet, wordmark on the bottom bezel.
       It goes INTO .nc-blk-vid rather than before the section: the banner
       and the features carousel are one block with a heading now, built the
       way Quick Access is, and .nc-blk is what part062.js registers. */
    { top:    '#home-nm .nc-blk-vid',              vid: './assets/video/connect-banner.mp4?v=1', frame: 'dev-tabc-l' },
    { top:    '#home .nc-blk-vid',                 vid: './assets/video/connect-banner.mp4?v=1', frame: 'dev-tabc-l' },

    // Trending
    { top:    '#home-nm .nmh-trend-shop-wrap',     vid: "" },
    { top:    '#home .fash-storevid-wrap',         vid: V + 'v1785402931/grok_video_2026-07-30-14-43-11_gjhfww.mp4' },

    // Meaning — a different clip in each place it appears
    { before: '#home-nm .krm-section',             vid: "", frame: 'dev-tab-l', wrap: 'nvb-blk' },
    /* The clip this tablet used to carry never arrived — the tablet above
       Meaning Search on the Fashion home was a black screen. It ships in
       the repo now rather than coming from a CDN, which is also why it
       cannot silently stop working again. */
    { before: '#home #fashMeaningSearchWrap',      vid: './assets/video/orb-loop.mp4?v=1', frame: 'dev-tab-l', wrap: 'nvb-blk glass-wrap', own: 1 },
    /* Below the store's own cinematic hero (#msBanner), not above it — a
       `top` placement into #msMeaningBody had been landing it before the
       hero as that host's first child instead. */
    { after:  '#msBanner',                         vid: V + 'v1785406069/grok_video_2026-07-30-15-36-38_uq9l5d.mp4' },

    /* These two pages hang their scroller off `position: absolute; inset: 0`,
       so a banner at the top of the page box sits behind it. It goes at the
       top of the scrolling content instead, below the hero and clear of the
       fixed header. */
    { top:    '#sub-offers .bgp-content',          vid: "" },
    { top:    '#sub-quick-access .bgp-content',    vid: "" },

    // Every word's own page, above About This Word — a player banner, so it
    // carries the player mark on the right and opens the practice.
    { before: '.rmd-desc-block',                   vid: 'https://res.cloudinary.com/yvi3d7ov/video/upload/v1785438349/grok_video_2026-07-31-00-34-23_ouxhic.mp4',
      player: 1, go: 'openPracticeIntro()' }
  ];

  /* The coupon art is a clip now. The rotators keep swapping the <img> they
     have always swapped; it is simply hidden underneath, so nothing has to be
     unpicked and every surface changes at once. */
  /* Three clips, not one. There are four coupon surfaces in the app and
     they used to be the same ten seconds of video on all of them; each now
     takes the next clip in the list, and the list starts at a different
     place on each launch, so the same surface is not always the same clip
     either. The two new ones are local files — they ship with the app and
     the cache warms them like everything else. */
  var COUPON_VIDS = [
    'https://res.cloudinary.com/yvi3d7ov/video/upload/v1785438343/grok_video_2026-07-31-00-34-06_c2fuko.mp4',
    './assets/video/coupon-a.mp4',
    './assets/video/coupon-b.mp4'
  ];
  /* The offset is per launch rather than per render, so a rotator redrawing
     a banner does not make the clip jump under the reader. */
  var COUPON_OFFSET = Math.floor(Math.random() * COUPON_VIDS.length);
  var _couponSeen = 0;
  function nextCouponVid() {
    return COUPON_VIDS[(COUPON_OFFSET + _couponSeen++) % COUPON_VIDS.length];
  }
  /* Exposed so the Signature store can take one too, and so app/js/part051.js
     can warm all three — only the one currently in the DOM would be found by
     a scan, and the alternates never would. */
  window.NWSB_COUPON_VIDS = COUPON_VIDS;
  window.nwsbNextCouponVid = nextCouponVid;

  /* Everything this file can put on screen but might not have put on screen
     yet — the two coupon alternates and the subscription alternate. Only the
     clip actually chosen this launch is in the DOM, so a scan would warm one
     of three and leave the reader to download the others on the day they
     finally appear. See collectVideoUrls() in app/js/part051.js. */
  window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || []).concat(COUPON_VIDS);
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
  /* Alternates that are not in the DOM until they are chosen — same reason
     as the coupon list above. */
  /* Two more that live in the repo rather than on Cloudinary: the login
     phone, and the Word Science tile's clip. Listed here so part051.js
     warms them into VIDEO_CACHE during idle time like every other clip —
     the login one especially, because it is the first thing a new reader
     sees and it should not be arriving over the network while they wait. */
  window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || [])
    .concat(['./assets/video/subscription-a.mp4',
             './assets/video/login-phone.mp4']);

  var SWAP = [
    /* Two clips now, picked per launch — the banner that has always been
       here, and the new one. Added rather than swapped: the existing clip
       is the one the banner was designed around. */
    { sel: '#home-nm .nmh-vb-tall video, #home .fash-vb-tall video',
      vid: ["",
            './assets/video/subscription-a.mp4'] },
    { sel: '.ss-plan-banner-vid',
      vid: V + 'v1785406071/grok_video_2026-07-30-15-36-45_ihftsp.mp4' },
    /* The Edition section — the card that carries the plan and Upgrade,
       not the Subscribe Today banner above it. A different cloud from the
       rest, so the full URL rather than the V prefix. */
    { sel: '.fsec-video',
      vid: 'https://res.cloudinary.com/dkzxw33ln/video/upload/v1785518003/grok_video_2026-07-31-22-26-26_xiytvf.mp4' }
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
    /* The Connect banner takes no chips — Community / Chat / Profile sat
       over the right of the clip, and that clip carries its own wordmark. */
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
    /* `frame` puts a device render round the clip. The classes go ON the
       banner rather than in a wrapper around it, because .vb-banner[data-vb]
       is what app/js/part062.js matches — a wrapper would make the banner a
       grandchild of the home wrap and strand the whole section at the top of
       the page. The frame's padding is its bezel and its content box is the
       aperture, so .vbf-screen at 100%/100% fills the glass exactly. */
    d.className = 'vb-banner' + (spec.player ? ' vb-banner-player' : '')
                + (spec.frame ? ' nwsb-inframe ' + spec.frame : '');
    /* `own` takes a banner out of the shared video controller and gives it
       its own observer below. The controller decodes the four clips nearest
       the viewport, and on a page with as many as this home has, a banner
       that is not among them shows a black rectangle instead of a clip —
       which is exactly what the Meaning Search tablet had been doing. A
       banner marked `own` is never in that queue and never black. */
    var vid = '<video ' + (spec.own ? 'data-nwsb-own="1" data-nwsb-vis="1" preload="auto"' : 'data-nwsb-auto preload="none"') +
              ' muted loop playsinline src="' + spec.vid + '"></video>';
    var html = spec.frame ? '<div class="vbf-screen">' + vid + '</div>' : vid;
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
      var gbtns =
        '<button class="vb-g vb-g-f" onclick="event.stopPropagation();vbGender(\'female\')">' +
          '<span class="vb-g-lbl">Female</span>' + go + '</button>' +
        '<button class="vb-g vb-g-m" onclick="event.stopPropagation();vbGender(\'male\')">' +
          '<span class="vb-g-lbl">Male</span>' + go + '</button>';
      /* Inside the screen when there is one, so they sit on the glass and
         not over the lid or the keyboard. */
      if (spec.frame) html = html.replace('</div>', gbtns + '</div>');
      else html += gbtns;
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
      v.src = nextCouponVid();
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
  /* The clips that run themselves. One observer, play when seen, pause when
     not — no queue to lose a place in. */
  (function ownDriver() {
    if (!('IntersectionObserver' in window)) return;
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        var v = e.target;
        if (e.isIntersecting) {
          if (v.paused) { try { var p = v.play(); if (p && p.catch) p.catch(function () {}); } catch (err) {} }
        } else if (!v.paused) { try { v.pause(); } catch (err) {} }
      });
    }, { rootMargin: '20% 0px' });
    /* Nothing decodes underneath the start animation. That clip plays once,
       at the very front of the launch, and anything else starting a decoder
       while it runs is what makes it stutter — the app's own warmer waits
       for the same reason. */
    var splashDone = (typeof window.nwsbSplashWait !== 'function');
    if (!splashDone) { try { window.nwsbSplashWait(function () { splashDone = true; }); } catch (e) { splashDone = true; } }
    var scan = function () {
      if (!splashDone) return;
      /* [data-nwsb-own], not [data-nwsb-vis] — the plain hero's deck marks
         its cells with the latter to stay out of the shared controller too,
         and it runs exactly one of them at a time. Starting all six here
         would undo that. */
      document.querySelectorAll('video[data-nwsb-own="1"][src]').forEach(function (v) {
        if (v._ownSeen) return;
        v._ownSeen = 1;
        io.observe(v);
      });
    };
    scan();
    setInterval(scan, 2000);
  })();

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

  /* ── A heading above and a black banner below ──
     Quick Access, Connect and Subscription all read the same way: an orb
     and two lines of heading, the framed clip, then one black row saying
     where it goes. A wrapped banner can ask for the same. ── */
  var VB_ARROW = '<svg viewBox="0 0 24 24" fill="none"><path d="M5 12h14M12 5l7 7-7 7" stroke="rgba(255,255,255,0.9)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  function vbHead(h) {
    var d = document.createElement('div');
    d.className = 'qa-tv-head';
    d.innerHTML =
      /* The orb sits on a LIGHT disc on the Normal home, so the glyph takes
         the orb's colour instead of the hard white it wears on the black
         banner below — white on #f0f2f7 is an icon nobody can see. */
      '<div class="qa-tv-orb nsub-blk-orb" aria-hidden="true">' +
        h.icon.replace(/stroke="#fff"/g, 'stroke="currentColor"') +
      '</div>' +
      '<div class="qa-tv-head-txt">' +
        '<div class="qa-tv-hello">' + h.hello + '</div>' +
        '<div class="qa-tv-name">' + h.name + '</div>' +
      '</div>';
    return d;
  }
  function vbBanner(h) {
    var d = document.createElement('div');
    d.className = 'ncb-carousel nsub-ban';
    d.setAttribute('role', 'button');
    d.innerHTML =
      '<div class="ncb-slide">' +
        '<span class="ncb-ico">' + h.icon + '</span>' +
        '<span class="ncb-txt">' +
          '<span class="ncb-name">' + h.banName + '</span>' +
          '<span class="ncb-sub">' + h.banSub + '</span>' +
        '</span>' +
        '<span class="ncb-btn">' + VB_ARROW + '</span>' +
      '</div>';
    if (h.banGo) d.onclick = function () { try { h.banGo(); } catch (e) {} };
    return d;
  }

  function place() {
    var added = false;
    PLACE.forEach(function (spec, i) {
      var key = 'vb' + i;
      var sel = spec.before || spec.top || spec.bottom || spec.after;
      var host = document.querySelector(sel);
      if (!host) return;
      /* One banner per target, however many times this runs. */
      var scope = (spec.before || spec.after) ? host.parentNode : host;
      if (!scope) return;
      if (scope.querySelector(':scope > .vb-banner[data-vb="' + key + '"]')) return;
      if (scope.querySelector(':scope > [data-vbwrap="' + key + '"]')) return;
      var el = makeBanner(spec);
      el.setAttribute('data-vb', key);
      /* A wrapper of its own, when asked for. The banner keeps its data-vb
         so nothing that looks it up has to change; it is the WRAPPER that
         goes into the page and that the registry matches. */
      if (spec.wrap) {
        var w = document.createElement('div');
        w.className = spec.wrap;
        w.setAttribute('data-vbwrap', key);
        if (spec.head) w.appendChild(vbHead(spec.head));
        w.appendChild(el);
        if (spec.head) w.appendChild(vbBanner(spec.head));
        el = w;
      }
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
      /* An entry may carry one clip or a list of them. A list is picked from
         once per launch and then held, so `place()` running again — which it
         does, several times, to catch late-rendered sections — does not
         restart the video under the reader with a different one. */
      if (Array.isArray(s.vid) && s.pick == null) {
        s.pick = s.vid[Math.floor(Math.random() * s.vid.length)];
      }
      var src = s.pick || s.vid;
      document.querySelectorAll(s.sel).forEach(function (v) {
        if (v.tagName !== 'VIDEO') return;
        if (v.getAttribute('src') === src) return;
        v.setAttribute('src', src);
        /* load() starts a fetch there and then, which during the start
           animation means three more downloads under the one clip on
           screen. Every element here is preload="none" and is played by
           the controller in app/js/part051.js when it comes into view, so
           setting the source is enough — except before that controller
           exists, where the old behaviour is kept. */
        if (window._nwsbSplashOver !== false) { try { v.load(); } catch (e) {} }
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
