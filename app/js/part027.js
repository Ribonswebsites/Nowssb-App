
/* ══ ORDERS INTRO ══ */
window.ordersEnterFromIntro = function() {
  var intro = document.getElementById('ordersIntroPage');
  var main  = document.getElementById('ordersMainContent');
  if (intro) intro.classList.add('orders-intro-hidden');
  if (main)  { main.style.display = 'flex'; setTimeout(function(){ renderOrdersPage(); }, 60); }
};
/* Reset intro when orders sub-screen closes */
(function(){
  var _prev = window.closeSub;
  window.closeSub = function(id) {
    if (id === 'orders') {
      var intro = document.getElementById('ordersIntroPage');
      var main  = document.getElementById('ordersMainContent');
      if (intro) intro.classList.remove('orders-intro-hidden');
      if (main)  main.style.display = 'none';
    }
    if (id === 'order-history') {
      _ohResetAll();
    }
    if (typeof _prev === 'function') _prev.apply(this, arguments);
  };
})();

/* ══ ORDER HISTORY INTRO ══ */
window.ohEnterFromIntro = function() { /* legacy no-op — intro now uses category cards */ };

/* ══ ORDER HISTORY — wishlist-style navigation ══ */
function _ohUpdateIntroCounts() {
  var orders = (typeof getAllOrders === 'function') ? getAllOrders() : [];
  var wordCount    = orders.filter(function(o){ return o.type === 'Word'; }).length;
  var meaningCount = orders.filter(function(o){ return o.type === 'Meaning'; }).length;
  var wc = document.getElementById('ohIntroWordCount');
  var mc = document.getElementById('ohIntroMeaningCount');
  if (wc) wc.textContent = wordCount;
  if (mc) mc.textContent = meaningCount;
  var wci = document.getElementById('ohWordsIntroCount');
  var mci = document.getElementById('ohMeaningsIntroCount');
  if (wci) wci.textContent = wordCount;
  if (mci) mci.textContent = meaningCount;
}

/* Step 1: tap option card → open category intro */
window.ohOpenFilter = function(type) {
  window._ohCurrentFilter = type;
  _ohUpdateIntroCounts();
  var wordsEl    = document.getElementById('ohWordsIntro');
  var meaningsEl = document.getElementById('ohMeaningsIntro');
  if (type === 'words') {
    if (meaningsEl) meaningsEl.classList.remove('oh-cat-open');
    if (wordsEl)  { wordsEl.scrollTop = 0; requestAnimationFrame(function(){ wordsEl.classList.add('oh-cat-open'); }); }
  } else {
    if (wordsEl)    wordsEl.classList.remove('oh-cat-open');
    if (meaningsEl) { meaningsEl.scrollTop = 0; requestAnimationFrame(function(){ meaningsEl.classList.add('oh-cat-open'); }); }
  }
};

/* Step 2: tap "View History" → open the list */
window.ohOpenListFromIntro = function(type) {
  var filterView = document.getElementById('ohFilterView');
  var filterCount= document.getElementById('ohFilterCount');
  var title      = document.getElementById('ohFilterTitle');
  var orders     = (typeof getAllOrders === 'function') ? getAllOrders() : [];
  var cnt        = orders.filter(function(o){ return type === 'words' ? o.type === 'Word' : o.type === 'Meaning'; }).length;
  if (filterCount) filterCount.textContent = cnt + ' purchased';
  if (title) title.textContent = type === 'words' ? 'Words' : 'Meanings';

  if (type === 'words') {
    _ohSetBanners([
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778891277/image-143_pfuqmd.jpg',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778891320/image-213_sggc81.jpg'
    ]);
  } else {
    _ohSetBanners([
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778848483/image-148_zfrtqg.jpg',
      'https://res.cloudinary.com/dcbs8xr1l/image/upload/v1778891248/image-101_pppzbn.jpg'
    ]);
  }

  renderOhPage(type);
  if (filterView) { filterView.scrollTop = 0; requestAnimationFrame(function(){ filterView.classList.add('oh-filter-open'); }); }
};

/* Back from cat intro → main intro */
window.ohCloseCatIntro = function() {
  var wordsEl    = document.getElementById('ohWordsIntro');
  var meaningsEl = document.getElementById('ohMeaningsIntro');
  if (wordsEl)    wordsEl.classList.remove('oh-cat-open');
  if (meaningsEl) meaningsEl.classList.remove('oh-cat-open');
  window._ohCurrentFilter = null;
  _ohUpdateIntroCounts();
};

/* Back from list → cat intro */
window.ohCloseFilter = function() {
  var filterView = document.getElementById('ohFilterView');
  if (filterView) filterView.classList.remove('oh-filter-open');
};

function _ohResetAll() {
  setTimeout(function() {
    var intro      = document.getElementById('ohIntroPage');
    var filterView = document.getElementById('ohFilterView');
    var wordsEl    = document.getElementById('ohWordsIntro');
    var meaningsEl = document.getElementById('ohMeaningsIntro');
    if (intro)      intro.classList.remove('oh-intro-hidden');
    if (filterView) filterView.classList.remove('oh-filter-open');
    if (wordsEl)    wordsEl.classList.remove('oh-cat-open');
    if (meaningsEl) meaningsEl.classList.remove('oh-cat-open');
    window._ohCurrentFilter = null;
  }, 300);
}

