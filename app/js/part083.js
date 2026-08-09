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
    word:    '<path d="M4 19.4 11 5h2l7 14.4"/><path d="M7.1 14.6h9.8"/>',
    meaning: '<path d="M4.6 6.4h14.8M4.6 12h14.8M4.6 17.6h9"/>',
    book:    '<path d="M4 5.4h6.4a2 2 0 0 1 2 2v11.2a2.4 2.4 0 0 0-2-1H4z"/><path d="M20 5.4h-6.4a2 2 0 0 0-2 2v11.2a2.4 2.4 0 0 1 2-1H20z"/>',
    sound:   '<path d="M11.4 4.6 6.8 8.6H3.6v6.8h3.2l4.6 4V4.6z"/><path d="M15.6 8.8a4.6 4.6 0 0 1 0 6.4M18.4 6a8.6 8.6 0 0 1 0 12"/>'
  };
  function ico(k) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" ' +
      'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (I[k] || '') + '</svg>';
  }

  /* Every banner carries the heading its own block wears on the page — the
     disc with a mark, a light line and a heavy one. Same shape as the
     Subscription and Choose Your Path blocks, because it IS that shape. */
  var RAIL = [
    { i: 'crown',   h: 'The Full Library',        t: 'NowssB Subscription',
      s: 'Every word and every frequency',
      v: 'https://res.cloudinary.com/eenvubod/video/upload/v1784895544/grok_video_2026-07-24-17-46-41_vkxr4r.mp4',
      go: function () { if (window.SS && SS.open) SS.open('subscription'); } },
    { i: 'word',    h: 'Where a word begins',     t: 'NowssB Word Store',
      s: 'Every root, every origin',
      v: 'https://res.cloudinary.com/ds6duqabl/video/upload/v1779957220/grok_video_2026-05-28-14-02-13_zaoxnl.mp4',
      go: function () { openStore(''); } },
    { i: 'meaning', h: 'What a word truly means',  t: 'NowssB Meaning Store',
      s: 'Earth, water, god, your name',
      v: 'https://res.cloudinary.com/ds6duqabl/video/upload/v1780042918/grok_video_2026-05-29-04-36-47_cze9bz.mp4',
      go: function () { openStore('meaning-store'); } },
    { i: 'book',    h: 'Page by page',             t: 'NowssB eBooks',
      s: 'Deep-dive guides, yours to keep',
      v: 'https://res.cloudinary.com/eenvubod/video/upload/v1785406073/grok_video_2026-07-30-15-35-40_xwm1ei.mp4',
      go: function () { if (typeof window.ebSecOpen === 'function') ebSecOpen(); } },
    { i: 'sound',   h: 'Every word you own',       t: 'Sound Library',
      s: 'Root frequencies to practice with',
      v: './assets/video/sound-library-banner.mp4?v=1',
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
  var HERO_HOLD = 6000;      /* how long the hero card holds the deck */
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
    var v = c.querySelector('video');
    if (!v) return null;
    if (!v.getAttribute('src')) {
      v.setAttribute('src', RAIL[i - 1].v);
      v.preload = 'auto';
      try { v.load(); } catch (e) {}
    }
    return v;
  }

  function show(i, why) {
    var all = cells();
    if (!all.length) return;
    var n = all.length;
    i = ((i % n) + n) % n;
    var from = cur;
    cur = i;
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
    if (!v) {                                   /* the hero card */
      timer = setTimeout(function () { if (running) show(cur + 1); }, HERO_HOLD);
      return;
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
