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

  /* Icons come from the section each kind belongs to, so a row in the feed
     reads as "this is from the store / your routine / Connect" at a glance.
     Image URLs are the ones those sections already use — nothing new. */
  function img(u) { return '<img loading="lazy" decoding="async" alt="" src="' + u + '">'; }
  function sv(d, extra) {
    return '<svg viewBox="0 0 24 24" fill="none">' +
           '<path d="' + d + '" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>' +
           (extra || '') + '</svg>';
  }
  var IC = {
    messages:  sv('M21 11.5a8.4 8.4 0 0 1-9 8.5 9.5 9.5 0 0 1-3.4-.6L3 21l1.7-4.6A8.3 8.3 0 0 1 3.5 11.5 8.4 8.4 0 0 1 12 3a8.4 8.4 0 0 1 9 8.5Z'),
    posts:     sv('M4 5.5A1.5 1.5 0 0 1 5.5 4h13A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5zM10 9.2l5 2.8-5 2.8z'),
    reactions: sv('M20.8 6.6a4.7 4.7 0 0 0-6.7 0L12 8.7l-2.1-2.1a4.7 4.7 0 1 0-6.7 6.7l8.8 8.8 8.8-8.8a4.7 4.7 0 0 0 0-6.7z'),
    follows:   sv('M16 20v-1.6a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4V20M9 10.5a3.6 3.6 0 1 0 0-7.2 3.6 3.6 0 0 0 0 7.2M19 8v6M22 11h-6'),
    orders:    img('https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png'),
    delivery:  sv('M2 6.5h10v9H2zM12 9.5h4l3 3.2v2.8h-7zM4.5 19a1.6 1.6 0 1 0 0-3.2 1.6 1.6 0 0 0 0 3.2M16.5 19a1.6 1.6 0 1 0 0-3.2 1.6 1.6 0 0 0 0 3.2'),
    cart:      sv('M2.5 3.5h2.3l1.9 10.5a1.2 1.2 0 0 0 1.2 1h8.2a1.2 1.2 0 0 0 1.2-.95L19 7.5H6', '<circle cx="9" cy="19" r="1.4" fill="currentColor"/><circle cx="17" cy="19" r="1.4" fill="currentColor"/>'),
    arrivals:  sv('M12 3l2.1 5.3L20 9.4l-4 4 1 5.6-5-2.8-5 2.8 1-5.6-4-4 5.8-1.1z'),
    offers:    img('https://res.cloudinary.com/eenvubod/image/upload/v1784915420/file_000000006b20820b84961321dcdcaaa8_be9meu.png'),
    trending:  sv('M3 17l5.5-5.5 3.5 3.5L21 6M15 6h6v6'),
    routine:   img('https://res.cloudinary.com/eenvubod/image/upload/v1784361579/file_00000000f740820ba6aaa761133e8889_fitm0p.png'),
    rx:        sv('M6 20V5.5A1.5 1.5 0 0 1 7.5 4h4a3.5 3.5 0 0 1 0 7H6M12 11l6 8'),
    streak:    sv('M12 2.5s5.5 4.4 5.5 9.3A5.5 5.5 0 0 1 12 21.5a5.5 5.5 0 0 1-5.5-9.7C6.5 6.9 12 2.5 12 2.5Z'),
    subscription: sv('M3 8.5l4 3 5-6.5 5 6.5 4-3-2 10.5H5z'),
    support:   sv('M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7M5.6 5.6l3.9 3.9M14.5 14.5l3.9 3.9M18.4 5.6l-3.9 3.9M9.5 14.5l-3.9 3.9')
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
      { k: 'streak',    label: 'Streak',          sub: 'Before your streak is about to break' }
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

  /* ── Badge on the header bell ──────────────────────────────────── */
  function paintBadge() {
    var el = document.getElementById('homeNotifBadge');
    if (!el) return;
    var n = feed().filter(function (x) { return !x.read; }).length;
    el.textContent = n > 99 ? '99+' : String(n);
    el.style.display = n ? 'flex' : 'none';
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
  }

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
