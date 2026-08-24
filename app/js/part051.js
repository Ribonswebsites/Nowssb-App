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

  /* MUST match VIDEO_CACHE in sw.js. The service worker deletes every
     nowssb-media-precache-* bucket that is not the current one, so if this
     name lags behind, everything warmed here is wiped on the next
     activation and nothing is ever cached — which is exactly what happened
     when sw.js went to v2 and this stayed on v1. */
  var VIDEO_CACHE = 'nowssb-media-precache-v2';

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
    // and the pictures those clips sit behind — an uncached one is a
    // visible blank on the first word while the clip is still opening
    if (window.NWSB_PLAYER_IMAGE_URLS) urls = urls.concat(window.NWSB_PLAYER_IMAGE_URLS);
    // Same problem, everywhere else it happens: a clip that is only built
    // when a screen opens cannot be found by scanning the DOM before the
    // user goes there, which is precisely when warming it would have helped.
    // Worse for the banners that alternate — only the one currently showing
    // is ever in the document, so its alternates would never be warmed at
    // all. Any file with clips like that appends them here (word pages in
    // part012.js, meaning pages in part026.js, routines in part066.js).
    if (window.NWSB_EXTRA_VIDEO_URLS) urls = urls.concat(window.NWSB_EXTRA_VIDEO_URLS);
    // de-dupe — several screens intentionally reuse the same background video
    urls = urls.filter(function (u, i) { return u && urls.indexOf(u) === i; });
    /* The start animation goes first, ahead of thirty decorative loops. It
       is the one clip that plays on every single launch, so it is the one
       worth having before any of them — the queue is staggered 800ms apart
       and DOM order would have put it behind whatever else is on the page.
       sw.js also grabs it at install; this is the retry path for when that
       failed (offline at install, or a browser that never installed one). */
    var splash = window.NWSB_SPLASH_VIDEO;
    if (splash) {
      var at = urls.indexOf(splash);
      if (at > 0) urls.splice(at, 1);
      if (at !== 0) urls.unshift(splash);
    }
    return urls;
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
  /* Not while the start animation is playing. requestIdleCallback fires as
     soon as the main thread quietens, which during the splash it does — so
     this was queueing thirty video downloads underneath the one clip that
     is actually on screen, and the clip is what paid for it.
     nwsbSplashWait (index.html) is the callback form; window._nwsbSplashOver
     is the same answer read synchronously. Read the flag rather than latching
     a copy of it, so every file that defers work to it agrees. */
  function splashOver() { return window._nwsbSplashOver !== false; }
  function startAfterSplash() {
    var go = function () { idle(start, { timeout: 8000 }); };
    if (typeof window.nwsbSplashWait === 'function') window.nwsbSplashWait(go);
    else go();
  }
  startAfterSplash();

  // Screens/banners built dynamically after the initial scan (e.g. a store's
  // buy-page video banner, injected via innerHTML only once the user opens
  // it) never existed in the DOM when collectVideoUrls() first ran, so their
  // videos were silently never warmed. Watch for any newly-inserted <video>
  // and warm it too, same rules (Data Saver still respected).
  if ('MutationObserver' in window) {
    var mo = new MutationObserver(function () {
      /* Same reason as above, and this one matters more: the app rewrites
         a great deal of DOM while it boots, so this callback ran over and
         over — each time doing a querySelectorAll('video') across the whole
         document — during the exact seconds the start animation is on
         screen. Nothing is warmed before the clip is done anyway. */
      if (!splashOver()) return;
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
     · At most MAX_PLAYING videos decode at once — every clip that is
       actually on screen. Matched to Flutter's VideoPool.maxLive so the
       HTML app, the Capacitor WebView and Flutter all play the same
       films. Off-screen clips stay unmounted. Decoders, not downloads,
       are the cost.

   Behaviour is otherwise unchanged: only videos this script paused are ever
   resumed, WebRTC streams are never touched, the practice player keeps its
   own pause control, and everything stops when the app is backgrounded.
   ── */
(function () {
  var MARK = 'data-nwsb-vis';
  /* 4 was leaving most films as stills. 6 was still starving backgrounds
     the moment a home with banners was open. 24 matches Flutter's pool
     and is enough for every on-screen clip on any page of this app. */
  /* ── Nothing decorative claims the media notification ─────────────
     Thirteen of the clips in this app carry an audio track, and Android
     treats any video playing with sound as media: the app turns up in the
     notification shade next to a music player, with a play button on the
     lock screen. Every one of these clips is decoration — a banner, a
     background, a set — and the app is not a video player.

     So two things on every play: the clip is muted whatever its markup
     said, and the media session is cleared. The video call is the one
     exception, because that one IS meant to be heard, and the guard steps
     aside entirely if an <audio> element is actually playing — the word
     player's sound is the app's real audio and it keeps its own session. */
  document.addEventListener('play', function (e) {
    var v = e.target;
    if (!v || v.tagName !== 'VIDEO') return;
    if (v.id === 'chatCallRemoteVideo' || v.id === 'chatCallLocalVideo') return;
    if (!v.muted) { try { v.muted = true; v.volume = 0; } catch (err) {} }
    try {
      var a = document.querySelector('audio');
      if (a && !a.paused && !a.ended) return;      /* real audio is playing */
      if (navigator.mediaSession) {
        navigator.mediaSession.metadata = null;
        navigator.mediaSession.playbackState = 'none';
      }
    } catch (err) {}
  }, true);

  var MAX_PLAYING = 24;
  var autoPaused = new WeakSet();
  var onScreen = new WeakSet();
  var shownCache = new WeakMap();   // element -> boolean, cleared on class changes
  var tracked = [];

  function hasStaticSource(v) {
    if (v.getAttribute('src')) return true;
    return !!v.querySelector('source[src]');
  }

  /* What is in front of everything else right now, or null.
     A .sub-screen is a full-screen fixed page and the menu is a full-screen
     drawer; when one is open, the home is still there, still .active, and
     completely invisible. The last one in the document is the top of the
     stack, because that is the order they are laid out in. */
  function topLayer() {
    var open = document.querySelectorAll('.sub-screen.open, .menu-drawer.open');
    return open.length ? open[open.length - 1] : null;
  }

  /* Is every ancestor of this video actually being shown? The screens use
     .open / .active classes, so this only changes when a class changes —
     which is why the answer is cached rather than recomputed per frame. */
  function shown(el) {
    if (shownCache.has(el)) return shownCache.get(el);

    /* ── A page over the top means everything under it is not being looked at
       ──────────────────────────────────────────────────────────────────
       This was the bug behind "the background video on that page stopped
       working". Opening a sub-screen does not take .active off the home, so
       every clip on the home still answered "yes, I am shown" and the
       observer still called them on screen — the page is over them, not
       instead of them. Six decoders is the whole budget, the home was
       holding all six, and the page you had actually opened got none. Its
       background film sat on its poster looking broken.

       Nothing under the top layer is shown. It is that simple, and it is
       true of every screen in the app rather than of the two that were
       noticed. */
    var top = topLayer();
    if (top && !top.contains(el)) {
      shownCache.set(el, false);
      return false;
    }

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

  /* ══════════════════════════════════════════════════════════════════
     MOUNTING — a <video> with no src is not a decoder

     The cap above decides how many clips PLAY. It never decided how many
     exist, and that was the real cost: 112 video elements on one home,
     every one of them holding a source, a demuxer and a frame buffer from
     the moment the page parsed. Six were playing. The other hundred and
     six were paying rent.

     So a clip's src is stashed the moment it is tracked and taken straight
     off the element. A second observer with a ONE SCREEN margin puts it
     back when the clip comes near, and takes it off again when it leaves.
     load() after removing the attribute is what actually releases the
     decoder — without it the element keeps what it had.

     Coming back is not a download: these files are in the app. Re-mounting
     is a seek in a local file, and the poster covers the frame or two it
     takes. That is the whole trade — a hundred idle decoders for one
     poster and a few milliseconds.

     What is exempt: the splash (it is the first thing painted and its own
     script owns it), the live call streams, and anything another file
     drives by hand — the hero rail sets and clears its own sources and is
     marked data-nwsb-vis to say so. */
  var STASH = 'data-nwsb-src';
  var LOCAL = 'data-nwsb-local-src';
  var R2SRC = 'data-nwsb-r2-src';
  var R2FAILED = 'data-nwsb-r2-failed';
  var R2_VIDEO_BASE = 'https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/video/';
  var near = new WeakSet();     // clip is within a screen of the viewport
  var mine = false;             // this file is the one writing src right now

  function localVideoSrc(src) {
    if (!src) return '';
    var clean = src.split('#')[0].split('?')[0];
    return /^(?:\.\/)?assets\/video\/[^/]+\.mp4$/i.test(clean) ? clean : '';
  }

  function r2VideoSrc(src) {
    var local = localVideoSrc(src);
    if (!local) return '';
    var file = local.split('/').pop();
    if (file === 'start-animation.mp4') return '';
    return R2_VIDEO_BASE + encodeURIComponent(file);
  }

  function mount(v) {
    var src = v.getAttribute(STASH);
    if (!src) return;
    var local = v.getAttribute(LOCAL) || localVideoSrc(src) || src;
    v.setAttribute(LOCAL, local);
    var remote = r2VideoSrc(local);
    var preferred = remote && v.getAttribute(R2FAILED) !== '1' ? remote : local;
    if (v.getAttribute('src') === preferred) return;
    if (remote) v.setAttribute(R2SRC, remote);
    poster(v);
    mine = true;
    v.setAttribute('src', preferred);
    mine = false;
    try { v.load(); } catch (e) {}
  }

  function unmount(v) {
    var cur = v.getAttribute('src');
    if (!cur) return;
    var local = v.getAttribute(LOCAL) || localVideoSrc(cur) || cur;
    v.setAttribute(STASH, local);
    try { v.pause(); } catch (e) {}
    mine = true;
    v.removeAttribute('src');
    mine = false;
    /* the release. Without this the element holds its buffers. */
    try { v.load(); } catch (e) {}
  }

  /* R2 is authoritative for the shared catalog. Eligible clips do not fall
     back to deleted bundle files; only the splash is local-owned and never
     reaches this manager. */
  document.addEventListener('error', function (e) {
    var v = e.target;
    if (!v || v.tagName !== 'VIDEO') return;
    var remote = v.getAttribute(R2SRC);
    if (!remote || v.getAttribute('src') !== remote) return;
    v.setAttribute(R2FAILED, '1');
    mine = true;
    v.removeAttribute('src');
    mine = false;
    try { v.load(); } catch (err) {}
  }, true);

  /* One viewport of margin on each side: by the time a section is scrolled
     to, its clip has been mounted for a screen's worth of travel. */
  var mountIo = ('IntersectionObserver' in window) ? new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) { near.add(e.target); mount(e.target); }
      else { near.delete(e.target); unmount(e.target); }
    });
    queue();
  }, { rootMargin: '100% 0px 100% 0px', threshold: 0 }) : null;

  /* ── The stash stays authoritative ────────────────────────────────
     A dozen other files in this app set a clip's src by hand: the video
     banners re-run their placement pass three times after load, the
     coupon strip picks a new clip, the reader swaps the film behind it.
     Every one of those writes would put a source back on an element that
     is nowhere near the screen, and the observer would not undo it —
     an IntersectionObserver only speaks when something crosses, and
     nothing crossed.

     So the writes are watched. Off screen, an external src is taken as
     the new stashed value and lifted straight back off: the element is
     still empty, and what it will mount later is what that file asked
     for. On screen, the write is simply let through and recorded. No
     other file needs to know this is happening. */
  var srcWatch = ('MutationObserver' in window) ? new MutationObserver(function (muts) {
    if (mine) return;
    muts.forEach(function (m) {
      var v = m.target;
      var cur = v.getAttribute('src');
      if (!cur) return;
      var local = localVideoSrc(cur) || cur;
      v.setAttribute(LOCAL, local);
      v.setAttribute(R2FAILED, '');
      if (near.has(v)) {
        v.setAttribute(STASH, local);
        poster(v);
        mount(v);                         /* remount the new clip through R2 */
        return;
      }
      v.setAttribute(STASH, local);
      poster(v);                       /* the new clip's frame, not the old one's */
      try { v.pause(); } catch (e) {}
      mine = true;
      v.removeAttribute('src');
      mine = false;
      try { v.load(); } catch (e) {}
    });
  }) : null;

  /* The active home’s R2 hero and time-focus films are part of the home
     composition, not disposable list decoration. Keep them mounted and in
     the playback set when the user scrolls past their card; shown() still
     prevents them from playing under another full-screen layer. */
  function pinHomeFilm(v) {
    /* These two classes are the home’s R2-backed films. They may be hidden by
       the other home mode, but they must not lose their source when scrolling;
       shown() below still prevents a hidden mode from playing. */
    if (v.matches && v.matches('.nwsb-focus-video, .hero-bg-vid')) return true;
    return (v.id === 'fpBgVideo' || v.id === 'fp-bg-video') &&
           document.body.classList.contains('fashplus');
  }

  function manageable(v) {
    if (pinHomeFilm(v)) return false;
    if (v.id === 'splashVid') return false;
    if (v.id === 'chatCallRemoteVideo' || v.id === 'chatCallLocalVideo') return false;
    if (v.querySelector('source')) return false;   /* <source> children: not ours to move */
    /* The practice player and the word player are driven by a person, not
       by scrolling — a clip someone pressed play on is not decoration. */
    if (v.classList.contains('lgp-video')) return false;
    return true;
  }

  /* ── A poster is what unmounting costs ───────────────────────────
     Taking the source off an idle clip means the element has nothing to
     paint until it comes back, and a video with nothing to paint is a
     hole in the page. The poster is what fills it — the clip's own first
     frame, so what is on screen while it is unmounted is what would have
     been on screen anyway.

     Rather than write a poster on to a hundred tags across a dozen files
     — half of which are template strings built at runtime — the frame is
     worked out from the source, which is the only thing that decides
     which frame it is:

       ./assets/video/NAME.mp4?v=2  →  ./assets/video/NAME-poster.webp
       cloudinary /video/upload/…/NAME.mp4  →  /image/upload/…/f_auto/…/NAME.jpg

     Every local clip has a -poster.webp beside it. Cloudinary renders the
     first frame of any video it holds at the image URL for it, which is
     where the handful of posters already in the markup point. If either
     ever misses, the element paints nothing — which is exactly what it
     did before there were posters at all. */
  function posterFor(src) {
    if (!src) return '';
    var clean = src.split('#')[0].split('?')[0];
    if (/assets\/video\/[^/]+\.mp4$/i.test(clean)) return clean.replace(/\.mp4$/i, '-poster.webp');
    return '';
  }

  var POSMARK = 'data-nwsb-pos';

  function poster(v) {
    /* A poster written here is marked, so that when another file swaps the
       clip — the coupon strip picks a new one, the reader changes the film
       — the frame under it can be swapped too. A poster that came with the
       markup is left alone: someone chose that one. */
    if (v.getAttribute('poster') && !v.getAttribute(POSMARK)) return;
    var p = posterFor(v.getAttribute('src') || v.getAttribute(STASH) ||
                      (v.querySelector('source[src]') || {}).src || '');
    if (!p) return;
    if (v.getAttribute('poster') === p) return;
    v.setAttribute('poster', p);
    v.setAttribute(POSMARK, '1');
  }

  function track() {
    document.querySelectorAll('video').forEach(function (v) {
      /* The frame goes on FIRST, and on every clip — including the ones
         this file does not otherwise manage. The hero rail owns its own
         cells and fills them in later, from a file that may well have run
         before this one; asking on each pass costs an attribute read and
         means a cell gets its picture whenever its clip turns up, rather
         than only if the load order happened to work out. */
      poster(v);
      if (v.getAttribute(MARK)) return;
      if (!hasStaticSource(v)) return;          // live call stream — never touch
      v.setAttribute(MARK, '1');
      tracked.push(v);
      if (io) io.observe(v);
      /* Off the moment it is seen, and back on only when it comes near.
         A page that starts with every source attached is a page that has
         already paid for every decoder before anyone has scrolled. */
      if (mountIo && manageable(v)) {
        var local = localVideoSrc(v.getAttribute('src')) || v.getAttribute('src') || v.getAttribute(STASH);
        if (local) v.setAttribute(LOCAL, local);
        unmount(v);
        mountIo.observe(v);
        if (srcWatch) srcWatch.observe(v, { attributes: true, attributeFilter: ['src'] });
      }
      /* The browser's own autoplay attribute is a standing instruction that
         survives a JS pause, so it is stripped and playback is driven here. */
      v.removeAttribute('autoplay');
    });
  }

  /* Nothing decodes underneath the start animation.
     This controller runs up to MAX_PLAYING videos at once, and while the
     splash is up the screens behind it still look "shown" to it — so the
     start animation was competing with four other decoders for the exact
     five seconds it is the only thing anyone can see. It waits now, the
     same way the pre-warmer above does. */
  (function () {
    var go = function () { queue(); };
    if (typeof window.nwsbSplashWait === 'function') window.nwsbSplashWait(go);
    else go();
  })();

  function apply() {
    if (document.hidden) return;
    if (window._nwsbSplashOver === false) return;
    var live = [];
    for (var i = tracked.length - 1; i >= 0; i--) {
      var v = tracked[i];
      if (!v.isConnected) { tracked.splice(i, 1); continue; }
      if ((pinHomeFilm(v) || (io ? onScreen.has(v) : true)) && shown(v)) live.push(v);
    }
    /* Nearest the middle of the screen wins the decoders — except for a clip
       that IS its section rather than decoration behind one. The television
       screen is the whole point of the section it sits in, and on a home
       with a dozen background loops it kept losing the budget to whichever
       four happened to be nearer the middle: the clip loaded, played for a
       moment, and was paused again, which looks exactly like a still. Those
       sort first and therefore always get a slot while they are on screen.
       Still at most MAX_PLAYING — this changes which clips, not how many. */
    /* .feat-bgvid and .rd-hub-bgvid are the same kind of thing as the rest of
       this list — the film IS the page, not decoration on it — and were
       missing from it. */
    var PRIORITY = '.hero-bg-vid, .qa-tv-vid, .fpv-video, .gsel-bg-vid, ' +
                   '.slm-head-vid, .feat-bgvid, .rd-hub-bgvid, .fp-page-vid, ' +
                   '.wsg-bgvid, .lgp-info-video, #fpBgVideo, #fp-bg-video';
    function prio(v) { return v.matches && v.matches(PRIORITY) ? 0 : 1; }
    if (live.length > MAX_PLAYING) {
      var mid = (window.innerHeight || 800) / 2;
      live.sort(function (a, b) {
        var pa = prio(a), pb = prio(b);
        if (pa !== pb) return pa - pb;
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
  /* For the files that own their own clips and are therefore never tracked
     here — the hero rail sets and clears its cells by hand. They still want
     the frame under the clip while it has none. */
  window.nwsbVideoPoster = poster;

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
