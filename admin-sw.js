/* ══════════════════════════════════════════════════════════════════════
   Service worker for the studio (admin.html), separate from the app's.

   Its scope is admin.html alone, so it never touches what the app's own
   sw.js is doing — two workers, two scopes, no overlap.

   It exists for one reason: a notification needs a service worker to be
   shown from, and the studio wants to be told when somebody asks for
   something. It deliberately does not cache: an admin screen showing a
   stale version of itself is worse than one that waits for the network.
   ══════════════════════════════════════════════════════════════════════ */

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

/* If the studio is ever wired to a push feed, this is where it arrives.
   Until then the notifications it shows are raised by the page itself. */
self.addEventListener('push', (e) => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (err) {}
  e.waitUntil(self.registration.showNotification(d.title || 'NowssB Studio', {
    body: d.body || '',
    /* Transparent on purpose — see NOTIF_ICON in sw.js. Omitting `icon`
       makes Chrome generate an origin monogram for the right-hand side; a
       blank one leaves it empty. */
    icon: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/icons/notif-blank.png',
    badge: 'https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/icons/notif-badge.png',
    tag: d.tag || 'studio',
    data: { url: './admin.html' },
  }));
});

/* Tapping one should land in the studio — focus the window if it is
   already open rather than stacking up another copy. */
self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  e.waitUntil((async () => {
    const all = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const c of all) {
      if (c.url.includes('admin.html') && 'focus' in c) return c.focus();
    }
    if (self.clients.openWindow) return self.clients.openWindow('./admin.html');
  })());
});
