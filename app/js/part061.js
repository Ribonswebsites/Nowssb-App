/* ══════════════════════════════════════════════════════════
   QUICK LINKS — the glassmorphism sheet the "Quick Links" banner lifts up,
   plus its settings view and the floating button.

   Three parts:
     • the sheet — the app's black banners as shortcuts, rendered from
       CATALOG so the user's own selection drives what appears
     • settings (gear in the sheet header) — turn the floating button on or
       off, and tick which shortcuts are in the list
     • the floating button — an AssistiveTouch-style circle that rides above
       every screen, is draggable, and opens this sheet from anywhere

   Every destination is an existing screen and every icon is already used
   elsewhere in the app; nothing here is invented.

   qlRun() closes the sheet BEFORE running the action. Most destinations are
   .sub-screen overlays and openSub() only toggles a class without touching
   z-index, so leaving the sheet up would bury them underneath — the same
   stacking trap the Shabdapathy eBook button hit.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var IC = {
    store:    'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png',
    health:   'https://res.cloudinary.com/ds6duqabl/image/upload/v1785014534/file_0000000020cc82089a4eded2b0c2c62b_hmu0qv.png',
    connect:  'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_120/v1784218818/file_00000000b84c7209ab496862cacd6a7f_kagsie.png',
    streak:   'https://res.cloudinary.com/eenvubod/image/upload/v1784895543/file_0000000010fc820891f9e15a38316d2b_ffffhq.png',
    offer:    'https://res.cloudinary.com/eenvubod/image/upload/v1784915420/file_000000006b20820b84961321dcdcaaa8_be9meu.png',
    ai:       'https://res.cloudinary.com/eenvubod/image/upload/v1784895543/file_0000000062a882089abd27eb90ea3945_ngqyu6.png',
    meaning:  'https://res.cloudinary.com/eenvubod/image/upload/v1784460474/file_00000000854881fa9a548a68fae59c15_w1utya.png',
    quick:    'https://res.cloudinary.com/eenvubod/image/upload/v1784911241/file_000000002cf4820b865caf6fc0554959_k7drqx.png',
    tiles:    'https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png',
    library:  'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563282/c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png',
    progress: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157829/file_00000000ae607208aa51504989648920_ml2czc.png',
    wordsci:  'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783158082/file_0000000086d872089ce376674620d5f3_mtfftb.png',
    routines: 'https://res.cloudinary.com/eenvubod/image/upload/v1784361579/file_00000000f740820ba6aaa761133e8889_fitm0p.png',
    cart:     'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_00000000f02c72088cd128f3f4b08af5_vskoom.png',
    wishlist: 'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_0000000055d8720895f7ba98c4a7bf4a_s2lzab.png',
    search:   'https://res.cloudinary.com/dc4nsi3xs/image/upload/f_auto,q_auto,w_240/v1783157830/file_00000000029c7208b5e915d9af2c480c_tuccwo.png',
    chat:     'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1780123160/1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png',
    profile:  'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563282/62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png',
    settings: 'https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563283/260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png',
    every:    'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_220/v1784256220/file_00000000be547207aaa56f43cfef4f67_nxhvw0.png'
  };

  function sub(id) { return function () { if (typeof openSub === 'function') openSub(id); }; }

  var CATALOG = [
    { id: 'store',     t: 'NowssB Store',        s: 'Word Atelier, Meaning Store and more', ic: IC.store,    go: sub('nowssb-store') },
    { id: 'health',    t: 'Health Journey',      s: 'Body, organ and mind wellness',        ic: IC.health,   go: sub('health-journey') },
    { id: 'connect',   t: 'NowssB Community',    s: 'See what the community is practising', ic: IC.connect,  go: sub('people') },
    { id: 'streak',    t: 'Daily Streak',        s: 'Keep your healing streak alive',       ic: IC.streak,   go: sub('streak') },
    { id: 'offer',     t: "Today's Offer",       s: 'Rotating store coupons',               ic: IC.offer,    go: sub('offers') },
    { id: 'ai',        t: 'AI Prescription',     s: 'Your personalized word ritual',        ic: IC.ai,       go: sub('ai-prescription') },
    { id: 'meaning',   t: 'Meaning Search',      s: 'Uncover the meaning of any word',      ic: IC.meaning,  go: sub('meaning-search') },
    { id: 'quick',     t: 'Quick Access',        s: 'Customize your bottom navigation bar', ic: IC.quick,    go: sub('quick-access') },
    { id: 'tiles',     t: 'Home Tiles',          s: 'Restyle your four home buttons',       ic: IC.tiles,    go: function () { if (typeof htOpen === 'function') htOpen(); } },
    { id: 'library',   t: 'Sound Library',       s: 'Root frequencies to practice with',    ic: IC.library,  go: sub('sound-library') },
    { id: 'progress',  t: 'My Progress',         s: 'Your healing journey and body map',    ic: IC.progress, go: sub('my-progress') },
    { id: 'wordsci',   t: 'Word Science',        s: 'The NOWSBANSIU word science texts',    ic: IC.wordsci,  go: sub('word-science') },
    { id: 'wordstore', t: 'The Word Atelier',    s: 'Own the sounds that heal',             ic: IC.store,    go: sub('real-meaning') },
    { id: 'mstore',    t: 'Meaning Store',       s: 'Own the origins that were hidden',     ic: IC.meaning,  go: sub('meaning-store') },
    { id: 'routines',  t: 'My Routines',         s: 'Your daily practice system',           ic: IC.routines, go: sub('routines') },
    { id: 'cart',      t: 'Cart',                s: 'Everything you have added',            ic: IC.cart,     go: sub('cart') },
    { id: 'wishlist',  t: 'Wishlist',            s: 'Words you saved for later',            ic: IC.wishlist, go: sub('wishlist') },
    { id: 'search',    t: 'Word Search',         s: 'Search any word or meaning',           ic: IC.search,   go: sub('search-choice') },
    { id: 'chat',      t: 'Chat',                s: 'Your conversations',                   ic: IC.chat,     go: function () { if (typeof chatInboxOpen === 'function') chatInboxOpen(); } },
    { id: 'profile',   t: 'My Profile',          s: 'Your profile and preferences',         ic: IC.profile,  go: sub('profile') },
    { id: 'settings',  t: 'Settings',            s: 'All of your app settings',             ic: IC.settings, go: sub('social') },
    { id: 'every',     t: 'Everything on NowssB', s: 'Every feature in one place',          ic: IC.every,    go: sub('features') }
  ];
  var DEFAULTS = ['store', 'health', 'connect', 'streak', 'offer', 'ai', 'meaning', 'quick', 'tiles'];

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }
  function byId(id) { for (var i = 0; i < CATALOG.length; i++) if (CATALOG[i].id === id) return CATALOG[i]; return null; }

  function chosen() {
    var raw = ls('nwsb_ql_items', null);
    if (raw) {
      try {
        var a = JSON.parse(raw);
        if (a && a.length) { a = a.filter(byId); if (a.length) return a; }
      } catch (e) {}
    }
    return DEFAULTS.slice();
  }
  function floatOn() { return ls('nwsb_ql_float', '0') === '1'; }

  var ARROW = '<div class="nmh-sec-banner-arrow"><svg viewBox="0 0 24 24" fill="none"><path d="M5 12h14M12 5l7 7-7 7" stroke="rgba(255,255,255,0.9)" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/></svg></div>';

  function renderList() {
    var box = document.getElementById('qlList'); if (!box) return;
    box.innerHTML = chosen().map(function (id) {
      var it = byId(id); if (!it) return '';
      return '<div class="nmh-sec-banner ql-item" onclick="qlRun(\'' + it.id + '\')">' +
        '<div class="nmh-sec-banner-icon"><img decoding="async" loading="lazy" src="' + it.ic + '" alt=""></div>' +
        '<div class="nmh-sec-banner-divider"></div>' +
        '<div class="nmh-sec-banner-txt">' +
          '<div class="nmh-sec-banner-title">' + it.t + '</div>' +
          '<div class="nmh-sec-banner-sub">' + it.s + '</div>' +
        '</div>' + ARROW +
      '</div>';
    }).join('');
  }

  function renderSettings() {
    var box = document.getElementById('qlSetList'); if (!box) return;
    var picked = chosen();
    var tgl = document.getElementById('qlFloatToggle');
    if (tgl) tgl.classList.toggle('on', floatOn());
    box.innerHTML = CATALOG.map(function (it) {
      var on = picked.indexOf(it.id) >= 0;
      return '<div class="ql-pick' + (on ? ' on' : '') + '" onclick="qlTogglePick(\'' + it.id + '\')">' +
        '<span class="ql-pick-ic"><img decoding="async" loading="lazy" src="' + it.ic + '" alt=""></span>' +
        '<span class="ql-pick-txt"><span class="ql-pick-t">' + it.t + '</span><span class="ql-pick-s">' + it.s + '</span></span>' +
        '<span class="ql-pick-box">' + (on ? '<svg viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>' : '') + '</span>' +
      '</div>';
    }).join('');
  }

  // ── sheet ────────────────────────────────────────────────────
  window.qlOpen = function () {
    var ov = document.getElementById('qlOverlay'); if (!ov) return;
    window.qlShowList();
    renderList();
    ov.classList.add('open');
    var sc = ov.querySelector('.ql-scroll'); if (sc) sc.scrollTop = 0;
  };
  window.qlClose = function (e) {
    // as the overlay's own handler, only a tap on the backdrop closes
    if (e && e.target && e.target.id !== 'qlOverlay') return;
    var ov = document.getElementById('qlOverlay'); if (ov) ov.classList.remove('open');
  };
  window.qlRun = function (id) {
    var it = byId(id); if (!it) return;
    var ov = document.getElementById('qlOverlay'); if (ov) ov.classList.remove('open');
    setTimeout(function () { try { it.go(); } catch (err) {} }, 180);
  };

  // ── settings view (same sheet, swapped panes) ────────────────
  window.qlShowSettings = function () {
    renderSettings();
    var b = document.getElementById('qlBox'); if (b) b.classList.add('settings');
  };
  window.qlShowList = function () {
    var b = document.getElementById('qlBox'); if (b) b.classList.remove('settings');
  };
  window.qlTogglePick = function (id) {
    var a = chosen(), i = a.indexOf(id);
    if (i >= 0) { if (a.length <= 1) return; a.splice(i, 1); }   // never leave the list empty
    else a.push(id);
    lsSet('nwsb_ql_items', JSON.stringify(a));
    renderSettings(); renderList();
  };
  window.qlToggleFloat = function () {
    lsSet('nwsb_ql_float', floatOn() ? '0' : '1');
    renderSettings(); applyFloat();
  };

  // ── floating button ──────────────────────────────────────────
  function applyFloat() {
    var fab = document.getElementById('qlFab'); if (!fab) return;
    fab.style.display = floatOn() ? 'flex' : 'none';
    if (!floatOn()) return;
    var pos = null;
    try { pos = JSON.parse(ls('nwsb_ql_fab_pos', 'null')); } catch (e) {}
    var w = fab.offsetWidth || 54, h = fab.offsetHeight || 54;
    var x = pos && typeof pos.x === 'number' ? pos.x : (window.innerWidth - w - 14);
    var y = pos && typeof pos.y === 'number' ? pos.y : Math.round(window.innerHeight * 0.62);
    fab.style.left = Math.max(6, Math.min(x, window.innerWidth - w - 6)) + 'px';
    fab.style.top  = Math.max(6, Math.min(y, window.innerHeight - h - 6)) + 'px';
  }
  window.qlApplyFloat = applyFloat;

  /* Short buzz on grab, a firmer one when it snaps into the remove target and
     again when it actually goes. navigator.vibrate is Android-only and a no-op
     elsewhere, so it's feature-checked rather than assumed. */
  function haptic(ms) {
    try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {}
  }

  var MAGNET = 104;  // px from the target centre where the pull starts
  var SNAP   = 42;   // inside this it locks onto the centre

  function bindFab() {
    var fab = document.getElementById('qlFab');
    if (!fab || fab._qlBound) return;
    fab._qlBound = true;
    var drop = document.getElementById('qlDrop');
    var target = document.getElementById('qlDropTarget');
    var dragging = false, moved = false, armed = false, sx = 0, sy = 0, ox = 0, oy = 0;

    function targetCentre() {
      if (!target) return null;
      var r = target.getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
    }

    function down(cx, cy) {
      dragging = true; moved = false; armed = false; sx = cx; sy = cy;
      var r = fab.getBoundingClientRect(); ox = r.left; oy = r.top;
      fab.classList.add('dragging');
      if (drop) drop.classList.add('show');
      haptic(12);
    }

    function move(cx, cy) {
      if (!dragging) return;
      var dx = cx - sx, dy = cy - sy;
      if (Math.abs(dx) > 4 || Math.abs(dy) > 4) moved = true;
      var w = fab.offsetWidth, h = fab.offsetHeight;
      var x = Math.max(6, Math.min(ox + dx, window.innerWidth - w - 6));
      var y = Math.max(6, Math.min(oy + dy, window.innerHeight - h - 6));

      // Magnet: inside MAGNET px the button is pulled toward the target,
      // harder the closer it gets, so it visibly snaps in rather than
      // needing to be dropped precisely.
      var c = targetCentre();
      if (c) {
        var fcx = x + w / 2, fcy = y + h / 2;
        var d = Math.sqrt((c.x - fcx) * (c.x - fcx) + (c.y - fcy) * (c.y - fcy));
        if (d < MAGNET) {
          // Inside SNAP it goes all the way in, so it reads as being sucked
          // into the target rather than hovering near it. Between SNAP and
          // MAGNET the pull ramps up linearly.
          var pull = d <= SNAP ? 1 : (1 - (d - SNAP) / (MAGNET - SNAP)) * 0.9;
          x += (c.x - w / 2 - x) * pull;
          y += (c.y - h / 2 - y) * pull;
          if (!armed) { armed = true; haptic(22); }
        } else if (armed) {
          armed = false;
        }
      }
      if (drop) drop.classList.toggle('armed', armed);
      fab.classList.toggle('arming', armed);
      fab.style.left = x + 'px';
      fab.style.top  = y + 'px';
    }

    function up() {
      if (!dragging) return;
      dragging = false;
      fab.classList.remove('dragging', 'arming');
      if (drop) drop.classList.remove('show', 'armed');

      if (armed) {                       // dropped on the target — turn it off
        armed = false;
        haptic([18, 40, 18]);
        lsSet('nwsb_ql_float', '0');
        applyFloat();
        renderSettings();
        return;
      }
      var r = fab.getBoundingClientRect();
      lsSet('nwsb_ql_fab_pos', JSON.stringify({ x: Math.round(r.left), y: Math.round(r.top) }));
      if (!moved) window.qlOpen();       // a tap, not a drag
    }

    fab.addEventListener('touchstart', function (e) { down(e.touches[0].clientX, e.touches[0].clientY); }, { passive: true });
    fab.addEventListener('touchmove', function (e) {
      if (!dragging) return;
      if (e.cancelable) e.preventDefault();
      move(e.touches[0].clientX, e.touches[0].clientY);
    }, { passive: false });
    fab.addEventListener('touchend', up, { passive: true });
    fab.addEventListener('touchcancel', up, { passive: true });
    fab.addEventListener('mousedown', function (e) { down(e.clientX, e.clientY); e.preventDefault(); });
    window.addEventListener('mousemove', function (e) { move(e.clientX, e.clientY); });
    window.addEventListener('mouseup', up);
    window.addEventListener('resize', applyFloat);
  }

  function init() { bindFab(); applyFloat(); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();

})();
