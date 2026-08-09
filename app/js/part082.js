/* ══════════════════════════════════════════════════════════════════════
   SETTINGS → WIDGETS
   The home is built out of sections — Choose Your Path, Subscription,
   Quick Access, Connect — and every one of them is really a widget: a
   thing that can be there or not. This page says so out loud.

   Three rails, each scrolling sideways:
     1. Home sections — every section the home is made of, on or off.
        It does NOT keep its own list or its own storage. The layout
        registry (app/js/part062.js) already decides what a home is made
        of and remembers what is switched off, and the arrange-editor
        reads the same thing — a second copy would drift the first time
        a section was added.
     2. Jump to — the places the app can take you, one tap each.
     3. Make it yours — the editors and switches that change how the app
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

  function stripIds(node) {
    if (node.removeAttribute) node.removeAttribute('id');
    var kids = node.querySelectorAll ? node.querySelectorAll('[id]') : [];
    for (var i = 0; i < kids.length; i++) kids[i].removeAttribute('id');
  }

  function fillPreview(stage) {
    if (stage._filled) return;
    stage._filled = true;
    var k = stage.getAttribute('data-k');
    var nodes = (typeof window.hlNodes === 'function') ? window.hlNodes(null, k) : [];
    if (!nodes.length) { stage.classList.add('empty'); return; }
    nodes.forEach(function (n) {
      var c = n.cloneNode(true);
      stripIds(c);
      c.classList.remove('hl-off');          /* a hidden section still previews */
      c.style.display = '';
      stage.appendChild(c);
    });
    /* clips in a preview are decoration: muted, looping, and never a
       reason to hold up the page */
    stage.querySelectorAll('video').forEach(function (v) {
      v.muted = true; v.setAttribute('muted', ''); v.playsInline = true;
      v.loop = true; v.removeAttribute('controls');
      try { var p = v.play(); if (p && p.catch) p.catch(function () {}); } catch (e) {}
    });
    /* scale it to the card once we know how tall the real thing is */
    var card = stage.parentNode;
    if (!card) return;
    var scale = card.clientWidth / PREV_W;
    stage.style.transform = 'scale(' + scale + ')';
  }

  function observe() {
    if (io) io.disconnect();
    var fillIn = function (win) {
      var st = win.querySelector('.stw-prev-stage');
      if (st) fillPreview(st);
    };
    if (!('IntersectionObserver' in window)) {
      document.querySelectorAll('.stw-prev').forEach(fillIn);
      return;
    }
    /* Observe the WINDOW, not the stage. An unfilled stage is absolutely
       positioned with nothing in it — zero height — and a target with no
       area never reports as intersecting, so nothing would ever be built.
       .stw-prev has a real 190px box from the moment it exists. */
    io = new IntersectionObserver(function (ents) {
      ents.forEach(function (e) {
        if (e.isIntersecting) { fillIn(e.target); io.unobserve(e.target); }
      });
    }, { root: document.getElementById('stwSections'), rootMargin: '250px' });
    document.querySelectorAll('.stw-prev').forEach(function (w) { io.observe(w); });
  }

  function sectionsHtml() {
    var list = (typeof window.hlList === 'function') ? window.hlList() : [];
    if (!list.length) {
      return '<div class="stw-empty">Open a home first — the sections load with it.</div>';
    }
    return list.map(function (it) {
      var fixed = it.always || it.locked;
      return '<div class="stw-wcard' + (it.on ? ' on' : '') + (fixed ? ' fixed' : '') + '">' +
          '<div class="stw-prev"><div class="stw-prev-stage" data-k="' + esc(it.k) + '"></div></div>' +
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
    var list = window.hlList(), cur = null;
    for (var i = 0; i < list.length; i++) if (list[i].k === k) cur = list[i];
    if (!cur) return;
    window.hlSet(null, k, !cur.on);
    haptic(cur.on ? 18 : 30);
    /* repaint the one card rather than the rail — rebuilding would throw
       away every preview that has already been cloned */
    var card = document.querySelector('.stw-prev-stage[data-k="' + k + '"]');
    card = card && card.closest ? card.closest('.stw-wcard') : null;
    if (card) {
      card.classList.toggle('on', !cur.on);
      var pill = card.querySelector('.stw-pill');
      if (pill) pill.setAttribute('aria-pressed', (!cur.on) ? 'true' : 'false');
    }
    paintCount();
  };
  function paintCount() {
    var n = document.getElementById('stwSecCount');
    if (n && typeof window.hlList === 'function') {
      var l = window.hlList();
      n.textContent = l.filter(function (x) { return x.on; }).length + ' of ' + l.length + ' showing';
    }
  }
  function paintSections() {
    var el = document.getElementById('stwSections');
    if (el) { el.innerHTML = sectionsHtml(); observe(); }
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
      rail('stwSections', 'Home sections', '', sectionsHtml(), 'stwSecCount') +
      rail('', 'Jump to', 'The places the app can take you', cardsHtml('jump', JUMP)) +
      rail('', 'Make it yours', 'Every editor, in one place', cardsHtml('make', MAKE));
    paintSections();
  }

  window.stOpen = function () {
    render();
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
    }, 420);
  };
  window.stClose = function () { if (typeof closeSub === 'function') closeSub('settings'); };

  /* The sections rail has to be right every time it is looked at — the
     arrange-editor can change the same state from the other side. */
  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) paintSections();
  });
})();
