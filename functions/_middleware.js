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
const FLUTTER_APK_UPSTREAM = 'https://github.com/Ribonswebsites/Nowssb-App/releases/download/nowssb-flutter-android/NowssB-Flutter-Android.apk';

// Hosts the same-origin image proxy below is allowed to fetch — keeps it
// from becoming an open proxy for arbitrary URLs.
const IMG_PROXY_ALLOWED_HOSTS = ['res.r2.com'];



export async function onRequest(context) {
  const { request, next } = context;
  const url = new URL(request.url);

  // Same-domain Flutter APK download. The release asset is fetched at the
  // edge and streamed with an APK content type, so the WebView never opens a
  // GitHub release page or exposes the upstream redirect to the user.
  if (url.pathname === '/download/flutter.apk') {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405, headers: { Allow: 'GET, HEAD' } });
    }
    const upstream = await fetch(FLUTTER_APK_UPSTREAM, {
      cf: { cacheTtl: 300, cacheEverything: true },
    });
    if (!upstream.ok) {
      return new Response('Flutter APK is temporarily unavailable', {
        status: 502,
        headers: { 'Cache-Control': 'no-store' },
      });
    }
    const headers = new Headers(upstream.headers);
    headers.set('Content-Type', 'application/vnd.android.package-archive');
    headers.set('Content-Disposition', 'attachment; filename="NowssB-Flutter-Android.apk"');
    headers.set('Cache-Control', 'public, max-age=300, s-maxage=300');
    headers.delete('content-encoding');
    return new Response(request.method === 'HEAD' ? null : upstream.body, {
      status: 200,
      headers,
    });
  }

  if (url.pathname.startsWith('/__/')) {
    const target = 'https://' + FIREBASE_HOST + url.pathname + url.search;
    // Preserve method, headers and body; keep 3xx responses intact so the
    // browser (not the edge) follows the OAuth redirects.
    const res = await fetch(new Request(target, request), { redirect: 'manual' });

        /* Firebase's handler is returned untouched. The app owns the visible
       login transition; injecting a second loading page or video here breaks
       redirect completion in embedded WebViews and obscures the login flow. */

    const ct = res.headers.get('content-type') || '';
    if (url.pathname === '/__/auth/handler' && res.status === 200 && ct.includes('text/html')) {
      const html = await res.text();
      const headers = new Headers(res.headers);
      // The body has been read and is being re-served, so the upstream
      // length/encoding no longer describe it either way.
      headers.delete('content-length');
      headers.delete('content-encoding');
      /* Rebuilt from the text in BOTH branches. Returning `res` here after
         calling .text() on it would hand back an already-consumed body and
         the sign-in page would fail to load at all. */
      const body = html;
      return new Response(body, { status: res.status, statusText: res.statusText, headers });
    }
    return res;
  }

  // Same-origin image proxy — client-side canvas work (e.g. background
  // removal on the theme preview images) needs to read pixel data back out
  // of an <img>, which the browser blocks with a SecurityError unless the
  // image was served with CORS headers. R2 doesn't reliably send
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
