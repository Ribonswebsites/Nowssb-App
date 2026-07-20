
// ── NowssB Store — all logic uses direct DOM, no openSub chain dependency ──

// Open / close the NowssB Store sub-screen directly
function nssOpen() {
  var s = document.getElementById('sub-nowssb-store');
  if (s) s.classList.add('open');
  var iv = document.getElementById('nssIntroVid');
  if (iv) { iv.muted = true; iv.play().catch(function(){}); }
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
// checkout) to the generic "NowssB Store" badge instead, same as new
// Word items already get from rmdAddCart()/rmdToggleWish().
[nssCart, nssWishlist].forEach(function (list) {
  list.forEach(function (item) {
    if (item && item.type === 'Word' && typeof RM_CAT_LOGO !== 'undefined') item.img = RM_CAT_LOGO;
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

// Open sub-screens from inside NowssB Store — direct DOM, bypasses chain
function nssOpenSub(id) {
  var s = document.getElementById('sub-' + id);
  if (s) s.classList.add('open');
  // Init meaning-store
  if (id === 'meaning-store') {
    var msVid = document.getElementById('msBannerImg');
    if (msVid) { msVid.muted = true; msVid.play().catch(function(){}); }
    if (typeof msRenderStore   === 'function') setTimeout(msRenderStore,   80);
    if (typeof msInitParallax  === 'function') setTimeout(msInitParallax, 200);
  }
  // Init real-meaning (Word Store)
  if (id === 'real-meaning') {
    // Reset banner to first image every time the page is opened
    if (typeof window.rmBannerReset === 'function') window.rmBannerReset();
  }
  // social (needed by the Subscription quick-access card on the store
  // chooser, which opens 'social' then immediately opens the subscription
  // panel inside it — mirrors what openSub('social') itself does)
  if (id === 'social' && typeof ssSyncProfile === 'function') ssSyncProfile();
}

/* ══ EBOOKS STORE ══════════════════════════════════════════
   New product type added alongside the Word/Meaning stores — same cart/
   checkout pipeline (nssAddToCart), its own purchased-list localStorage
   key. No real reader built yet, so an owned ebook shows a "coming soon"
   stub instead of pretending to open real content. ══ */
var EB_BOOKS = [
  { key: 'shabdapathy-codex',    title: 'The Shabdapathy Codex',           sub: 'The complete origin science, in one volume.', price: 499 },
  { key: 'phonetic-field-guide', title: 'Phonetic Origins: A Field Guide', sub: 'Trace any word back to its first sound.',     price: 399 },
  { key: 'healing-frequencies',  title: 'Healing Frequencies Handbook',    sub: 'Which sounds activate which organs.',         price: 599 },
  { key: 'vagus-voice',          title: 'The Vagus Nerve & Voice',         sub: 'Why speaking aloud heals the body.',          price: 499 },
  { key: 'ancient-sounds',       title: 'Ancient Sounds, Modern Body',     sub: 'Pre-dictionary vibration, explained.',        price: 399 },
  { key: 'atelier-companion',    title: 'The Word Atelier Companion',      sub: 'A guide to your word library.',               price: 699 }
];
var EB_COVER = 'https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto/v1780065459/7562ed60-5b68-11f1-af5d-9196714121d3_y4f80z.png';

function ebGetPurchased() {
  try { return JSON.parse(localStorage.getItem('nwsb_ebook_purchased') || '[]'); } catch (e) { return []; }
}
window.ebIsPurchased = function (key) { return ebGetPurchased().some(function (p) { return p.key === key; }); };

window.ebRenderStore = function () {
  var container = document.getElementById('ebGrid');
  if (!container) return;
  var purchasedKeys = ebGetPurchased().map(function (p) { return p.key; });
  var html = '<div class="ms-grid">';
  EB_BOOKS.forEach(function (b) {
    var isPur = purchasedKeys.indexOf(b.key) !== -1;
    var titleSafe = b.title.replace(/'/g, "\\'");
    html += '<div class="ms-card' + (isPur ? ' unlocked' : '') + '" style="position:relative;" onclick="' +
      (isPur ? "window.ebOpenReader('" + b.key + "','" + titleSafe + "')" : "window.ebBuy('" + b.key + "','" + titleSafe + "'," + b.price + ")") +
      '">' +
      '<div class="ms-card-img" style="background-image:url(\'' + EB_COVER + '\')"></div>' +
      '<div class="ms-card-overlay"></div>' +
      '<div class="ms-card-body">' +
      '<div class="ms-card-word">' + b.title + '</div>' +
      '<div class="ms-card-root">' + b.sub + '</div>' +
      (isPur
        ? '<div class="ms-card-unlocked-badge"><svg width="8" height="7" viewBox="0 0 10 9" fill="none"><path d="M1 4L3.5 7L9 1" stroke="rgba(232,213,163,0.85)" stroke-width="1.5" stroke-linecap="square"/></svg>Owned</div>'
        : '<div class="ms-card-price">$' + (b.price / 100).toFixed(2) + '</div>') +
      '</div></div>';
  });
  html += '</div>';
  container.innerHTML = html;
  if (typeof nssRefreshCardStates === 'function') nssRefreshCardStates();
};

window.ebBuy = function (key, title, price) {
  if (typeof nssAddToCart === 'function') {
    nssAddToCart({ id: 'ebook-' + key, name: title, type: 'Ebook', price: price, img: EB_COVER });
  }
};

window.ebOpenReader = function (key, title) {
  alert('Opening "' + title + '" — the in-app reader is coming soon. Your purchase is saved.');
};

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
    if (id === 'nowssb-store') { nssOpen(); return; }
    if (typeof _prev === 'function') _prev.apply(this, arguments);
  };
  var _prevC = window.closeSub;
  window.closeSub = function(id) {
    if (id === 'nowssb-store') { nssClose(); return; }
    if (typeof _prevC === 'function') _prevC.apply(this, arguments);
  };
})();