/* ── Hero banner slider helper ── */
var _ohBannerTimer = null;
var _ohBannerIdx   = 0;
function _ohSetBanners(urls) {
  var track  = document.getElementById('ohHeroTrack');
  var slide0 = document.getElementById('ohHeroSlide0');
  var slide1 = document.getElementById('ohHeroSlide1');
  var dots   = document.getElementById('ohHeroDots');
  if (!track || !slide0 || !slide1) return;

  _ohBannerIdx = 0;
  if (_ohBannerTimer) { clearInterval(_ohBannerTimer); _ohBannerTimer = null; }

  /* Set backgrounds */
  slide0.style.backgroundImage = "url('" + (urls[0]||'') + "')";
  slide1.style.backgroundImage = "url('" + (urls[1]||urls[0]||'') + "')";

  /* Reset to first slide */
  track.style.transition = 'none';
  track.style.transform  = 'translateX(0)';

  /* Build dots */
  if (dots) {
    dots.innerHTML = '';
    urls.forEach(function(_, i) {
      var d = document.createElement('div');
      d.style.cssText = 'width:5px;height:5px;border-radius:50%;background:' + (i===0?'rgba(232,213,163,0.85)':'rgba(255,255,255,0.28)') + ';transition:background 0.3s;';
      dots.appendChild(d);
    });
  }

  function goTo(idx) {
    _ohBannerIdx = (idx + urls.length) % urls.length;
    track.style.transition = 'transform 0.48s cubic-bezier(0.4,0,0.2,1)';
    track.style.transform  = 'translateX(-' + (_ohBannerIdx * 100) + '%)';
    if (dots) {
      Array.from(dots.children).forEach(function(d, i){
        d.style.background = i === _ohBannerIdx ? 'rgba(232,213,163,0.85)' : 'rgba(255,255,255,0.28)';
      });
    }
  }

  /* Touch swipe on the hero */
  var wrap = document.getElementById('ohHeroWrap');
  if (wrap) {
    var startX = 0;
    wrap.ontouchstart = function(e){ startX = e.touches[0].clientX; };
    wrap.ontouchend   = function(e){ var dx = e.changedTouches[0].clientX - startX; if (Math.abs(dx)>40) goTo(_ohBannerIdx+(dx<0?1:-1)); };
  }

  /* Auto-advance every 3.5 s */
  if (urls.length > 1) {
    _ohBannerTimer = setInterval(function(){ goTo(_ohBannerIdx + 1); }, 3500);
  }
}

function renderOhPage(filter) {
  var orders  = (typeof getAllOrders === 'function') ? getAllOrders() : [];
  var body    = document.getElementById('ohPageBody');
  var stats   = document.getElementById('ohStatsBar');
  if (!body) return;

  var filtered = orders;
  if (filter === 'words')    filtered = orders.filter(function(o){ return o.type === 'Word'; });
  if (filter === 'meanings') filtered = orders.filter(function(o){ return o.type === 'Meaning'; });

  var totalSpend = 0;
  filtered.forEach(function(o){ totalSpend += (o.price||0); });

  if (stats) {
    stats.innerHTML =
      '<div class="oh-stat-box"><div class="oh-stat-val">' + filtered.length + '</div><div class="oh-stat-key">Items</div></div>' +
      (totalSpend > 0 ? '<div class="oh-stat-box"><div class="oh-stat-val">$' + (totalSpend/100).toFixed(2) + '</div><div class="oh-stat-key">Spent</div></div>' : '') +
      '<div class="oh-stat-box"><div class="oh-stat-val">' + (filter === 'words' ? orders.filter(function(o){return o.type==='Word';}).length : orders.filter(function(o){return o.type==='Meaning';}).length) + '</div><div class="oh-stat-key">' + (filter === 'words' ? 'Words' : 'Meanings') + '</div></div>';
  }

  if (filtered.length === 0) {
    body.innerHTML = '<div class="cwp-empty"><div class="cwp-empty-title">No ' + (filter === 'words' ? 'words' : 'meanings') + ' yet</div><div class="cwp-empty-sub">Your purchase archive will appear here once you start unlocking ' + (filter === 'words' ? 'words' : 'meanings') + '.</div><div class="cwp-empty-cta" onclick="ohCloseFilter();ohCloseCatIntro();navFromSub(\'order-history\',function(){openSub(\'nowssb-store\');});">Browse Store →</div></div>';
    return;
  }

  /* Group by Month-Year */
  var groups = {}, groupOrder = [];
  filtered.forEach(function(o) {
    var d   = o.at ? new Date(o.at) : new Date(0);
    var key = d.toLocaleDateString('en', {month:'long', year:'numeric'});
    if (!groups[key]) { groups[key] = []; groupOrder.push(key); }
    groups[key].push(o);
  });

  var html = '';
  groupOrder.forEach(function(key) {
    html += '<div class="oh-month-group"><span class="oh-month-label">' + key + '</span>';
    groups[key].forEach(function(item) {
      html +=
        '<div class="oh-item">' +
        '<div class="oh-item-thumb">' + (item.img ? '<img loading="lazy" decoding="async" src="' + item.img + '" alt="">' : (typeof cwpIconFor === 'function' ? cwpIconFor(item.type||'Word') : '')) + '</div>' +
        '<div class="oh-item-info"><div class="oh-item-name">' + item.name + '</div><div class="oh-item-meta">' + item.type + '</div></div>' +
        '<div class="oh-item-right">' + (item.price ? '<div class="oh-item-price">$' + (item.price/100).toFixed(2) + '</div>' : '') + '<div class="oh-item-date">' + (typeof fmtDate === 'function' ? fmtDate(item.at) : '') + '</div></div>' +
        '</div>';
    });
    html += '</div>';
  });
  body.innerHTML = html;
}
