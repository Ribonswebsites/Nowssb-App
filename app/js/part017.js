
// ── NowssB Store — all logic uses direct DOM, no openSub chain dependency ──

// Store pages are standalone screens. Close any previous sub-screen first so
// an older page cannot remain visible through a Store intro.
function nssCloseOtherSubScreens(exceptId) {
  document.querySelectorAll('.sub-screen.open').forEach(function (screen) {
    if (screen.id !== exceptId) screen.classList.remove('open');
  });
}
window.nwsbResetStoreIntro = function (id) {
  var map = {
    'sub-real-meaning': ['rmIntroPage', 'rmMainContent'],
    'sub-nowssb-store': ['nssIntroPage', 'nssBody'],
    'sub-meaning-store': ['msIntroPage', 'msMcontent'],
    'sub-ebooks-store': ['ebIntroPage', 'ebMcontent'],
    'sub-signature-store': ['sigIntroPage', null]
  };
  var pair = map[id];
  if (!pair) return;
  var intro = document.getElementById(pair[0]);
  var main = pair[1] ? document.getElementById(pair[1]) : null;
  if (intro) {
    intro.classList.remove('rm-intro-hidden', 'ms-intro-hidden', 'sig-intro-hidden', 'nss-intro-hidden');
    intro.style.opacity = '';
    intro.style.pointerEvents = '';
    intro.style.display = '';
  }
  if (main) {
    if (id === 'sub-nowssb-store') main.classList.remove('visible');
    else main.style.display = 'none';
  }
};

// Open / close the NowssB Store sub-screen directly
function nssOpen() {
  var s = document.getElementById('sub-nowssb-store');
  nssCloseOtherSubScreens('sub-nowssb-store');
  window.nwsbResetStoreIntro('sub-nowssb-store');
  if (s) s.classList.add('open');
  var iv = document.getElementById('nssIntroVid');
  if (iv) { try { iv.pause(); } catch (e) {} }
  if (typeof window.nwsbFpSyncPageBackdrop === 'function') window.nwsbFpSyncPageBackdrop();
}

function nssClose() {
  var s = document.getElementById('sub-nowssb-store');
  if (s) s.classList.remove('open');
  setTimeout(function(){
    var intro = document.getElementById('nssIntroPage');
    var body  = document.getElementById('nssBody');
    var topbar = document.getElementById('nssStoreTopbar');
    if (intro) { intro.style.display = ''; intro.style.opacity = ''; intro.style.pointerEvents = ''; }
    if (body)  { body.classList.remove('visible'); body.scrollTop = 0; }
    /* nssEnterStore() sets this to 'flex' and never resets it — left it
       stuck visible over the intro image next time the store opens. */
    if (topbar) topbar.style.display = 'none';
  }, 500);
}

// Enter the store (dismiss intro)
function nssEnterStore() {
  var intro = document.getElementById('nssIntroPage');
  var body  = document.getElementById('nssBody');
  if (intro) { intro.style.opacity = '0'; intro.style.pointerEvents = 'none'; setTimeout(function(){ intro.style.display = 'none'; }, 480); }
  if (body)  { body.classList.add('visible'); body.scrollTop = 0; }
  var topbar = document.getElementById('nssStoreTopbar');
  if (topbar) { topbar.style.display = 'flex'; nssUpdateBadges(); }
  ['nssBannerVid','nssWordVid','nssMeaningVid'].forEach(function(id){
    var v = document.getElementById(id);
    if (v) { v.muted = true; v.play().catch(function(){}); }
  });
  // Init 3D banner scroll + tilt
  setTimeout(nssInitBanner3D, 80);
}

// ════════════════════════════════════════════
// CART & WISHLIST SYSTEM
// ════════════════════════════════════════════

var nssCart     = JSON.parse(localStorage.getItem('nowssb_cart') || '[]');
var nssWishlist = JSON.parse(localStorage.getItem('nowssb_wish') || '[]');

// Word-type items never had a genuine per-word image — they inherited a
// promotional banner shared across every word in the same price tier,
// and several of those banners have a DIFFERENT word's name baked into
// the artwork. Anything saved with that stale img before this was fixed
// would keep showing the wrong name forever; swap it once here (for
// every render path that reads from these same arrays — cart, wishlist,
// checkout) to the real Word Atelier card image instead, same as new
// Word items already get from rmdAddCart()/rmdToggleWish().
[nssCart, nssWishlist].forEach(function (list) {
  list.forEach(function (item) {
    if (item && item.type === 'Word') item.img = window.RM_WORD_IMG || (typeof RM_CAT_LOGO !== 'undefined' ? RM_CAT_LOGO : item.img);
  });
});

