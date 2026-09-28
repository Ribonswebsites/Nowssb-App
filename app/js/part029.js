
(function(){
'use strict';

var _chkPayMethod = 'upi';

/* ── Select payment method ── */
window.chkSelectPay = function(method) {
  _chkPayMethod = method;
  ['upi','card','netbanking'].forEach(function(m) {
    var el = document.getElementById('chkPay' + m.charAt(0).toUpperCase() + m.slice(1));
    if (el) el.classList.toggle('selected', m === method);
  });
};

/* ── COUPONS (match the home-page banner offers + the dedicated coupon
   pages in app/js/part055.js) ──
   NOWSSB10 — flat 10% off, any order (your first word)
   NOWSSB30 — flat 30% off when the cart has 5+ items
   NOWSSB50 — flat 50% off, Signature Bundle — needs 5+ items tagged
              sigTag:'signature' specifically (not just any 5 items)
   NOWSSB60 — flat 60% off when the cart has 20+ items */
var NSS_COUPONS = {
  NOWSSB10: { pct: 10, min: 1,  label: 'Flat 10% off' },
  NOWSSB30: { pct: 30, min: 5,  label: 'Flat 30% off · 5+ words' },
  NOWSSB50: { pct: 50, min: 5,  label: 'Signature Bundle · 50% off · 5+ signature words', requireTag: 'signature' },
  NOWSSB60: { pct: 60, min: 20, label: 'Flat 60% off · 20+ words' }
};
window.NSS_COUPONS = NSS_COUPONS; // exposed for the All Offers page (app/js/part053.js) + coupon pages (part055.js)
window._nssCoupon = window._nssCoupon || null;

/* Cart items counted toward a coupon's minimum — every item for a plain
   coupon, or only the ones tagged for a requireTag coupon (e.g. Signature
   Bundle only counts items added from the Signature coupon page). */
function chkQualifyingItems(cart, c) {
  return c.requireTag ? cart.filter(function(i) { return i.sigTag === c.requireTag; }) : cart;
}

/* discount for the current cart (coupon drops silently if the cart shrinks
   below the coupon's minimum) */
function chkCouponFor(cart) {
  var c = NSS_COUPONS[window._nssCoupon];
  if (!c || chkQualifyingItems(cart, c).length < c.min) return null;
  return c;
}
window.chkCouponFor = chkCouponFor;
window.chkQualifyingItems = chkQualifyingItems; // reused by the offers hub (part053.js) for live progress

window.chkApplyCoupon = function() {
  var inp  = document.getElementById('chkCouponInput');
  var msg  = document.getElementById('chkCouponMsg');
  var cart = window.nssCart || [];
  var code = ((inp && inp.value) || '').trim().toUpperCase();
  if (!msg) return;
  if (!code) { window._nssCoupon = null; msg.textContent = ''; chkRenderSummary(); return; }
  var c = NSS_COUPONS[code];
  var qualifying = c ? chkQualifyingItems(cart, c) : [];
  if (!c) {
    window._nssCoupon = null;
    msg.style.color = 'rgba(255,120,120,0.85)';
    msg.textContent = 'Invalid coupon code.';
  } else if (qualifying.length < c.min) {
    window._nssCoupon = null;
    msg.style.color = 'rgba(255,120,120,0.85)';
    msg.textContent = 'This coupon needs at least ' + c.min + (c.requireTag ? ' signature items' : ' items') +
      ' in your cart (you have ' + qualifying.length + ').';
  } else {
    window._nssCoupon = code;
    msg.style.color = 'rgba(140,230,170,0.9)';
    msg.textContent = c.label + ' applied ✓';
  }
  chkRenderSummary();
};

/* ── Render order summary inside checkout ── */
function chkRenderSummary() {
  var cart = window.nssCart || [];
  var box  = document.getElementById('chkSummaryBox');
  var barTotal = document.getElementById('chkBarTotal');
  var btn  = document.getElementById('chkPayBtn');
  if (!box) return;

  var total = cart.reduce(function(s,c){ return s + (c.price||0); }, 0);
  var coup  = chkCouponFor(cart);
  var discount = coup ? Math.round(total * coup.pct / 100) : 0;
  if (barTotal) barTotal.textContent = '$' + ((total - discount)/100).toFixed(2);
  if (btn) btn.disabled = (cart.length === 0);

  if (cart.length === 0) {
    box.innerHTML = '<div style="padding:20px 16px;font-size:12px;font-weight:300;color:rgba(255,255,255,0.3);">No items — return to cart.</div>';
    return;
  }

  var html = '';
  cart.forEach(function(item) {
    html += '<div class="chk-sum-item">' +
      '<div class="chk-sum-thumb">' +
        (item.img
          ? '<img loading="lazy" decoding="async" src="' + item.img + '" alt="" onerror="this.style.display=\'none\'">'
          : (typeof cwpIconFor === 'function' ? cwpIconFor(item.type||'Word') : '')) +
      '</div>' +
      '<div class="chk-sum-info">' +
        '<div class="chk-sum-name">' + (item.name||'—') + '</div>' +
        '<div class="chk-sum-type">' + (item.type||'Word') + '</div>' +
      '</div>' +
      '<div class="chk-sum-price">$' + ((item.price||0)/100).toFixed(2) + '</div>' +
    '</div>';
  });

  // Discount row (when a coupon is applied)
  if (discount > 0) {
    html += '<div class="chk-total-row" style="border-bottom:none;padding-bottom:0;">' +
      '<span class="chk-total-label" style="color:rgba(140,230,170,0.85);">Coupon ' + window._nssCoupon + ' · −' + coup.pct + '%</span>' +
      '<span class="chk-total-val" style="color:rgba(140,230,170,0.9);">−$' + (discount/100).toFixed(2) + '</span>' +
    '</div>';
  }

  // Total row
  html += '<div class="chk-total-row">' +
    '<span class="chk-total-label">' + cart.length + ' item' + (cart.length !== 1 ? 's' : '') + '</span>' +
    '<span class="chk-total-val">$' + ((total - discount)/100).toFixed(2) + '</span>' +
  '</div>';

  box.innerHTML = html;
}

/* ── Pre-fill email from Firebase if logged in ── */
function chkPrefillEmail() {
  var emailEl = document.getElementById('chkEmail');
  if (!emailEl || emailEl.value) return;
  var user = window._currentUser;
  if (user && user.email) emailEl.value = user.email;
}

/* ── Checkout: purchasing is disabled on the website ──
   Words, meanings, eBooks, badges and streak restores are paid for only in
   the NowssB Android app through Google Play. This page never charges and
   never marks anything as bought — it points the buyer to the app. */
window.chkProceedToCheckout = function() {
  if (typeof window.nwsbGetAppPrompt === 'function') window.nwsbGetAppPrompt('Purchases');
  else if (typeof nssShowToast === 'function') nssShowToast('Purchases are in the NowssB Android app');
};

/* ── Wire openSub: render checkout when opened ── */
var _chkPrevOpen = window.openSub;
window.openSub = function(id) {
  if (id === 'checkout') {
    if (typeof _chkPrevOpen === 'function') _chkPrevOpen(id);
    chkRenderSummary();
    chkPrefillEmail();
    // Reset payment method selection to UPI
    _chkPayMethod = 'upi';
    ['upi','card','netbanking'].forEach(function(m) {
      var el = document.getElementById('chkPay' + m.charAt(0).toUpperCase() + m.slice(1));
      if (el) el.classList.toggle('selected', m === 'upi');
    });
    return;
  }
  if (typeof _chkPrevOpen === 'function') _chkPrevOpen.apply(this, arguments);
};

})();

