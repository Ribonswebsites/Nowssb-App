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
      { k: 'offers',    label: "Today's Offers",  sub: 'Coupons and limited-time discounts' }
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
    if (document.getElementById('sub-notifications') &&
        document.getElementById('sub-notifications').classList.contains('open')) render();
    return true;
  };

  window.nwsbNotifClear = function () {
    saveFeed([]);
    paintBadge();
    render();
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
            '<div class="nt-item-dot"></div>' +
            '<div class="nt-item-txt">' +
              '<div class="nt-item-title">' + esc(n.title) + '</div>' +
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
    saveFeed(a); paintBadge(); render();
  };

  /* Self-contained opener — openSub is chain-wrapped by a dozen files, so
     this page does not depend on any of them running its branch. */
  window.ntOpen = function () {
    var sc = document.getElementById('sub-notifications');
    if (!sc) return;
    render();
    sc.classList.add('open');
    haptic(28);
  };
  window.ntClose = function () {
    var sc = document.getElementById('sub-notifications');
    if (sc) sc.classList.remove('open');
  };

  function boot() { paintBadge(); }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

})();
