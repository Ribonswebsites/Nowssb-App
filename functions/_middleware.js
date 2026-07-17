// Cloudflare Pages Function — reverse-proxy for Firebase Auth on a custom domain.
//
// Firebase Auth serves its OAuth handler + helper files at /__/auth/* and
// /__/firebase/*. When `authDomain` is a custom domain (nowssb.com) but the site
// is hosted on Cloudflare Pages (which does NOT serve those files), Google
// sign-in breaks and the browser can't complete the redirect flow.
//
// This middleware forwards every /__/ request to the Firebase-hosted origin
// (nowssb-34f1b.firebaseapp.com) so the auth handler is served *same-origin*
// from nowssb.com. Everything else falls through to the normal static pipeline.
//
// Requirements (Google Cloud Console → APIs & Services → Credentials → the
// OAuth 2.0 Web client):
//   • Authorized JavaScript origins:  https://nowssb.com
//   • Authorized redirect URIs:       https://nowssb.com/__/auth/handler
// and nowssb.com must be in Firebase Auth → Settings → Authorized domains.

const FIREBASE_HOST = 'nowssb-34f1b.firebaseapp.com';

// Hosts the same-origin image proxy below is allowed to fetch — keeps it
// from becoming an open proxy for arbitrary URLs.
const IMG_PROXY_ALLOWED_HOSTS = ['res.cloudinary.com'];

export async function onRequest(context) {
  const { request, next } = context;
  const url = new URL(request.url);

  if (url.pathname.startsWith('/__/')) {
    const target = 'https://' + FIREBASE_HOST + url.pathname + url.search;
    // Preserve method, headers and body; keep 3xx responses intact so the
    // browser (not the edge) follows the OAuth redirects.
    return fetch(new Request(target, request), { redirect: 'manual' });
  }

  // Same-origin image proxy — client-side canvas work (e.g. background
  // removal on the theme preview images) needs to read pixel data back out
  // of an <img>, which the browser blocks with a SecurityError unless the
  // image was served with CORS headers. Cloudinary doesn't reliably send
  // Access-Control-Allow-Origin for every delivery URL, so this fetches the
  // image server-side and re-serves it from our own origin instead —
  // canvas access "just works" on a same-origin image, no CORS needed.
  if (url.pathname === '/img-proxy') {
    const target = url.searchParams.get('u');
    if (!target) return new Response('Missing u param', { status: 400 });
    let targetUrl;
    try { targetUrl = new URL(target); } catch (e) { return new Response('Bad url', { status: 400 }); }
    if (!IMG_PROXY_ALLOWED_HOSTS.includes(targetUrl.hostname)) {
      return new Response('Host not allowed', { status: 403 });
    }
    const upstream = await fetch(targetUrl.toString(), { cf: { cacheTtl: 86400, cacheEverything: true } });
    const headers = new Headers(upstream.headers);
    headers.set('Access-Control-Allow-Origin', '*');
    headers.set('Cache-Control', 'public, max-age=86400');
    return new Response(upstream.body, { status: upstream.status, headers });
  }

  return next();
}
