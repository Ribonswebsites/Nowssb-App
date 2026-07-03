
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

/* ── Render order summary inside checkout ── */
function chkRenderSummary() {
  var cart = window.nssCart || [];
  var box  = document.getElementById('chkSummaryBox');
  var barTotal = document.getElementById('chkBarTotal');
  var btn  = document.getElementById('chkPayBtn');
  if (!box) return;

  var total = cart.reduce(function(s,c){ return s + (c.price||0); }, 0);
  if (barTotal) barTotal.textContent = '$' + (total/100).toFixed(2);
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

  // Total row
  html += '<div class="chk-total-row">' +
    '<span class="chk-total-label">' + cart.length + ' item' + (cart.length !== 1 ? 's' : '') + '</span>' +
    '<span class="chk-total-val">$' + (total/100).toFixed(2) + '</span>' +
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

/* ── Razorpay payment flow ── */
window.chkProceedToRazorpay = function() {
  var cart  = window.nssCart || [];
  if (cart.length === 0) return;

  var email  = (document.getElementById('chkEmail') || {}).value || '';
  var phone  = (document.getElementById('chkPhone') || {}).value || '';
  var total  = cart.reduce(function(s,c){ return s + (c.price||0); }, 0);
  var amountMinor = total; // prices are already stored in USD cents (the minor unit)

  // Validate email
  if (!email || !/\S+@\S+\.\S+/.test(email)) {
    var emailEl = document.getElementById('chkEmail');
    if (emailEl) {
      emailEl.style.borderColor = 'rgba(255,100,100,0.6)';
      emailEl.focus();
      setTimeout(function(){ emailEl.style.borderColor = ''; }, 2200);
    }
    return;
  }

  // Show loading state
  var btn     = document.getElementById('chkPayBtn');
  var spinner = document.getElementById('chkSpinner');
  var arrow   = document.getElementById('chkPayArrow');
  if (btn)     { btn.disabled = true; btn.style.opacity = '0.75'; }
  if (spinner) spinner.style.display = 'block';
  if (arrow)   arrow.style.display   = 'none';

  var itemNames = cart.map(function(c){ return c.name; }).join(', ');
  var description = 'NowssB · ' + itemNames;

  // ── Create order_id via Cloudflare Worker (server-side, secure) ──
  var RAZORPAY_KEY_ID = 'rzp_live_REPLACE_WITH_YOUR_KEY'; // Only the public key goes here

  function openRazorpay(orderId) {
    var options = {
      key:         RAZORPAY_KEY_ID,
      amount:      amountMinor,
      currency:    'USD',
      name:        'NowssB',
      description: description,
      order_id:    orderId,
      prefill: { email: email, contact: phone || '' },
      theme: { color: '#e8d5a3' },
      modal: {
        ondismiss: function() {
          if (btn)     { btn.disabled = false; btn.style.opacity = ''; }
          if (spinner) spinner.style.display = 'none';
          if (arrow)   arrow.style.display   = '';
        }
      },
      handler: function(response) { chkHandleSuccess(response, cart); }
    };
    if (typeof Razorpay !== 'undefined') {
      try { new Razorpay(options).open(); }
      catch(e) { chkFallbackConfirm(total, cart); resetBtn(); }
    } else { chkFallbackConfirm(total, cart); resetBtn(); }
  }

  function resetBtn() {
    if (btn)     { btn.disabled = false; btn.style.opacity = ''; }
    if (spinner) spinner.style.display = 'none';
    if (arrow)   arrow.style.display   = '';
  }

  // Get order_id from Worker (hides Razorpay secret key)
  var apiBase = (typeof NOWSSB_API !== 'undefined') ? NOWSSB_API : '';
  if (apiBase) {
    fetch(apiBase + '/api/razorpay/order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount: amountMinor, currency: 'USD',
        notes: { email: email, items: itemNames.slice(0, 100) } })
    })
    .then(function(r){ return r.json(); })
    .then(function(ord){ openRazorpay(ord.id); })
    .catch(function(){ openRazorpay(''); }); // fallback: no order_id
  } else {
    openRazorpay('');
  }

  // Dead code — kept as reference, never runs
  if (false) {
    try {
      var rzp = {};
      rzp.open();
    } catch(e) {
      chkFallbackConfirm(total, cart);
      if (btn)     { btn.disabled = false; btn.style.opacity = ''; }
      if (spinner) spinner.style.display = 'none';
      if (arrow)   arrow.style.display   = '';
    }
  } else {
    // Razorpay SDK not loaded yet — fallback
    chkFallbackConfirm(total, cart);
    if (btn)     { btn.disabled = false; btn.style.opacity = ''; }
    if (spinner) spinner.style.display = 'none';
    if (arrow)   arrow.style.display   = '';
  }
};

