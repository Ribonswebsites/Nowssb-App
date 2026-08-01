/* ══════════════════════════════════════════════════════════
   THE ANDROID SHELL — what changes when this page is running inside the
   app on Google Play rather than in a browser tab.

   Everything the app does still runs here: it is the same HTML, the same
   CSS, the same JS, loaded from assets bundled into the APK instead of
   over the network. Three things are different, and this file is all three.

   1. Notifications. Android's WebView has no Notification API, no service
      worker and no push service, so nothing in part068.js can reach the
      phone on its own. Firebase Cloud Messaging can, through the native
      layer, and Capacitor's PushNotifications plugin is the door. This
      file installs itself as part068.js's backend, so the notifications
      page, the master switch and the sixteen per-kind switches all keep
      working unchanged and simply drive a different pipe underneath.

      The token FCM hands back goes into the same pushSubs collection the
      web subscriptions go into, written as `fcm:<token>` so that one
      admin screen and one /api/push endpoint serve both.

   2. The hardware back button. A browser gives us popstate and
      app/js/part049.js already traps it; the shell gives us a Capacitor
      event instead. Same handler, so back closes the topmost thing that is
      open and only leaves the app from the home screen.

   3. The status bar, which the shell draws itself and which would
      otherwise sit as a white strip above a very dark app.

   In a browser none of this exists and the whole file does nothing — it
   returns before touching anything. It is safe to ship everywhere, and it
   has to be, because the same build serves the website and the app.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var C = window.Capacitor;
  if (!C || typeof C.isNativePlatform !== 'function' || !C.isNativePlatform()) return;

  var P = C.Plugins || {};
  var Push = P.PushNotifications;
  var App  = P.App;
  var Bar  = P.StatusBar;

  /* Anything that wants to style for the shell can hang off this rather
     than sniffing the user agent. */
  document.documentElement.classList.add('nwsb-native');
  window.nwsbIsNative = true;

  function ls(k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }
  function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) {} }

  /* ── 3. Status bar ─────────────────────────────────────────────────── */
  if (Bar) {
    try {
      Bar.setStyle({ style: 'DARK' });          // light glyphs, for a dark app
      Bar.setBackgroundColor({ color: '#060c18' });
    } catch (e) {}
  }

  /* ── 2. Hardware back ──────────────────────────────────────────────── */
  if (App && App.addListener) {
    App.addListener('backButton', function (ev) {
      var closed = false;
      try { closed = !!(window.nwsbCloseTop && window.nwsbCloseTop()); } catch (e) {}
      if (closed) return;
      /* Nothing was open. If we are not on a home screen, go to one rather
         than dropping the reader out of the app from the middle of it. */
      var onHome = ['home', 'home-nm'].some(function (id) {
        var el = document.getElementById(id);
        return el && el.classList.contains('active');
      });
      if (!onHome && typeof window.goTo === 'function') {
        try { window.goTo(ls('nwsb_home_mode', 'home') === 'nm' ? 'home-nm' : 'home'); return; } catch (e) {}
      }
      if (ev && ev.canGoBack && typeof window.history !== 'undefined') { window.history.back(); return; }
      try { App.exitApp(); } catch (e) {}
    });
  }

  /* ── 1. Notifications through FCM ──────────────────────────────────── */
  if (!Push) return;

  var K_PERM  = 'nwsb_native_perm';    // last answer, so the page can draw before the plugin replies
  var K_PEND  = 'nwsb_push_pending';   // shared with part068.js

  var state = ls(K_PERM, 'default');
  if (state !== 'granted' && state !== 'denied') state = 'default';

  function setState(s) {
    state = s;
    lsSet(K_PERM, s);
    if (window.nwsbPushRenderRow) { try { window.nwsbPushRenderRow(); } catch (e) {} }
  }

  /* Capacitor reports 'prompt', 'prompt-with-rationale', 'granted' or
     'denied'; part068.js speaks the web's three. */
  function normalise(r) {
    var v = r && r.receive;
    if (v === 'granted') return 'granted';
    if (v === 'denied') return 'denied';
    return 'default';
  }

  function register() {
    try { Push.register(); } catch (e) {}
  }

  /* ── Keeping the token ─────────────────────────────────────────────
     Same collection, same shape of id (a hash, so re-registering the same
     phone overwrites rather than piling up), same rules. `endpoint` is
     filled with `fcm:<token>` because that is the handle the studio and
     /api/push already pass around — an FCM send is just a different way of
     delivering to it. */
  function tokenId(token) {
    if (!(window.crypto && crypto.subtle)) return Promise.resolve(null);
    return crypto.subtle.digest('SHA-256', new TextEncoder().encode(token))
      .then(function (buf) {
        var b = new Uint8Array(buf), s = '';
        for (var i = 0; i < b.length; i++) s += b[i].toString(16).padStart(2, '0');
        return s.slice(0, 40);
      });
  }

  function saveToken(token) {
    window.nwsbNativeToken = token;
    tokenId(token).then(function (id) {
      if (!id) return;
      return import('https://www.gstatic.com/firebasejs/11.8.1/firebase-firestore.js')
        .then(function (fs) {
          var db = window._db;
          if (!db) return;
          return fs.setDoc(fs.doc(db, 'pushSubs', id), {
            endpoint: 'fcm:' + token,
            fcmToken: token,
            platform: 'android-native',
            uid: window._currentUid || null,
            ua: (navigator.userAgent || '').slice(0, 180),
            updatedAt: Date.now()
          }, { merge: true });
        });
    }).catch(function () { /* offline or signed out — the next launch retries */ });
  }

  Push.addListener('registration', function (t) {
    if (t && t.value) { setState('granted'); saveToken(t.value); }
  });
  Push.addListener('registrationError', function () { /* nothing to do — the row stays as it is */ });

  /* Arriving while the app is open. Android does not draw a notification
     for a foreground message, so route it into the app's own feed, which is
     where a running app should show it anyway. part064.js still applies the
     master switch and the per-kind switches. */
  Push.addListener('pushNotificationReceived', function (n) {
    if (!n) return;
    var d = n.data || {};
    if (!window.nwsbNotify) return;
    try {
      window.nwsbNotify({
        type: d.type || 'support',
        title: n.title || d.title || 'NowssB',
        body: n.body || d.body || ''
      });
    } catch (e) {}
  });

  /* Tapping one. If the app was cold the screens may not exist yet, so park
     it the same way part068.js parks a service-worker tap. */
  Push.addListener('pushNotificationActionPerformed', function (a) {
    var d = (a && a.notification && a.notification.data) || {};
    var type = d.type || '';
    if (!type) return;
    if (document.readyState === 'complete' && window.nwsbPushGo) {
      setTimeout(function () { try { window.nwsbPushGo(type); } catch (e) {} }, 60);
    } else {
      lsSet(K_PEND, type);
    }
  });

  /* ── The backend part068.js asks ───────────────────────────────────── */
  window.nwsbNativePush = {
    state: function () { return state; },

    ask: function () {
      return Push.checkPermissions().then(function (r) {
        var cur = normalise(r);
        if (cur === 'granted') { setState('granted'); register(); return 'granted'; }
        if (cur === 'denied') { setState('denied'); return 'denied'; }
        return Push.requestPermissions().then(function (r2) {
          var after = normalise(r2);
          setState(after);
          if (after === 'granted') register();
          return after;
        });
      }).catch(function () { return state; });
    },

    /* An in-app notification while the shell is in the foreground has
       nowhere useful to go — Android will not draw one for the app that is
       already on screen, and the app's own feed already has it. Returning
       without drawing keeps part068.js from falling through to the web
       path, which does not exist here. */
    show: function () {}
  };

  /* Already allowed from a previous launch: re-register, because FCM tokens
     rotate and the stored one may be stale. */
  Push.checkPermissions().then(function (r) {
    var cur = normalise(r);
    if (cur !== state) setState(cur);
    if (cur === 'granted') register();
  }).catch(function () {});

  /* part068.js drew its row before this file installed the backend, so ask
     it to draw again now that the answer has changed. */
  if (window.nwsbPushRenderRow) { try { window.nwsbPushRenderRow(); } catch (e) {} }

})();
