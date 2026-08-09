/* ══════════════════════════════════════════════════════════════════════
   SETTINGS → WIDGETS
   The home is built out of sections — Choose Your Path, Subscription,
   Quick Access, Connect — and every one of them is really a widget: a
   thing that can be there or not. This page says so out loud.

   It shows the FASHION home. It used to follow whichever home was in use,
   which meant opening it from the Normal home quietly edited the Normal
   home's layout; these sections are the Fashion home's and the page stays
   on it.

   Nothing here keeps its own list or its own storage. The layout registry
   (app/js/part062.js) already decides what a home is made of, remembers
   what is switched off, and says what SHAPE each unit is — and the
   arrange-editor reads the same thing. A second copy would drift the first
   time a section was added.

   The rows, and why they are not one row:
     1. Hero header — the three ways the top of the home can look.
     2. Home sections — on the television. One set, standing still, with
        the sections swinging through it.
     3. Video banners — the same, on the tablet. A bare clip is a
        different decision from a section you use.
     4. Clips and their banners — a plain row, no device. These blocks
        arrive with a frame of their own; lending them another would be a
        device inside a device.
     5. Buttons and tabs — the two rows of buttons. Not sections at all,
        so not among them.
     6. Jump to — the places the app can take you, one tap each.
     7. Make it yours — the editors and switches that change how the app
        looks, gathered instead of scattered.
   ══════════════════════════════════════════════════════════════════════ */
