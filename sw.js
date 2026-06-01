const CACHE = 'nowsbansiu-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(clients.claim());
});

self.addEventListener('fetch', e => {
  const url = e.request.url;
  // Skip videos and large media — browser handles range requests natively
  if (url.includes('.mp4') || url.includes('/video/upload/') || url.includes('video/mp4')) return;
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
