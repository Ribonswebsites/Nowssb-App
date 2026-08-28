/* AUTH LOADER — video-free transition while Firebase resolves.
   The credential flow in firebase.module.js owns navigation and hides this
   layer on success or failure. This module only updates the wait message so
   authentication is never blocked by a media element. */
(function () {
  'use strict';

  var LONG_WAIT_MS = 9000;
  var loader, subEl, escalateTimer = null;

  function start() {
    if (!loader) return;
    if (subEl) subEl.textContent = 'Signing you in…';
    if (escalateTimer) clearTimeout(escalateTimer);
    escalateTimer = setTimeout(function () {
      if (loader.classList.contains('visible') && subEl) {
        subEl.textContent = 'Still signing you in, please wait';
      }
    }, LONG_WAIT_MS);
  }

  function stop() {
    if (escalateTimer) {
      clearTimeout(escalateTimer);
      escalateTimer = null;
    }
  }

  function init() {
    loader = document.getElementById('authLoader');
    if (!loader) return;
    subEl = document.getElementById('authLoaderSub');
    var wasVisible = loader.classList.contains('visible');
    if (wasVisible) start();
    new MutationObserver(function () {
      var isVisible = loader.classList.contains('visible');
      if (isVisible && !wasVisible) start();
      else if (!isVisible && wasVisible) stop();
      wasVisible = isVisible;
    }).observe(loader, { attributes: true, attributeFilter: ['class'] });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
