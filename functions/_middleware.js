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

export async function onRequest(context) {
  const { request, next } = context;
  const url = new URL(request.url);

  if (url.pathname.startsWith('/__/')) {
    const target = 'https://' + FIREBASE_HOST + url.pathname + url.search;
    // Preserve method, headers and body; keep 3xx responses intact so the
    // browser (not the edge) follows the OAuth redirects.
    return fetch(new Request(target, request), { redirect: 'manual' });
  }

  return next();
}