(function () {

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#x27;');
  }
  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  var I = {
    /* One drawn set. The app's icons used to be photographs fetched from a
       CDN; these cost nothing and take the colour they are given. */
    practice: '<path d="M12 3.5a3 3 0 0 1 3 3v5a3 3 0 1 1-6 0v-5a3 3 0 0 1 3-3z"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21M8.5 21h7"/>',
    library:  '<path d="M4 5.5h6.5a2 2 0 0 1 2 2V20a2.4 2.4 0 0 0-2-1H4z"/><path d="M20 5.5h-6.5a2 2 0 0 0-2 2V20a2.4 2.4 0 0 1 2-1H20z"/>',
    search:   '<circle cx="10.6" cy="10.6" r="6.3"/><path d="M15.3 15.3L20 20"/>',
    meaning:  '<path d="M4.5 6.5h15M4.5 12h15M4.5 17.5h9"/>',
    store:    '<path d="M4.6 7.6h14.8l-1.1 12a1.6 1.6 0 0 1-1.6 1.4H7.3a1.6 1.6 0 0 1-1.6-1.4z"/><path d="M8.9 10V6.4a3.1 3.1 0 0 1 6.2 0V10"/>',
    cart:     '<path d="M3 4h2.1l2 10.2a1.4 1.4 0 0 0 1.4 1.1h7.8a1.4 1.4 0 0 0 1.4-1.1L19 7.6H6"/><circle cx="9" cy="19.4" r="1.4"/><circle cx="17" cy="19.4" r="1.4"/>',
    heart:    '<path d="M12 20 4.8 13a4.5 4.5 0 0 1 6.4-6.3l.8.8.8-.8A4.5 4.5 0 0 1 19.2 13z"/>',
    streak:   '<path d="M12 3.2s5.4 4.2 5.4 9a5.4 5.4 0 1 1-10.8 0c0-1.9.9-3.6 1.9-5 .3 1.4 1.1 2.3 2 2.3 1.6 0 1.5-3.4 1.5-6.3z"/>',
    routine:  '<circle cx="12" cy="12" r="8.4"/><path d="M12 7.2V12l3.2 1.9"/>',
    connect:  '<circle cx="8" cy="9" r="2.6"/><circle cx="16" cy="9" r="2.6"/><path d="M3.4 19v-1a4.2 4.2 0 0 1 8.4 0v1M12.2 19v-1a4.2 4.2 0 0 1 8.4 0v1"/>',
    progress: '<path d="M4 19V9M10 19V5M16 19v-6M22 19H2"/>',
    notes:    '<path d="M6 3.6h8.4L19 8.2V20.4H6z"/><path d="M14.2 3.6v4.6H19"/><path d="M9 12.4h6M9 15.8h4"/>',
    layout:   '<rect x="3.4" y="3.4" width="17.2" height="5.4" rx="1.8"/><rect x="3.4" y="11.6" width="17.2" height="9" rx="1.8"/>',
    tiles:    '<rect x="3.4" y="3.4" width="7.2" height="7.2" rx="2"/><rect x="13.4" y="3.4" width="7.2" height="7.2" rx="2"/><rect x="3.4" y="13.4" width="7.2" height="7.2" rx="2"/><rect x="13.4" y="13.4" width="7.2" height="7.2" rx="2"/>',
    brush:    '<path d="M4 20s1.6-.4 2.6-1.4C8.2 17 8 15 8 15l-3 3s-.6 1.4-1 2z"/><path d="M8.4 14.6 17.8 5.2a2 2 0 0 1 2.8 2.8L11.2 17.4"/>',
    sparkle:  '<path d="M12 3.4l1.8 4.8 4.8 1.8-4.8 1.8L12 16.6l-1.8-4.8L5.4 10l4.8-1.8z"/><path d="M18.4 15.6l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8z"/>',
    film:     '<rect x="3.2" y="5.2" width="17.6" height="13.6" rx="2.2"/><path d="M3.2 9.4h17.6M8.2 5.2 9.6 9.4M14.4 5.2 15.8 9.4"/>',
    bell:     '<path d="M12 3.4a5.6 5.6 0 0 0-5.6 5.6c0 5-2 6.4-2 6.4h15.2s-2-1.4-2-6.4A5.6 5.6 0 0 0 12 3.4z"/><path d="M10.2 19a2 2 0 0 0 3.6 0"/>',
    person:   '<circle cx="12" cy="8" r="3.6"/><path d="M4.8 20v-1.2a7.2 7.2 0 0 1 14.4 0V20"/>'
  };
  function ico(k) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" ' +
      'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + (I[k] || '') + '</svg>';
  }

  /* ── Rail 2 · where the app can take you ──────────────────────────
     Every one of these is a screen that already exists; the card is a
     shortcut to it, not a new feature pretending to be one. */
  var JUMP = [
    { i: 'practice', t: 'Practice',      s: "Today's word ritual", go: "openPracticeIntro" },
    { i: 'library',  t: 'Sound Library', s: 'Every word you own',  sub: 'sound-library' },
    { i: 'search',   t: 'Word Search',   s: 'Where a word begins', sub: 'word-search' },
    { i: 'meaning',  t: 'Meaning',       s: 'What it truly means',  sub: 'meaning-search' },
    { i: 'streak',   t: 'Streak',        s: 'Keep the run alive',   sub: 'streak' },
    { i: 'routine',  t: 'Routines',      s: 'Your daily practice',  sub: 'routines' },
    { i: 'progress', t: 'Progress',      s: 'How far you have come', sub: 'my-progress' },
    { i: 'store',    t: 'Store',         s: 'Words and frequencies', sub: 'nowssb-store' },
    { i: 'cart',     t: 'Cart',          s: 'Ready to buy',          sub: 'cart' },
    { i: 'heart',    t: 'Wishlist',      s: 'Saved for later',       sub: 'wishlist' },
    { i: 'connect',  t: 'Connect',       s: 'The social space',      sub: 'connect-hub' },
    { i: 'bell',     t: 'Notifications', s: 'What you have missed',  sub: 'notifications' }
  ];

  /* ── Rail 3 · the things that change how it looks ─────────────────
     They were scattered: one behind the home's Customize card, one on a
     tile rail, one in the Fashion Plus section. Same functions, one
     place to find them. */
  var MAKE = [
    { i: 'layout', t: 'Arrange home',  s: 'Order and hide sections', fn: function () { if (window.hlOpen) hlOpen(); } },
    { i: 'tiles',  t: 'Home buttons',  s: 'Restyle the four tiles',  fn: function () { if (window.htOpen) htOpen(); } },
    { i: 'brush',  t: 'Customize',     s: 'Themes, navs and cards',  fn: function () { if (window.cuOpen) cuOpen(); } },
    { i: 'sparkle',t: 'Fashion Plus',  s: 'The motion mode',         sub: 'fashion-plus' },
    { i: 'film',   t: 'All features',  s: 'Everything in the app',   sub: 'features' },
    { i: 'person', t: 'Profile',       s: 'Your account',            nav: 'profile' }
  ];

  function jumpTo(c) {
    haptic(18);
    window.stClose();
    setTimeout(function () {
      try {
        if (c.go && typeof window[c.go] === 'function') window[c.go]();
        else if (c.sub && typeof openSub === 'function') openSub(c.sub);
        else if (c.nav && window.IG) IG.nav(c.nav);
        else if (c.fn) c.fn();
      } catch (e) {}
    }, 240);
  }
  window._stJump = function (kind, i) {
    var c = (kind === 'jump' ? JUMP : MAKE)[i];
    if (c) jumpTo(c);
  };

  /* ── The hero header has three looks ──────────────────────────────
     'tv'     — inside the television, which is what it ships as;
     'full'   — the way it was before the set: the five photographs
                crossfading behind it, edge to edge, a screenful tall;
     'plain'  — an ordinary app header. No photographs, no picture rail,
                no set: the wordmark, the word and the buttons on a card
                that is as tall as what is in it.
     All three are the same markup — each look is one class — so switching
     is a class and a remembered string, and nothing is rebuilt.
     'plain' used to be the name of the full-screen look, so a value saved
     under the old meaning is read forward as 'full'. ── */
  var HKEY = 'nwsb_hero_style';
  var HVER = 'nwsb_hero_style_v';
  (function migrate() {
    try {
      if (localStorage.getItem(HVER)) return;
      if (localStorage.getItem(HKEY) === 'plain') localStorage.setItem(HKEY, 'full');
      localStorage.setItem(HVER, '2');
    } catch (e) {}
  })();
  window.heroStyle = function () {
    var v = localStorage.getItem(HKEY);
    return (v === 'full' || v === 'plain') ? v : 'tv';   /* the set is the default */
  };
  function applyHero() {
    var h = document.querySelector('#home .hero-section');
    if (!h) return false;
    var v = window.heroStyle();
    h.classList.toggle('hero-tv', v === 'tv');
    h.classList.toggle('hero-simple', v === 'plain');
    return true;
  }
  window.setHeroStyle = function (v) {
    try { localStorage.setItem(HKEY, (v === 'full' || v === 'plain') ? v : 'tv'); } catch (e) {}
    applyHero();
    haptic(26);
    paintHero();
  };
  /* The hero is static markup, so this only has to happen once — but the
     screen it lives on may not be parsed yet when this file runs. */
  (function waitForHero(n) {
    if (applyHero() || n > 40) return;
    setTimeout(function () { waitForHero(n + 1); }, 150);
  })(0);

  var HEROES = [
    { v: 'tv',    t: 'On the television', s: 'The set, on the page' },
    { v: 'full',  t: 'Full screen',       s: 'The photographs, edge to edge' },
    { v: 'plain', t: 'Plain header',      s: 'No pictures, no set' }
  ];
  function heroHtml() {
    var cur = window.heroStyle();
    return HEROES.map(function (h) {
      return '<div class="stw-wcard stw-hero' + (cur === h.v ? ' on' : '') + '">' +
          '<div class="stw-wrap"><div class="stw-prev stw-prev-tall">' +
            '<div class="stw-screen" data-fixed="1"><div class="stw-prev-stage" data-hero="' + h.v + '"></div></div>' +
          '</div></div>' +
          '<div class="stw-wfoot">' +
            '<div class="stw-wtxt"><div class="stw-t">' + h.t + '</div>' +
            '<div class="stw-s">' + h.s + '</div></div>' +
            (cur === h.v
              ? '<span class="stw-pill fixed on">In use</span>'
              : '<button class="stw-use" onclick="window.setHeroStyle(\'' + h.v + '\')">Apply now</button>') +
          '</div>' +
        '</div>';
    }).join('');
  }
  function paintHero() {
    var el = document.getElementById('stwHero');
    if (!el) return;
    el.innerHTML = heroHtml();
    el.querySelectorAll('.stw-prev-stage').forEach(fillPreview);
  }

  /* ── Rail 1 · the home's own sections ─────────────────────────────
     Each card is the SECTION ITSELF, cloned out of the home and scaled
     down — its clip, its artwork, its heading, whatever it is made of.
     A name and a one-line description could never tell you what "Connect
     Banner" or "Trending Shop" looks like, and choosing what your home is
     made of is a visual decision.

     Three things make cloning safe:
       · ids are stripped from the clone, or the copy would answer to
         getElementById ahead of the real section and every script that
         looks one up would find the preview instead;
       · the clone is inert — pointer-events off, so nothing inside it can
         be pressed by accident;
       · it is built only when the card comes into view. Twenty-six live
         copies, several carrying video, is not something to construct at
         once for a rail most of which is off-screen.
     ── */
  var PREV_W = 358;          /* the width a section is laid out at */
  var io = null;

  /* ── This page is the Fashion home's ──────────────────────────────
     It used to follow whichever home was in use, so opening it from the
     Normal home showed the Normal home's sections and edited the Normal
     home's layout. The Fashion home is the one these sections belong to;
     the page names one home and stays on it, whichever home you came
     from, and the registry is asked for that one by name. ── */
  var HOME = 'fash';

  function stripIds(node) {
    if (node.removeAttribute) node.removeAttribute('id');
    var kids = node.querySelectorAll ? node.querySelectorAll('[id]') : [];
    for (var i = 0; i < kids.length; i++) kids[i].removeAttribute('id');
  }

  /* ── fit the whole section in the window ──────────────────────────
     The scale used to be the card's width over the layout width, full
     stop, and whatever fell past the bottom of the window was simply
     cut off — most sections are taller than they are wide, so most cards
     showed a section's top third and nothing else. The scale is the
     smaller of the two fits now, so height decides it whenever height is
     the tighter one, and the section is centred in what is left over.
     Clips and artwork settle after the clone is built, so this is asked
     again whenever the stage changes size. ── */
  var MIN_H = 170, MAX_H = 500;   /* how tall a screen is allowed to get */
  function fit(stage) {
    var box = stage.parentNode;
    if (!box) return;
    /* the rect, not clientWidth — clientWidth is rounded to a whole pixel
       and rounding UP makes the scaled stage a fraction wider than the
       screen it is meant to sit inside. The padding comes off it: a slide
       is inset from the bezel on all four sides, and the clone is fitted
       to what is left rather than to the whole box. The stage is absolutely
       positioned, so its 0,0 is the PADDING edge — the inset has to be
       added back into the translate or the whole thing sits high and left. */
    var cs = getComputedStyle(box);
    var padL = parseFloat(cs.paddingLeft) || 0, padR = parseFloat(cs.paddingRight)  || 0,
        padT = parseFloat(cs.paddingTop)  || 0, padB = parseFloat(cs.paddingBottom) || 0;
    var br = box.getBoundingClientRect();
    var bw = br.width - padL - padR;
    var ch = stage.scrollHeight || stage.offsetHeight || 1;
    if (bw <= 0) return;
    /* a clone with nothing in it — a section the home has not built yet —
       says so rather than showing an empty set */
    stage.classList.toggle('empty', ch < 12);
    var s, bh;
    if (box.getAttribute('data-fixed') === '1') {
      /* the hero cards keep one window height — three looks of the same
         thing are only comparable at the same size */
      bh = br.height - padT - padB;
      if (bh <= 0) return;
      s = Math.min(bw / PREV_W, bh / ch);
    } else {
      /* the set is stretchable, so the screen is exactly as tall as the
         section on it: scaled to the width unless that would make it
         taller than a card should be, and never taller than the content */
      s = Math.min(bw / PREV_W, MAX_H / ch);
      bh = Math.max(MIN_H, Math.min(MAX_H, ch * s));
      box.style.height = (bh + padT + padB).toFixed(2) + 'px';
    }
    stage.style.transform =
      'translate(' + (padL + (bw - PREV_W * s) / 2).toFixed(2) + 'px,' +
                     (padT + (bh - ch * s) / 2).toFixed(2) + 'px) scale(' + s.toFixed(4) + ')';
  }
  function watch(stage) {
    fit(stage);
    requestAnimationFrame(function () { fit(stage); });
    setTimeout(function () { fit(stage); }, 500);
    if (!('ResizeObserver' in window)) return;
    /* the observer reads the stage while the transform it sets changes
       the stage's rendered box — measure off scrollHeight, which is the
       untransformed content, and guard against the loop anyway */
    var busy = false;
    var ro = new ResizeObserver(function () {
      if (busy) return;
      busy = true;
      requestAnimationFrame(function () { fit(stage); busy = false; });
    });
    ro.observe(stage);
  }

  function fillPreview(stage) {
    if (stage._filled) return;
    stage._filled = true;
    var nodes;
    var heroMode = stage.getAttribute('data-hero');
    if (heroMode) {
      var h = document.querySelector('#home .hero-section');
      nodes = h ? [h] : [];
    } else {
      var k = stage.getAttribute('data-k');
      nodes = (typeof window.hlNodes === 'function') ? window.hlNodes(HOME, k) : [];
    }
    if (!nodes.length) { stage.classList.add('empty'); return; }
    nodes.forEach(function (n) {
      var c = n.cloneNode(true);
      stripIds(c);
      c.classList.remove('hl-off');          /* a hidden section still previews */
      c.style.display = '';
      /* the hero previews are one clone shown three ways, so BOTH look
         classes are set on the copy rather than read off the original —
         the original is only ever wearing one of them */
      if (heroMode) {
        c.classList.toggle('hero-tv', heroMode === 'tv');
        c.classList.toggle('hero-simple', heroMode === 'plain');
      }
      stage.appendChild(c);
    });
    /* Clips in a preview are decoration. They are built STOPPED — twenty-six
       clones each starting a decoder is what made this page hang — and
       pump() below starts only the ones you are actually looking at. */
    stage.querySelectorAll('video').forEach(function (v) {
      v.muted = true; v.setAttribute('muted', ''); v.playsInline = true;
      v.loop = true; v.removeAttribute('controls');
      v.removeAttribute('autoplay'); v.autoplay = false;
      v.preload = 'none';
      try { v.pause(); } catch (e) {}
    });
    /* size it to the window once we know how tall the real thing is */
    watch(stage);
  }

  /* ── Which clips are allowed to run ───────────────────────────────
     A decoding video is the most expensive thing on a page, and this one
     can hold thirty of them. The rule is simple and absolute: in a deck,
     only the clip on the screen you are looking at; in a plain row, only
     the cards actually in the viewport. Everything else is paused — and a
     paused clip costs nothing but the frame it is showing.

     Called after every deck move and, rate-limited to one frame, on every
     scroll. Nothing else starts a clip. */
  /* Idempotent on purpose. A clip that cannot start — no codec, no data
     yet — stays paused however often it is asked, so testing `paused` to
     decide would call play() again on every pass forever. The intent is
     recorded on the element and only a CHANGE of intent does anything. */
  function setPlay(v, on) {
    if (v._stOn === on) return;
    v._stOn = on;
    if (on) {
      if (v.preload === 'none') v.preload = 'auto';
      try { var p = v.play(); if (p && p.catch) p.catch(function () {}); } catch (e) {}
    } else {
      try { v.pause(); } catch (e) {}
    }
  }

  var pumping = false;
  function pump() {
    if (pumping) return;
    pumping = true;
    requestAnimationFrame(function () {
      pumping = false;
      var open = document.getElementById('sub-settings');
      var live = !!(open && open.classList.contains('open'));
      /* `_vis` is written by the observer below — reading a flag costs
         nothing, while asking each card for its rectangle would force a
         layout of the whole page on every pass. */
      document.querySelectorAll('#stBody .stw-slide, #stBody .stw-wcard').forEach(function (el) {
        var on = live && el._vis !== false && el._vis !== undefined;
        if (on && el.classList.contains('stw-slide')) on = el.classList.contains('on');
        el.querySelectorAll('video').forEach(function (v) { setPlay(v, on); });
      });
    });
  }
  window._stPump = pump;

  /* ── Who is on screen ─────────────────────────────────────────────
     One observer for the whole page rather than a scroll handler: a
     listener that measured every card each frame was asking the browser
     to lay the page out sixty times a second to answer a question it can
     report for free. It also re-measures a deck the first time it is
     scrolled to — the rails are `content-visibility: auto`, so a rail
     below the fold has no geometry to measure until then. */
  var vio = null;
  function visObserve() {
    if (vio) vio.disconnect();
    if (!('IntersectionObserver' in window)) {
      document.querySelectorAll('#stBody .stw-slide, #stBody .stw-wcard')
        .forEach(function (el) { el._vis = true; });
      pump();
      return;
    }
    vio = new IntersectionObserver(function (ents) {
      var decks = {};
      ents.forEach(function (e) {
        e.target._vis = e.isIntersecting;
        if (!e.isIntersecting) return;
        var d = e.target.closest ? e.target.closest('.stw-deck') : null;
        if (d && !d._laid) { d._laid = 1; decks[d.id] = 1; }
      });
      Object.keys(decks).forEach(layoutDeck);
      pump();
    }, { root: document.getElementById('stBody'), rootMargin: '80px' });
    document.querySelectorAll('#stBody .stw-slide, #stBody .stw-wcard')
      .forEach(function (el) { vio.observe(el); });
  }

  /* ── Building a clone, between frames ─────────────────────────────
     Cloning a whole section is the single most expensive thing this page
     does, and doing it inside the observer's callback meant it happened
     mid-scroll: the frame that brought a card into view was the frame that
     built it, and it showed. The work is queued instead and drained when
     the browser has time going spare, two at a time, so a scroll never
     waits for one. The one you are looking at — the middle of a deck — is
     still built at once, because that one you would notice missing. */
  var queue = [], draining = false;
  var idle = window.requestIdleCallback || function (cb) {
    return setTimeout(function () { cb({ timeRemaining: function () { return 8; } }); }, 30);
  };
  function fillLater(stage) {
    if (!stage || stage._filled || stage._queued) return;
    stage._queued = true;
    queue.push(stage);
    drain();
  }
  function drain() {
    if (draining || !queue.length) return;
    draining = true;
    idle(function (dl) {
      draining = false;
      var n = 0;
      while (queue.length && n < 2) {
        var st = queue.shift();
        st._queued = false;
        fillPreview(st); fit(st);
        n++;
        if (dl && dl.timeRemaining && dl.timeRemaining() < 5) break;
      }
      pump();
      if (queue.length) drain();
    }, { timeout: 900 });
  }

  function observe() {
    if (io) io.disconnect();
    var fillIn = function (win) {
      fillLater(win.querySelector('.stw-prev-stage'));
    };
    if (!('IntersectionObserver' in window)) {
      document.querySelectorAll('.stw-prev').forEach(fillIn);
      return;
    }
    /* Observe the WINDOW, not the stage. An unfilled stage is absolutely
       positioned with nothing in it — zero height — and a target with no
       area never reports as intersecting, so nothing would ever be built.
       .stw-prev has a real box from the moment it exists.

       The root is the viewport, not one rail — there is more than one rail
       of section cards now, and a root that is one of them reports every
       card in the other as permanently outside itself. */
    io = new IntersectionObserver(function (ents) {
      ents.forEach(function (e) {
        if (e.isIntersecting) { fillIn(e.target); io.unobserve(e.target); }
      });
    }, { rootMargin: '250px' });
    document.querySelectorAll('.stw-prev').forEach(function (w) { io.observe(w); });
  }

  /* The registry says what shape each unit is, so these four groups cannot
     drift from what the home is actually made of. */
  function listOf(kind) {
    var list = (typeof window.hlList === 'function') ? window.hlList(HOME) : [];
    return list.filter(function (it) { return it.kind === kind; });
  }

  /* ══ THE DECK ═══════════════════════════════════════════════════════
     One device, standing still in the middle, and the sections passing
     through it — the shape the footer carousel already uses on this app.
     Giving every card its own television was the wrong reading twice
     over: a set around a block that already has a tablet inside it is a
     device in a device, and twenty-six sets is twenty-six bezels to look
     past. There is one set. The section you are on is inside it; the ones
     either side stand back at an angle and are half behind its edge.

     Two decks: the sections are on the television, the bare clips are on
     the tablet. Blocks that arrive with a frame of their own get neither
     — they are a plain row, because they already have the thing a deck
     would be lending them.

     The device element carries the bezel as PADDING, so its content box
     IS the aperture: one measurement puts every slide exactly on the
     screen, and the numbers cannot drift from the artwork.
     ══════════════════════════════════════════════════════════════════ */
  var DECKS = {};   /* emptied when the page closes */

  function chev(dir) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
      'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M' +
      (dir === 'l' ? '15 5 8 12l7 7' : '9 5 16 12l-7 7') + '"/></svg>';
  }

  function deckHtml(id, kind, dev) {
    var list = listOf(kind);
    if (!list.length) return '<div class="stw-empty">Open the Fashion home first — these load with it.</div>';
    DECKS[id] = { kind: kind, i: 0 };
    var slides = list.map(function (it, i) {
      /* data-fixed: the slide IS the aperture, a box this file sets the size
         of. Without it fit() would resize its own container to the clone —
         which is right for a card that grows to what is in it, and wrong
         for a screen that has to stay the size of the screen. */
      return '<div class="stw-slide" data-fixed="1" data-i="' + i + '" onclick="window._stGo(\'' + id + '\',' + i + ')">' +
               '<div class="stw-prev-stage" data-k="' + esc(it.k) + '"></div>' +
             '</div>';
    }).join('');
    return '<div class="stw-deck stw-deck-' + dev + '" id="' + id + '">' +
        '<div class="stw-dstage">' + slides +
          '<div class="stw-dev stw-dev-' + dev + '" aria-hidden="true"></div>' +
        '</div>' +
        '<div class="stw-dbar">' +
          '<button class="stw-dnav" onclick="window._stStep(\'' + id + '\',-1)" aria-label="Previous">' + chev('l') + '</button>' +
          '<div class="stw-dtxt"><div class="stw-t"></div><div class="stw-s"></div></div>' +
          '<span class="stw-dsw"></span>' +
          '<button class="stw-dnav" onclick="window._stStep(\'' + id + '\',1)" aria-label="Next">' + chev('r') + '</button>' +
        '</div>' +
        '<div class="stw-dots"></div>' +
      '</div>';
  }

  function layoutDeck(id) {
    var deck = document.getElementById(id), d = DECKS[id];
    if (!deck || !d) return;
    var stage = deck.querySelector('.stw-dstage'), dev = deck.querySelector('.stw-dev');
    if (!stage || !dev) return;
    var sr = stage.getBoundingClientRect(), dr = dev.getBoundingClientRect();
    if (!dr.width || !dr.height) return;
    var cs = getComputedStyle(dev);
    var pl = parseFloat(cs.paddingLeft)  || 0, pr = parseFloat(cs.paddingRight)  || 0,
        pt = parseFloat(cs.paddingTop)   || 0, pb = parseFloat(cs.paddingBottom) || 0;
    /* the device's content box, in the stage's own coordinates */
    var apL = dr.left - sr.left + pl, apT = dr.top - sr.top + pt;
    var apW = dr.width - pl - pr,     apH = dr.height - pt - pb;
    var list = listOf(d.kind);
    if (d.i >= list.length) d.i = list.length - 1;
    if (d.i < 0) d.i = 0;
    deck.querySelectorAll('.stw-slide').forEach(function (sl) {
      var i = +sl.getAttribute('data-i'), k = i - d.i, a = Math.abs(k);
      sl.style.left = apL.toFixed(2) + 'px'; sl.style.top = apT.toFixed(2) + 'px';
      sl.style.width = apW.toFixed(2) + 'px'; sl.style.height = apH.toFixed(2) + 'px';
      if (a > 2) { sl.style.display = 'none'; return; }
      sl.style.display = '';
      var tx = 0, ry = 0, sc = 1, op = 1, z = 4;
      if (a === 1)      { tx = k * apW * 0.70; ry = -k * 38; sc = 0.84; op = 0.92; z = 3; }
      else if (a === 2) { tx = k * apW * 1.14; ry = -k * 46; sc = 0.68; op = 0.42; z = 2; }
      sl.style.transform = 'translateX(' + tx.toFixed(1) + 'px) rotateY(' + ry + 'deg) scale(' + sc + ')';
      sl.style.opacity = op; sl.style.zIndex = z;
      sl.classList.toggle('on', a === 0);
      sl.classList.toggle('off', !!(list[i] && !list[i].on));
    });
    /* build only what can be seen — the centre and the two either side.
       The centre at once, its neighbours when there is time. */
    for (var j = d.i - 2; j <= d.i + 2; j++) {
      if (j < 0 || j >= list.length) continue;
      var st = deck.querySelector('.stw-slide[data-i="' + j + '"] .stw-prev-stage');
      if (!st) continue;
      if (j === d.i) { fillPreview(st); fit(st); }
      else fillLater(st);
    }
    paintDeckBar(id);
    pump();
  }

  function paintDeckBar(id) {
    var deck = document.getElementById(id), d = DECKS[id];
    if (!deck || !d) return;
    var list = listOf(d.kind), it = list[d.i];
    if (!it) return;
    deck.querySelector('.stw-dtxt .stw-t').textContent = it.label;
    deck.querySelector('.stw-dtxt .stw-s').textContent = it.sub || '';
    var fixed = it.always || it.locked;
    deck.querySelector('.stw-dsw').innerHTML = fixed
      ? '<span class="stw-pill fixed">Always</span>'
      : '<button class="stw-pill' + (it.on ? ' on' : '') + '" onclick="window._stToggle(\'' + esc(it.k) + '\')"' +
        ' aria-pressed="' + (it.on ? 'true' : 'false') + '"><span class="stw-knob"></span></button>';
    deck.querySelector('.stw-dots').innerHTML = list.map(function (x, i) {
      return '<i class="' + (i === d.i ? 'on' : '') + (x.on ? '' : ' off') + '"></i>';
    }).join('');
  }

  window._stGo = function (id, i) {
    var d = DECKS[id]; if (!d || d.i === i) return;
    d.i = i; haptic(14); layoutDeck(id);
  };
  window._stStep = function (id, dir) {
    var d = DECKS[id]; if (!d) return;
    var n = listOf(d.kind).length;
    var i = d.i + dir;
    if (i < 0 || i >= n) return;
    d.i = i; haptic(16); layoutDeck(id);
  };

  /* a swipe moves the deck — the arrows are there for anyone who does not
     think to try, not instead of it */
  function bindSwipe(id) {
    var deck = document.getElementById(id); if (!deck) return;
    var stage = deck.querySelector('.stw-dstage'); if (!stage) return;
    var x0 = null, y0 = null, done = false;
    stage.addEventListener('touchstart', function (e) {
      var t = e.touches[0]; x0 = t.clientX; y0 = t.clientY; done = false;
    }, { passive: true });
    stage.addEventListener('touchmove', function (e) {
      if (x0 === null || done) return;
      var t = e.touches[0], dx = t.clientX - x0, dy = t.clientY - y0;
      if (Math.abs(dx) < 34 || Math.abs(dx) < Math.abs(dy)) return;
      done = true;
      window._stStep(id, dx < 0 ? 1 : -1);
    }, { passive: true });
    stage.addEventListener('touchend', function () { x0 = null; }, { passive: true });
  }
  function sectionsHtml(kind) {
    var list = listOf(kind);
    if (!list.length) {
      return '<div class="stw-empty">Open a home first — the sections load with it.</div>';
    }
    return list.map(function (it) {
      var fixed = it.always || it.locked;
      return '<div class="stw-wcard' + (it.on ? ' on' : '') + (fixed ? ' fixed' : '') + '">' +
          '<div class="stw-wrap"><div class="stw-prev stw-plain"><div class="stw-screen">' +
            '<div class="stw-prev-stage" data-k="' + esc(it.k) + '"></div>' +
          '</div></div></div>' +
          '<div class="stw-wfoot">' +
            '<div class="stw-wtxt">' +
              '<div class="stw-t">' + esc(it.label) + '</div>' +
              '<div class="stw-s">' + esc(it.sub || '') + '</div>' +
            '</div>' +
            (fixed
              ? '<span class="stw-pill fixed">Always</span>'
              : '<button class="stw-pill" onclick="window._stToggle(\'' + esc(it.k) + '\')"' +
                ' aria-pressed="' + (it.on ? 'true' : 'false') + '">' +
                '<span class="stw-knob"></span></button>') +
          '</div>' +
        '</div>';
    }).join('');
  }
  window._stToggle = function (k) {
    if (typeof window.hlSet !== 'function') return;
    var list = window.hlList(HOME), cur = null;
    for (var i = 0; i < list.length; i++) if (list[i].k === k) cur = list[i];
    if (!cur) return;
    window.hlSet(HOME, k, !cur.on);
    haptic(cur.on ? 18 : 30);
    /* repaint the one thing that changed rather than the rail — rebuilding
       would throw away every preview that has already been cloned */
    var st = document.querySelector('.stw-prev-stage[data-k="' + k + '"]');
    var slide = st && st.closest ? st.closest('.stw-slide') : null;
    if (slide) {
      slide.classList.toggle('off', cur.on);
      var deck = slide.closest('.stw-deck');
      if (deck) paintDeckBar(deck.id);
    }
    var card = st && st.closest ? st.closest('.stw-wcard') : null;
    if (card) {
      card.classList.toggle('on', !cur.on);
      var pill = card.querySelector('.stw-pill');
      if (pill) pill.setAttribute('aria-pressed', (!cur.on) ? 'true' : 'false');
    }
    paintCount();
  };
  function paintCount() {
    [['stwSecCount', 'sec'], ['stwBanCount', 'ban'],
     ['stwBlkCount', 'blk'], ['stwTabCount', 'tab']].forEach(function (p) {
      var n = document.getElementById(p[0]);
      if (!n || typeof window.hlList !== 'function') return;
      var l = listOf(p[1]);
      n.textContent = l.filter(function (x) { return x.on; }).length + ' of ' + l.length + ' showing';
    });
  }
  function paintSections() {
    var a = document.getElementById('stwBlocks');
    if (a) a.innerHTML = sectionsHtml('blk');
    var b = document.getElementById('stwTabs');
    if (b) b.innerHTML = sectionsHtml('tab');
    if (a || b) { observe(); visObserve(); }
    paintCount();
  }

  function cardsHtml(kind, arr) {
    return arr.map(function (c, i) {
      return '<button class="stw-card stw-go" onclick="window._stJump(\'' + kind + '\',' + i + ')">' +
        '<span class="stw-ico">' + ico(c.i) + '</span>' +
        '<span class="stw-t">' + esc(c.t) + '</span>' +
        '<span class="stw-s">' + esc(c.s) + '</span>' +
      '</button>';
    }).join('');
  }

  function rail(id, title, sub, body, extra) {
    return '<div class="stw-rail">' +
      '<div class="stw-head">' +
        '<div class="stw-head-txt"><div class="stw-title">' + title + '</div>' +
        '<div class="stw-sub" ' + (extra ? 'id="' + extra + '"' : '') + '>' + sub + '</div></div>' +
      '</div>' +
      '<div class="stw-scroll"' + (id ? ' id="' + id + '"' : '') + '>' + body + '</div>' +
    '</div>';
  }

  function render() {
    var body = document.getElementById('stBody');
    if (!body) return;
    body.innerHTML =
      '<div class="stw-intro">' +
        '<div class="stw-intro-t">Your home, in parts</div>' +
        '<div class="stw-intro-s">Your home is built out of sections. Turn off what you do not use — the rest moves up to fill the space.</div>' +
      '</div>' +
      rail('stwHero', 'Hero header', 'Three ways the top of your home can look', heroHtml()) +
      deckRail('deckSec', 'sec', 'tv',  'Home sections', 'stwSecCount') +
      deckRail('deckBan', 'ban', 'tab', 'Video banners', 'stwBanCount') +
      rail('stwBlocks', 'Clips and their banners', '', sectionsHtml('blk'), 'stwBlkCount') +
      rail('stwTabs', 'Buttons and tabs', '', sectionsHtml('tab'), 'stwTabCount') +
      rail('', 'Jump to', 'The places the app can take you', cardsHtml('jump', JUMP)) +
      rail('', 'Make it yours', 'Every editor, in one place', cardsHtml('make', MAKE));
    paintSections();
    paintHero();
    ['deckSec', 'deckBan'].forEach(function (id) {
      if (!DECKS[id]) return;
      bindSwipe(id);
      layoutDeck(id);
      /* the deck is measured while the screen is still opening, so ask
         again once it has arrived */
      setTimeout(function () { layoutDeck(id); }, 360);
      setTimeout(function () { layoutDeck(id); }, 900);
    });
  }
  window.addEventListener('resize', function () {
    ['deckSec', 'deckBan'].forEach(function (id) { if (DECKS[id]) layoutDeck(id); });
  });

  /* a deck sits in the same rail shell as every other row */
  function deckRail(id, kind, dev, title, countId) {
    return '<div class="stw-rail">' +
      '<div class="stw-head"><div class="stw-head-txt">' +
        '<div class="stw-title">' + title + '</div>' +
        '<div class="stw-sub" id="' + countId + '"></div>' +
      '</div></div>' +
      deckHtml(id, kind, dev) +
    '</div>';
  }

  /* ── Warm what this page is made of ───────────────────────────────
     The clips are the home's own, so app/js/part051.js already warms them
     at idle — they are in the document whether or not this page is open.
     What it cannot warm is the artwork this page introduces: the two
     devices. They are backgrounds, not <video> and not <img>, so nothing
     scans them, and the first open of the page drew a set with no bezel
     while they came down. Fetching them puts them in the same cache
     sw.js answers from, so the second open — and every offline one — has
     them already. Idle, once, and silent if it fails. */
  var FRAMES = [
    './assets/frames/tv-l-top.webp',
    './assets/frames/tv-l-mid.webp',
    './assets/frames/tv-l-bottom.webp',
    './assets/frames/tab-landscape.webp',
    './assets/frames/tv-hero-portrait.webp?v=2'
  ];
  var warmed = false;
  function warm() {
    if (warmed) return;
    warmed = true;
    var go = function () {
      FRAMES.forEach(function (u) {
        try { fetch(u, { cache: 'force-cache' }).catch(function () {}); } catch (e) {}
      });
      /* and the clips of whatever this page is about to show, ahead of the
         idle warmer reaching them in DOM order */
      try {
        var urls = [];
        ['sec', 'ban', 'blk'].forEach(function (kind) {
          listOf(kind).forEach(function (it) {
            (window.hlNodes(HOME, it.k) || []).forEach(function (n) {
              n.querySelectorAll('video[src]').forEach(function (v) { urls.push(v.getAttribute('src')); });
            });
          });
        });
        window.NWSB_EXTRA_VIDEO_URLS = (window.NWSB_EXTRA_VIDEO_URLS || []).concat(urls);
      } catch (e) {}
    };
    (window.requestIdleCallback || function (cb) { setTimeout(cb, 1200); })(go, { timeout: 3000 });
  }
  /* the page's own artwork is worth having before the page is ever opened */
  setTimeout(warm, 6000);

  /* ── The mode's film, on this page ────────────────────────────────
     Fashion Plus plays one fixed clip behind the whole app, and a
     sub-screen covers it. Rather than punching a hole through this page —
     which shows the home screen, not the film, because a screen sits above
     the clip — the page plays the same file itself, at the layer its own
     background would have been. Whatever the mode is showing is what this
     shows: the src is read off the mode's own element, so choosing a
     different background changes this one too with nothing to keep in
     step. */
  function film() {
    var page = document.getElementById('sub-settings');
    if (!page) return;
    var had = page.querySelector('.stw-film');
    var b = document.body;
    var on = b.classList.contains('fashplus') && !b.classList.contains('fp-bg-off');
    var bg = document.getElementById('fpBgVideo');
    var src = (on && bg) ? (bg.getAttribute('src') || '') : '';
    if (!src) { if (had) had.remove(); return; }
    if (had && had.getAttribute('src') === src) {
      try { var q = had.play(); if (q && q.catch) q.catch(function () {}); } catch (e) {}
      return;
    }
    if (had) had.remove();
    var v = document.createElement('video');
    v.className = 'stw-film';
    v.muted = true; v.loop = true; v.playsInline = true; v.preload = 'auto';
    v.setAttribute('muted', ''); v.setAttribute('loop', ''); v.setAttribute('playsinline', '');
    v.setAttribute('src', src);
    page.insertBefore(v, page.firstChild);
    try { var p = v.play(); if (p && p.catch) p.catch(function () {}); } catch (e) {}
  }

  window.stOpen = function () {
    warm();
    render();
    film();
    var s = document.getElementById('sub-settings');
    if (s && typeof openSub === 'function') openSub('settings');
    haptic(24);
    /* The rail is measured for the first time while the screen is still
       opening. Look again once it has arrived, and fill the first few
       outright so the page is never blank while the observer decides. */
    setTimeout(function () {
      var wins = document.querySelectorAll('.stw-prev');
      for (var i = 0; i < Math.min(3, wins.length); i++) {
        var st = wins[i].querySelector('.stw-prev-stage');
        if (st) fillPreview(st);
      }
      observe();
      visObserve();
      pump();
    }, 420);
  };
  window.stClose = function () {
    if (typeof closeSub === 'function') closeSub('settings');
    /* Everything on this page is a copy of something else, so nothing is
       lost by letting it go — and holding twenty-six cloned sections, their
       clips and their observers behind a closed screen is a cost the rest
       of the app pays for a page nobody is looking at. It is rebuilt from
       the registry the next time it opens, which is what render() does
       anyway. The wait is the close animation's length, so the page is
       never seen emptying. */
    setTimeout(function () {
      var open = document.getElementById('sub-settings');
      if (open && open.classList.contains('open')) return;   /* reopened meanwhile */
      var body = document.getElementById('stBody');
      if (!body) return;
      body.querySelectorAll('video').forEach(function (v) {
        try { v.pause(); v.removeAttribute('src'); v.load(); } catch (e) {}
      });
      if (io) { io.disconnect(); io = null; }
      if (vio) { vio.disconnect(); vio = null; }
      queue.length = 0;
      DECKS = {};
      var page = document.getElementById('sub-settings');
      var fv = page && page.querySelector('.stw-film');
      if (fv) { try { fv.pause(); } catch (e) {} fv.remove(); }
      body.innerHTML = '';
    }, 420);
  };



  /* The sections rail has to be right every time it is looked at — the
     arrange-editor can change the same state from the other side. */
  document.addEventListener('visibilitychange', function () {
    if (document.hidden) return;
    paintSections();
    ['deckSec', 'deckBan'].forEach(function (id) { if (DECKS[id]) paintDeckBar(id); });
  });
})();
