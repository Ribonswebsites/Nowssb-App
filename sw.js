const CACHE = 'nowsbansiu-v959';
// Separate, stable-named bucket for background-prefetched videos (see
// app/js/part051.js). Kept OUT of the version-bumped CACHE above so a
// routine JS/CSS deploy never wipes out videos the user already has warmed —
// it's purged only by its own explicit version number when the prefetch
// list itself changes.
// Bump this whenever a video FILE changes behind a URL that stays the same.
// The fetch handler answers every .mp4 from cache first, and this bucket
// survives ordinary deploys — so without a bump here, replacing a clip on
// disk changes nothing for anyone who already had the old one warmed. That
// is exactly what happened to the start animation.
const VIDEO_CACHE = 'nowssb-media-precache-v2';

/* The start animation is not like the other clips. Every one of those is
   decorative and warmed at idle time by app/js/part051.js, four to eight
   seconds after boot — which is fine for a banner nobody has scrolled to
   yet, and useless for this one, because it starts playing one second into
   the launch. Left to the idle warmer it streamed from the network on every
   open, which is what made it stutter.
   So it is fetched here, at install, and from then on the fetch handler
   below answers it from cache instantly. Keep the ?v= in step with
   index.html — a different query is a different cache entry. */
const BOOT_MEDIA = ['./assets/video/start-animation.mp4?v=2'];

self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil((async () => {
    try {
      const c = await caches.open(VIDEO_CACHE);
      await Promise.all(BOOT_MEDIA.map(async u => {
        try {
          if (await c.match(u)) return;                 // already have it
          const res = await fetch(u, { cache: 'reload' });
          if (res && res.ok) await c.put(u, res);
        } catch (err) { /* offline at install — the idle warmer retries */ }
      }));
    } catch (err) {}
  })());
});

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    // Purge stale *versioned* caches so a stale index.html can never be
    // served — but never touch VIDEO_CACHE here, it's versioned separately.
    const keys = await caches.keys();
    await Promise.all(
      keys.filter(k => k !== CACHE && k !== VIDEO_CACHE && k.startsWith('nowsbansiu-')).map(k => caches.delete(k))
    );
    // Superseded media buckets go too. Same rule, its own prefix: anything
    // named nowssb-media-precache-* that isn't the current one is holding
    // videos that have since been replaced on disk.
    await Promise.all(
      keys.filter(k => k !== VIDEO_CACHE && k.startsWith('nowssb-media-precache-')).map(k => caches.delete(k))
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

   NOTIF_ICON is a 192×192 PNG that is transparent in every pixel, and that
   is deliberate. `icon` is the large image on the RIGHT of the notification
   — the one that should not be there. Leaving it out does not remove it:
   Chrome on Android, given a web notification with no icon, generates one
   itself from the origin (NotificationBuilderBase.ensureNormalizedIcon —
   a coloured circle with the first letter of nowssb.com in it) and sets
   that as the large icon. The only way to have nothing on the right is to
   supply an icon that is valid and invisible. The badge, which is the small
   circle beside the app name on the LEFT, stays exactly as it was — that
   part already reads the way it should.
   ── */
const NOTIF_ICON  = './assets/icons/notif-blank.png';
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

/* ── Range requests against a cached video ────────────────────────────────
   A <video> asks for bytes, not for files: it sends `Range: bytes=0-` and
   expects `206 Partial Content` with a Content-Range back.

   Cache Storage does NOT do that. caches.match() ignores the Range header
   entirely and hands back the whole 200. Chrome will play it, but its media
   stack loses the ability to ask for the part it wants, so it re-requests
   and re-buffers — which is heard as a clip that keeps catching for a few
   frames at a time. The start animation only started doing this once it
   was genuinely cached; before that it streamed from the server, which
   answers ranges properly, and was smooth.

   So the slicing is done here. */
async function rangeResponse(req, cached) {
  const range = req.headers.get('range');
  if (!range) return cached;
  const m = /^bytes=(\d*)-(\d*)$/.exec(range.trim());
  if (!m) return cached;

  const buf = await cached.clone().arrayBuffer();
  const size = buf.byteLength;
  let start, end;
  if (m[1] === '') {
    // `bytes=-N` — the last N bytes, which is how a player finds the index
    // of a file whose moov atom sits at the end.
    const n = parseInt(m[2], 10);
    if (!isFinite(n) || n <= 0) return cached;
    start = Math.max(0, size - n);
    end = size - 1;
  } else {
    start = parseInt(m[1], 10);
    end = m[2] === '' ? size - 1 : parseInt(m[2], 10);
  }
  if (!isFinite(start) || start < 0 || start >= size) {
    return new Response(null, { status: 416, headers: { 'Content-Range': 'bytes */' + size } });
  }
  if (!isFinite(end) || end >= size) end = size - 1;
  if (end < start) return cached;

  const body = buf.slice(start, end + 1);
  const headers = new Headers(cached.headers);
  headers.set('Content-Range', 'bytes ' + start + '-' + end + '/' + size);
  headers.set('Content-Length', String(body.byteLength));
  headers.set('Accept-Ranges', 'bytes');
  return new Response(body, { status: 206, statusText: 'Partial Content', headers });
}

self.addEventListener('fetch', e => {
  const req = e.request;
  const url = req.url;
  // Videos: never fetched eagerly by the SW itself (that's the large-download
  // cost we're avoiding), but if app/js/part051.js already background-warmed
  // this exact file into VIDEO_CACHE during idle time, serve it from there
  // instantly instead of hitting the network. Anything not yet warmed just
  // falls through to the network as before.
  if (url.includes('.mp4') || url.includes('/video/upload/') || url.includes('video/mp4')) {
    e.respondWith((async () => {
      const cached = await caches.match(req, { ignoreVary: true });
      if (!cached) return fetch(req);
      try { return await rangeResponse(req, cached); }
      catch (err) { return cached; }   // never let a slice failure kill playback
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
    // Cross-origin (R2, fonts, etc.): plain network, cache only as offline fallback.
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
