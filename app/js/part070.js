/* ══════════════════════════════════════════════════════════
   THE STUDIO DOOR — how admin.html is reached from the app.

   Five taps on the copyright line at the foot of either home, inside three
   seconds. Nothing marks it, nothing hints at it, and a stray tap does
   nothing: the count resets the moment the run is broken.

   It is a door, not a lock. Anyone can type /admin.html into a browser and
   land on the same sign-in screen — being hidden is convenience, not
   security. What actually protects the studio is the sign-in and the admin
   list behind it, and behind that the rules in firestore.rules, which are
   the only thing a stranger cannot argue with.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var NEEDED = 5;
  var WINDOW_MS = 3000;
  var count = 0;
  var first = 0;

  function open() {
    try { if (navigator.vibrate) navigator.vibrate([30, 50, 30]); } catch (e) {}
    location.href = './admin.html';
  }

  function tap() {
    var now = Date.now();
    if (!count || now - first > WINDOW_MS) { count = 0; first = now; }
    count++;
    if (count >= NEEDED) { count = 0; open(); }
  }

  /* Delegated, because both footers are re-ordered by the layout editor and
     one of them may not exist yet when this runs. */
  document.addEventListener('click', function (e) {
    var t = e.target;
    if (t && t.closest && t.closest('.studio-door')) tap();
  });

  /* For anyone who would rather just say so. */
  window.nwsbOpenStudio = open;

})();
