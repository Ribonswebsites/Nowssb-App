/* ══════════════════════════════════════════════════════════
   PHONE NOTIFICATIONS — the app's own notifications, raised on the phone.

   app/js/part064.js already owns what a notification IS: sixteen kinds
   grouped as the app is grouped, a master switch, a switch per kind, and a
   feed behind the bell. Everything went into that feed and stopped there —
   nothing ever reached the phone.

   This file is the last step of that journey. It wraps nwsbNotify(), so
   anything the app already sends now also appears in the phone's own
   notification tray, with the app icon and the app name, exactly the way
   any installed app's notifications look. The existing switches still
   decide what gets sent: a kind that is off is dropped inside nwsbNotify()
   before this ever sees it, so there is one set of preferences, not two.

   What this cannot do, and why
   ----------------------------
   A notification can only arrive while something is running. With the app
   fully closed, the only thing that can wake it is a push from a server,
   and a browser will only accept a push that is signed with the key pair
   the subscription was made against. The public half of that pair goes in
   VAPID_PUBLIC_KEY below; the private half lives on a server that does the
   sending. Until both exist, this file raises notifications while the app
   is open or recently used, which covers everything the app itself decides
   — a routine falling due, an offer, a streak about to break. The push path
   is written and waiting: fill the key in and subscriptions start being
   made, and sw.js already knows what to do with what arrives.

   The look of the notification is the phone's, not ours. Android draws the
   badge and the app name across the top and the title and body underneath;
   a page cannot draw inside that. The two images we choose are `icon`, the
   large one, and `badge`, the small monochrome silhouette in the status
   bar — both below.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  /* The Web Push certificate's PUBLIC key, from Firebase console → Project
     settings → Cloud Messaging → Web Push certificates. Public is the point
     of it: a browser needs it to make a subscription, and it is worth
     nothing on its own. The private half of the pair signs the sends and
     belongs on a server — it must never appear in this file or any other
     the app serves. */
  var VAPID_PUBLIC_KEY = 'BKOj_da2V8ebcvZidlL94VdVKtsbNXos-f41Sd_sS9V918Ex3TH210NOMKndTb5FX6k9NGfa2X3U6fgjtBdVXK4';

  var ICON  = './assets/icons/app-icon-192.png';
  var BADGE = './assets/icons/notif-badge.png';

  var K_ASKED = 'nwsb_push_asked';
  var K_PEND  = 'nwsb_push_pending';   // a tap that arrived before the app booted

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  function supported() {
    return 'Notification' in window && 'serviceWorker' in navigator;
  }
  function granted() {
    return supported() && Notification.permission === 'granted';
  }

  /* ── Where each kind of notification leads ──────────────────────────
     Keyed by the kinds part064.js already defines. Every entry is guarded:
     if a screen is not there, tapping just opens the app rather than
     throwing. ── */
  var GO = {
    offers:       function () { openSub('offers'); },
    arrivals:     function () { openSub('nowssb-store'); },
    trending:     function () { openSub('nowssb-store'); },
    orders:       function () { openSub('orders'); },
    delivery:     function () { openSub('orders'); },
    cart:         function () { window.nssOpenCart(); },
    routine:      function () { openSub('routines'); },
    rx:           function () { openSub('ai-prescription'); },
    streak:       function () { openSub('streak'); },
    reader:       function () { openSub('reader'); },
    subscription: function () { window.SS.open('subscription'); },
    messages:     function () { openSub('social'); },
    posts:        function () { openSub('social'); },
    reactions:    function () { openSub('social'); },
    follows:      function () { openSub('social'); },
    support:      function () { openSub('profile'); }
  };

  function go(type) {
    var f = GO[type];
    if (!f) return;
    try { f(); } catch (e) { /* screen not on this build — leave the app where it is */ }
  }

  /* ── Raising one ───────────────────────────────────────────────────
     Through the service worker registration rather than new Notification(),
     because that is the only form Android accepts from an installed page. */
  function show(n) {
    if (!granted() || !navigator.serviceWorker) return;
    navigator.serviceWorker.ready.then(function (reg) {
      if (!reg || !reg.showNotification) return;
      reg.showNotification(String(n.title || 'NowssB'), {
        body: String(n.body || ''),
        icon: ICON,
        badge: BADGE,
        tag: n.type || 'nowssb',
        renotify: true,
        data: { type: n.type || '', url: './' },
        vibrate: [28, 40, 28]
      }).catch(function () {});
    }).catch(function () {});
  }

  /* ── Asking ────────────────────────────────────────────────────────
     Only ever off the back of something the reader did — a permission
     prompt fired on load is the fastest way to be blocked for good. */
  window.nwsbPushAsk = function () {
    if (!supported()) return Promise.resolve('unsupported');
    if (Notification.permission !== 'default') {
      if (granted()) subscribe();
      return Promise.resolve(Notification.permission);
    }
    lsSet(K_ASKED, '1');
    return Notification.requestPermission().then(function (p) {
      if (p === 'granted') subscribe();
      return p;
    }).catch(function () { return 'default'; });
  };

  window.nwsbPushStatus = function () {
    return {
      supported: supported(),
      permission: supported() ? Notification.permission : 'unsupported',
      pushConfigured: !!VAPID_PUBLIC_KEY
    };
  };

  /* ── Push subscription ─────────────────────────────────────────────
     Only attempted once a key is configured. The subscription is what a
     server needs in order to send anything; it is handed to
     window.nwsbPushSubscription and to a hook the backend can pick up. */
  function urlB64ToUint8Array(base64String) {
    var padding = '='.repeat((4 - base64String.length % 4) % 4);
    var base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    var raw = atob(base64);
    var out = new Uint8Array(raw.length);
    for (var i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
    return out;
  }

  function subscribe() {
    if (!VAPID_PUBLIC_KEY || !granted() || !navigator.serviceWorker) return;
    navigator.serviceWorker.ready.then(function (reg) {
      if (!reg || !reg.pushManager) return;
      return reg.pushManager.getSubscription().then(function (existing) {
        if (existing) return existing;
        return reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlB64ToUint8Array(VAPID_PUBLIC_KEY)
        });
      });
    }).then(function (sub) {
      if (!sub) return;
      window.nwsbPushSubscription = sub;
      /* Whatever stores subscriptions can listen for this rather than this
         file needing to know the endpoint. */
      try {
        window.dispatchEvent(new CustomEvent('nwsb-push-subscription', { detail: sub.toJSON() }));
      } catch (e) {}
    }).catch(function () { /* blocked, or no push service — nothing to do */ });
  }

  /* ── Wrapping the app's own notifier ───────────────────────────────
     part064.js decides whether a notification is wanted at all; it returns
     true only for the ones it kept. Those are the ones worth raising. */
  function wrapNotify() {
    if (!window.nwsbNotify || window.nwsbNotify.__push) return false;
    var inner = window.nwsbNotify;
    var wrapped = function (n) {
      var kept = inner.apply(this, arguments);
      if (kept) show(n);
      return kept;
    };
    wrapped.__push = 1;
    window.nwsbNotify = wrapped;
    return true;
  }

  /* Turning the master switch on is the reader asking for notifications in
     as many words, which is the right moment to ask the phone too. */
  function wrapMaster() {
    if (!window.ntToggleMaster || window.ntToggleMaster.__push) return false;
    var inner = window.ntToggleMaster;
    var wrapped = function () {
      var before = ls('nwsb_notif_master', '1') !== '0';
      inner.apply(this, arguments);
      var after = ls('nwsb_notif_master', '1') !== '0';
      if (!before && after) window.nwsbPushAsk();
      return undefined;
    };
    wrapped.__push = 1;
    window.ntToggleMaster = wrapped;
    return true;
  }

  /* part064.js and the notifications page are set up by their own files
     after this one parses, so keep trying until both are there. */
  function bind() {
    var a = wrapNotify(), b = wrapMaster();
    return a && b;
  }
  if (!bind()) {
    var tries = 0;
    var t = setInterval(function () {
      if (bind() || ++tries > 40) clearInterval(t);
    }, 250);
  }

  /* ── Tapping one ───────────────────────────────────────────────────
     A running app is told directly. One opened from cold cannot be, so the
     type is parked and read back here once the screens exist. */
  if (navigator.serviceWorker) {
    navigator.serviceWorker.addEventListener('message', function (e) {
      var d = e.data;
      if (!d || d.nwsb !== 'notification-click') return;
      if (document.readyState === 'complete') setTimeout(function () { go(d.type); }, 60);
      else lsSet(K_PEND, d.type || '');
    });
  }
  window.addEventListener('load', function () {
    var pend = ls(K_PEND, '');
    if (!pend) return;
    lsSet(K_PEND, '');
    setTimeout(function () { go(pend); }, 700);
  });

  /* Already allowed from a previous visit — make sure a subscription
     exists, in case the key was added after permission was given. */
  if (granted()) subscribe();

})();
