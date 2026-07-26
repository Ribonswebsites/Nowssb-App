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

  /* Floating-button faces. Each is the same black NowssB orb with a different
     energy wave, so the tracing ring around the wrapper is tinted to match. */
  var FAB_ICONS = [
    { id: 'blue',   label: 'Blue',   img: 'https://res.cloudinary.com/eenvubod/image/upload/v1785040037/file_00000000f6e881fa9c614af0994b5dda_pxkbl4.png' },
    { id: 'yellow', label: 'Yellow', img: 'https://res.cloudinary.com/eenvubod/image/upload/v1785040061/file_00000000989482309ec4a5e82fead5e0_i4cbfw.png' },
    { id: 'red',    label: 'Red',    img: 'https://res.cloudinary.com/eenvubod/image/upload/v1785040038/file_00000000394081fa9924bcd31a345869_magp1x.png' },
    { id: 'purple', label: 'Purple', img: 'https://res.cloudinary.com/eenvubod/image/upload/v1785040038/file_00000000944081fabf1a7c01b225f478_qbxhjq.png' }
  ];
  function fabIcon() {
    var id = ls('nwsb_ql_icon', 'blue');
    for (var i = 0; i < FAB_ICONS.length; i++) if (FAB_ICONS[i].id === id) return FAB_ICONS[i];
    return FAB_ICONS[0];
  }

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

  /* The bubble switch appears twice — once in the list pane, once in
     settings — so both have to move together whichever one was tapped, and
     the how-to only makes sense while the bubble is actually on. */
  function paintFloatToggles() {
    var on = floatOn();
    ['qlFloatToggle', 'qlFloatToggleList'].forEach(function (id) {
      var t = document.getElementById(id);
      if (t) t.classList.toggle('on', on);
    });
    ['qlFloatHelp', 'qlFloatHelpList'].forEach(function (id) {
      var h = document.getElementById(id);
      if (h) h.style.display = on ? 'block' : 'none';
    });
  }

  function renderSettings() {
    var box = document.getElementById('qlSetList'); if (!box) return;
    var picked = chosen();
    paintFloatToggles();
    var faces = document.getElementById('qlFaceRow');
    if (faces) {
      var cur = fabIcon().id;
      faces.innerHTML = FAB_ICONS.map(function (o) {
        return '<div class="ql-face ic-' + o.id + (o.id === cur ? ' on' : '') + '" onclick="qlSetIcon(\'' + o.id + '\')">' +
          '<span class="ql-face-orb"><img decoding="async" loading="lazy" src="' + o.img + '" alt=""></span>' +
          '<span class="ql-face-lbl">' + o.label + '</span>' +
          '<span class="ql-face-pick">' + (o.id === cur ? '<svg viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>' : '') + '</span>' +
        '</div>';
      }).join('');
    }
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
  /* Belt and braces against the ghost click: even with touchend prevented,
     nothing in the sheet responds for a moment after it opens, so a stray
     synthesised click can't fire the row that happens to be under the
     finger. */
  var openedAt = 0;
  window.qlOpen = function () {
    var ov = document.getElementById('qlOverlay'); if (!ov) return;
    window.qlShowList();
    renderList();
    ov.classList.add('open');
    paintFloatToggles();
    openedAt = Date.now();
    var sc = ov.querySelector('.ql-scroll'); if (sc) sc.scrollTop = 0;
  };
  window.qlClose = function (e) {
    // as the overlay's own handler, only a tap on the backdrop closes
    if (e && e.target && e.target.id !== 'qlOverlay') return;
    var ov = document.getElementById('qlOverlay'); if (ov) ov.classList.remove('open');
  };
  window.qlRun = function (id) {
    if (Date.now() - openedAt < 400) return;
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
  window.qlSetIcon = function (id) {
    lsSet('nwsb_ql_icon', id);
    renderSettings();
    applyFloat();
  };
  window.qlToggleFloat = function () {
    lsSet('nwsb_ql_float', floatOn() ? '0' : '1');
    renderSettings(); paintFloatToggles(); applyFloat();
    try { if (navigator.vibrate) navigator.vibrate(28); } catch (e) {}
  };

  // ── floating button ──────────────────────────────────────────
  function applyFloat() {
    var fab = document.getElementById('qlFab'); if (!fab) return;
    var ic = fabIcon();
    FAB_ICONS.forEach(function (o) { fab.classList.remove('ic-' + o.id); });
    fab.classList.add('ic-' + ic.id);
    var img = fab.querySelector('img');
    if (img && img.getAttribute('src') !== ic.img) img.setAttribute('src', ic.img);
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
  var HOLD   = 1000; // ms the button must be held before the bin appears

  function bindFab() {
    var fab = document.getElementById('qlFab');
    if (!fab || fab._qlBound) return;
    fab._qlBound = true;
    var drop = document.getElementById('qlDrop');
    var target = document.getElementById('qlDropTarget');
    var hot = document.getElementById('qlDropHot');   // the bin itself, not the artwork's centre
    var dragging = false, moved = false, armed = false, sx = 0, sy = 0, ox = 0, oy = 0;
    // The bin only exists after a deliberate press-and-hold. A quick drag
    // just repositions the button; you can't lose it by accident.
    var binMode = false, holdTimer = null;

    function startHold() {
      clearTimeout(holdTimer);
      holdTimer = setTimeout(function () {
        if (!dragging) return;
        binMode = true;
        fab.classList.add('held');
        if (drop) drop.classList.add('show');
        haptic([0, 40]);              // the buzz that says "now you can bin it"
      }, HOLD);
    }
    function cancelHold() { clearTimeout(holdTimer); holdTimer = null; }

    function targetCentre() {
      var el = hot || target;
      if (!el) return null;
      var r = el.getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
    }

    function down(cx, cy) {
      dragging = true; moved = false; armed = false; binMode = false;
      sx = cx; sy = cy;
      var r = fab.getBoundingClientRect(); ox = r.left; oy = r.top;
      fab.classList.add('dragging');
      startHold();
      haptic(20);
    }

    function move(cx, cy) {
      if (!dragging) return;
      var dx = cx - sx, dy = cy - sy;
      if (Math.abs(dx) > 4 || Math.abs(dy) > 4) moved = true;
      // Moving off the spot before the hold completes means this is a drag,
      // not a press — so the bin never comes up.
      if (!binMode && (Math.abs(dx) > 8 || Math.abs(dy) > 8)) cancelHold();
      var w = fab.offsetWidth, h = fab.offsetHeight;
      var x = Math.max(6, Math.min(ox + dx, window.innerWidth - w - 6));
      var y = Math.max(6, Math.min(oy + dy, window.innerHeight - h - 6));

      // Magnet: inside MAGNET px the button is pulled toward the target,
      // harder the closer it gets, so it visibly snaps in rather than
      // needing to be dropped precisely.
      var c = binMode ? targetCentre() : null;
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
          if (!armed) { armed = true; haptic(45); }
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
      cancelHold();
      fab.classList.remove('dragging', 'arming', 'held');
      if (drop) drop.classList.remove('show', 'armed');

      if (armed) {                       // dropped on the target — turn it off
        armed = false; binMode = false;
        haptic([30, 55, 30, 55, 60]);
        lsSet('nwsb_ql_float', '0');
        applyFloat();
        renderSettings();
        return;
      }
      binMode = false;
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
    // Not passive, and prevented on a tap: otherwise the browser synthesises
    // a click ~300ms later that lands on the sheet qlOpen() just put under
    // the finger — which is why tapping the button opened the Store.
    fab.addEventListener('touchend', function (e) {
      var wasTap = dragging && !moved;
      up();
      if (wasTap && e.cancelable) e.preventDefault();
    }, { passive: false });
    fab.addEventListener('touchcancel', function () { cancelHold(); up(); }, { passive: true });
    fab.addEventListener('mousedown', function (e) { down(e.clientX, e.clientY); e.preventDefault(); });
    window.addEventListener('mousemove', function (e) { move(e.clientX, e.clientY); });
    window.addEventListener('mouseup', up);
    window.addEventListener('resize', applyFloat);
  }


  /* The sheet, the floating button and the drop zone are injected here rather
     than shipped in index.html — that document is already ~9k lines and this
     markup is inert until something opens it. */
  var MARKUP = '<div class="ql-overlay" id="qlOverlay" onclick="qlClose(event)">' +
    '  <div class="ql-box" id="qlBox" onclick="event.stopPropagation()">' +
    '    <div class="ql-head">' +
    '      <button class="ql-hbtn ql-back" onclick="qlShowList()" aria-label="Back">' +
    '        <svg viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg>' +
    '      </button>' +
    '      <div class="ql-head-txt">' +
    '        <div class="ql-head-title">Quick Links</div>' +
    '        <div class="ql-head-sub">Jump straight to any corner of NowssB</div>' +
    '      </div>' +
    '      <button class="ql-hbtn ql-gear" onclick="qlShowSettings()" aria-label="Quick Links settings">' +
    '        <img decoding="async" loading="lazy" src="https://res.cloudinary.com/dc4nsi3xs/image/upload/v1782718779/f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png" alt="">' +
    '      </button>' +
    '      <button class="ql-hbtn ql-close" onclick="qlClose()" aria-label="Close">' +
    '        <svg viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="2.2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>' +
    '      </button>' +
    '    </div>' +
    '' +
    '    <!-- LIST pane -->' +
    '    <div class="ql-scroll ql-pane-list">' +
    '      <div class="ql-float-row ql-float-row-list" onclick="qlToggleFloat()">' +
    '        <span class="ql-float-txt">' +
    '          <span class="ql-float-t">Floating bubble</span>' +
    '          <span class="ql-float-s">A circle over every screen. Tap it — or its arrow — to open this list from anywhere.</span>' +
    '        </span>' +
    '        <span class="ql-switch" id="qlFloatToggleList"><span class="ql-switch-knob"></span></span>' +
    '      </div>' +
    '      <div class="ql-float-help" id="qlFloatHelpList">' +
    '        <b>To remove it:</b> switch it off here, or press and hold the bubble for a second until it buzzes, then drag it down into the bin.' +
    '      </div>' +
    '      <div id="qlList"><!-- rendered by JS --></div>' +
    '    </div>' +
    '' +
    '    <!-- SETTINGS pane -->' +
    '    <div class="ql-scroll ql-pane-set">' +
    '      <div class="ql-float-row" onclick="qlToggleFloat()">' +
    '        <span class="ql-float-txt">' +
    '          <span class="ql-float-t">Floating button</span>' +
    '          <span class="ql-float-s">A circle that floats over every screen — tap it to open Quick Links from anywhere, drag it wherever you like.</span>' +
    '        </span>' +
    '        <span class="ql-switch" id="qlFloatToggle"><span class="ql-switch-knob"></span></span>' +
    '      </div>' +
    '      <div class="ql-float-help" id="qlFloatHelp">' +
    '        <b>To remove it:</b> switch it off here, or press and hold the bubble for a second until it buzzes, then drag it down into the bin.' +
    '      </div>' +
    '      <div class="ql-set-label">Button look</div>' +
    '      <div class="ql-face-row" id="qlFaceRow"><!-- rendered by JS --></div>' +
    '      <div class="ql-set-label">Shortcuts in your list</div>' +
    '      <div id="qlSetList"><!-- rendered by JS --></div>' +
    '    </div>' +
    '  </div>' +
    '</div>' +
    '' +
    '<!-- Floating Quick Links button — off by default, enabled in the sheet\'s settings -->' +
    '<div class="ql-fab" id="qlFab" style="display:none;" role="button" aria-label="Quick Links">' +
    '  <img decoding="async" loading="lazy" src="https://res.cloudinary.com/eenvubod/image/upload/v1784911241/file_000000002cf4820b865caf6fc0554959_k7drqx.png" alt="">' +
    '  <span class="ql-fab-arrow" aria-hidden="true">' +
    '    <svg viewBox="0 0 24 24" fill="none"><path d="M9 6l6 6-6 6" stroke="#060c18" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
    '  </span>' +
    '</div>' +
    '<!-- Drag-to-remove zone — fades up under the floating button while it\'s held,' +
    '     with a target the button magnets into when it gets close. -->' +
    '<div class="ql-drop" id="qlDrop" aria-hidden="true">' +
    '  <div class="ql-drop-target" id="qlDropTarget">' +
    '    <img decoding="async" loading="lazy" src="https://res.cloudinary.com/eenvubod/image/upload/v1785040037/file_00000000735c8207b7fa48448b9f6ecf_ouac1f.png" alt="">' +
    '    <span class="ql-drop-vignette"></span>' +
    '    <span class="ql-drop-hot" id="qlDropHot"></span>' +
    '  </div>' +
    '  <div class="ql-drop-label" id="qlDropLabel">Drag here to remove</div>' +
    '</div>';

  function mount() {
    if (document.getElementById('qlOverlay')) return true;
    if (!document.body) return false;
    var host = document.createElement('div');
    host.id = 'qlHost';
    host.innerHTML = MARKUP;
    while (host.firstChild) document.body.appendChild(host.firstChild);
    return true;
  }

  function init() { mount(); bindFab(); applyFloat(); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();

})();
