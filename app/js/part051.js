/* ── Background video pre-warmer ──────────────────────────────────────────
   All the decorative/looping <video> tags across the app now load with
   preload="none" so they never compete with the initial page load. This
   script quietly downloads each one into Cache Storage (NOT the device's
   visible Downloads/Gallery — a private per-site cache only the app can
   read) once the app has gone idle, so that by the time the user actually
   opens a screen with one of these videos, sw.js can hand it back instantly
   from cache instead of hitting the network. If a screen is opened before
   its video finishes warming, playback just falls back to a normal network
   load exactly like before — this never blocks or breaks anything, it only
   helps once it's done.
   Respects Data Saver / slow connections: skips entirely rather than
   burning someone's mobile data in the background without asking. ── */
(function () {
  if (typeof caches === 'undefined') return;

  var VIDEO_CACHE = 'nowssb-media-precache-v1';

  function shouldSkip() {
    var c = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
    if (!c) return false;
    if (c.saveData) return true;
    if (c.effectiveType && /2g/.test(c.effectiveType)) return true;
    return false;
  }

  function collectVideoUrls() {
    var urls = [];
    document.querySelectorAll('video').forEach(function (v) {
      var src = v.getAttribute('src');
      if (src) urls.push(src);
      v.querySelectorAll('source[src]').forEach(function (s) { urls.push(s.getAttribute('src')); });
    });
    // Practice player builds its <video> elements dynamically per word, so
    // none of them exist in the DOM yet at this point — nowssb-player.js
    // exposes the full pre-transformed list separately for exactly this.
    if (window.NWSB_PLAYER_VIDEO_URLS) urls = urls.concat(window.NWSB_PLAYER_VIDEO_URLS);
    // de-dupe — several screens intentionally reuse the same background video
    return urls.filter(function (u, i) { return u && urls.indexOf(u) === i; });
  }

  function warmOne(cache, url) {
    return cache.match(url).then(function (existing) {
      if (existing) return; // already warmed in a previous session
      return fetch(url, { mode: 'cors' })
        .then(function (res) { if (res && res.ok) return cache.put(url, res); })
        .catch(function () { /* cross-origin/network hiccup — just skip it, no retry */ });
    });
  }

  var warmedUrls = {}; // every URL we've ever kicked off a warmOne() for — never re-queue it

  function warmAll(urls) {
    var fresh = urls.filter(function (u) { return !warmedUrls[u]; });
    if (!fresh.length) return;
    fresh.forEach(function (u) { warmedUrls[u] = true; });
    var cache;
    var i = 0;
    function next() {
      if (i >= fresh.length) return;
      var url = fresh[i++];
      warmOne(cache, url).catch(function () {}).then(function () {
        // Still staggered (never fire dozens of fetches in the same tick and
        // choke whatever the user is actively doing), but short — the goal
        // is "download everything soon", not "trickle it in over minutes".
        setTimeout(next, 800);
      });
    }
    caches.open(VIDEO_CACHE).then(function (c) { cache = c; next(); });
  }

  function start() {
    if (shouldSkip()) return;
    var urls = collectVideoUrls();
    if (urls.length) warmAll(urls);
  }

  var idle = window.requestIdleCallback || function (cb) { setTimeout(cb, 4000); };
  idle(start, { timeout: 8000 });

  // Screens/banners built dynamically after the initial scan (e.g. a store's
  // buy-page video banner, injected via innerHTML only once the user opens
  // it) never existed in the DOM when collectVideoUrls() first ran, so their
  // videos were silently never warmed. Watch for any newly-inserted <video>
  // and warm it too, same rules (Data Saver still respected).
  if ('MutationObserver' in window) {
    var mo = new MutationObserver(function () {
      if (shouldSkip()) return;
      var urls = collectVideoUrls();
      if (urls.length) warmAll(urls);
    });
    mo.observe(document.documentElement, { childList: true, subtree: true });
  }

  // A PWA install is exactly the moment the user commits to this being a
  // real app on their device — that's the signal to eagerly grab everything
  // right away instead of waiting for idle time, so it's already fast by the
  // time they actually open it again.
  window.addEventListener('appinstalled', function () { start(); });
})();
/* ── Decorative-video playback controller ─────────────────────────────────
   Every looping background video in the app is managed here: play the few
   that are actually on screen, keep everything else paused.

   This used to poll every 500ms and, on every scroll frame, walk each
   video's ancestor chain calling getComputedStyle and getBoundingClientRect.
   With a handful of videos that was fine. It is not fine now — there are
   around thirty, and that work happened per video per frame while the
   finger was moving, which is a forced synchronous layout on the scroll
   path. That is what made scrolling stutter.

   Three changes:
     · An IntersectionObserver reports what is on screen, so scrolling costs
       nothing — no layout reads on the scroll path at all.
     · The expensive part, "is this inside a screen that is currently
       shown", is cached per element and only recomputed when a class
       actually changes, not on every frame.
     · At most MAX_PLAYING videos decode at once — the ones nearest the
       middle of the viewport. Everything else stays paused even if it is
       technically on screen. Decoders, not downloads, are the cost.

   Behaviour is otherwise unchanged: only videos this script paused are ever
   resumed, WebRTC streams are never touched, the practice player keeps its
   own pause control, and everything stops when the app is backgrounded.
   ── */
