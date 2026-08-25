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

/* What goes over Firebase's blank auth handler. Same-origin video, so it is
   the file the app already caches — nothing extra to fetch and nothing that
   can fail independently. Fixed and above everything, muted and inline so
   it plays without a gesture, with the poster colour showing instantly in
   case the first frame has not decoded yet. */
const AUTH_LOADER = `
<style>
  #nwsbAuthWait{position:fixed;inset:0;z-index:2147483647;background:#060c18;
    display:flex;flex-direction:column;align-items:center;justify-content:center;gap:18px;
    font-family:'DM Sans',system-ui,-apple-system,sans-serif;}
  #nwsbAuthWait video{width:min(78vw,340px);aspect-ratio:1080/411;object-fit:cover;
    border-radius:16px;display:block;background:#060c18;}
  #nwsbAuthWait .t{font-size:13px;font-weight:300;letter-spacing:1px;color:rgba(255,255,255,0.62);}
</style>
<div id="nwsbAuthWait">
  <video src="https://nowssb-api.ribonpatil2.workers.dev/media/media/repo/assets/video/loading.mp4" autoplay muted loop playsinline preload="auto"></video>
  <div class="t">Signing you in…</div>
</div>`;

export async function onRequest(context) {
  const { request, next } = context;
  const url = new URL(request.url);

  if (url.pathname.startsWith('/__/')) {
    const target = 'https://' + FIREBASE_HOST + url.pathname + url.search;
    // Preserve method, headers and body; keep 3xx responses intact so the
    // browser (not the edge) follows the OAuth redirects.
    const res = await fetch(new Request(target, request), { redirect: 'manual' });

    /* ── The blank white page during Google sign-in ──────────────────
       /__/auth/handler is Firebase's own page. It paints nothing — it is
       a script that bounces you to Google and back — so the reader sits
       looking at a white screen with a Chrome address bar over it, which
       reads as the app having died mid sign-in.

       It comes through this proxy, so the loader can go on it: the app's
       own loading video, over the blank, while Firebase's script runs
       underneath exactly as before. Injected only into the HTML of the
       handler itself — never the /__/firebase/* helper scripts, never a
       redirect — and only appended before </body>, so nothing Firebase
       serves is rewritten or reordered. If the markup ever changes shape
       and the anchor is missing, the page is returned untouched. */
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
         the sign-in page would fail to load at all — worse than the blank
         screen this is here to fix. */
      const body = html.includes('</body>')
        ? html.replace('</body>', AUTH_LOADER + '</body>')
        : html;
      return new Response(body, { status: res.status, statusText: res.statusText, headers });
    }
    return res;
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
