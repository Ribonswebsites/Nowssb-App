/* ══════════════════════════════════════════════════════════
   NOTIFICATIONS — the bell in the Fashion home's fixed header.

   Two halves on one page:

     Updates   the notifications the app has actually sent, newest first,
               with a Clear that empties the list.
     What you  a switch per kind, grouped the way the app is grouped, plus
     get       a master switch above them all.

   Nothing here invents notifications. The feed is a real store that starts
   empty and only fills when something calls window.nwsbNotify() — see the
   API note above that function. A kind that is switched off is dropped at
   nwsbNotify(), so turning it off stops it arriving rather than merely
   hiding it after the fact.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var K_OFF    = 'nwsb_notif_off';
  var K_MASTER = 'nwsb_notif_master';
  var K_FEED   = 'nwsb_notif_feed';
  var FEED_MAX = 60;

  /* Icons come from the section each kind belongs to — the same image files
     those sections already use, so a row in the feed reads as "this is from
     the store / your routine / Connect" at a glance. No new assets: every
     URL here is already loaded somewhere else in the app. */
  function img(u) { return '<img loading="lazy" decoding="async" alt="" src="' + u + '">'; }

  var A = {
    chat:     'assets/media/image/265b5e8805e9e2288b69852af9cf4d7e4eac111b034d565e-46fef40b.webp',
    reels:    'assets/media/image/99c0f4c887eaf6c0590c402c1a084d711687ae57a791b8ee-f9494031.webp',
    connect:  'assets/media/image/589b6824072557ad8eda6d6eac0411c6056d1a4593e4130a-c4734c2d.webp',
    profile:  'assets/media/image/1e60226665c68128ad03987930169b94504c89b3fe74ccc8-d7dfb697.webp',
    store:    'assets/media/image/71c48094f340d790cd2e7020f0ad78fd80e7f268edc6fe6d-330d4dee.webp',
    cart:     'assets/media/image/712ebb6fcce54014ce10264bcb6805954a9f3b45a9c99c5d-e05a2e25.webp',
    library:  'assets/media/image/19e9a80ef81fcb8f99de917b2ada10114250cf63f44978f4-e7261be5.webp',
    offer:    'assets/media/image/6b747aedbfb40a251b398b9008515762e808019375e58389-afcb8741.png',
    wordsci:  'assets/media/image/2e30a7d85cff2f88eeca40d929d9fe19db47b941586210f7-64ecc8c2.webp',
    routines: 'assets/media/image/f19d52470a876209c8289b54081839108ba1b076bbf63926-64c6e8a0.png',
    ai:       'assets/media/image/1ad8a28461e97ed8e682ad06730f6d245fd8bb3a718b71f7-66da3ed1.png',
    streak:   'assets/media/image/375647daaff93ba2784f6ac0ecf6c3f9b207639c3444529f-5e809db4.png',
    every:    'assets/media/image/aa2e75819832c6648532079b7499b33175725fc3eaae80db-1e188c9b.webp',
    settings: 'assets/media/image/6fec694bea6199550bbf4ea9df232769f01e6cfa5ccbfd82-75bedcbf.webp'
  };

  var IC = {
    messages:     img(A.chat),
    posts:        img(A.reels),
    reactions:    img(A.connect),
    follows:      img(A.profile),
    orders:       img(A.store),
    delivery:     img(A.store),      // same order, later in its life
    cart:         img(A.cart),
    arrivals:     img(A.library),
    offers:       img(A.offer),
    trending:     img(A.wordsci),
    routine:      img(A.routines),
    rx:           img(A.ai),
    streak:       img(A.streak),
    reader:       img(A.library),
    subscription: img(A.every),
    support:      img(A.settings)
  };

  /* Every kind of notification the app can send, grouped as the app is. */
  var GROUPS = [
    { name: 'NowssB Connect', items: [
      { k: 'messages',  label: 'Messages',        sub: 'New texts from people you follow' },
      { k: 'posts',     label: 'Posts & Reels',   sub: 'New posts and reels on your feed' },
      { k: 'reactions', label: 'Likes & Comments', sub: 'When someone reacts to what you shared' },
      { k: 'follows',   label: 'New Followers',   sub: 'When someone starts following you' }
    ]},
    { name: 'Store & Orders', items: [
      { k: 'orders',    label: 'Order Updates',   sub: 'Confirmed, packed and completed' },
      { k: 'delivery',  label: 'On Its Way',      sub: 'Where your order is and how long it will take' },
      { k: 'cart',      label: 'Cart Reminders',  sub: 'Words still in your cart, before they are gone' },
      { k: 'arrivals',  label: 'New Arrivals',    sub: 'New words, meanings and drops' },
      { k: 'offers',    label: "Today's Offers",  sub: 'Coupons and limited-time discounts' },
      { k: 'trending',  label: "Today's Trending", sub: 'The word healing the most today' }
    ]},
    { name: 'Your Practice', items: [
      { k: 'routine',   label: 'Daily Routine',   sub: 'Reminders for each routine slot' },
      { k: 'rx',        label: 'AI Prescription', sub: 'When your daily words are ready' },
      { k: 'streak',    label: 'Streak',          sub: 'Before your streak is about to break' },
      { k: 'reader',    label: 'Reading Reminders', sub: 'Reminders you set yourself in the Reader' }
    ]},
    { name: 'Account', items: [
      { k: 'subscription', label: 'Subscription', sub: 'Renewals, plan changes and billing' },
      { k: 'support',      label: 'Support',      sub: 'Replies to your support requests' }
    ]}
  ];

  var ALL = [];
  GROUPS.forEach(function (g) { g.items.forEach(function (i) { ALL.push(i.k); }); });

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  function master() { return ls(K_MASTER, '1') !== '0'; }
  function offSet() {
    var raw; try { raw = JSON.parse(ls(K_OFF, '[]')); } catch (e) { raw = []; }
    return Array.isArray(raw) ? raw.filter(function (k) { return ALL.indexOf(k) >= 0; }) : [];
  }
  function feed() {
    var raw; try { raw = JSON.parse(ls(K_FEED, '[]')); } catch (e) { raw = []; }
    return Array.isArray(raw) ? raw : [];
  }
  function saveFeed(a) { lsSet(K_FEED, JSON.stringify(a.slice(0, FEED_MAX))); }

  function labelOf(k) {
    var out = k;
    GROUPS.forEach(function (g) { g.items.forEach(function (i) { if (i.k === k) out = i.label; }); });
    return out;
  }

  function haptic(ms) { try { if (navigator.vibrate) navigator.vibrate(ms); } catch (e) {} }

  /* ── Badge on the header bells ─────────────────────────────────────
     There is a bell on each home and one on the Sound Library, so paint
     every badge rather than the Fashion one alone. */
  var BADGES = ['homeNotifBadge', 'nmhNotifBadge', 'slmNotifBadge'];
  function paintBadge() {
    var n = feed().filter(function (x) { return !x.read; }).length;
    BADGES.forEach(function (id) {
      var el = document.getElementById(id);
      if (!el) return;
      el.textContent = n > 99 ? '99+' : String(n);
      el.style.display = n ? 'flex' : 'none';
    });
  }
  window.nwsbNotifBadge = paintBadge;

  /* ── Public API ────────────────────────────────────────────────────
     window.nwsbNotify({ type, title, body })

     `type` must be one of the keys in GROUPS above. Anything sent with the
     master switch off, or with its own kind switched off, is dropped here —
     so a caller never has to check the preferences itself. Returns true if
     the notification was kept.

     Nothing in the app calls this yet; the feed is empty until something
     does, which is why the Updates list ships with an empty state rather
     than sample rows. ── */
  window.nwsbNotify = function (n) {
    if (!n || !n.type || ALL.indexOf(n.type) < 0) return false;
    if (!master() || offSet().indexOf(n.type) >= 0) return false;
    var a = feed();
    a.unshift({
      type: n.type,
      title: String(n.title || labelOf(n.type)),
      body: String(n.body || ''),
      at: Number(n.at) || Date.now(),
      read: false
    });
    saveFeed(a);
    paintBadge();
    render(); renderSheet();
    return true;
  };

  window.nwsbNotifClear = function () {
    saveFeed([]);
    paintBadge();
    render(); renderSheet();
    haptic([30, 55, 30]);
  };

  /* ── Rendering ─────────────────────────────────────────────────── */
  function ago(ts) {
    var s = Math.max(0, Math.floor((Date.now() - ts) / 1000));
    if (s < 60) return 'just now';
    var m = Math.floor(s / 60); if (m < 60) return m + 'm ago';
    var h = Math.floor(m / 60); if (h < 24) return h + 'h ago';
    var d = Math.floor(h / 24); if (d < 7) return d + 'd ago';
    return Math.floor(d / 7) + 'w ago';
  }
  function esc(s) {
    return String(s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  }

  function render() {
    var body = document.getElementById('ntBody');
    if (!body) return;
    var on = master(), off = offSet(), list = feed();

    var html = '';

    html +=
      '<div class="nt-master' + (on ? ' on' : '') + '">' +
        '<div class="nt-master-icon"><svg viewBox="0 0 24 24" fill="none">' +
          '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>' +
          '<path d="M13.7 21a2 2 0 0 1-3.4 0" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>' +
        '</svg></div>' +
        '<div class="nt-master-txt">' +
          '<div class="nt-master-title">All Notifications</div>' +
          '<div class="nt-master-sub">' + (on ? 'You are receiving notifications' : 'Everything is muted') + '</div>' +
        '</div>' +
        '<div class="nt-sw' + (on ? ' on' : '') + '" onclick="ntToggleMaster()"><div class="nt-sw-knob"></div></div>' +
      '</div>';

    /* The master switch above is this app's own preference and nothing else.
       Whether the PHONE will actually show anything is a separate permission
       that only the browser can grant, and it defaults to neither on nor off.
       app/js/part068.js fills this in with the real state and a way to ask
       for it; if that file is absent the slot simply stays empty. */
    html += '<div id="ntPhoneRow"></div>';

    html += '<div class="nt-sec-head"><span>Updates</span>' +
            (list.length ? '<span class="nt-clear" onclick="nwsbNotifClear()">Clear all</span>' : '') +
            '</div>';

    if (!list.length) {
      html +=
        '<div class="nt-empty">' +
          '<div class="nt-empty-icon"><svg viewBox="0 0 24 24" fill="none">' +
            '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" stroke="rgba(255,255,255,0.3)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' +
            '<path d="M13.7 21a2 2 0 0 1-3.4 0" stroke="rgba(255,255,255,0.3)" stroke-width="1.5" stroke-linecap="round"/>' +
          '</svg></div>' +
          '<div class="nt-empty-title">You are all caught up</div>' +
          '<div class="nt-empty-sub">New updates land here — orders, messages, offers, your routine and everything else you have switched on below.</div>' +
        '</div>';
    } else {
      html += '<div class="nt-list">';
      list.forEach(function (n, i) {
        html +=
          '<div class="nt-item' + (n.read ? '' : ' unread') + '" onclick="ntRead(' + i + ')">' +
            '<div class="nt-item-icon">' + (IC[n.type] || IC.support) + '</div>' +
            '<div class="nt-item-txt">' +
              '<div class="nt-item-title">' +
                (n.read ? '' : '<span class="nt-item-dot"></span>') + esc(n.title) +
              '</div>' +
              (n.body ? '<div class="nt-item-body">' + esc(n.body) + '</div>' : '') +
              '<div class="nt-item-meta">' + esc(labelOf(n.type)) + ' · ' + ago(n.at) + '</div>' +
            '</div>' +
          '</div>';
      });
      html += '</div>';
    }

    html += '<div class="nt-sec-head"><span>What you get</span></div>';
    GROUPS.forEach(function (g) {
      html += '<div class="nt-group-label">' + g.name + '</div><div class="nt-group">';
      g.items.forEach(function (it) {
        var isOn = on && off.indexOf(it.k) < 0;
        html +=
          '<div class="nt-row' + (on ? '' : ' nt-row-muted') + '">' +
            '<div class="nt-row-icon">' + (IC[it.k] || IC.support) + '</div>' +
            '<div class="nt-row-txt">' +
              '<div class="nt-row-title">' + it.label + '</div>' +
              '<div class="nt-row-sub">' + it.sub + '</div>' +
            '</div>' +
            '<div class="nt-sw' + (isOn ? ' on' : '') + '" onclick="ntToggle(\'' + it.k + '\')"><div class="nt-sw-knob"></div></div>' +
          '</div>';
      });
      html += '</div>';
    });

    body.innerHTML = html;
    if (window.nwsbPushRenderRow) { try { window.nwsbPushRenderRow(); } catch (e) {} }
  }
  window.nwsbNotifRender = render;

  window.ntToggleMaster = function () {
    lsSet(K_MASTER, master() ? '0' : '1');
    render(); haptic(28);
  };
  window.ntToggle = function (k) {
    // With everything muted, an individual switch has nothing to say — turn
    // the master back on rather than silently doing nothing.
    if (!master()) { lsSet(K_MASTER, '1'); render(); haptic(28); return; }
    var off = offSet(), i = off.indexOf(k);
    if (i >= 0) off.splice(i, 1); else off.push(k);
    lsSet(K_OFF, JSON.stringify(off));
    render(); haptic(28);
  };
  window.ntRead = function (i) {
    var a = feed();
    if (!a[i] || a[i].read) return;
    a[i].read = true;
    saveFeed(a); paintBadge(); render(); renderSheet();
  };

  /* ── The sheet ─────────────────────────────────────────────────────
     The bell opens this, not the settings page: a glass tab with the
     updates in it and a gear that leads through to the full page, the same
     shape as the Quick Links sheet. ── */
  var SHEET =
    '<div class="nt-overlay" id="ntOverlay" onclick="if(event.target===this)ntSheetClose()">' +
      '<div class="nt-sheet">' +
        '<div class="nt-sheet-head">' +
          '<div class="nt-sheet-txt">' +
            '<div class="nt-sheet-title">Notifications</div>' +
            '<div class="nt-sheet-sub" id="ntSheetSub">Everything NowssB has told you</div>' +
          '</div>' +
          '<button class="nt-hbtn nt-hbtn-gear" onclick="ntOpenSettings()" aria-label="Notification settings">' +
            '<svg viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round">' +
              '<circle cx="12" cy="12" r="3"/>' +
              '<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.6a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>' +
            '</svg>' +
          '</button>' +
          '<button class="nt-hbtn nt-hbtn-close" onclick="ntSheetClose()" aria-label="Close">' +
            '<svg viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="2.2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>' +
          '</button>' +
        '</div>' +
        '<div class="nt-sheet-scroll" id="ntSheetBody"><!-- rendered by JS --></div>' +
        '<div class="nt-sheet-foot">' +
          '<div class="nt-sheet-clear" onclick="nwsbNotifClear()">Clear all</div>' +
          '<div class="nt-sheet-manage" onclick="ntOpenSettings()">Manage</div>' +
        '</div>' +
      '</div>' +
    '</div>';

  function mountSheet() {
    if (document.getElementById('ntOverlay')) return;
    if (!document.body) return;
    var d = document.createElement('div');
    d.innerHTML = SHEET;
    document.body.appendChild(d.firstChild);
  }

  function renderSheet() {
    var body = document.getElementById('ntSheetBody');
    if (!body) return;
    var list = feed(), on = master();
    var sub = document.getElementById('ntSheetSub');
    if (sub) {
      var unread = list.filter(function (x) { return !x.read; }).length;
      sub.textContent = !on ? 'Muted — nothing is coming through'
                      : !list.length ? 'Nothing new right now'
                      : unread ? unread + ' unread of ' + list.length
                      : list.length + (list.length === 1 ? ' update' : ' updates');
    }
    if (!list.length) {
      body.innerHTML =
        '<div class="nt-empty">' +
          '<div class="nt-empty-icon"><svg viewBox="0 0 24 24" fill="none">' +
            '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" stroke="rgba(255,255,255,0.3)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' +
            '<path d="M13.7 21a2 2 0 0 1-3.4 0" stroke="rgba(255,255,255,0.3)" stroke-width="1.5" stroke-linecap="round"/>' +
          '</svg></div>' +
          '<div class="nt-empty-title">' + (on ? 'You are all caught up' : 'Notifications are off') + '</div>' +
          '<div class="nt-empty-sub">' + (on
            ? 'New updates land here — orders, messages, offers, your routine and everything else you have switched on.'
            : 'Turn them back on from the gear above to start receiving updates again.') + '</div>' +
        '</div>';
      return;
    }
    body.innerHTML = list.map(function (n, i) {
      return '<div class="nt-item' + (n.read ? '' : ' unread') + '" onclick="ntRead(' + i + ')">' +
               '<div class="nt-item-icon">' + (IC[n.type] || IC.support) + '</div>' +
               '<div class="nt-item-txt">' +
                 '<div class="nt-item-title">' +
                   (n.read ? '' : '<span class="nt-item-dot"></span>') + esc(n.title) +
                 '</div>' +
                 (n.body ? '<div class="nt-item-body">' + esc(n.body) + '</div>' : '') +
                 '<div class="nt-item-meta">' + esc(labelOf(n.type)) + ' · ' + ago(n.at) + '</div>' +
               '</div>' +
             '</div>';
    }).join('');
  }

  /* The bell opens the tab. */
  window.ntOpen = function () {
    mountSheet();
    renderSheet();
    var ov = document.getElementById('ntOverlay');
    requestAnimationFrame(function () { if (ov) ov.classList.add('open'); });
    haptic(28);
  };
  window.ntSheetClose = function () {
    var ov = document.getElementById('ntOverlay');
    if (ov) ov.classList.remove('open');
  };

  /* The gear leads through to the full settings page. */
  window.ntOpenSettings = function () {
    window.ntSheetClose();
    haptic(45);
    setTimeout(function () {
      var sc = document.getElementById('sub-notifications');
      if (!sc) return;
      render();
      sc.classList.add('open');
    }, 280);
  };
  window.ntClose = function () {
    var sc = document.getElementById('sub-notifications');
    if (sc) sc.classList.remove('open');
  };

  /* ── Producers ──────────────────────────────────────────────────────
     What actually puts notifications in the feed. Each one reads real app
     state and fires at most once a day, keyed on the day plus the thing it
     is about — so the trending word changing tomorrow sends a new one, but
     reopening the app ten times today does not send ten.

     Nothing here invents a fact. If the state a producer needs isn't there
     (no cart, no trending word yet), it sends nothing. ── */
  var K_SENT = 'nwsb_notif_sent';

  function today() {
    var d = new Date();
    return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
  }
  function sentKeys() {
    var raw; try { raw = JSON.parse(ls(K_SENT, '[]')); } catch (e) { raw = []; }
    return Array.isArray(raw) ? raw : [];
  }
  function once(key, n) {
    var keys = sentKeys();
    if (keys.indexOf(key) >= 0) return false;
    // The list only needs to remember today, so anything from another day goes.
    keys = keys.filter(function (k) { return k.indexOf(today() + '|') === 0; });
    keys.push(key);
    lsSet(K_SENT, JSON.stringify(keys));
    return window.nwsbNotify(n);
  }
  function txt(id) {
    var e = document.getElementById(id);
    return e ? (e.textContent || '').trim() : '';
  }

  function produce() {
    var day = today();

    // Today's Offer — the coupon rail rotates daily, so this is a real
    // daily event rather than a made-up one.
    once(day + '|offers', {
      type: 'offers',
      title: "Today's Offer is live",
      body: 'New coupons on the store — tap Today’s Offer to see what you can claim.'
    });

    // Trending — only if the home has actually resolved a word.
    var word = txt('nmh-trending-shop-word') || txt('nmh-trending-text');
    if (word) {
      once(day + '|trending|' + word, {
        type: 'trending',
        title: word + ' is trending today',
        body: 'The word healing the most people right now.'
      });
    }

    // Cart — only when something is genuinely sitting in it.
    var cart = window._nssCart;
    if (cart && cart.length) {
      once(day + '|cart|' + cart.length, {
        type: 'cart',
        title: cart.length + (cart.length === 1 ? ' word is' : ' words are') + ' waiting in your cart',
        body: 'Finish checking out before they are gone.'
      });
    }

    // Streak — only once there is a streak to talk about.
    var d = window._userDataCache || {};
    var streak = d.currentStreak || d.streakCount || 0;
    if (streak > 0) {
      once(day + '|streak|' + streak, {
        type: 'streak',
        title: streak + '-day streak',
        body: 'Practise today to keep it alive.'
      });
    }

    // Daily routine — the slot the clock is actually in.
    var h = new Date().getHours();
    var slot = h < 10 ? 'Morning' : h < 13 ? 'Midday' : h < 17 ? 'Afternoon' : h < 21 ? 'Evening' : 'Night';
    once(day + '|routine|' + slot, {
      type: 'routine',
      title: 'Your ' + slot + ' routine is ready',
      body: 'Open My Routines to start this session.'
    });
  }

  function boot() {
    paintBadge();
    // After first paint, so the home has had a chance to fill in the
    // trending word and the cart before the producers read them.
    setTimeout(function () { try { produce(); } catch (e) {} }, 2200);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