function nssSaveCart()     { localStorage.setItem('nowssb_cart', JSON.stringify(nssCart)); }
function nssSaveWishlist() { localStorage.setItem('nowssb_wish', JSON.stringify(nssWishlist)); }

// ── BADGE UPDATES ──
function nssUpdateBadges() {
  var cb = document.getElementById('nssCartBadge');
  var wb = document.getElementById('nssWishBadge');
  if (cb) {
    cb.textContent = nssCart.length;
    cb.classList.toggle('show', nssCart.length > 0);
  }
  if (wb) {
    wb.textContent = nssWishlist.length;
    wb.classList.toggle('show', nssWishlist.length > 0);
  }
  // Cart icon also appears in the Word Atelier / Meaning Store headers, and
  // the wishlist icon in the Cart page's own header — every instance shares
  // its class so they all stay in sync together.
  document.querySelectorAll('.nss-cart-badge-shared').forEach(function (el) {
    el.textContent = nssCart.length;
    el.classList.toggle('show', nssCart.length > 0);
  });
  document.querySelectorAll('.nss-wish-badge-shared').forEach(function (el) {
    el.textContent = nssWishlist.length;
    el.classList.toggle('show', nssWishlist.length > 0);
  });
  /* Visibility of the topbar itself is owned by nssEnterStore() (show) and
     nssClose() (hide) — forcing it visible here too meant any badge-count
     refresh (e.g. adding a word while browsing) could pop the cart/wishlist
     icons up over the intro page even before the store was entered. */
}
// Sync every badge once at boot (Word Atelier / Meaning Store headers are
// static markup already in the DOM, unlike the store topbar's own badge
// which nssEnterStore() syncs on entry) so a returning user with items
// already in their cart doesn't see a stale "0" until the next change.
nssUpdateBadges();

// ── ADD TO CART ──
function nssAddToCart(item) {
  // item = { id, name, type, price, img }
  /* Cart/Buy Now must never be gated behind an active subscription check —
     that blocked the exact action a lapsed-trial user needs to become a
     paying customer again (Buy Now routes through here too). Purchases
     themselves are billed individually at checkout regardless of tier. */
  var exists = nssCart.find(function(c){ return c.id === item.id; });
  if (exists) { nssShowToast('Already in cart'); return; }
  nssCart.push(item);
  nssSaveCart();
  nssUpdateBadges();
  nssUpdateCartPanel();
  nssRefreshCardStates();
  nssShowToast('Added to cart');
  // Flash the cart badge
  var badge = document.getElementById('nssCartBadge');
  if (badge) { badge.style.transform = 'scale(1.4)'; setTimeout(function(){ badge.style.transform = ''; }, 200); }
}

// ── REMOVE FROM CART ──
function nssRemoveFromCart(id) {
  nssCart = nssCart.filter(function(c){ return c.id !== id; });
  nssSaveCart();
  nssUpdateBadges();
  nssUpdateCartPanel();
  nssRefreshCardStates();
}

// ── TOGGLE WISHLIST ──
function nssToggleWishlist(item) {
  var idx = nssWishlist.findIndex(function(w){ return w.id === item.id; });
  if (idx >= 0) {
    nssWishlist.splice(idx, 1);
    nssSaveWishlist();
    nssUpdateBadges();
    nssUpdateWishlistPanel();
    nssRefreshCardStates();
    nssShowToast('Removed from wishlist');
  } else {
    nssWishlist.push(item);
    nssSaveWishlist();
    nssUpdateBadges();
    nssUpdateWishlistPanel();
    nssRefreshCardStates();
    nssShowToast('Saved to wishlist');
    var badge = document.getElementById('nssWishBadge');
    if (badge) { badge.style.transform = 'scale(1.4)'; setTimeout(function(){ badge.style.transform = ''; }, 200); }
  }
}

// ── MOVE FROM WISHLIST TO CART ──
function nssMoveToCart(id) {
  var item = nssWishlist.find(function(w){ return w.id === id; });
  if (!item) return;
  nssWishlist = nssWishlist.filter(function(w){ return w.id !== id; });
  nssSaveWishlist();
  nssAddToCart(item);
  nssUpdateWishlistPanel();
  nssUpdateBadges();
  nssRefreshCardStates();
}

