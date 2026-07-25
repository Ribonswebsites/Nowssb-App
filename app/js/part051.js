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

/* ── Pause offscreen videos ────────────────────────────────────────────────
   Every autoplay/loop video keeps decoding frames even after its screen is
   closed and covered by whatever opened next — that's a real, continuous
   CPU/battery cost with nothing on screen to show for it. This periodically
   checks each video's actual visibility (via the same .open/.active classes
   the app already uses to show/hide screens, not a guess) and pauses ones
   that are hidden.
   Only ever resumes a video THIS script itself paused (tracked in
   autoPaused) — anything already paused for some other reason (the user
   tapped pause, a carousel deliberately stopped it, etc.) is never touched,
   so no existing pause/play behavior anywhere in the app can be overridden.
   Skips WebRTC call videos entirely (they use srcObject, not src/<source>,
   so a live call is never paused by this).
   Important: the plain <video autoplay> HTML attribute is the browser's OWN
   standing instruction to keep the element playing — calling .pause() via
   JS does not cancel that instruction, so if the browser's media pipeline
   ever resets (observed in testing: an internal abort/reload cycle on a
   stalled load) the autoplay attribute silently resumes playback again a
   moment later, fighting our own pause. Stripping the attribute the first
   time we pause a video hands full control to this script from then on —
   .play()/.pause() calls here still work exactly the same either way. ── */
(function () {
  var autoPaused = (typeof WeakSet !== 'undefined') ? new WeakSet() : null;
  if (!autoPaused) return; // no WeakSet support — skip rather than leak references

  var MARK = 'data-nwsb-vidmanaged';

  // Is the video actually within (or just outside) the viewport? A phone
  // only has ~2-4 hardware video decoders, but a single OPEN screen can hold
  // 8-10 decorative loops — Home alone has 8. Checking only "is the screen
  // open" therefore still left every one of them decoding at once, which is
  // the stutter/heat you feel while scrolling. Anything more than half a
  // screen away is paused; it resumes before it scrolls back into view, so
  // nothing is ever visibly stopped.
  function inViewport(el) {
    var r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) return false;
    var margin = (window.innerHeight || 800) * 0.5;
    return r.bottom > -margin && r.top < (window.innerHeight || 800) + margin;
  }

  function isVisible(el) {
    var node = el;
    while (node && node !== document.documentElement) {
      if (node.classList) {
        if (node.classList.contains('sub-screen')) return node.classList.contains('open') && inViewport(el);
        if (node.classList.contains('screen'))     return node.classList.contains('active') && inViewport(el);
        if (node.classList.contains('menu-drawer')) return node.classList.contains('open') && inViewport(el);
      }
      var cs = window.getComputedStyle(node);
      if (cs.display === 'none' || cs.visibility === 'hidden') return false;
      // Overlays like #authLoader hide themselves with opacity:0 while still
      // occupying layout — without this they'd keep a decoder running the
      // whole time the app is open for something nobody can see.
      if (parseFloat(cs.opacity) === 0) return false;
      node = node.parentElement;
    }
    // Not inside any known screen wrapper — always-visible chrome (the auth
    // loader, etc.). Still only worth decoding while it's actually on screen.
    return inViewport(el);
  }

  function hasStaticSource(v) {
    // Checks the HTML itself (src attribute or a <source> child), not the
    // resolved .currentSrc/.src PROPERTY — those stay empty for a
    // <source>-child video until the browser actually starts loading it,
    // which made this check wrongly treat several real decorative videos
    // (the ones built with <source> instead of a plain src attribute) as
    // WebRTC call streams and skip them entirely, forever. A true call
    // video (srcObject-driven) has neither a src attribute nor a <source>
    // child, so this still correctly excludes those.
    return v.hasAttribute('src') || !!v.querySelector('source[src]');
  }

  function refresh() {
    // App backgrounded / phone locked: nothing is visible, so don't let the
    // poll re-start what the visibilitychange handler just paused. (That
    // fight also produced a stream of "play() interrupted by pause()"
    // console warnings.)
    if (document.hidden) return;
    // video[autoplay] catches ones not seen yet; [MARK] keeps tracking ones
    // whose autoplay attribute we already stripped after pausing them once.
    document.querySelectorAll('video[autoplay], video[data-nwsb-auto], video[' + MARK + ']').forEach(function (v) {
      if (!hasStaticSource(v)) return; // live call stream (srcObject) — never touch
      v.setAttribute(MARK, '1');
      if (isVisible(v)) {
        autoPaused.delete(v);
        // Not just "resume if WE paused it" — also actively (re)try any
        // visible decorative video that's sitting paused for any reason,
        // including one whose own autoplay attribute never actually
        // managed to start it in the first place (the real bug this was
        // fixing: those videos looked permanently blank because nothing
        // ever asked them to play). Safe here because every video this
        // reaches is a controls-free decorative loop — never something
        // with a real pause button a user could have intentionally hit.
        // The practice-session video is explicitly excluded below since
        // it DOES have a real pause control.
        if (v.paused && !v.classList.contains('lgp-video')) v.play().catch(function () {});
      } else if (!v.paused) {
        v.pause();
        v.removeAttribute('autoplay');
        autoPaused.add(v);
      }
    });
  }

  setInterval(refresh, 500);

  // Don't wait for the next poll tick to react to a screen opening/closing —
  // run refresh() the instant any .open/.active class change happens, so a
  // freshly-revealed video starts immediately instead of sitting blank for
  // up to half a second first. Coalesced to once per frame (class changes
  // often fire in bursts — dots, badges, etc. — no need to rescan per-node).
  if ('MutationObserver' in window) {
    var refreshQueued = false;
    function queueRefresh() {
      if (refreshQueued) return;
      refreshQueued = true;
      requestAnimationFrame(function () { refreshQueued = false; refresh(); });
    }
    var classMo = new MutationObserver(queueRefresh);
    classMo.observe(document.documentElement, {
      attributes: true, attributeFilter: ['class'], subtree: true
    });

    // Scrolling changes which videos are on screen just as much as opening a
    // screen does. Capture-phase so it catches every inner scroller, passive
    // so it never blocks the scroll itself, and coalesced to one pass per
    // frame like everything else here.
    document.addEventListener('scroll', queueRefresh, { capture: true, passive: true });
    window.addEventListener('resize', queueRefresh, { passive: true });

    // Phone locked / app backgrounded — nothing is visible, so stop every
    // managed decoder instead of leaving them running against the battery.
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) {
        document.querySelectorAll('video[autoplay], video[data-nwsb-auto], video[' + MARK + ']').forEach(function (v) {
          if (hasStaticSource(v) && !v.paused) {
            v.pause();
            v.removeAttribute('autoplay');
            autoPaused.add(v);
          }
        });
      } else {
        queueRefresh();
      }
    });
  }
})();