/* ── Payment success handler ── */
function chkHandleSuccess(response, cart) {
  // Mark all cart items as purchased in localStorage
  var wordPurchased    = [];
  var meaningPurchased = [];
  try { wordPurchased    = JSON.parse(localStorage.getItem('nwsb_purchased')           || '[]'); } catch(e) {}
  try { meaningPurchased = JSON.parse(localStorage.getItem('nwsb_meaning_purchased')   || '[]'); } catch(e) {}

  var badgeOrder = ['blue','silver','gold','diamond'];
  var grantBadge = '';
  cart.forEach(function(item) {
    // Verified badge purchase — grant the tier, don't treat it as a word/meaning
    if (item.type === 'Badge' && item.tier) {
      if (badgeOrder.indexOf(item.tier) > badgeOrder.indexOf(grantBadge)) grantBadge = item.tier;
      return;
    }
    var entry = { word: item.name, purchasedAt: Date.now(), img: item.img || '', price: item.price };
    if (item.type === 'Meaning') {
      if (!meaningPurchased.some(function(p){ return p.word.toLowerCase() === item.name.toLowerCase(); })) {
        meaningPurchased.push(entry);
      }
    } else {
      if (!wordPurchased.some(function(p){ return p.word.toLowerCase() === item.name.toLowerCase(); })) {
        wordPurchased.push(entry);
      }
    }
  });

  try { localStorage.setItem('nwsb_purchased',          JSON.stringify(wordPurchased));    } catch(e) {}
  try { localStorage.setItem('nwsb_meaning_purchased',  JSON.stringify(meaningPurchased)); } catch(e) {}

  // Grant the verified badge tier that was bought
  if (grantBadge) {
    try { localStorage.setItem('nwsb_verify_tier', grantBadge); } catch(e) {}
    window._userDataCache = window._userDataCache || {};
    window._userDataCache.verifyTier = grantBadge;
    if (window._fbSetDoc && window._currentUid) window._fbSetDoc(window._currentUid, { verifyTier: grantBadge }).catch(function(){});
  }

  // Clear cart
  if (window.nssCart) window.nssCart = [];
  if (typeof nssUpdateBadges       === 'function') nssUpdateBadges();
  if (typeof nssUpdateHomeBadges   === 'function') nssUpdateHomeBadges();
  if (typeof nssUpdateProfileCounts === 'function') nssUpdateProfileCounts();

  // Navigate to success state
  closeSub('checkout');
  setTimeout(function() {
    if (typeof openSub === 'function') openSub('orders');
    if (typeof nssShowToast === 'function') {
      nssShowToast(grantBadge ? "You're now "+grantBadge.charAt(0).toUpperCase()+grantBadge.slice(1)+" verified ✓" : 'Purchase complete — words unlocked');
    }
  }, 120);
}