// ── RENDER CART PANEL ──
function nssUpdateCartPanel() {
  var list  = document.getElementById('nssCartList');
  var total = document.getElementById('nssCartTotal');
  var btn   = document.getElementById('nssCheckoutBtn');
  var count = document.getElementById('nssCartCountLabel');
  if (!list) return;

  if (nssCart.length === 0) {
    list.innerHTML = '<div class="nss-panel-empty">Your cart is empty.<br>Add words or meanings to get started.</div>';
    if (total) total.textContent = '$0.00';
    if (btn)   btn.disabled = true;
    if (count) count.textContent = '0 items';
    return;
  }

  var sum = 0;
  var html = '';
  nssCart.forEach(function(item) {
    sum += item.price || 0;
    html += '<div class="nss-panel-item">' +
      '<img loading="lazy" decoding="async" class="nss-panel-item-img" src="' + (item.img || '') + '" onerror="this.style.background=\'rgba(255,255,255,0.05)\'">' +
      '<div class="nss-panel-item-info">' +
        '<div class="nss-panel-item-name">' + item.name + '</div>' +
        '<div class="nss-panel-item-type">' + (item.type || 'Word') + '</div>' +
      '</div>' +
      '<div class="nss-panel-item-actions">' +
        '<div class="nss-panel-item-price">$' + (item.price/100).toFixed(2) + '</div>' +
        '<div class="nss-item-action-btn" onclick="nssRemoveFromCart(\'' + item.id + '\')" title="Remove">' +
          '<svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M1 1L9 9M9 1L1 9" stroke="rgba(255,100,100,0.7)" stroke-width="1.3" stroke-linecap="square"/></svg>' +
        '</div>' +
      '</div>' +
    '</div>';
  });

  list.innerHTML = html;
  if (total) total.textContent = '$' + (sum/100).toFixed(2);
  if (btn)   btn.disabled = false;
  if (count) count.textContent = nssCart.length + ' item' + (nssCart.length !== 1 ? 's' : '');
}