;

// ── Inject cart + wishlist buttons into rm-word-cards ──
(function() {
  function rmLoadGlassStyles() {
    if (document.getElementById('nwsbWordLibraryGlassStyles')) return;
    var link = document.createElement('link');
    link.id = 'nwsbWordLibraryGlassStyles';
    link.rel = 'stylesheet';
    link.href = 'app/word-library-glass.css?v=1';
    document.head.appendChild(link);
  }

  function rmInjectCardActions() {
    rmLoadGlassStyles();
    var cards = document.querySelectorAll('.rm-word-card');
    cards.forEach(function(card) {
      if (card.querySelector('.rm-card-actions')) return; // already injected
      var nameEl = card.querySelector('.rm-word-card-name');
      if (!nameEl) return;
      var word = nameEl.textContent.trim();
      var key  = word.toLowerCase();
      // Find price from MS_BASE_MEANINGS or default to 49
      var price = 49;
      if (window.MS_BASE_MEANINGS) {
        var found = MS_BASE_MEANINGS.find(function(m){ return m.key === key; });
        if (found) price = found.price;
      }
      // Check purchased
      var purchased = [];
      try { purchased = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]'); } catch(e) {}
      var isPur = purchased.some(function(p){ return p.word && p.word.toLowerCase() === key; });
      if (isPur) return; // already owned, no buttons needed

      var cartIds = (window.nssCart||[]).map(function(c){ return c.id; });
      var wishIds = (window.nssWishlist||[]).map(function(w){ return w.id; });
      var inCart  = cartIds.indexOf('rm-' + key) >= 0;
      var inWish  = wishIds.indexOf('rm-' + key) >= 0;

      var imgEl = card.querySelector('.rm-word-card-img');
      var img = imgEl ? imgEl.src : '';

      var wrap = document.createElement('div');
      wrap.className = 'rm-card-actions';

      // Wishlist button
      var wBtn = document.createElement('div');
      wBtn.className = 'rm-card-action' + (inWish ? ' wishlisted' : '');
      wBtn.setAttribute('data-rm-wish', 'rm-' + key);
      wBtn.innerHTML = '<svg width="11" height="11" viewBox="0 0 16 16" fill="' + (inWish ? 'rgba(220,80,80,0.9)' : 'none') + '" xmlns="http://www.w3.org/2000/svg"><path d="M8 13.5S2 9.5 2 5.5A3 3 0 0 1 8 4.1 3 3 0 0 1 14 5.5C14 9.5 8 13.5 8 13.5Z" stroke="rgba(255,255,255,0.6)" stroke-width="1.2" stroke-linejoin="round"/></svg>';
      wBtn.onclick = function(e) {
        e.stopPropagation();
        if (typeof nssToggleWishlist === 'function') {
          nssToggleWishlist({id:'rm-'+key, name:word, type:'Word', price:price, img:img});
          // toggle class
          var isNowWished = (window.nssWishlist||[]).some(function(w){ return w.id === 'rm-'+key; });
          wBtn.classList.toggle('wishlisted', isNowWished);
          wBtn.querySelector('path').setAttribute('fill', isNowWished ? 'rgba(220,80,80,0.9)' : 'none');
        }
      };

      wrap.appendChild(wBtn);
      card.appendChild(wrap);

      var body = card.querySelector('.rm-word-card-body');
      if (!body) return;
      body.classList.add('rm-word-card-glass-body');
      var desc = document.createElement('div');
      desc.className = 'rm-word-card-vibration';
      desc.textContent = word.toLowerCase() === 'fire'
        ? 'Ignites clarity and transformation'
        : word.toLowerCase() === 'earth'
          ? 'Grounds presence and steady growth'
          : 'A sound signature for focused practice';
      body.appendChild(desc);

      var priceEl = document.createElement('div');
      priceEl.className = 'rm-word-card-price';
      priceEl.textContent = '₹' + price;
      body.appendChild(priceEl);

      var buy = document.createElement('button');
      buy.type = 'button';
      buy.className = 'rm-word-buy-btn' + (inCart ? ' carted' : '');
      buy.setAttribute('data-rm-cart', 'rm-' + key);
      buy.innerHTML = '<span>Buy Now</span><span class="rm-word-buy-icon"><svg width="16" height="16" viewBox="0 0 22 22" fill="none" stroke="#060c18" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3h1.5l2.5 7h9l2-5H7"/><circle cx="9" cy="18.5" r="1.4" fill="#060c18" stroke="none"/><circle cx="16" cy="18.5" r="1.4" fill="#060c18" stroke="none"/></svg></span>';
      buy.onclick = function(e) {
        e.stopPropagation();
        if (typeof nssAddToCart === 'function') {
          nssAddToCart({id:'rm-'+key, name:word, type:'Word', price:price, img:img});
          buy.classList.add('carted');
          rmPlayCartFlight(img, card);
        }
      };
      body.appendChild(buy);
    });
  }

  function rmPlayCartFlight(img, card) {
    var target = document.querySelector('#sub-real-meaning.open .rm-cart-btn, #sub-real-meaning.open [aria-label="Cart"]');
    if (!target || !img) return;
    var from = card.querySelector('.rm-word-card-img');
    if (!from) return;
    var a = from.getBoundingClientRect(), b = target.getBoundingClientRect();
    var fly = document.createElement('img');
    fly.className = 'rm-cart-flight';
    fly.src = img;
    fly.style.left = (a.left + a.width / 2 - 26) + 'px';
    fly.style.top = (a.top + a.height / 2 - 26) + 'px';
    fly.style.setProperty('--rm-flight-x', (b.left + b.width / 2 - a.left - a.width / 2) + 'px');
    fly.style.setProperty('--rm-flight-y', (b.top + b.height / 2 - a.top - a.height / 2) + 'px');
    document.body.appendChild(fly);
    fly.addEventListener('animationend', function(){ fly.remove(); }, {once:true});
  }

  // Run when real-meaning opens
  var _origOpen = window.openSub;
  window.openSub = function(id) {
    if (typeof _origOpen === 'function') _origOpen(id);
    if (id === 'real-meaning') setTimeout(rmInjectCardActions, 120);
  };

  // Also run on DOMContentLoaded in case already visible
  document.addEventListener('DOMContentLoaded', function() {
    setTimeout(rmInjectCardActions, 500);
  });
})();
