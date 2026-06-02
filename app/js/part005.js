
(function() {
  function wireSlBtn() {
    // ── Enter / Open Library button ──
    var btn = document.getElementById('slEnterBtn');
    if (btn) {
      function doEnter(e) {
        if (e && e.preventDefault) e.preventDefault();
        // Route through slEnterLibrary so any hooks (e.g. pgGuide) fire correctly
        var fn = window.slEnterLibrary || function() {
          var intro = document.getElementById('slIntroPage');
          if (intro) intro.classList.add('sl-intro-hidden');
          setTimeout(function() {
            var r = window.slRender || (typeof slRender === 'function' && slRender);
            if (r) r();
          }, 60);
        };
        fn();
      }
      btn.addEventListener('click', doEnter);
      btn.addEventListener('touchend', doEnter);
    }

    // ── Tab buttons: wire directly so inline onclick isn't needed ──
    var tabIds = ['sentences', 'words', 'purchased'];
    tabIds.forEach(function(tabName) {
      var tabBtn = document.getElementById('slTab-' + tabName);
      if (!tabBtn) return;
      // Remove existing onclick to prevent double-fire
      tabBtn.removeAttribute('onclick');
      function doTab(e) {
        if (e && e.preventDefault) e.preventDefault();
        // Update active state immediately for instant feedback
        tabIds.forEach(function(t) {
          var b = document.getElementById('slTab-' + t);
          if (b) b.classList.toggle('active', t === tabName);
        });
        // Call the real tab switch function
        var fn = window.slSetTab || (typeof slSetTab === 'function' && slSetTab);
        if (fn) { fn(tabName); }
      }
      tabBtn.addEventListener('click', doTab);
      tabBtn.addEventListener('touchend', doTab);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', wireSlBtn);
  } else {
    wireSlBtn();
  }
})();
