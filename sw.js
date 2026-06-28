const CACHE = 'nowsbansiu-v66';

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
  const url = e.request.url;
  // Skip videos and large media — browser handles range requests natively
  if (url.includes('.mp4') || url.includes('/video/upload/') || url.includes('video/mp4')) return;
  // Never serve HTML from cache — always go to network so updates land immediately
  if (e.request.mode === 'navigate' || (e.request.destination === 'document')) {
    e.respondWith(fetch(e.request).catch(() => caches.match(e.request)));
    return;
  }
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
