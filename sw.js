const CACHE = 'nowsbansiu-v345';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    // Purge any old caches so a stale index.html can never be served
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)));
    await clients.claim();
  })());
});

self.addEventListener('fetch', e => {
  const req = e.request;
  const url = req.url;
  // Skip videos and large media — browser handles range requests natively
  if (url.includes('.mp4') || url.includes('/video/upload/') || url.includes('video/mp4')) return;
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
