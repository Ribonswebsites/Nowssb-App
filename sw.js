const CACHE = 'nowsbansiu-v789';
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

/* ── Notifications ────────────────────────────────────────────────────
   Two ways in, one way out.

   `push` fires when a server sends one — that is the only path that works
   with the app fully closed, and it needs a push subscription, which needs
   a VAPID key (see VAPID_PUBLIC_KEY in app/js/part068.js). Until one
   is set nothing subscribes and this handler simply never fires; everything
   else below still works.

   The app itself also raises notifications directly while it is running,
   through registration.showNotification() in part068.js. Both end up as the
   same system notification, so they look and behave identically.

   The layout of that notification belongs to the phone, not to us: Android
   draws the small icon and the app name along the top and the title and
   body beneath. `icon` and `badge` are the two images we get to choose.
   ── */
const NOTIF_ICON  = './assets/icons/app-icon-192.png';
const NOTIF_BADGE = './assets/icons/notif-badge.png';

self.addEventListener('push', e => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (err) { d = { body: e.data && e.data.text() }; }
  const title = d.title || 'NowssB';
  e.waitUntil(self.registration.showNotification(title, {
    body: d.body || '',
    icon: d.icon || NOTIF_ICON,
    badge: NOTIF_BADGE,
    tag: d.tag || d.type || 'nowssb',
    renotify: true,
    data: { type: d.type || '', url: d.url || './' },
    vibrate: [28, 40, 28]
  }));
});

/* Tapping one should land on the thing it is about: focus a window that is
   already open and tell it where to go, or open the app if none is. */
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const type = (e.notification.data && e.notification.data.type) || '';
  e.waitUntil((async () => {
    const all = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const c of all) {
      if ('focus' in c) {
        await c.focus();
        c.postMessage({ nwsb: 'notification-click', type });
        return;
      }
    }
    const url = (e.notification.data && e.notification.data.url) || './';
    if (clients.openWindow) {
      const w = await clients.openWindow(url);
      /* A window opened from cold has not booted yet, so it cannot be told
         where to go — part068.js reads this back out of storage instead. */
      if (w && type) { try { await w.postMessage({ nwsb: 'notification-click', type }); } catch (err) {} }
    }
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
  // cache:'reload' for the same reason as the static-asset handler below: skip
  // straight past the browser's own HTTP cache, not just this SW's Cache Storage.
  if (req.mode === 'navigate' || req.destination === 'document') {
    e.respondWith(fetch(req, { cache: 'reload' }).catch(() => caches.match(req)));
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
  //
  // cache:'reload' on the fetch below is deliberate: passing the intercepted
  // `req` straight to fetch() still lets the BROWSER's own HTTP cache satisfy
  // it (or silently 304-revalidate it) whenever the CDN's Cache-Control on
  // these files allows it — meaning "network-first" wasn't actually
  // guaranteeing a live round-trip past that layer. Every URL already carries
  // its own ?v= cache-busting query string, so forcing a genuine bypass here
  // is always safe and closes off an entire class of "still stale after
  // clearing the SW cache" bugs.
  e.respondWith((async () => {
    try {
      const res = await fetch(req, { cache: 'reload' });
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