/* ── Fallback while Razorpay isn't wired up ── */
function chkFallbackConfirm(total, cart) {
  var existing = document.getElementById('chkFallbackSheet');
  if (existing) existing.remove();
  var names = cart.map(function(c){ return c.name; }).join(', ');
  var sheet = document.createElement('div');
  sheet.id = 'chkFallbackSheet';
  sheet.style.cssText = 'position:fixed;inset:0;z-index:99999;display:flex;align-items:flex-end;background:rgba(0,0,0,0.72);backdrop-filter:none;-webkit-backdrop-filter:none;';
  sheet.innerHTML =
    '<div style="width:100%;max-width:480px;margin:0 auto;background:#0e1624;border-radius:20px 20px 0 0;border-top:1px solid rgba(232,213,163,0.18);padding:28px 24px 40px;">' +
      '<div style="width:40px;height:4px;background:rgba(255,255,255,0.15);border-radius:2px;margin:0 auto 24px;"></div>' +
      '<div style="font-size:11px;font-weight:600;letter-spacing:1.2px;color:rgba(232,213,163,0.55);text-transform:uppercase;margin-bottom:8px;">Confirm Purchase</div>' +
      '<div style="font-size:15px;font-weight:500;color:rgba(255,255,255,0.85);margin-bottom:6px;">' + names + '</div>' +
      '<div style="font-size:28px;font-weight:700;color:rgba(232,213,163,0.95);margin-bottom:20px;">$' + (total/100).toFixed(2) + '</div>' +
      '<div style="font-size:11px;color:rgba(255,255,255,0.3);margin-bottom:22px;line-height:1.6;">Payment gateway coming soon. This simulates a successful purchase for testing.</div>' +
      '<button id="chkFbConfirm" style="width:100%;padding:15px;background:linear-gradient(135deg,rgba(232,213,163,0.95),rgba(200,170,100,0.9));color:#0a0e1a;font-size:14px;font-weight:700;letter-spacing:0.5px;border:none;border-radius:12px;cursor:pointer;margin-bottom:10px;">✓ Confirm Order</button>' +
      '<button id="chkFbCancel" style="width:100%;padding:14px;background:rgba(255,255,255,0.06);color:rgba(255,255,255,0.45);font-size:13px;border:1px solid rgba(255,255,255,0.1);border-radius:12px;cursor:pointer;">Cancel</button>' +
    '</div>';
  document.body.appendChild(sheet);
  function doCancel() {
    sheet.remove();
    var btn=document.getElementById('chkPayBtn'),spinner=document.getElementById('chkSpinner'),arrow=document.getElementById('chkPayArrow');
    if(btn){btn.disabled=false;btn.style.opacity='';}
    if(spinner)spinner.style.display='none';
    if(arrow)arrow.style.display='';
  }
  document.getElementById('chkFbConfirm').onclick=function(){sheet.remove();chkHandleSuccess({razorpay_payment_id:'sim_'+Date.now()},cart);};
  document.getElementById('chkFbCancel').onclick=doCancel;
  sheet.onclick=function(e){if(e.target===sheet)doCancel();};
}

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
  function rmInjectCardActions() {
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

      // Cart button
      var cBtn = document.createElement('div');
      cBtn.className = 'rm-card-action' + (inCart ? ' carted' : '');
      cBtn.setAttribute('data-rm-cart', 'rm-' + key);
      cBtn.innerHTML = '<svg width="11" height="11" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M2 2h1.5l2 8h7l1.5-5.5H4.5" stroke="rgba(232,213,163,0.8)" stroke-width="1.2" stroke-linecap="square"/><circle cx="7" cy="12.5" r="1" fill="rgba(232,213,163,0.7)"/><circle cx="11" cy="12.5" r="1" fill="rgba(232,213,163,0.7)"/></svg>';
      cBtn.onclick = function(e) {
        e.stopPropagation();
        if (typeof nssAddToCart === 'function') {
          nssAddToCart({id:'rm-'+key, name:word, type:'Word', price:price, img:img});
          cBtn.classList.add('carted');
        }
      };

      wrap.appendChild(wBtn);
      wrap.appendChild(cBtn);
      card.appendChild(wrap);
    });
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
