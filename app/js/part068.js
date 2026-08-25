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

  /* The two images Android lets us choose.

     ICON is the big one on the RIGHT, and ours is a PNG that is transparent
     in every pixel — the notification should read "NowssB · nowssb.com" and
     the words, with nothing beside them, the way Grok's and ChatGPT's do.
     Dropping the field does not achieve that: Chrome on Android answers a
     missing icon by generating one from the origin (a coloured circle with
     the first letter of nowssb.com) and hanging that on the right instead.
     An icon that exists and paints nothing is the only way to end up with
     an empty right-hand side.

     BADGE is the small one beside the app name on the left, and Android
     builds it from the ALPHA CHANNEL ONLY: it throws the colours away and
     paints the shape in a tint of its own choosing. So the badge is
     authored as a full disc with the word knocked out of it, which is the
     only way to get "solid circle, NowssB showing through" — a coloured
     PNG would come back as a flat silhouette. */
  var ICON  = 'assets/media/image/notif-blank-442eb067.png';
  var BADGE = 'assets/media/image/notif-badge-81c1b3e2.png';

  var K_ASKED = 'nwsb_push_asked';
  var K_PEND  = 'nwsb_push_pending';   // a tap that arrived before the app booted

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  /* Inside the Android shell there is no Notification API and no push
     service — the phone is reached through FCM instead, and app/js/part072.js
     installs itself here to answer for it. Everything below asks these two
     rather than the browser directly, so one notifications page serves both
     the web app and the shipped app. */
  function backend() { return window.nwsbNativePush || null; }

  function supported() {
    var b = backend();
    if (b) return b.state() !== 'unsupported';
    return 'Notification' in window && 'serviceWorker' in navigator;
  }
  function permission() {
    var b = backend();
    if (b) return b.state();
    if (!('Notification' in window)) return 'unsupported';
    return Notification.permission;
  }
  function granted() { return permission() === 'granted'; }

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
  /* The Android shell gets its taps from FCM rather than from the service
     worker, but they should land in the same places. */
  window.nwsbPushGo = go;

  /* ── Raising one ───────────────────────────────────────────────────
     Through the service worker registration rather than new Notification(),
     because that is the only form Android accepts from an installed page. */
  function show(n) {
    var b = backend();
    if (b && b.show) { try { b.show(n); } catch (e) {} return; }
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
    var b = backend();
    if (b) { lsSet(K_ASKED, '1'); return b.ask(); }
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
      permission: permission(),
      native: !!backend(),
      pushConfigured: !!VAPID_PUBLIC_KEY,
      subscribed: !!(window.nwsbPushSubscription || window.nwsbNativeToken)
    };
  };

  /* ── The row on the notifications page ─────────────────────────────
     The master switch above it is this app's own preference, kept in local
     storage, and it ships ON. That is the right default for the in-app feed
     — but it meant the one place that asked the phone for permission (the
     off→on transition of that switch, below) could never fire for anybody
     who had not first turned it off. So the permission had no way of ever
     being requested. This row is that way: it shows what the phone actually
     says and asks when it is asked to.

     part064.js leaves #ntPhoneRow empty and calls this after every render. */
  function permCopy() {
    if (!supported()) {
      return { cls: '', title: 'Not available on this browser',
               sub: 'This browser cannot show notifications. Install NowssB to your home screen, or open it in Chrome.',
               btn: '' };
    }
    var p = permission();
    if (p === 'granted') {
      return { cls: ' on', title: 'Notifications on this phone',
               sub: 'Allowed. NowssB can reach you here even when the app is closed.',
               btn: '<div class="nt-phone-btn" onclick="nwsbPushTest()">Send a test</div>' };
    }
    if (p === 'denied') {
      return { cls: ' nt-phone-blocked', title: 'Notifications on this phone',
               sub: 'Blocked. Your phone is refusing them — turn NowssB back on in your browser or app settings, then come back here.',
               btn: '' };
    }
    return { cls: '', title: 'Notifications on this phone',
             sub: 'Not on yet. Turn this on and your phone will show offers, your routine, your streak and everything else you have left switched on below.',
             btn: '<div class="nt-phone-btn" onclick="nwsbPushEnable()">Turn on</div>' };
  }

  window.nwsbPushRenderRow = function () {
    var el = document.getElementById('ntPhoneRow');
    if (!el) return;
    var c = permCopy();
    el.innerHTML =
      '<div class="nt-phone' + c.cls + '">' +
        '<div class="nt-phone-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' +
          '<rect x="6" y="2" width="12" height="20" rx="2.5"/><path d="M10.5 18.5h3"/>' +
        '</svg></div>' +
        '<div class="nt-phone-txt">' +
          '<div class="nt-phone-title">' + c.title + '</div>' +
          '<div class="nt-phone-sub">' + c.sub + '</div>' +
        '</div>' +
        c.btn +
      '</div>';
  };

  window.nwsbPushEnable = function () {
    /* Phone notifications while the app's own master switch is muted would
       be a contradiction, so this turns that on too. */
    try { if (localStorage.getItem('nwsb_notif_master') === '0') localStorage.setItem('nwsb_notif_master', '1'); } catch (e) {}
    try { if (navigator.vibrate) navigator.vibrate(28); } catch (e) {}
    var redraw = function () {
      if (window.nwsbNotifRender) { try { window.nwsbNotifRender(); } catch (e) {} }
      else window.nwsbPushRenderRow();
    };
    /* requestPermission() has to be reached from this tap without an await
       in between, or Android drops it as un-gestured — nwsbPushAsk() calls it
       synchronously, so only the redraw waits. Redraw once now so the master
       switch above reflects the flip immediately, and again when the phone
       answers; a prompt the reader never answers leaves the first one
       standing rather than a page that disagrees with itself. */
    var pending = window.nwsbPushAsk();
    redraw();
    pending.then(redraw, redraw);
  };

  /* Proof it works, on the phone in your hand. This is the in-app path
     (registration.showNotification), which is the same notification a push
     from the server draws — so if this appears, the phone side is right and
     anything left is the sending side. */
  window.nwsbPushTest = function () {
    if (!granted()) return;
    show({ type: 'support', title: 'NowssB', body: 'Notifications are on. This is what they will look like.' });
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
      saveSubscription(sub);
      /* Whatever else wants it can listen rather than this file needing to
         know every consumer. */
      try {
        window.dispatchEvent(new CustomEvent('nwsb-push-subscription', { detail: sub.toJSON() }));
      } catch (e) {}
    }).catch(function () { /* blocked, or no push service — nothing to do */ });
  }

  /* ── Keeping the subscription ──────────────────────────────────────
     A subscription is the only way to reach this phone, so it has to
     outlive the tab. It goes in Firestore under pushSubs, keyed by a hash
     of its own endpoint so the same phone re-registering overwrites rather
     than piling up duplicates. Only an admin can read the collection back
     (see firestore.rules); a person can only write their own.

     The Firestore SDK is an ES module and this file is not, so it is
     imported on demand — the same way part012.js reaches for it. */
  function endpointId(endpoint) {
    if (!(crypto && crypto.subtle)) return Promise.resolve(null);
    return crypto.subtle.digest('SHA-256', new TextEncoder().encode(endpoint))
      .then(function (buf) {
        var b = new Uint8Array(buf), s = '';
        for (var i = 0; i < b.length; i++) s += b[i].toString(16).padStart(2, '0');
        return s.slice(0, 40);
      });
  }

  function saveSubscription(sub) {
    var json;
    try { json = sub.toJSON(); } catch (e) { return; }
    if (!json || !json.endpoint || !json.keys) return;
    endpointId(json.endpoint).then(function (id) {
      if (!id) return;
      return import('https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js')
        .then(function (fs) {
          var db = window._db;
          if (!db) return;
          return fs.setDoc(fs.doc(db, 'pushSubs', id), {
            endpoint: json.endpoint,
            keys: { p256dh: json.keys.p256dh, auth: json.keys.auth },
            uid: window._currentUid || null,
            ua: (navigator.userAgent || '').slice(0, 180),
            updatedAt: Date.now()
          }, { merge: true });
        });
    }).catch(function () { /* offline or not signed in — it retries next load */ });
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
