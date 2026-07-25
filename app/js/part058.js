/* ══════════════════════════════════════════════════════════
   AUTH LOADER — two videos alternate while #authLoader is visible, and
   the sub-line escalates from "a few seconds" to "a few minutes" the
   longer it stays open. Driven by a MutationObserver on the loader's
   own class list (toggled from firebase.module.js) so this stays fully
   decoupled from the auth flow itself.
   ══════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var SWAP_MS = 4500;       // how often the two videos alternate
  var LONG_WAIT_MS = 9000;  // how long before the message escalates

  var loader, videos, subEl;
  var swapTimer = null, escalateTimer = null;
  var activeIdx = 0;

  function swapVideo() {
    if (!videos || videos.length < 2) return;
    videos[activeIdx].classList.remove('active');
    activeIdx = (activeIdx + 1) % videos.length;
    videos[activeIdx].classList.add('active');
    var v = videos[activeIdx];
    if (v.paused) v.play().catch(function () {});
  }

  function start() {
    if (!loader) return;
    activeIdx = 0;
    videos.forEach(function (v, i) { v.classList.toggle('active', i === 0); });
    if (subEl) subEl.textContent = 'This might take a few seconds';
    if (swapTimer) clearInterval(swapTimer);
    swapTimer = setInterval(swapVideo, SWAP_MS);
    if (escalateTimer) clearTimeout(escalateTimer);
    escalateTimer = setTimeout(function () {
      if (subEl) subEl.textContent = 'This might take a few minutes, please wait';
    }, LONG_WAIT_MS);
  }

  function stop() {
    if (swapTimer) { clearInterval(swapTimer); swapTimer = null; }
    if (escalateTimer) { clearTimeout(escalateTimer); escalateTimer = null; }
  }

  function init() {
    loader = document.getElementById('authLoader');
    if (!loader) return;
    videos = Array.prototype.slice.call(loader.querySelectorAll('.auth-loader-video'));
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
