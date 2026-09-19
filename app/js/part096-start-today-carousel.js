/* Start Today carousel is gone (website + WebView).
   The old rail jumped the page on a timer, and the layout engine stranded
   the unregistered section at the top of the home.

   This file only strips leftover nodes and restores Today's Practice title
   the previous script hid. It never injects a rail. */
(function () {
  'use strict';

  function strip() {
    var nodes = document.querySelectorAll('.st-today-sec, .pc-coach-sec, [data-st-today]');
    Array.prototype.forEach.call(nodes, function (n) {
      if (n && n.parentNode) n.parentNode.removeChild(n);
    });
    var title = document.getElementById('todayPracticeTitle');
    if (title) title.style.removeProperty('display');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', strip);
  } else {
    strip();
  }
  /* Late layout / banner injectors used to re-append registered siblings
     around a leftover rail. Run twice more so a stale cached copy cannot
     put the section back. */
  setTimeout(strip, 1200);
  setTimeout(strip, 3200);
})();