// ── RENDER WISHLIST PANEL ──
function nssUpdateWishlistPanel() {
  var list  = document.getElementById('nssWishlistList');
  var count = document.getElementById('nssWishCountLabel');
  if (!list) return;

  if (nssWishlist.length === 0) {
    list.innerHTML = '<div class="nss-panel-empty">No words saved yet.<br>Tap the heart on any word to save it.</div>';
    if (count) count.textContent = '0 saved';
    return;
  }

  var html = '';
  nssWishlist.forEach(function(item) {
    html += '<div class="nss-panel-item">' +
      '<img loading="lazy" decoding="async" class="nss-panel-item-img" src="' + (item.img || '') + '" onerror="this.style.background=\'rgba(255,255,255,0.05)\'">' +
      '<div class="nss-panel-item-info">' +
        '<div class="nss-panel-item-name">' + item.name + '</div>' +
        '<div class="nss-panel-item-type">' + (item.type || 'Word') + '</div>' +
      '</div>' +
      '<div class="nss-panel-item-actions">' +
        '<div class="nss-panel-item-price">$' + (item.price/100).toFixed(2) + '</div>' +
        '<div class="nss-item-action-btn move" onclick="nssMoveToCart(\'' + item.id + '\')" title="Move to Cart">' +
          '<svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M2 5h6M6 2l3 3-3 3" stroke="rgba(232,213,163,0.8)" stroke-width="1.3" stroke-linecap="square"/></svg>' +
        '</div>' +
        '<div class="nss-item-action-btn" onclick="nssToggleWishlist({id:\'' + item.id + '\',name:\'' + item.name.replace(/'/g,"\\'") + '\',type:\'' + (item.type||'Word') + '\',price:' + item.price + ',img:\'' + (item.img||'') + '\'})" title="Remove">' +
          '<svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M1 1L9 9M9 1L1 9" stroke="rgba(255,100,100,0.7)" stroke-width="1.3" stroke-linecap="square"/></svg>' +
        '</div>' +
      '</div>' +
    '</div>';
  });

  list.innerHTML = html;
  if (count) count.textContent = nssWishlist.length + ' saved';
}

// ── REFRESH CARD HEART/CART ICON STATES ──
function nssRefreshCardStates() {
  var cartIds = nssCart.map(function(c){ return c.id; });
  var wishIds = nssWishlist.map(function(w){ return w.id; });

  document.querySelectorAll('[data-nss-wish]').forEach(function(el) {
    var id = el.getAttribute('data-nss-wish');
    el.classList.toggle('wishlisted', wishIds.indexOf(id) >= 0);
    var path = el.querySelector('path');
    if (path) path.setAttribute('fill', wishIds.indexOf(id) >= 0 ? 'rgba(220,80,80,0.9)' : 'none');
  });
  document.querySelectorAll('[data-nss-cart]').forEach(function(el) {
    var id = el.getAttribute('data-nss-cart');
    el.classList.toggle('carted', cartIds.indexOf(id) >= 0);
  });
}

// ── OPEN / CLOSE PANELS ──
function nssOpenCart() {
  nssUpdateCartPanel();
  var el = document.getElementById('nssCartOverlay');
  if (el) el.classList.add('open');
}
function nssCloseCart() {
  var el = document.getElementById('nssCartOverlay');
  if (el) el.classList.remove('open');
}
function nssCartOverlayClick(e) {
  if (e.target === document.getElementById('nssCartOverlay')) nssCloseCart();
}

function nssOpenWishlist() {
  nssUpdateWishlistPanel();
  var el = document.getElementById('nssWishlistOverlay');
  if (el) el.classList.add('open');
}
function nssCloseWishlist() {
  var el = document.getElementById('nssWishlistOverlay');
  if (el) el.classList.remove('open');
}
function nssWishOverlayClick(e) {
  if (e.target === document.getElementById('nssWishlistOverlay')) nssCloseWishlist();
}

// ── CHECKOUT (Razorpay placeholder) ──
function nssCheckout() {
  if (!nssCart || nssCart.length === 0) return;
  // Open checkout ON TOP of the still-open cart (checkout sits later in the
  // DOM, so it paints above cart at the same z-index) BEFORE closing cart —
  // closing cart first briefly reveals whatever screen sits underneath both
  // (e.g. Fashion Home) as a visible flash while checkout hasn't slid in yet.
  if (typeof openSub === 'function') openSub('checkout');
  if (typeof closeSub === 'function') closeSub('cart');
  // "Proceed to Checkout" is also reachable from the slide-out cart PANEL
  // (#nssCartOverlay/#nssCartPanel, opened by the store's cart icon) — a
  // completely separate widget from the #sub-cart full screen, sitting at
  // z-index 1200 (well above every .sub-screen's 600). closeSub('cart')
  // only ever touched #sub-cart, so opening checkout from THIS panel left
  // the dark scrim + panel covering the newly-opened checkout screen the
  // entire time, which read as "checkout never opens / goes back to store".
  if (typeof nssCloseCart === 'function') nssCloseCart();
}

// ── TOAST NOTIFICATION ──
function nssShowToast(msg) {
  var t = document.getElementById('nssToast');
  if (!t) {
    t = document.createElement('div');
    t.id = 'nssToast';
    t.style.cssText = 'position:fixed;bottom:96px;left:50%;transform:translateX(-50%) translateY(20px);' +
      'background:rgba(11,17,32,0.95);border:1px solid rgba(255,255,255,0.1);' +
      'backdrop-filter:none;-webkit-backdrop-filter:none;' +
      'color:rgba(255,255,255,0.9);font-size:12px;font-weight:600;letter-spacing:0.3px;' +
      'padding:10px 18px;border-radius:20px;z-index:9999;pointer-events:none;' +
      'opacity:0;transition:opacity 0.2s ease,transform 0.2s ease;white-space:nowrap;';
    document.body.appendChild(t);
  }
  t.textContent = msg;
  t.style.opacity = '1';
  t.style.transform = 'translateX(-50%) translateY(0)';
  clearTimeout(t._timer);
  t._timer = setTimeout(function(){
    t.style.opacity = '0';
    t.style.transform = 'translateX(-50%) translateY(20px)';
  }, 2000);
}

// Init badges on load
document.addEventListener('DOMContentLoaded', function() {
  nssUpdateBadges();
  nssUpdateHomeBadges();
  nssUpdateProfileCounts();
});

// ── HOME PAGE BADGE SYNC ──
function nssUpdateHomeBadges() {
  // Cart badge + sub text
  // Switch cart icon empty/full
  var cartIconEls = document.querySelectorAll('#subCartIcon, #homeCwCartIcon');
  var cartCount = window._nssCart ? window._nssCart.length : 0;
  cartIconEls.forEach(function(el){
    el.src = cartCount > 0 ? 'https://res.cloudinary.com/ds6duqabl/image/upload/v1779558988/cb456de0-56cf-11f1-8fad-095787cce754_zplzrc.png' : 'https://res.cloudinary.com/ds6duqabl/image/upload/v1779558987/c9c4e860-56cf-11f1-8fad-095787cce754_t6k8gb.png';
  });
  var hcb = document.getElementById('homeCwCartBadge');
  var hcs = document.getElementById('homeCwCartSub');
  if (hcb) { hcb.textContent = nssCart.length; hcb.classList.toggle('show', nssCart.length > 0); }
  if (hcs) { hcs.textContent = nssCart.length + ' item' + (nssCart.length !== 1 ? 's' : ''); }
  // Wishlist badge + sub text
  var hwb = document.getElementById('homeCwWishBadge');
  var hws = document.getElementById('homeCwWishSub');
  if (hwb) { hwb.textContent = nssWishlist.length; hwb.classList.toggle('show', nssWishlist.length > 0); }
  if (hws) { hws.textContent = nssWishlist.length + ' saved'; }
}

// ── PROFILE COUNTS SYNC ──
function nssUpdateProfileCounts() {
  var pc = document.getElementById('profileCartCount');
  var pw = document.getElementById('profileWishCount');
  var po = document.getElementById('profileOrderCount');
  if (pc) pc.textContent = nssCart.length + ' item' + (nssCart.length !== 1 ? 's' : '');
  if (pw) pw.textContent = nssWishlist.length + ' saved';
  // orders = word + meaning purchases
  var wordBought = 0, meaningBought = 0;
  try { wordBought    = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]').length; } catch(e) {}
  try { meaningBought = JSON.parse(localStorage.getItem('nwsb_meaning_purchased') || '[]').length; } catch(e) {}
  var total = wordBought + meaningBought;
  if (po) po.textContent = total + ' purchased';
}

// Patch all mutating functions to also refresh home + profile counters
var _origNssAddToCart     = nssAddToCart;
var _origNssRemoveFromCart = nssRemoveFromCart;
var _origNssToggleWishlist = nssToggleWishlist;
var _origNssMoveToCart    = nssMoveToCart;
nssAddToCart = function(item) { _origNssAddToCart(item); nssUpdateHomeBadges(); nssUpdateProfileCounts(); };
nssRemoveFromCart = function(id) { _origNssRemoveFromCart(id); nssUpdateHomeBadges(); nssUpdateProfileCounts(); };
nssToggleWishlist = function(item) { _origNssToggleWishlist(item); nssUpdateHomeBadges(); nssUpdateProfileCounts(); };
nssMoveToCart = function(id) { _origNssMoveToCart(id); nssUpdateHomeBadges(); nssUpdateProfileCounts(); };

// ── ORDERS — redirect to sub-screen page (panel removed) ──
function profileOpenOrders() { if (typeof openSub === 'function') openSub('orders'); }
function nssOpenOrders()     { if (typeof openSub === 'function') openSub('orders'); }
function nssCloseOrders()    { if (typeof closeSub === 'function') closeSub('orders'); }

// ── NSS BANNER: 3D SCROLL PARALLAX + TOUCH TILT ──
function nssInitBanner3D() {
  var slides = document.getElementById('nssBannerSlides');
  var banner = document.getElementById('nssBanner');
  var body   = document.getElementById('nssBody');
  if (!slides || !banner || !body) return;
  if (banner._b3d) return;          // guard: only wire once
  banner._b3d = true;

  // give the banner real depth so transforms read as true 3D
  banner.style.perspective = '1000px';
  banner.style.perspectiveOrigin = '50% 0%';
  slides.style.transformOrigin = '50% 0%';
  slides.style.transformStyle = 'preserve-3d';

  var tilting = false;

  // 3D scroll: as the page scrolls up, the banner tilts back into the screen,
  // sinks away (translateZ) and rises with parallax — a real 3D scroll.
  body.addEventListener('scroll', function() {
    if (tilting) return;
    var h = banner.offsetHeight || 1;
    var sy = body.scrollTop;
    var p = Math.min(sy / h, 1);                 // 0 → 1 across the banner height
    var rotX = p * 14;                           // tilt back up to 14°
    var ty   = sy * 0.42;                        // parallax rise
    var tz   = -p * 140;                         // sink into the screen
    var sc   = 1.12 - p * 0.06;
    slides.style.transition = 'none';
    slides.style.transform = 'translate3d(0,' + ty + 'px,' + tz + 'px) rotateX(' + rotX + 'deg) scale(' + sc + ')';
    slides.style.opacity = String(Math.max(1 - p * 0.85, 0.15));
  }, { passive: true });

  // Touch / pointer tilt — parallax follows the finger for a hand-held 3D feel
  function applyTilt(clientX, clientY) {
    tilting = true;
    var rect = banner.getBoundingClientRect();
    var cx = rect.width / 2, cy = rect.height / 2;
    var dx = (clientX - rect.left - cx) / cx;
    var dy = (clientY - rect.top - cy) / cy;
    var rotY =  dx * 8;
    var rotX = -dy * 6;
    slides.style.transition = 'transform 0.12s ease-out';
    slides.style.transform = 'translate3d(0,0,40px) rotateX(' + rotX + 'deg) rotateY(' + rotY + 'deg) scale(1.1)';
  }
  function resetTilt() {
    tilting = false;
    slides.style.transition = 'transform 0.55s cubic-bezier(0.25,0.46,0.45,0.94)';
    slides.style.transform = 'translate3d(0,0,0) rotateX(0deg) rotateY(0deg) scale(1.12)';
    slides.style.opacity = '1';
  }
  banner.addEventListener('touchmove', function(e) {
    if (body.scrollTop < 12) applyTilt(e.touches[0].clientX, e.touches[0].clientY);
  }, { passive: true });
  banner.addEventListener('touchend', resetTilt);
  banner.addEventListener('mousemove', function(e) { if (body.scrollTop < 12) applyTilt(e.clientX, e.clientY); });
  banner.addEventListener('mouseleave', resetTilt);
}

// Open sub-screens from inside NowssB Store. This deliberately bypasses the
// long openSub wrapper chain: Store cards must not depend on whichever module
// happened to wrap navigation last.
function nssOpenSub(id) {
  var aliases = {
    'word-atelier': 'real-meaning',
    'word-store': 'real-meaning',
    'meaning': 'meaning-store',
    'ebooks': 'ebooks-store',
    'signature': 'signature-store'
  };
  id = aliases[id] || id;
  var screenId = 'sub-' + id;
  var target = document.getElementById(screenId);
  if (!target) {
    console.warn('[NowssB] Store route not found:', id, screenId);
    return false;
  }

  // Close the hub and every older overlay before opening the destination.
  nssCloseOtherSubScreens(screenId);
  var hub = document.getElementById('sub-nowssb-store');
  if (hub && hub !== target) hub.classList.remove('open');
  if (typeof window.nwsbResetStoreIntro === 'function') window.nwsbResetStoreIntro(screenId);
  target.classList.add('open');
  target.setAttribute('aria-hidden', 'false');
  if (typeof window.nwsbFpSyncPageBackdrop === 'function') window.nwsbFpSyncPageBackdrop();

  if (id === 'meaning-store') {
    var msVid = document.getElementById('msBannerImg');
    if (msVid) { msVid.muted = true; msVid.play().catch(function(){}); }
    if (typeof msRenderStore === 'function') setTimeout(msRenderStore, 80);
    if (typeof msInitParallax === 'function') setTimeout(msInitParallax, 200);
  }
  if (id === 'real-meaning' && typeof window.rmBannerReset === 'function') window.rmBannerReset();
  if (id === 'ebooks-store' && typeof ebRenderStore === 'function') setTimeout(ebRenderStore, 80);
  if (id === 'signature-store' && typeof sigSyncProfile === 'function') sigSyncProfile();
  if (id === 'social' && typeof ssSyncProfile === 'function') ssSyncProfile();
  return true;
}

/* ══ EBOOKS STORE ══════════════════════════════════════════
   New product type added alongside the Word/Meaning stores — same cart/
   checkout pipeline (nssAddToCart), its own purchased-list localStorage
   key. No real reader built yet, so an owned ebook shows a "coming soon"
   stub instead of pretending to open real content. ══ */
/* Three real titles, each with its own cover art, long-form description and
   contents list — the detail page (ebOpenBook) renders straight from this,
   so a book is described in exactly one place. */
var EB_BOOKS = [
  {
    key: 'shabdapathy-codex',
    title: 'The Shabdapathy Codex',
    sub: 'The complete origin science, in one volume.',
    price: 499,
    cover: 'https://res.cloudinary.com/eenvubod/image/upload/v1784974929/file_000000007fec81f4b097aaae4e7ac297_ohtqy9.png',
    about: 'The foundational text of Shabdapathy — how sound carried meaning long before dictionaries existed, and why the human body still responds to the original vibration of a word rather than its spelling.',
    contents: [
      'What Shabdapathy is, and what it is not',
      'The natural origin of sound, before written language',
      'Why the body reacts to vibration, not definition',
      'Reading a word back to its first sound',
      'Daily practice: building your own routine'
    ]
  },
  {
    key: 'phonetic-field-guide',
    title: 'Phonetic Origins: A Field Guide',
    sub: 'Trace any word back to its first sound.',
    price: 399,
    cover: 'https://res.cloudinary.com/eenvubod/image/upload/v1784974929/file_000000007af081f49748cd0a1b77c566_f8qslq.png',
    about: 'A practical companion for tracing any word back through its phonetic ancestry. Built as a working field guide rather than a theory book — open it mid-practice and follow the method on whatever word you are holding.',
    contents: [
      'The tracing method, step by step',
      'Root syllables and how to isolate them',
      'Common false trails and how to spot them',
      'Cross-language sound families',
      'Worked examples you can follow along with'
    ]
  },
  {
    key: 'sound-healing-atlas',
    title: 'The Sound Healing Atlas',
    sub: 'Which sounds reach which parts of the body.',
    price: 599,
    cover: 'https://res.cloudinary.com/eenvubod/image/upload/v1784975675/file_00000000ee688208950f4126ed15d9b3_esohnw.png',
    about: 'A mapped reference of sound to the body — which syllables carry to which regions, why speaking aloud lands differently than thinking a word, and how to build a session around the area you actually want to work on.',
    contents: [
      'The body map: sound to region',
      'Why aloud differs from silent',
      'Breath, pitch and placement',
      'Building a session around one area',
      'Sequencing and how long to hold'
    ]
  }
];
/* One disclaimer, shown under every book and on every detail page. */
var EB_DISCLAIMER = 'For educational and wellness purposes only — not medical advice, and not a replacement for professional diagnosis or treatment.';
/* Fallback only — every book above ships its own cover. */
var EB_COVER = 'https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto/v1780065459/7562ed60-5b68-11f1-af5d-9196714121d3_y4f80z.png';
function ebCoverFor(key) {
  for (var i = 0; i < EB_BOOKS.length; i++) if (EB_BOOKS[i].key === key) return EB_BOOKS[i].cover || EB_COVER;
  return EB_COVER;
}

function ebGetPurchased() {
  try { return JSON.parse(localStorage.getItem('nwsb_ebook_purchased') || '[]'); } catch (e) { return []; }
}
window.ebIsPurchased = function (key) { return ebGetPurchased().some(function (p) { return p.key === key; }); };

function ebBookByKey(key) {
  for (var i = 0; i < EB_BOOKS.length; i++) if (EB_BOOKS[i].key === key) return EB_BOOKS[i];
  return null;
}
function ebEsc(s) { return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }

/* Store list — one full-width row per book: big cover, vertical rule, then
   title / subtitle / about / disclaimer, with its own Get It button. */
window.ebRenderStore = function () {
  var container = document.getElementById('ebGrid');
  if (!container) return;
  var purchasedKeys = ebGetPurchased().map(function (p) { return p.key; });
  container.innerHTML = EB_BOOKS.map(function (b) {
    var isPur = purchasedKeys.indexOf(b.key) !== -1;
    return '<div class="eb-row" onclick="window.ebOpenBook(\'' + b.key + '\')">' +
      // Top band: cover | vertical rule | the book name in big bold type
      '<div class="eb-row-head">' +
        '<div class="eb-cover-wrap"><img class="eb-cover-img" loading="lazy" decoding="async" src="' + (b.cover || EB_COVER) + '" alt=""></div>' +
        '<div class="eb-row-rule"></div>' +
        '<div class="eb-row-title">' + ebEsc(b.title) + '</div>' +
      '</div>' +
      // Everything else runs full width underneath the cover + name
      '<div class="eb-row-meta">' +
        '<div class="eb-row-sub">' + ebEsc(b.sub) + '</div>' +
        '<div class="eb-row-about">' + ebEsc(b.about) + '</div>' +
        '<div class="eb-row-disc">' + ebEsc(EB_DISCLAIMER) + '</div>' +
        '<div class="eb-row-foot">' +
          (isPur
            ? '<span class="eb-row-owned">✓ Owned</span><span class="eb-row-rule"></span><button class="eb-get-btn" onclick="event.stopPropagation();window.ebOpenBook(\'' + b.key + '\')">Read It</button>'
            : '<span class="eb-row-price">$' + (b.price / 100).toFixed(2) + '</span>' +
              '<span class="eb-row-rule"></span>' +
              '<button class="eb-get-btn" onclick="event.stopPropagation();window.ebOpenBook(\'' + b.key + '\')">Get It' +
              '<svg width="11" height="11" viewBox="0 0 12 12" fill="none"><path d="M2 6H10M7 3L10 6L7 9" stroke="#060c18" stroke-width="1.8" stroke-linecap="square"/></svg></button>') +
        '</div>' +
      '</div>' +
    '</div>';
  }).join('');
  if (typeof nssRefreshCardStates === 'function') nssRefreshCardStates();
};

/* ── Per-book detail page ── */
window.ebOpenBook = function (key) {
  var b = ebBookByKey(key);
  if (!b) return;
  var body = document.getElementById('ebdBody');
  var titleEl = document.getElementById('ebdTitle');
  if (!body) return;
  if (titleEl) titleEl.textContent = b.title;

  var isPur = window.ebIsPurchased(b.key);
  var priceStr = '$' + (b.price / 100).toFixed(2);
  var esc = function (s) { return String(s).replace(/'/g, "\\'"); };
  var args = "'" + esc(b.key) + "'";

  body.innerHTML =
    // Same shape as the list row: cover on the left, vertical rule, then
    // the book name — everything else runs full width underneath.
    '<div class="eb-row-head ebd-head">' +
      '<div class="eb-cover-wrap ebd-cover-wrap"><img class="eb-cover-img" src="' + (b.cover || EB_COVER) + '" alt=""></div>' +
      '<div class="eb-row-rule"></div>' +
      '<div>' +
        '<div class="ebd-eyebrow">Read · Learn · Practice</div>' +
        '<div class="ebd-title">' + ebEsc(b.title) + '</div>' +
      '</div>' +
    '</div>' +
    '<div class="ebd-sub">' + ebEsc(b.sub) + '</div>' +
    '<div class="ebd-label">About This Book</div>' +
    '<div class="ebd-text">' + ebEsc(b.about) + '</div>' +
    '<div class="ebd-label">What\'s Inside</div>' +
    '<ul class="ebd-list">' + (b.contents || []).map(function (c) { return '<li>' + ebEsc(c) + '</li>'; }).join('') + '</ul>' +
    (isPur
      ? '<div class="ebd-price-row"><span class="ebd-price">Owned</span></div>' +
        '<div class="ebd-owned-note">✓ You own this book — the in-app reader is coming soon.</div>'
      : '<div class="ebd-price-row"><span class="ebd-price">' + priceStr + '</span>' +
          '<span class="ebd-price-note">one-time · yours forever</span></div>' +
        '<button class="ebd-buy-btn" onclick="window.ebBuyNow(' + args + ')">Buy Now' +
          '<svg width="14" height="14" viewBox="0 0 14 14" fill="none"><path d="M3 7H11M7 3L11 7L7 11" stroke="#060c18" stroke-width="1.9" stroke-linecap="square"/></svg></button>' +
        '<div class="ebd-action-row">' +
          '<button class="ebd-action-btn" onclick="window.ebAddToCart(' + args + ')">' +
            '<svg width="15" height="15" viewBox="0 0 22 22" fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3h1.5l2.5 7h9l2-5H7"/><circle cx="9" cy="18.5" r="1.5" fill="#fff" stroke="none"/><circle cx="16" cy="18.5" r="1.5" fill="#fff" stroke="none"/></svg>Add to Cart</button>' +
          '<button class="ebd-action-btn" onclick="window.ebToggleWishlist(' + args + ')">' +
            '<svg width="15" height="15" viewBox="0 0 22 22" fill="none"><path d="M11 18.5S3 13.8 3 8.4C3 5.6 5.2 3.5 7.8 3.5c1.5 0 2.8.7 3.2 1.9.4-1.2 1.7-1.9 3.2-1.9 2.6 0 4.8 2.1 4.8 4.9 0 5.4-8 10.1-8 10.1z" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/></svg>Wishlist</button>' +
        '</div>') +
    '<div class="rm-disclaimer" style="margin-top:22px;">' +
      '<div class="rm-disclaimer-title">Disclaimer &amp; Confidentiality</div>' +
      '<div class="rm-disclaimer-text">' + ebEsc(EB_DISCLAIMER) + ' Purchases are final once unlocked. Any information you share with us is kept strictly confidential and never sold or shared with third parties.</div>' +
    '</div>';

  if (typeof openSub === 'function') openSub('ebook-detail');
};

function ebCartItem(b) {
  return { id: 'ebook-' + b.key, name: b.title, type: 'Ebook', price: b.price, img: b.cover || EB_COVER };
}

window.ebAddToCart = function (key) {
  var b = ebBookByKey(key); if (!b) return;
  if (typeof nssAddToCart === 'function') nssAddToCart(ebCartItem(b));
};

window.ebToggleWishlist = function (key) {
  var b = ebBookByKey(key); if (!b) return;
  if (typeof nssToggleWishlist === 'function') nssToggleWishlist(ebCartItem(b));
};

window.ebBuyNow = function (key) {
  var b = ebBookByKey(key); if (!b) return;
  if (typeof nssAddToCart === 'function') nssAddToCart(ebCartItem(b));
  if (typeof openSub === 'function') openSub('checkout');
};

/* Kept for older call sites (store chooser deep links) — now routes to the
   real book page instead of silently dropping the book into the cart. */
window.ebBuy = function (key) { window.ebOpenBook(key); };

window.ebOpenReader = function (key) { window.ebOpenBook(key); };

window.ebEnterFromIntro = function () {
  var intro = document.getElementById('ebIntroPage');
  var mc = document.getElementById('ebMcontent');
  if (!intro || !mc) return;
  intro.classList.add('ms-intro-hidden');
  mc.style.display = 'flex';
  setTimeout(ebRenderStore, 80);
};

// Wrap openSub to handle 'nowssb-store'
(function(){
  var _prev = window.openSub;
  window.openSub = function(id) {
    var storeIds = {
      'real-meaning': 'sub-real-meaning',
      'nowssb-store': 'sub-nowssb-store',
      'meaning-store': 'sub-meaning-store',
      'ebooks-store': 'sub-ebooks-store',
      'signature-store': 'sub-signature-store'
    };
    if (storeIds[id]) {
      var screenId = storeIds[id];
      nssCloseOtherSubScreens(screenId);
      window.nwsbResetStoreIntro(screenId);
      if (id === 'nowssb-store') { nssOpen(); return; }
    }
    if (typeof _prev === 'function') _prev.apply(this, arguments);
  };
  var _prevC = window.closeSub;
  window.closeSub = function(id) {
    if (id === 'nowssb-store') { nssClose(); return; }
    if (typeof _prevC === 'function') _prevC.apply(this, arguments);
  };
})();
