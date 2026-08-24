/* ══════════════════════════════════════════════════════════════════════
   THE PLAIN HERO — the greeting, the glass, and the rail

   The hero has three looks (app/js/part082.js): inside the television,
   full-screen behind the five photographs, or plain. This file is the
   third one's furniture, and it only exists while that look is chosen —
   turn the television back on and everything here is taken out again.

   Three parts:

     1. A greeting ABOVE the card, the way the Normal home opens: a light
        line that reads the clock and a heavy one with your name. It sits
        clear of the fixed header, which is what --home-header-h measures.

     2. The card itself is glass — the blur, the border and the highlight
        are in nowssb-nm.css. Behind it is either the Fashion Plus film or
        the home's own artwork, and both are worth seeing through.

     3. A rail inside it, where the five-photograph strip used to be. One
        banner at a time, each sliding in FROM THE RIGHT, playing ONCE, and
        handing over to the next as it ends. Four of them, and each is a
        door: the player, the Meaning store, the Word store and the Sound
        Library, every clip the one that page opens with.

   What it costs. Only the clip on screen has a src at all — the others
   are empty <video> elements until their turn — so nothing downloads
   ahead of being seen, and the one playing is the only one decoding. The
   whole rail stops when the home is not the screen you are on, when the
   app goes to the background, and when the look is switched away.
   ══════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  /* Each banner is the clip its own page opens with, so the rail is a
     window onto the app rather than a set of adverts made for it. */
  /* The six banners, each the clip that section already carries — the one
     at the top of its own page, not something made for here. Naming them
     by where they live is the point: this rail is the app introducing
     itself with its own footage. */
  function openStore(sec) {
    var s = document.getElementById('sub-nowssb-store');
    if (s) s.classList.add('open');
    var iv = document.getElementById('nssIntroVid');
    if (iv) { iv.muted = true; try { iv.play().catch(function () {}); } catch (e) {} }
    if (sec) setTimeout(function () {
      if (typeof window.nssOpenSub === 'function') { try { nssOpenSub(sec); } catch (e) {} }
    }, 300);
  }

  var I = {
    crown:   '<path d="M4 8.4l3.6 3.2L12 5.4l4.4 6.2L20 8.4l-1.6 9.2H5.6z"/><path d="M5.6 19.6h12.8"/>',
    /* Both stores wear a store mark — a bag — rather than a letter or a
       list. The Word Store's carries a sound wave, the Meaning Store's a
       line of text: the same shop, two things sold in it. */
    word:    '<path d="M4.4 7.6h15.2l-1.1 12.2a1.5 1.5 0 0 1-1.5 1.4H7a1.5 1.5 0 0 1-1.5-1.4z"/>' +
             '<path d="M8.7 10V6.6a3.3 3.3 0 0 1 6.6 0V10"/>' +
             '<path d="M8.4 15.6v1.6M10.8 13.8v5.2M13.2 12.8v6.2M15.6 15.2v2.4"/>',
    meaning: '<path d="M4.4 7.6h15.2l-1.1 12.2a1.5 1.5 0 0 1-1.5 1.4H7a1.5 1.5 0 0 1-1.5-1.4z"/>' +
             '<path d="M8.7 10V6.6a3.3 3.3 0 0 1 6.6 0V10"/>' +
             '<path d="M8.6 14.4h6.8M8.6 17.4h4.4"/>',
    book:    '<path d="M4 5.4h6.4a2 2 0 0 1 2 2v11.2a2.4 2.4 0 0 0-2-1H4z"/><path d="M20 5.4h-6.4a2 2 0 0 0-2 2v11.2a2.4 2.4 0 0 1 2-1H20z"/>',
    sound:   '<path d="M11.4 4.6 6.8 8.6H3.6v6.8h3.2l4.6 4V4.6z"/><path d="M15.6 8.8a4.6 4.6 0 0 1 0 6.4M18.4 6a8.6 8.6 0 0 1 0 12"/>',
    sig:     '<path d="M3.6 16.6c3-.4 5-2.2 6.6-5.4 1.2-2.4 2-4.6 3.2-4.6 1 0 1.4 1 1 2.4-.5 1.8-2 3-3.4 3.6-1.4.6-2 1.4-1.6 2.2.4.8 1.8.9 3.2.4 1.6-.6 2.8-1.6 4-3"/><path d="M4 20h16"/>'
  };
  function ico(k) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" ' +
      'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (I[k] || '') + '</svg>';
  }

  /* Every banner carries the heading its own block wears on the page — the
     disc with a mark, a light line and a heavy one. Same shape as the
     Subscription and Choose Your Path blocks, because it IS that shape. */
  /* Six banners, and every one of them is the clip that heads its OWN
     page — not something chosen for here. That is the whole rule, and it
     is why these are the URLs they are:
       Subscription   the gold clip its block carries
       Word Store     the clip a word page opens with (app/js/part012.js)
       Meaning Store  the clip every meaning's page opens with (part026.js)
       Signature      the Signature page's own banner clip
       eBooks         the eBooks banner clip (part067.js)
       Sound Library  the Sound Library's banner clip
     Where another file owns the URL it is READ from that file at build
     time rather than copied, so the two can never drift. */
  function vidOf(owner, fallback) {
    try { var v = window[owner]; if (typeof v === 'string' && v) return v;
          if (v && v.length) return v[0]; } catch (e) {}
    return fallback;
  }
  /* Read the clip off the block ITSELF where the block is on the page.
     Naming a URL twice is how the hero ended up showing one Subscription
     film while the section under it showed another — this cannot: it is
     the same element's src or nothing. Asked for at build time, when the
     home is already parsed. */
  function vidFrom(sel, fallback) {
    try {
      var el = document.querySelector(sel);
      var v = el && (el.matches('video') ? el : el.querySelector('video'));
      var src = v && (v.getAttribute('src') || (v.querySelector('source') || {}).src);
      if (src) return src;
    } catch (e) {}
    return fallback;
  }

  var RAIL = [
    { i: 'crown',   h: 'The Full Library',       t: 'NowssB Subscription',
      s: 'Every word and every frequency',
      sel: '#home .nsub-blk .vbs-screen video',
      v: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/650223ca119ab9368a3fc6e3b4b3e533621fed8dda158319aa9299a8485b2dfc.mp4',
      go: function () { if (window.SS && SS.open) SS.open('subscription'); } },
    { i: 'word',    h: 'Where a word begins',    t: 'NowssB Word Store',
      s: 'Every root, every origin',
      v: vidOf('NWSB_WORD_BANNER_VID',
               'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/928f93861b9beb2672f989f80fc1ee0d5db4572a4cd60ac3dd599976f6899118.mp4'),
      go: function () { openStore(''); } },
    { i: 'meaning', h: 'What a word truly means', t: 'NowssB Meaning Store',
      s: 'Earth, water, god, your name',
      v: vidOf('MS_MEANING_VID',
               'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/4c1c17d70f5656d48438620681f91a5a03c9cbef907f4c865ceb4bc1e2b56ed2.mp4'),
      go: function () { openStore('meaning-store'); } },
    { i: 'sig',     h: 'The rarest word',        t: 'The Signature',
      s: 'One per collection, the most exclusive',
      v: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/video/signature-banner.mp4',
      go: function () { openStore('signature-store'); } },
    { i: 'book',    h: 'Page by page',           t: 'NowssB eBooks',
      s: 'Deep-dive guides, yours to keep',
      /* .fash-ebsec-wrap video matched the FIRST video in the block, which
         is the little clip spinning inside the spill disc — so the eBooks
         banner played the gold rings instead of its own film. The banner is
         the one in .ebsec-vid; name it. */
      sel: '#home .fash-ebsec-wrap .ebsec-vid video',
      v: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/cloudinary/beaf11ea10561d439ff2d8217da6c6e889accdbb3b20bb1e7b4236cbe754305e.mp4',
      go: function () { if (typeof window.ebSecOpen === 'function') ebSecOpen(); } },
    { i: 'sound',   h: 'Every word you own',     t: 'Sound Library',
      s: 'Root frequencies to practice with',
      v: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/video/sound-library-banner.mp4?v=1',
      go: function () { if (typeof openSub === 'function') openSub('sound-library'); } }
  ];

  /* Registered so the idle pre-warmer fetches them. Three of the four are
     only ever in the document one at a time — without this each would
     download the moment it was its turn, which is the one moment it must
     not. */
  window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || [])
    .concat(RAIL.map(function (r) { return r.v; }));

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#x27;');
  }
  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  function hello() {
    var h = new Date().getHours();
    if (h < 5)  return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }
  /* The same name the rest of the app greets you by, asked for in the same
     order — a profile name if there is one, then the login name, then the
     brand, which is what a reader who has not told us anything sees. */
  function who() {
    var n = '';
    try {
      n = (window.nwsbUserName && window.nwsbUserName()) ||
          localStorage.getItem('nwsb_profile_name') ||
          localStorage.getItem('nwsb_user_name') || '';
    } catch (e) {}
    n = (n || '').trim();
    return n || 'NowssB';
  }

  /* The disc's mark reads the clock, the way the Normal home's does: the
     sun climbing, the sun high, the sun setting, the moon. */
  function timeMark() {
    var h = new Date().getHours();
    var sun = '<circle cx="12" cy="12" r="4.4"/>' +
      '<path d="M12 2.6v2.4M12 19v2.4M21.4 12H19M5 12H2.6M18.6 5.4 17 7M7 17l-1.6 1.6M18.6 18.6 17 17M7 7 5.4 5.4"/>';
    var dawn = '<path d="M3.4 18.4h17.2"/><circle cx="12" cy="13.6" r="4"/>' +
      '<path d="M12 4.6v2.2M19.2 7.6l-1.6 1.6M4.8 7.6l1.6 1.6"/>';
    var moon = '<path d="M20.4 14.6A8.6 8.6 0 0 1 9.4 3.6a8.6 8.6 0 1 0 11 11z"/>';
    var d = (h < 5 || h >= 21) ? moon : (h < 9 ? dawn : (h < 17 ? sun : dawn));
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" ' +
      'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + d + '</svg>';
  }

  /* ── The deck ──────────────────────────────────────────────────────
     One place, one thing in it at a time. The hero card is the first cell;
     the five banners follow. Each arrives FROM THE RIGHT and the one it
     replaces leaves to the LEFT, so the deck only ever travels one way and
     comes back round to the hero. It runs itself — no dots, no arrows,
     nothing to press but the banner you are looking at.

     The deck's height follows whatever is in it, animated, because a hero
     card and a tablet are not the same height and a box that jumps is the
     difference between an app and a page. */
  var cur = 0, timer = null, running = false, shownAt = 0;
  /* The rail advances itself — unless something else has taken it over.
     app/js/part084.js swaps the banners for the guide's step cards, and a
     step you are reading must not slide away on a timer. */
  var AUTO = true;
  /* The hero is the app's own header, not a banner passing through, and six
     seconds was not long enough to read it before it left. It also has the
     film in it now, which wants time to be watched rather than glimpsed. */
  var HERO_HOLD = 12000;     /* how long the hero card holds the deck */
  var MIN_DWELL = 2600;      /* nothing leaves before it has been readable */

  function deck()  { return document.getElementById('hsDeck'); }
  function cells() { return document.querySelectorAll('#hsDeck .hs-cell'); }

  function fitHeight() {
    var d = deck();
    if (!d) return;
    var on = d.querySelector('.hs-cell.on');
    if (!on) return;
    var h = on.offsetHeight;
    if (h > 0) d.style.height = h + 'px';
  }

  function stop() {
    running = false;
    if (timer) { clearTimeout(timer); timer = null; }
    cells().forEach(function (c) {
      var v = c.querySelector('video');
      if (v && !v.paused) { try { v.pause(); } catch (e) {} }
    });
  }

  /* A clip is given its source only when it is about to be seen, and the
     NEXT one at the same time so it is ready to move rather than starting
     from nothing. Cell 0 is the hero and has no clip. */
  function arm(i) {
    if (i < 1) return null;
    var c = cells()[i];
    if (!c) return null;
    var v = c.querySelector('.hs-vid');
    if (!v) return null;
    var r = RAIL[i - 1];
    if (!r) return null;                       /* not a banner — a step card */
    if (!v.getAttribute('src')) {
      /* resolved here, not at parse time: a block whose clip is injected
         by another file after this one runs still wins */
      v.setAttribute('src', r.sel ? vidFrom(r.sel, r.v) : r.v);
      v.preload = 'auto';
      /* the clip's own first frame, so a cell that has not decoded yet
         shows its picture rather than a black rectangle */
      if (window.nwsbVideoPoster) try { window.nwsbVideoPoster(v); } catch (e) {}
      try { v.load(); } catch (e) {}
    }
    return v;
  }

  /* ── Swipe ────────────────────────────────────────────────────────
     The deck ran itself and that was the only way through it: to reach the
     fourth banner you waited out the three before it, and a clip you wanted
     to look at left on its own schedule. A drag moves it by hand — left for
     the next, right for the one before — and it wraps at both ends.

     Nothing is drawn to say so. The deck was built with no dots and no
     arrows on purpose and that does not change; the gesture is its own
     affordance, and the auto-advance still runs underneath, restarted from
     each move because show() re-arms the timer every time it is called. */
  function armSwipe(d) {
    if (!d || d._hsSwipe) return;
    d._hsSwipe = 1;
    var x0 = 0, y0 = 0, t0 = 0, tracking = false, swiped = false;

    d.addEventListener('touchstart', function (e) {
      if (!e.touches || e.touches.length !== 1) return;
      x0 = e.touches[0].clientX; y0 = e.touches[0].clientY;
      t0 = Date.now(); tracking = true;
    }, { passive: true });

    d.addEventListener('touchend', function (e) {
      if (!tracking) return;
      tracking = false;
      var t = e.changedTouches && e.changedTouches[0];
      if (!t) return;
      var dx = t.clientX - x0, dy = t.clientY - y0;
      /* A swipe, and not the two things it sits between: a tap on the card
         (too short to count) and the page scrolling under the finger (more
         vertical than horizontal). The time bound rejects a slow drag that
         changed its mind halfway. */
      if (Math.abs(dx) < 45) return;
      if (Math.abs(dx) < Math.abs(dy) * 1.6) return;
      if (Date.now() - t0 > 800) return;
      haptic(14);
      /* Every cell is a button or holds them, and a touchend inside one
         still fires a click. Swallowed for a moment so a swipe that ends
         over Explore does not also open it. */
      swiped = true;
      setTimeout(function () { swiped = false; }, 420);
      show(cur + (dx < 0 ? 1 : -1), dx < 0 ? 'swipe' : 'back');
    }, { passive: true });

    d.addEventListener('click', function (e) {
      if (!swiped) return;
      e.stopPropagation();
      e.preventDefault();
    }, true);
  }

  function show(i, why) {
    var all = cells();
    if (!all.length) return;
    var n = all.length;
    i = ((i % n) + n) % n;
    var from = cur;
    cur = i;
    /* mirrors the deck's direction for a backward move — see .hs-back */
    var d0 = document.getElementById('hsDeck');
    if (d0) d0.classList.toggle('hs-back', why === 'back');
    all.forEach(function (c, j) {
      c.classList.toggle('on', j === i);
      c.classList.toggle('out', why !== 'first' && j === from && j !== i);
      var v = c.querySelector('video');
      if (v && j !== i && !v.paused) { try { v.pause(); } catch (e) {} }
    });
    shownAt = Date.now();
    /* the box takes the new cell's height as the new cell arrives */
    requestAnimationFrame(fitHeight);
    setTimeout(fitHeight, 60);

    var v = arm(i);
    arm(i + 1 >= n ? 0 : i + 1);
    if (!running) return;

    if (timer) clearTimeout(timer);
    if (!AUTO) return;
    if (!v) {                                   /* the hero card */
      timer = setTimeout(function () { if (running) show(cur + 1); }, HERO_HOLD);
      return;
    }
    /* A block whose clip is swapped in by another file after this cell was
       first armed would otherwise keep whatever the markup shipped with.
       Asked again every time the cell comes round: the hero and the block
       under it show the same film, always. */
    var r0 = RAIL[i - 1];
    if (r0 && r0.sel) {
      var live = vidFrom(r0.sel, r0.v);
      if (live && live !== v.getAttribute('src')) {
        v.setAttribute('src', live);
        if (window.nwsbVideoPoster) try { window.nwsbVideoPoster(v); } catch (e) {}
        try { v.load(); } catch (e) {}
      }
    }
    try { v.currentTime = 0; } catch (e) {}
    var p = v.play();
    if (p && p.catch) p.catch(function () {});

    /* `ended` is the handover; this is the net under it — a clip that never
       starts would otherwise stop the deck dead. */
    var wait = 9000;
    if (v.duration && isFinite(v.duration) && v.duration > 0.4) wait = (v.duration * 1000) + 700;
    wait = Math.max(MIN_DWELL, Math.min(wait, 13000));
    timer = setTimeout(function () { if (running) show(cur + 1); }, wait);
  }

  function start() {
    if (running) return;
    running = true;
    show(cur, 'first');
  }

  window._hsGo = function (i) {
    var r = RAIL[i];
    if (!r) return;
    haptic(18);
    try { r.go(); } catch (e) {}
  };

  /* Each banner is a rounded glass wrapper with a tablet in it — the app's
     own landscape render, its padding the bezel and its content box the
     screen. No dots and no arrows: this runs itself. */
  function cellsHtml() {
    return RAIL.map(function (r, i) {
      return '<button class="hs-cell hs-ban" data-i="' + (i + 1) + '" ' +
               'onclick="window._hsGo(' + i + ')" aria-label="' + esc(r.t) + ' — ' + esc(r.s) + '">' +
               '<span class="hs-head">' +
                 '<span class="hs-orb">' + ico(r.i) + '</span>' +
                 '<span class="hs-head-txt">' +
                   '<span class="hs-head-h">' + esc(r.h) + '</span>' +
                   '<span class="hs-head-t">' + esc(r.t) + '</span>' +
                 '</span>' +
               '</span>' +
               '<span class="hs-tab nwsb-inframe dev-tab-l">' +
                 '<video class="hs-vid" muted playsinline preload="none" ' +
                        'data-nwsb-vis="1" aria-hidden="true" tabindex="-1"></video>' +
               '</span>' +
             '</button>';
    }).join('');
  }

  /* ── Putting it in and taking it out ──────────────────────────────
     The hero card is MOVED into the deck rather than copied — it is the
     app's real header, with the search that opens the explore sheet and
     the word that changes on a timer, and a copy of it would be a second
     one of those. Taking the look away moves it back where it was. */
  /* ── The wrapper's own furniture ──────────────────────────────────
     Everything that is not the picture comes OUT of the television and
     onto the glass around it. The set is a screen; a screen with an
     Explore button drawn on it is a screen with a button drawn on it, and
     the two were fighting for the same 230px.

     So the wrapper gets a strip above the set and a strip below it:

       above   the store, on the left, and the search on the right
       below   Explore and App Guide, and the way into the guide

     The elements are MOVED, not copied. The search opens the explore
     sheet and the two buttons are the app's real doors — a second copy of
     any of them is a second thing to keep in step. Each remembers where it
     came from, and tearDown puts it back, because this look is one of
     three and the other two want them on the screen where they were.

     Small vertical rules between the pieces, the same ones the app header
     uses between its own three marks. ── */
  function sep() {
    var s = document.createElement('span');
    s.className = 'hs-sep';
    return s;
  }
  var moved = [];
  function park(el, host) {
    if (!el || !host || el.parentNode === host) return;
    moved.push({ el: el, from: el.parentNode, next: el.nextSibling });
    host.appendChild(el);
  }
  function unpark() {
    moved.forEach(function (m) {
      try { m.from.insertBefore(m.el, m.next); } catch (e) {}
    });
    moved = [];
  }

  function furniture(hero) {
    if (!hero || hero.querySelector(':scope > .hs-top')) return;
    var box = hero.querySelector(':scope > .hero-tvbox');
    if (!box) return;

    var top = document.createElement('div');
    top.className = 'hs-top';
    top.innerHTML =
      '<button class="hs-shop" type="button" aria-label="Today\u2019s words and meanings">' +
        '<span class="hs-disc"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
          'stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
          '<path d="M4.4 7.6h15.2l-1.1 12.2a1.5 1.5 0 0 1-1.5 1.4H7a1.5 1.5 0 0 1-1.5-1.4z"/>' +
          '<path d="M8.7 10V6.6a3.3 3.3 0 0 1 6.6 0V10"/></svg></span>' +
        '<span class="hs-sep hs-sep-sm"></span>' +
        '<span class="hs-shop-txt"><span class="hs-shop-h">Today\u2019s</span>' +
        '<span class="hs-shop-t">Words &amp; meanings</span></span>' +
      '</button>';
    top.appendChild(sep());
    hero.insertBefore(top, box);
    top.querySelector('.hs-shop').addEventListener('click', function (e) {
      e.preventDefault(); e.stopPropagation();
      var sc = document.getElementById('sub-nowssb-store');
      if (sc) sc.classList.add('open');
      var iv = document.getElementById('nssIntroVid');
      if (iv) { iv.muted = true; try { iv.play().catch(function () {}); } catch (e2) {} }
    });
    /* The search says what it is, and the ring around it turns — the one
       control on this card that is a live invitation rather than a label. */
    var pill = document.createElement('span');
    pill.className = 'hs-searchpill';
    var slbl = document.createElement('span');
    slbl.className = 'hs-slbl';
    slbl.textContent = 'Search';
    pill.appendChild(slbl);
    var sw = document.createElement('span');
    sw.className = 'hs-searchwrap';
    sw.innerHTML = '<svg class="hs-trace" viewBox="0 0 44 44" aria-hidden="true">' +
      '<circle cx="22" cy="22" r="20.5"/></svg>';
    pill.appendChild(sw);
    top.appendChild(pill);
    park(hero.querySelector('.hero-search-btn'), sw);

    var foot = document.createElement('div');
    foot.className = 'hs-foot';
    hero.appendChild(foot);
    var btns = hero.querySelector('.hero-btns');
    park(btns, foot);
    /* a rule between the two of them as well — "each thing" means each */
    if (btns && btns.children.length > 1) btns.insertBefore(sep(), btns.children[1]);
    foot.appendChild(sep());
    /* The word beside the disc. It is the only thing on this card that
       says what the disc is for, and a circle with an arrow in it does not
       say it on its own. */
    var learn = document.createElement('span');
    learn.className = 'hs-learn';
    learn.textContent = 'Learn';
    foot.appendChild(learn);
  }

  function build(hero) {
    if (!hero) return;
    var home = hero.parentNode;
    if (!home) return;

    var g = document.getElementById('hsGreet');
    if (!g) {
      g = document.createElement('div');
      g.id = 'hsGreet';
      g.className = 'hs-greet';
      g.innerHTML = '<div class="hs-orb hs-greet-orb"></div>' +
                    '<div class="hs-greet-txt">' +
                      '<div class="hs-hello"></div><div class="hs-name"></div>' +
                      '<div class="hs-line">Ready for today\'s healing practice?</div>' +
                    '</div>';
      home.insertBefore(g, hero);
    }
    g.querySelector('.hs-hello').textContent = hello() + ',';
    g.querySelector('.hs-name').textContent = who();
    var orb = g.querySelector('.hs-greet-orb');
    if (orb) orb.innerHTML = timeMark();

    var d = document.getElementById('hsDeck');
    if (!d) {
      d = document.createElement('div');
      d.id = 'hsDeck';
      d.className = 'hs-deck';
      home.insertBefore(d, hero);
      hero.classList.add('hs-cell', 'hs-hero-cell', 'on');
      hero.setAttribute('data-i', '0');
      d.appendChild(hero);                       /* moved, not copied */
      d.insertAdjacentHTML('beforeend', cellsHtml());
    }
    furniture(hero);
    armSwipe(d);
    cur = 0;
    show(0, 'first');
  }

  function tearDown() {
    stop();
    var g = document.getElementById('hsGreet');
    if (g) g.remove();
    var d = document.getElementById('hsDeck');
    if (!d) return;
    var hero = d.querySelector('.hero-section');
    if (hero) {
      hero.classList.remove('hs-cell', 'hs-hero-cell', 'on', 'out');
      hero.removeAttribute('data-i');
      /* the strips go, and everything they borrowed goes home */
      unpark();
      var t = hero.querySelector(':scope > .hs-top'); if (t) t.remove();
      var f = hero.querySelector(':scope > .hs-foot'); if (f) f.remove();
      d.parentNode.insertBefore(hero, d);        /* put it back */
    }
    d.querySelectorAll('video').forEach(function (v) {
      try { v.pause(); v.removeAttribute('src'); v.load(); } catch (e) {}
    });
    d.remove();
  }

  /* Called by app/js/part082.js every time the hero's look is applied, so
     there is one owner of which look is on and this file only answers. It
     was lost in a rewrite of this section, which is why the deck stopped
     being built at all. */
  /* ── Lending the rail out ─────────────────────────────────────────
     The deck is this file's, and it stays this file's — the cells, the
     slide, the height and the swipe are all here. What another file can do
     is say WHAT is passing through it: app/js/part084.js swaps the six
     banners for the guide's fifteen step cards and swaps them back, and
     never touches how any of it moves.

     Cell 0 is left alone in both directions. It is the hero itself, moved
     into the deck rather than copied, and taking it out would take the
     app's real header out with it. */
  window.nwsbHeroCells = function (html) {
    var d = deck();
    if (!d) return false;
    d.querySelectorAll('.hs-cell:not(.hs-hero-cell)').forEach(function (c) {
      var v = c.querySelector('video');
      if (v) { try { v.pause(); v.removeAttribute('src'); v.load(); } catch (e) {} }
      c.remove();
    });
    d.insertAdjacentHTML('beforeend', html == null ? cellsHtml() : html);
    cur = 0;
    show(0, 'first');
    return true;
  };
  /* Off while something else is reading; on when the rail is its own again.
     Turning it off also cancels the timer already ticking, or the cell that
     was in flight when it was called would still leave. */
  window.nwsbHeroAuto = function (on) {
    AUTO = on !== false;
    if (!AUTO && timer) { clearTimeout(timer); timer = null; }
    else if (AUTO) pump();
  };
  /* Move by hand — the same call the swipe makes, so a button and a finger
     land in exactly the same place. */
  window.nwsbHeroGo = function (step) {
    show(cur + step, step < 0 ? 'back' : 'swipe');
    return cur;
  };
  window.nwsbHeroAt = function () { return cur; };
  window.nwsbHeroCount = function () { return cells().length; };

  window.nwsbPlainHero = function (on) {
    var hero = document.querySelector('#home .hero-section');
    if (!hero) return;
    if (!on) { tearDown(); return; }
    build(hero);
    pump();
  };

  window.addEventListener('resize', fitHeight);

  /* ── When it is allowed to run ────────────────────────────────────── */
  function visible() {
    if (document.hidden) return false;
    var hero = document.querySelector('#home .hero-section.hero-simple');
    if (!hero) return false;
    var home = document.getElementById('home');
    if (!home || !home.classList.contains('active')) return false;
    /* a sub-screen over the top means nobody is looking at this */
    if (document.querySelector('.sub-screen.open')) return false;
    var r = hero.getBoundingClientRect();
    return r.bottom > 0 && r.top < (window.innerHeight || 800);
  }
  var pending = false;
  function pump() {
    if (pending) return;
    pending = true;
    requestAnimationFrame(function () {
      pending = false;
      if (!document.getElementById('hsDeck')) return;
      if (visible()) start(); else stop();
    });
  }
  window._hsPump = pump;

  document.addEventListener('visibilitychange', pump);
  window.addEventListener('scroll', pump, { passive: true });
  document.addEventListener('scroll', pump, { passive: true, capture: true });
  /* A heartbeat as well as the events, because the things that decide
     whether this should be running — the home becoming the active screen,
     a page closing over it — do not all announce themselves. It reads a
     class and a rectangle; it is cheaper than being wrong. */
  setInterval(function () { if (document.getElementById('hsDeck')) { pump(); fitHeight(); } }, 1200);

  /* The clip that ends is the one that hands over. Delegated, because the
     rail is built and thrown away as the look is switched. */
  document.addEventListener('ended', function (e) {
    var sl = e.target && e.target.closest ? e.target.closest('.hs-cell') : null;
    if (!sl || !running) return;
    if (!sl.classList.contains('on')) return;
    var left = MIN_DWELL - (Date.now() - shownAt);
    if (left > 0) {
      if (timer) clearTimeout(timer);
      timer = setTimeout(function () { if (running) show(cur + 1); }, left);
      return;
    }
    show(cur + 1);
  }, true);

  /* ── First run ────────────────────────────────────────────────────
     part082.js applies the look the moment it parses, and this file is
     loaded after it — so at that moment nwsbPlainHero did not exist yet
     and the call was skipped. It applies itself once here, retrying while
     the home is still being parsed, and from then on part082 drives it. */
  (function boot(n) {
    var hero = document.querySelector('#home .hero-section');
    if (hero && typeof window.heroStyle === 'function') {
      try { window.nwsbPlainHero(window.heroStyle() === 'plain'); } catch (e) {}
      return;
    }
    if (n > 60) return;
    setTimeout(function () { boot(n + 1); }, 150);
  })(0);

  /* The greeting reads the clock, so it is re-read when the app comes back
     — someone who left it open overnight should not still be told good
     evening in the morning. */
  setInterval(function () {
    var g = document.getElementById('hsGreet');
    if (!g) return;
    g.querySelector('.hs-hello').textContent = hello() + ',';
    g.querySelector('.hs-name').textContent = who();
  }, 120000);
})();