(function () {
  var MARK = 'data-nwsb-vis';
  var MAX_PLAYING = 4;
  var autoPaused = new WeakSet();
  var onScreen = new WeakSet();
  var shownCache = new WeakMap();   // element -> boolean, cleared on class changes
  var tracked = [];

  function hasStaticSource(v) {
    if (v.getAttribute('src')) return true;
    return !!v.querySelector('source[src]');
  }

  /* Is every ancestor of this video actually being shown? The screens use
     .open / .active classes, so this only changes when a class changes —
     which is why the answer is cached rather than recomputed per frame. */
  function shown(el) {
    if (shownCache.has(el)) return shownCache.get(el);
    var ok = true, node = el;
    while (node && node !== document.documentElement) {
      if (node.classList) {
        if (node.classList.contains('sub-screen')) { ok = node.classList.contains('open'); break; }
        if (node.classList.contains('screen'))     { ok = node.classList.contains('active'); break; }
        if (node.classList.contains('menu-drawer')) { ok = node.classList.contains('open'); break; }
      }
      var cs = window.getComputedStyle(node);
      if (cs.display === 'none' || cs.visibility === 'hidden' || parseFloat(cs.opacity) === 0) { ok = false; break; }
      node = node.parentElement;
    }
    shownCache.set(el, ok);
    return ok;
  }

  var io = ('IntersectionObserver' in window) ? new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) onScreen.add(e.target); else onScreen.delete(e.target);
    });
    queue();
  }, { rootMargin: '15% 0px 15% 0px', threshold: 0.01 }) : null;

  function track() {
    document.querySelectorAll('video').forEach(function (v) {
      if (v.getAttribute(MARK)) return;
      if (!hasStaticSource(v)) return;          // live call stream — never touch
      v.setAttribute(MARK, '1');
      tracked.push(v);
      if (io) io.observe(v);
      /* The browser's own autoplay attribute is a standing instruction that
         survives a JS pause, so it is stripped and playback is driven here. */
      v.removeAttribute('autoplay');
    });
  }

  function apply() {
    if (document.hidden) return;
    var live = [];
    for (var i = tracked.length - 1; i >= 0; i--) {
      var v = tracked[i];
      if (!v.isConnected) { tracked.splice(i, 1); continue; }
      if ((io ? onScreen.has(v) : true) && shown(v)) live.push(v);
    }
    /* Nearest the middle of the screen wins the decoders. */
    if (live.length > MAX_PLAYING) {
      var mid = (window.innerHeight || 800) / 2;
      live.sort(function (a, b) {
        var ra = a.getBoundingClientRect(), rb = b.getBoundingClientRect();
        return Math.abs((ra.top + ra.bottom) / 2 - mid) - Math.abs((rb.top + rb.bottom) / 2 - mid);
      });
    }
    var play = live.slice(0, MAX_PLAYING);
    var playSet = new Set(play);
    tracked.forEach(function (v) {
      if (playSet.has(v)) {
        if (v.paused && !v.classList.contains('lgp-video')) {
          autoPaused.delete(v);
          var pr = v.play(); if (pr && pr.catch) pr.catch(function () {});
        }
      } else if (!v.paused) {
        v.pause();
        autoPaused.add(v);
      }
    });
  }

  var queued = false;
  function queue() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () { queued = false; track(); apply(); });
  }
  window.nwsbVideoRefresh = queue;

  if ('MutationObserver' in window) {
    /* A class change can change what is shown, so the cache is dropped and
       the pass re-runs. childList catches videos injected after load. */
    new MutationObserver(function (muts) {
      var classChanged = false, added = false;
      muts.forEach(function (m) {
        if (m.type === 'attributes') classChanged = true;
        else if (m.addedNodes && m.addedNodes.length) added = true;
      });
      if (classChanged) shownCache = new WeakMap();
      if (classChanged || added) queue();
    }).observe(document.documentElement, {
      attributes: true, attributeFilter: ['class'], childList: true, subtree: true
    });
  }

  /* Scrolling no longer measures anything — the observer already knows what
     moved in and out. This only re-ranks which of them get the decoders. */
  document.addEventListener('scroll', queue, { capture: true, passive: true });
  window.addEventListener('resize', function () { shownCache = new WeakMap(); queue(); }, { passive: true });

  document.addEventListener('visibilitychange', function () {
    if (document.hidden) {
      tracked.forEach(function (v) {
        if (!v.paused) { v.pause(); autoPaused.add(v); }
      });
    } else queue();
  });

  /* A slow heartbeat as a backstop for anything the observers miss —
     seconds apart rather than twice a second, and it does no layout work
     unless something actually needs to change. */
  setInterval(queue, 4000);
  queue();
})();
