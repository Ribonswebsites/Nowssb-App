/* ══════════════════════════════════════════════════════════
   AUTH BUTTONS THAT SURVIVE A SLOW FIREBASE.

   Every button on the login screen is an inline `onclick="fbGoogleLogin()"`.
   Those functions are assigned by app/js/firebase.module.js, which is a
   `type="module"` script — deferred by definition, and it imports the SDK
   over the network before it assigns anything.

   So there is a window, from first paint until the SDK lands, where the
   login screen is fully drawn and every button on it throws
   `ReferenceError: fbGoogleLogin is not defined` into the console and does
   nothing visible. On a fast connection that window is short enough not to
   notice. On a slow one — or when the SDK is blocked outright — the login
   screen is simply dead, with no spinner, no message, and nothing on
   screen to say why.

   This file runs first (a classic script, so it executes before any
   deferred module) and puts a stub behind each name. A tap during the gap
   is remembered rather than thrown away: the stub waits for the real
   function to be assigned and then calls it with the same arguments, so
   the sign-in the reader asked for still happens a moment later. If it
   never arrives, they are told that instead of being left tapping.

   The moment firebase.module.js assigns the real function it simply
   replaces the stub — there is nothing to unwind and no handoff to get
   wrong.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var NAMES = ['fbGoogleLogin', 'fbEmailLogin', 'fbSignUp', 'fbMagicLink', 'fbSignOut'];
  var WAIT_MS = 15000;     // how long a tap keeps waiting before we admit defeat
  var TICK = 120;

  function note(msg, bad) {
    var el = document.getElementById('nwsbAuthNote');
    if (!el) {
      el = document.createElement('div');
      el.id = 'nwsbAuthNote';
      el.className = 'nwsb-auth-note';
      var host = document.querySelector('#login .nm-btn-list') ||
                 document.querySelector('#login .nm-wrap') || document.body;
      host.insertBefore(el, host.firstChild);
    }
    el.textContent = msg;
    el.classList.toggle('bad', !!bad);
    el.classList.add('show');
  }
  function clearNote() {
    var el = document.getElementById('nwsbAuthNote');
    if (el) el.classList.remove('show');
  }
  window.nwsbAuthNote = note;

  /* A stub is only ever installed over a name nothing has claimed yet, so
     this can never shadow the real thing. */
  NAMES.forEach(function (name) {
    if (typeof window[name] === 'function') return;

    var stub = function () {
      var args = arguments, self = this, waited = 0;
      note('Connecting to NowssB…');

      (function poll() {
        var fn = window[name];
        /* `fn !== stub` is the whole test: the module assigns over the
           name, so the first time it is something other than us, it is the
           real one. */
        if (typeof fn === 'function' && fn !== stub) {
          clearNote();
          try { return fn.apply(self, args); } catch (e) { note('Sign-in failed. Please try again.', 1); }
          return;
        }
        waited += TICK;
        if (waited >= WAIT_MS) {
          note('Could not reach the sign-in service. Check your connection and try again.', 1);
          return;
        }
        setTimeout(poll, TICK);
      })();
    };
    stub._nwsbStub = 1;
    window[name] = stub;
  });

  /* If the SDK never lands at all, say so once rather than waiting for
     somebody to tap a dead button and find out. */
  setTimeout(function () {
    var fn = window.fbGoogleLogin;
    if (typeof fn === 'function' && fn._nwsbStub) {
      var login = document.getElementById('login');
      if (login && login.classList.contains('active')) {
        note('Still connecting to the sign-in service…');
      }
    }
  }, 8000);

})();

/* ══════════════════════════════════════════════════════════
   ONE NAME, EVERYWHERE.

   The app kept asking four different objects for the reader's name and
   each caller picked a different one, so the greeting could say "Healer"
   while the profile clearly showed a name — they were not reading the same
   field. This is the single answer: every field the name can land in, in
   the order it should be trusted, with the profile's own saved value
   first because that is the one the reader typed.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';
  window.nwsbUserName = function (fallback) {
    var u = window._userDataCache || {};
    var cu = window._currentUser || {};
    var ls = '';
    try { ls = localStorage.getItem('nb_display_name') || localStorage.getItem('nwsb_name') || ''; } catch (e) {}
    var n = u.displayName || u.name || u.fullName || ls || window._userName ||
            cu.displayName || '';
    n = String(n || '').trim();
    /* An email is a last resort and only its local part — "sanjay@gmail.com"
       greeting somebody as sanjay@gmail.com reads like a bug. */
    if (!n && cu.email) n = String(cu.email).split('@')[0];
    return n || (fallback === undefined ? 'Practitioner' : fallback);
  };
})();
