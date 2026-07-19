const CACHE = 'nowsbansiu-v469';
// Separate, stable-named bucket for background-prefetched videos (see
// app/js/part051.js). Kept OUT of the version-bumped CACHE above so a
// routine JS/CSS deploy never wipes out videos the user already has warmed —
// it's purged only by its own explicit version number when the prefetch
// list itself changes.
const VIDEO_CACHE = 'nowssb-media-precache-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    // Purge stale *versioned* caches so a stale index.html can never be
    // served — but never touch VIDEO_CACHE here, it's versioned separately.
    const keys = await caches.keys();
    await Promise.all(
      keys.filter(k => k !== CACHE && k !== VIDEO_CACHE && k.startsWith('nowsbansiu-')).map(k => caches.delete(k))
    );
    await clients.claim();
  })());
});

self.addEventListener('fetch', e => {
  const req = e.request;
  const url = req.url;
  // Videos: never fetched eagerly by the SW itself (that's the large-download
  // cost we're avoiding), but if app/js/part051.js already background-warmed
  // this exact file into VIDEO_CACHE during idle time, serve it from there
  // instantly instead of hitting the network. Cache Storage natively answers
  // Range requests against a fully-cached Response, so seeking/looping still
  // works. Anything not yet warmed just falls through to the network as before.
  if (url.includes('.mp4') || url.includes('/video/upload/') || url.includes('video/mp4')) {
    e.respondWith((async () => {
      const cached = await caches.match(req, { ignoreVary: true });
      return cached || fetch(req);
    })());
    return;
  }
  // Never touch the Firebase Auth handler/helpers — let them pass straight to the
  // network (reverse-proxied by functions/_middleware.js) so Google sign-in works.
  if (url.includes('/__/')) return;
  if (req.method !== 'GET') return;

  // Never serve HTML from cache — always go to network so updates land immediately.
  if (req.mode === 'navigate' || req.destination === 'document') {
    e.respondWith(fetch(req).catch(() => caches.match(req)));
    return;
  }

  const sameOrigin = url.startsWith(self.location.origin);
  if (!sameOrigin) {
    // Cross-origin (Cloudinary, fonts, etc.): plain network, cache only as offline fallback.
    e.respondWith(fetch(req).catch(() => caches.match(req)));
    return;
  }

  // Same-origin static assets (CSS/JS/images): network-first, but keep a copy of
  // every GOOD response and fall back to that copy when the network fails OR
  // returns a bad status (e.g. a transient CDN 5xx during a deploy). This means a
  // broken deploy-time response can never leave a page half-styled — the last
  // known-good asset is served instead.
  e.respondWith((async () => {
    try {
      const res = await fetch(req);
      if (res && res.ok) {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(req, copy)).catch(() => {});
        return res;
      }
      const cached = await caches.match(req);
      return cached || res;
    } catch (err) {
      const cached = await caches.match(req);
      if (cached) return cached;
      throw err;
    }
  })());
});
