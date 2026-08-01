/* ══════════════════════════════════════════════════════════
   PRESENCE — how the studio knows who is actually using the app.

   "How many are logged in" cannot be answered from the users collection
   alone: signing in leaves no trace, and a document written at sign-up
   says nothing about whether that person opened the app this morning or
   last April. So each signed-in copy of the app stamps its own document
   with the time, and the studio reads recency.

   Deliberately cheap. A write only happens when somebody is signed in,
   only while the app is actually on screen, and at most once every five
   minutes — a phone left open all day costs a handful of writes, and a
   phone in a pocket costs none. Coming back to the app stamps
   immediately, because that is the moment the answer changes.

   It writes one field to the person's own document, which the rules
   already allow them to write. Nothing here needs new permissions.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var EVERY = 5 * 60 * 1000;
  var last = 0;
  var timer = null;

  function stamp() {
    var uid = window._currentUid;
    if (!uid || !window._fbSetDoc) return;
    var now = Date.now();
    if (now - last < EVERY) return;
    last = now;
    try {
      window._fbSetDoc(uid, {
        lastSeen: now,
        /* Enough to tell a phone from a desktop in the studio's list,
           and no more than that. */
        lastPlatform: /Android/i.test(navigator.userAgent) ? 'android'
                    : /iPhone|iPad|iPod/i.test(navigator.userAgent) ? 'ios'
                    : 'web',
        lastStandalone: !!(window.matchMedia &&
                           window.matchMedia('(display-mode: standalone)').matches)
      });
    } catch (e) { /* offline — the next tick will do it */ }
  }

  function tick() { if (!document.hidden) stamp(); }

  function start() {
    if (timer) return;
    tick();
    timer = setInterval(tick, 60 * 1000);   // checks often, writes rarely
  }

  /* Coming back to the app is exactly when the answer changes, so stamp
     then rather than waiting for the next interval. */
  document.addEventListener('visibilitychange', function () { if (!document.hidden) stamp(); });

  /* Sign-in happens after this file parses, so wait for a uid rather than
     assuming one. */
  if (window._currentUid) start();
  else {
    var n = 0;
    var wait = setInterval(function () {
      if (window._currentUid) { clearInterval(wait); start(); }
      else if (++n > 240) clearInterval(wait);   // ~4 minutes, then give up
    }, 1000);
  }

})();
