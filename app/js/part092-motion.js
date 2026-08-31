/* NowssB Motion System
 * A compact, GPU-friendly motion layer shared by the WebView shell.
 * It observes existing screen/open state instead of replacing feature routing.
 */
(function () {
  'use strict';

  var reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var ENTER_CLASS = 'nwsb-motion-enter';
  var scrollHosts = [];
  var raf = 0;

  function each(list, fn) {
    Array.prototype.forEach.call(list || [], fn);
  }

  function revealChildren(root) {
    if (reduced || !root) return;
    root.classList.remove(ENTER_CLASS);
    root.offsetWidth;
    root.classList.add(ENTER_CLASS);
    var children = root.children || [];
    each(children, function (child, index) {
      child.style.setProperty('--nwsb-motion-index', String(Math.min(index, 8)));
    });
    window.setTimeout(function () {
      if (root) root.classList.remove(ENTER_CLASS);
    }, 620);
  }

  function markOverlay(el, open) {
    if (!el) return;
    if (open) {
      if (el.getAttribute('data-nwsb-motion-opened') !== '1') {
        el.setAttribute('data-nwsb-motion-opened', '1');
        revealChildren(el);
      }
      el.setAttribute('data-nwsb-motion-state', 'open');
    } else {
      el.removeAttribute('data-nwsb-motion-opened');
      el.setAttribute('data-nwsb-motion-state', 'closed');
    }
  }

  function findScrollHost(root) {
    if (!root) return null;
    var candidates = [];
    function consider(el) {
      var style = window.getComputedStyle(el);
      if ((style.overflowY === 'auto' || style.overflowY === 'scroll') && el.scrollHeight > el.clientHeight + 8) {
        candidates.push(el);
      }
    }
    consider(root);
    each(root.querySelectorAll('*'), consider);
    candidates.sort(function (a, b) { return (b.scrollHeight - b.clientHeight) - (a.scrollHeight - a.clientHeight); });
    return candidates[0] || null;
  }

  function attachScroll(root) {
    if (!root || root.getAttribute('data-nwsb-motion-scroll') === '1') return;
    var host = findScrollHost(root);
    if (!host) return;
    root.setAttribute('data-nwsb-motion-scroll', '1');
    host.classList.add('nwsb-motion-scroll-host');
    var previous = host.scrollTop;
    var queued = false;
    function update() {
      queued = false;
      var current = host.scrollTop;
      var delta = current - previous;
      previous = current;
      if (Math.abs(delta) < 0.5) return;
      root.classList.toggle('nwsb-scroll-forward', delta > 0);
      root.classList.toggle('nwsb-scroll-back', delta < 0);
      root.style.setProperty('--nwsb-scroll-y', String(Math.max(0, Math.min(current, 480))));
    }
    host.addEventListener('scroll', function () {
      if (queued) return;
      queued = true;
      window.requestAnimationFrame(update);
    }, { passive: true });
    scrollHosts.push({ root: root, host: host });
  }

  function scan() {
    each(document.querySelectorAll('.sub-screen'), function (el) {
      markOverlay(el, el.classList.contains('open'));
    });
    each(document.querySelectorAll('#home, #home-nm'), function (root) {
      attachScroll(root);
      if (root.classList.contains('active') && root.getAttribute('data-nwsb-motion-active') !== '1') {
        root.setAttribute('data-nwsb-motion-active', '1');
        revealChildren(root);
      }
    });
  }

  function observe() {
    if (!document.body || !window.MutationObserver) return;
    var observer = new MutationObserver(function (mutations) {
      var needsScan = false;
      each(mutations, function (mutation) {
        if (mutation.type === 'childList') needsScan = true;
        if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
          var target = mutation.target;
          if (target.matches && target.matches('.sub-screen')) {
            markOverlay(target, target.classList.contains('open'));
          }
          if (target.id === 'home' || target.id === 'home-nm') {
            if (target.classList.contains('active')) {
              if (target.getAttribute('data-nwsb-motion-active') !== '1') {
                target.setAttribute('data-nwsb-motion-active', '1');
                revealChildren(target);
              }
            } else {
              target.removeAttribute('data-nwsb-motion-active');
            }
            attachScroll(target);
          }
        }
      });
      if (needsScan) {
        if (raf) window.cancelAnimationFrame(raf);
        raf = window.requestAnimationFrame(function () { raf = 0; scan(); });
      }
    });
    observer.observe(document.body, { subtree: true, childList: true, attributes: true, attributeFilter: ['class'] });
  }

  function init() {
    scan();
    observe();
    document.documentElement.classList.add('nwsb-motion-ready');
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init, { once: true });
  else init();
})();
