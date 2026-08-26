
(function(){
'use strict';

/* ─────────────────────────────────────────────
   HELPERS
───────────────────────────────────────────── */
function getCart()     { return window.nssCart     || []; }
function getWish()     { return window.nssWishlist || []; }
function getAllOrders() {
  var w = [], m = [], e = [];
  try { w = JSON.parse(localStorage.getItem('nwsb_purchased')          || '[]'); } catch(err){}
  try { m = JSON.parse(localStorage.getItem('nwsb_meaning_purchased')  || '[]'); } catch(err){}
  try { e = JSON.parse(localStorage.getItem('nwsb_ebook_purchased')    || '[]'); } catch(err){}
  var all = [];
  w.forEach(function(p){ all.push({ name:p.word,  type:'Word',    at:p.purchasedAt||0, img:p.img||'' }); });
  m.forEach(function(p){ all.push({ name:p.word,  type:'Meaning', at:p.purchasedAt||0, img:p.img||'' }); });
  e.forEach(function(p){ all.push({ name:p.title, type:'Ebook',   at:p.purchasedAt||0, img:p.img||'' }); });
  all.sort(function(a,b){ return b.at - a.at; });
  return all;
}

function fmtDate(ts) {
  if (!ts) return 'Unknown date';
  return new Date(ts).toLocaleDateString('en', {day:'numeric', month:'short', year:'numeric'});
}

function thumbHTML(item) {
  if (item.img) {
    return '<img loading="lazy" decoding="async" src="' + item.img + '" alt="" onerror="this.parentNode.innerHTML=cwpIconFor(\'' + (item.type||'Word') + '\')">';
  }
  return cwpIconFor(item.type || 'Word');
}

window.cwpIconFor = function(type) {
  if (type === 'Meaning') {
    return '<div class="cwp-item-thumb-icon"><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><rect x="3" y="4" width="16" height="14" stroke="rgba(232,213,163,0.55)" stroke-width="1.2"/><path d="M6 9H16M6 13H11" stroke="rgba(232,213,163,0.55)" stroke-width="1.2"/></svg></div>';
  }
  if (type === 'Ebook') {
    return '<div class="cwp-item-thumb-icon"><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><path d="M4 4.5A2 2 0 016 3h11v15H6a2 2 0 00-2 1.5" stroke="rgba(232,213,163,0.55)" stroke-width="1.2"/><path d="M4 4.5V18a2 2 0 002 2h11" stroke="rgba(232,213,163,0.55)" stroke-width="1.2"/></svg></div>';
  }
  if (type === 'Badge') {
    return '<div class="cwp-item-thumb-icon"><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><path d="M11 2l2.4 4.8 5.3.8-3.8 3.7.9 5.3L11 14.2l-4.8 2.4.9-5.3-3.8-3.7 5.3-.8z" stroke="rgba(200,232,245,0.55)" stroke-width="1.2"/></svg></div>';
  }
  return '<div class="cwp-item-thumb-icon"><svg width="22" height="22" viewBox="0 0 22 22" fill="none"><circle cx="11" cy="11" r="8" stroke="rgba(200,232,245,0.55)" stroke-width="1.2"/><path d="M7 11h8M11 7v8" stroke="rgba(200,232,245,0.55)" stroke-width="1.2"/></svg></div>';
};

/* ─────────────────────────────────────────────
   CART PAGE RENDER
───────────────────────────────────────────── */
function renderCartPage() {
  var cart  = getCart();
  var body  = document.getElementById('cartPageBody');
  var count = document.getElementById('cartPageCount');
  var total = document.getElementById('cartPageTotal');
  var btn   = document.getElementById('cartPageCheckoutBtn');
  if (!body) return;

  if (count) count.textContent = cart.length + ' item' + (cart.length !== 1 ? 's' : '');

  if (cart.length === 0) {
    body.innerHTML =
      '<div class="cwp-empty">' +
        '<div class="cwp-empty-icon"><svg width="26" height="26" viewBox="0 0 28 28" fill="none"><path d="M4 4h2.5l3.5 13h12l2.5-9H8" stroke="rgba(232,213,163,0.45)" stroke-width="1.4" stroke-linecap="square"/><circle cx="12" cy="22" r="1.5" fill="rgba(232,213,163,0.45)"/><circle cx="18" cy="22" r="1.5" fill="rgba(232,213,163,0.45)"/></svg></div>' +
        '<div class="cwp-empty-title">Cart is empty</div>' +
        '<div class="cwp-empty-sub">Add words or meanings from the NowssB Store to begin your order.</div>' +
        '<div class="cwp-empty-cta" onclick="navFromSub(\'cart\',function(){openSub(\'nowssb-store\');});">Browse Store →</div>' +
      '</div>';
    if (total) total.textContent = '$0.00';
    if (btn)   btn.disabled = true;
    return;
  }

  var sum  = 0;
  var html = '<span class="cwp-section-label">Items in cart</span>';
  cart.forEach(function(item) {
    sum += (item.price || 0);
    var safeId   = item.id.replace(/'/g,"\\'");
    var safeName = item.name.replace(/'/g,"\\'");
    html +=
      '<div class="cwp-item" id="cwp-cart-' + item.id + '">' +
        '<div class="cwp-item-thumb">' + thumbHTML(item) + '</div>' +
        '<div class="cwp-item-info">' +
          '<div class="cwp-item-name">' + item.name + '</div>' +
          '<div class="cwp-item-meta">' + (item.type || 'Word') + '</div>' +
        '</div>' +
        '<div class="cwp-item-right">' +
          '<div class="cwp-item-price">$' + (item.price/100).toFixed(2) + '</div>' +
          '<div class="cwp-item-actions">' +
            '<div class="cwp-item-btn gold" title="Save to wishlist" onclick="cwpCartToWish(\'' + safeId + '\',\'' + safeName + '\',' + item.price + ',\'' + (item.img||'').replace(/'/g,"\\'") + '\',\'' + (item.type||'Word') + '\')">' +
              '<img class="cw-svg-img" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779558984/20d73d50-56cc-11f1-9352-7b4e59e4b0d9_xp7xwq.png" alt="Wishlist" style="width:20px;height:20px;object-fit:contain;display:block;">' +
            '</div>' +
            '<div class="cwp-item-btn red" title="Remove" onclick="cwpRemoveFromCart(\'' + safeId + '\')">' +
              '<svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M1 1L9 9M9 1L1 9" stroke="rgba(255,80,80,0.7)" stroke-width="1.4" stroke-linecap="square"/></svg>' +
            '</div>' +
          '</div>' +
        '</div>' +
      '</div>';
  });

  html += '<span class="cwp-swipe-hint">Tap the × to remove · Tap ♡ to save for later</span>';
  body.innerHTML = html;
  if (total) total.textContent = '$' + (sum/100).toFixed(2);
  if (btn)   btn.disabled = false;
}
// Was only ever callable from this file's own IIFE-internal handlers
// (remove item, move to wishlist, ...) — never exposed, so nothing
// refreshed this screen when it was simply opened after adding an item
// elsewhere in the app. That's the actual "checkout does nothing" bug:
// the button sat on its hardcoded `disabled` and the body on whatever
// (usually nothing) was last rendered.
window.renderCartPage = renderCartPage;

/* ─────────────────────────────────────────────
   WISHLIST PAGE RENDER
───────────────────────────────────────────── */
function renderWishPage(filter) {
  var wish  = getWish();
  // filter: 'words' | 'meanings' | undefined (all)
  var filtered = wish;
  if (filter === 'words')    filtered = wish.filter(function(i){ return (i.type||'Word').toLowerCase() !== 'meaning'; });
  if (filter === 'meanings') filtered = wish.filter(function(i){ return (i.type||'Word').toLowerCase() === 'meaning'; });

  var body  = document.getElementById('wishPageBody');
  var count = document.getElementById('wishFilterCount');
  if (!body) return;

  if (count) count.textContent = filtered.length + ' saved';

  if (filtered.length === 0) {
    body.innerHTML =
      '<div class="cwp-empty">' +
        '<div class="cwp-empty-icon"><svg width="26" height="26" viewBox="0 0 28 28" fill="none"><path d="M14 23S4 16 4 9.5A5 5 0 0 1 14 7.2 5 5 0 0 1 24 9.5C24 16 14 23 14 23Z" stroke="rgba(220,80,80,0.45)" stroke-width="1.4" stroke-linejoin="round" fill="none"/></svg></div>' +
        '<div class="cwp-empty-title">Nothing saved yet</div>' +
        '<div class="cwp-empty-sub">Tap the heart icon on any word or meaning card to save it here.</div>' +
        '<div class="cwp-empty-cta" onclick="navFromSub(\'wishlist\',function(){openSub(\'nowssb-store\');});">Browse Store →</div>' +
      '</div>';
    return;
  }

  var html = '';
  if (filtered.length > 1) {
    html += '<button class="cwp-wish-move-all" onclick="cwpMoveAllToCart()">Move All to Cart (' + filtered.length + ' items)</button>';
  }
  html += '<span class="cwp-section-label">Saved items</span>';

  filtered.forEach(function(item) {
    var safeId   = item.id.replace(/'/g,"\\'");
    var safeName = item.name.replace(/'/g,"\\'");
    html +=
      '<div class="cwp-item">' +
        '<div class="cwp-item-thumb">' + thumbHTML(item) + '</div>' +
        '<div class="cwp-item-info">' +
          '<div class="cwp-item-name">' + item.name + '</div>' +
          '<div class="cwp-item-meta">' + (item.type || 'Word') + '</div>' +
        '</div>' +
        '<div class="cwp-item-right">' +
          '<div class="cwp-item-price">$' + (item.price/100).toFixed(2) + '</div>' +
          '<div class="cwp-item-actions">' +
            '<div class="cwp-item-btn gold" title="Move to cart" onclick="cwpWishToCart(\'' + safeId + '\')">' +
              '<img class="cw-svg-img" src="https://res.cloudinary.com/ds6duqabl/image/upload/v1779558987/c9c4e860-56cf-11f1-8fad-095787cce754_t6k8gb.png" alt="Move to cart" style="width:20px;height:20px;object-fit:contain;display:block;">' +
            '</div>' +
            '<div class="cwp-item-btn red" title="Remove" onclick="cwpRemoveFromWish(\'' + safeId + '\',\'' + safeName + '\',' + item.price + ',\'' + (item.img||'').replace(/'/g,"\\'") + '\',\'' + (item.type||'Word') + '\')">' +
              '<svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M1 1L9 9M9 1L1 9" stroke="rgba(255,80,80,0.7)" stroke-width="1.4" stroke-linecap="square"/></svg>' +
            '</div>' +
          '</div>' +
        '</div>' +
      '</div>';
  });

  html += '<span class="cwp-swipe-hint">Tap → to move to cart · Tap × to remove</span>';
  body.innerHTML = html;
}

/* ─────────────────────────────────────────────
   ORDERS PAGE RENDER
───────────────────────────────────────────── */
function renderOrdersPage() {
  var orders = getAllOrders();
  var body   = document.getElementById('ordersPageBody');
  var count  = document.getElementById('ordersPageCount');
  if (!body) return;

  if (count) count.textContent = orders.length + ' purchased';

  if (orders.length === 0) {
    body.innerHTML =
      '<div class="cwp-empty">' +
        '<div class="cwp-empty-icon"><svg width="26" height="26" viewBox="0 0 28 28" fill="none"><rect x="4" y="6" width="20" height="18" stroke="rgba(200,232,245,0.4)" stroke-width="1.4"/><path d="M8 12H20M8 17H14" stroke="rgba(200,232,245,0.4)" stroke-width="1.4"/><path d="M8 6V4a6 6 0 0112 0v2" stroke="rgba(200,232,245,0.4)" stroke-width="1.4"/></svg></div>' +
        '<div class="cwp-empty-title">No purchases yet</div>' +
        '<div class="cwp-empty-sub">Words and meanings you unlock from the NowssB Store will appear here permanently.</div>' +
        '<div class="cwp-empty-cta" onclick="navFromSub(\'orders\',function(){openSub(\'nowssb-store\');});">Browse Store →</div>' +
      '</div>';
    return;
  }

  var wordCount    = orders.filter(function(o){ return o.type === 'Word'; }).length;
  var meaningCount = orders.filter(function(o){ return o.type === 'Meaning'; }).length;

  var html =
    '<div class="cwp-orders-summary">' +
      '<div class="cwp-orders-stat"><div class="cwp-orders-stat-val" style="color:var(--accent-gold);">' + orders.length + '</div><div class="cwp-orders-stat-label">Total</div></div>' +
      '<div class="cwp-orders-stat"><div class="cwp-orders-stat-val" style="color:var(--accent);">' + wordCount + '</div><div class="cwp-orders-stat-label">Words</div></div>' +
      '<div class="cwp-orders-stat"><div class="cwp-orders-stat-val" style="color:rgba(232,213,163,0.75);">' + meaningCount + '</div><div class="cwp-orders-stat-label">Meanings</div></div>' +
    '</div>';

  html += '<span class="cwp-section-label">Purchase history</span>';

  orders.forEach(function(item) {
    var accentColor = item.type === 'Word' ? 'rgba(200,232,245,0.55)' : 'rgba(232,213,163,0.55)';
    html +=
      '<div class="cwp-item">' +
        '<div class="cwp-item-thumb">' + thumbHTML(item) + '</div>' +
        '<div class="cwp-item-info">' +
          '<div class="cwp-item-name">' + item.name + '</div>' +
          '<div class="cwp-item-meta">' + item.type + ' · ' + fmtDate(item.at) + '</div>' +
        '</div>' +
        '<div class="cwp-item-right">' +
          '<div class="cwp-order-badge owned">Owned</div>' +
        '</div>' +
      '</div>';
  });

  body.innerHTML = html;
}

/* ─────────────────────────────────────────────
   ACTIONS
───────────────────────────────────────────── */
window.cwpRemoveFromCart = function(id) {
  if (typeof nssRemoveFromCart === 'function') nssRemoveFromCart(id);
  renderCartPage();
};

window.cwpCartToWish = function(id, name, price, img, type) {
  // Move item from cart to wishlist
  var item = getCart().find(function(c){ return c.id === id; });
  if (!item) item = { id:id, name:name, price:price, img:img, type:type };
  if (typeof nssRemoveFromCart  === 'function') nssRemoveFromCart(id);
  if (typeof nssToggleWishlist  === 'function') nssToggleWishlist(item);
  renderCartPage();
  nssShowToast && nssShowToast('Moved to wishlist');
};

window.cwpWishToCart = function(id) {
  if (typeof nssMoveToCart === 'function') nssMoveToCart(id);
  renderWishPage(window._wishCurrentFilter);
};

window.cwpRemoveFromWish = function(id, name, price, img, type) {
  if (typeof nssToggleWishlist === 'function') nssToggleWishlist({ id:id, name:name, price:price, img:img, type:type });
  renderWishPage(window._wishCurrentFilter);
};

window.cwpMoveAllToCart = function() {
  var wish = getWish().slice();
  wish.forEach(function(item) {
    if (typeof nssMoveToCart === 'function') nssMoveToCart(item.id);
  });
  renderWishPage(window._wishCurrentFilter);
  nssShowToast && nssShowToast('All items moved to cart');
};

/* ─────────────────────────────────────────────
   WIRE INTO openSub / HOME & PROFILE BUTTONS
───────────────────────────────────────────── */

/* ── Cart intro helpers ── */
window.cartEnterFromIntro = function() {
  var intro = document.getElementById('cartIntroPage');
  var main  = document.getElementById('cartMainContent');
  if (!intro || !main) return;
  intro.style.opacity = '0';
  intro.style.pointerEvents = 'none';
  setTimeout(function() {
    intro.classList.add('cart-intro-hidden');
    intro.style.opacity = '';
    intro.style.pointerEvents = '';
    main.style.display = 'flex';
    renderCartPage();
  }, 480);
};

function _cartResetIntro() {
  setTimeout(function() {
    var intro = document.getElementById('cartIntroPage');
    var main  = document.getElementById('cartMainContent');
    if (intro) { intro.classList.remove('cart-intro-hidden'); intro.style.opacity = ''; intro.style.pointerEvents = ''; }
    if (main)  { main.style.display = 'none'; }
  }, 300);
}

/* ── Wishlist intro helpers ── */
window._wishCurrentFilter = null;

/* ── Wishlist intro bg slideshow ── */
(function() {
  // Slideshow removed — single static bg image per intro page
  // Hook into openSub / closeSub for wishlist (kept for other hooks)
  var _wlPrevOpen2  = window.openSub;
  window.openSub = function(id) {
    if (typeof _wlPrevOpen2 === 'function') _wlPrevOpen2.apply(this, arguments);
  };
  var _wlPrevClose2 = window.closeSub;
  window.closeSub = function(id) {
    if (typeof _wlPrevClose2 === 'function') _wlPrevClose2.apply(this, arguments);
  };
})();

function _wishUpdateIntroCounts() {
  var wish = getWish();
  var wordCount    = wish.filter(function(i){ return (i.type||'Word').toLowerCase() !== 'meaning'; }).length;
  var meaningCount = wish.filter(function(i){ return (i.type||'Word').toLowerCase() === 'meaning'; }).length;
  // main intro
  var wc = document.getElementById('wishIntroWordCount');
  var mc = document.getElementById('wishIntroMeaningCount');
  if (wc) wc.textContent = wordCount;
  if (mc) mc.textContent = meaningCount;
  // cat intro counts
  var wci = document.getElementById('wishWordsIntroCount');
  var mci = document.getElementById('wishMeaningsIntroCount');
  if (wci) wci.textContent = wordCount;
  if (mci) mci.textContent = meaningCount;
}

/* ── Step 1: tap card → open category intro page ── */
window.wishOpenFilter = function(type) {
  window._wishCurrentFilter = type;
  _wishUpdateIntroCounts();
  var wordsEl    = document.getElementById('wishWordsIntro');
  var meaningsEl = document.getElementById('wishMeaningsIntro');
  if (type === 'words') {
    if (meaningsEl) meaningsEl.classList.remove('wish-cat-open');
    if (wordsEl) {
      wordsEl.scrollTop = 0;
      requestAnimationFrame(function() { wordsEl.classList.add('wish-cat-open'); });
    }
  } else {
    if (wordsEl) wordsEl.classList.remove('wish-cat-open');
    if (meaningsEl) {
      meaningsEl.scrollTop = 0;
      requestAnimationFrame(function() { meaningsEl.classList.add('wish-cat-open'); });
    }
  }
};

/* ── Step 2: tap "View Collection" → open the list ── */
window.wishOpenListFromIntro = function(type) {
  var filterView = document.getElementById('wishFilterView');
  var title      = document.getElementById('wishFilterTitle');
  var eyebrow    = document.getElementById('wishFilterEyebrow');
  var heroTitle  = document.getElementById('wishFilterHeroTitle');
  var heroBg     = document.getElementById('wishFilterHeroBg');
  var heroOvl    = document.getElementById('wishFilterHeroOverlay');

  if (type === 'words') {
    if (title)    title.textContent = 'Words';
    if (eyebrow)  { eyebrow.textContent = 'NowssB Store · Words'; eyebrow.style.color = 'rgba(200,232,245,0.75)'; }
    if (heroTitle) heroTitle.innerHTML = 'Saved <span style="font-weight:200;">Words</span>';
    if (heroBg)    { heroBg.style.backgroundImage = "url('https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778783778/grok_image_1778783018581_aeitdi.jpg')"; heroBg.style.backgroundPosition = 'center top'; }
    if (heroOvl)   heroOvl.style.background = 'none';
  } else {
    if (title)    title.textContent = 'Meanings';
    if (eyebrow)  { eyebrow.textContent = 'NowssB Store · Meanings'; eyebrow.style.color = 'rgba(232,213,163,0.75)'; }
    if (heroTitle) heroTitle.innerHTML = 'Saved <span style="font-weight:200;">Meanings</span>';
    if (heroBg)    { heroBg.style.backgroundImage = "url('https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778774321/grok_image_1778773657342_pdufwz.jpg')"; heroBg.style.backgroundPosition = 'center top'; }
    if (heroOvl)   heroOvl.style.background = 'none';
  }

  renderWishPage(type);
  if (filterView) {
    filterView.scrollTop = 0;
    requestAnimationFrame(function() { filterView.classList.add('wish-filter-open'); });
  }
};

/* ── Back from cat intro → go back to main wishlist intro ── */
window.wishCloseCatIntro = function() {
  var wordsEl    = document.getElementById('wishWordsIntro');
  var meaningsEl = document.getElementById('wishMeaningsIntro');
  if (wordsEl)    wordsEl.classList.remove('wish-cat-open');
  if (meaningsEl) meaningsEl.classList.remove('wish-cat-open');
  window._wishCurrentFilter = null;
  _wishUpdateIntroCounts();
};

/* ── Back from filter list → go back to cat intro ── */
window.wishCloseFilter = function() {
  var filterView = document.getElementById('wishFilterView');
  if (filterView) filterView.classList.remove('wish-filter-open');
  // don't clear _wishCurrentFilter so cat intro stays visible
};

function _wishResetIntro() {
  setTimeout(function() {
    var intro      = document.getElementById('wishIntroPage');
    var filterView = document.getElementById('wishFilterView');
    var wordsEl    = document.getElementById('wishWordsIntro');
    var meaningsEl = document.getElementById('wishMeaningsIntro');
    if (intro)      { intro.classList.remove('wish-intro-hidden'); intro.style.opacity = ''; intro.style.pointerEvents = ''; }
    if (filterView) filterView.classList.remove('wish-filter-open');
    if (wordsEl)    wordsEl.classList.remove('wish-cat-open');
    if (meaningsEl) meaningsEl.classList.remove('wish-cat-open');
    window._wishCurrentFilter = null;
  }, 300);
}

// Patch openSub to render pages on open
var _cwpPrevOpen = window.openSub;
window.openSub = function(id) {
  if (id === 'cart') {
    if (typeof _cwpPrevOpen === 'function') _cwpPrevOpen(id);
    if (typeof shouldShowIntro === 'function' && !shouldShowIntro('cart')) {
      setTimeout(function() {
        if (typeof window.cartEnterFromIntro === 'function') window.cartEnterFromIntro();
      }, 80);
    } else {
      var intro = document.getElementById('cartIntroPage');
      var main  = document.getElementById('cartMainContent');
      if (intro) { intro.classList.remove('cart-intro-hidden'); intro.style.opacity = ''; intro.style.pointerEvents = ''; }
      if (main)  { main.style.display = 'none'; }
    }
    return;
  }
  if (id === 'wishlist') {
    if (typeof _cwpPrevOpen === 'function') _cwpPrevOpen(id);
    // Show intro page; filter views hidden until user picks Words or Meanings
    var wishIntro = document.getElementById('wishIntroPage');
    var wishFilter = document.getElementById('wishFilterView');
    if (wishIntro)  { wishIntro.classList.remove('wish-intro-hidden'); wishIntro.style.opacity = ''; wishIntro.style.pointerEvents = ''; }
    if (wishFilter) wishFilter.classList.remove('wish-filter-open');
    window._wishCurrentFilter = null;
    _wishUpdateIntroCounts();
    return;
  }
  if (id === 'orders')   { if (typeof _cwpPrevOpen === 'function') _cwpPrevOpen(id); /* intro handles render */ return; }
  if (id === 'order-history') {
    if (typeof _cwpPrevOpen === 'function') _cwpPrevOpen(id);
    _ohUpdateIntroCounts();
    return;
  }
  if (typeof _cwpPrevOpen === 'function') _cwpPrevOpen.apply(this, arguments);
};

// Reset cart intro when closed
var _cwpOrigCloseSub = window.closeSub;
if (typeof window.closeSub === 'function') {
  var _cwpOrigClose = window.closeSub;
  window.closeSub = function(id) {
    _cwpOrigClose.apply(this, arguments);
    if (id === 'cart')     _cartResetIntro();
    if (id === 'wishlist') _wishResetIntro();
  };
}

// Redirect home-page buttons to sub-screen pages instead of panels
// Override the onclick-level calls too by re-pointing nssOpenCart etc.
var _cwpOrigNssOpenCart     = window.nssOpenCart;
var _cwpOrigNssOpenWishlist = window.nssOpenWishlist;

window.nssOpenCart     = function() { openSub('cart'); };
window.nssOpenWishlist = function() { openSub('wishlist'); };
window.profileOpenOrders = function() { openSub('orders'); };

// Profile cart/wishlist row taps already call nssOpenCart / nssOpenWishlist — now routed above
// Profile orders row calls profileOpenOrders — now routed above

})();
