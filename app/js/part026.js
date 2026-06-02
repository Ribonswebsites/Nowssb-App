
(function(){
'use strict';

/* ── DATA ── */
var MS_BASE_MEANINGS = [
  // Elements
  { word:'Earth',   key:'earth',   root:'Proto-Germanic · erþō',        category:'Elements',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030389/grok_image_1777030001969_2_mpmpu2.jpg' },
  { word:'Water',   key:'water',   root:'Proto-Indo-European · wódr̥',   category:'Elements',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030372/grok_image_1777029845867_2_abtxad.jpg' },
  { word:'Fire',    key:'fire',    root:'Proto-Indo-European · péh₂wr̥', category:'Elements',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850648/1000033063-ezremove_r22cph.png' },
  { word:'Sun',     key:'sun',     root:'Proto-Indo-European · séh₂wl̥', category:'Elements',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850648/1000033063-ezremove_r22cph.png' },
  { word:'Moon',    key:'moon',    root:'Proto-Germanic · mēnô',         category:'Elements',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850550/1000033096-ezremove_eb2gnu.png' },
  { word:'Light',   key:'light',   root:'Proto-Indo-European · leuk-',   category:'Elements',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850648/1000033063-ezremove_r22cph.png' },
  { word:'Dark',    key:'dark',    root:'Proto-Germanic · derkaz',       category:'Elements',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850550/1000033096-ezremove_eb2gnu.png' },
  // Human
  { word:'Body',    key:'body',    root:'Old English · bodig',           category:'Human',             price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850607/1000033084-ezremove_ybzuzs.png' },
  { word:'Mind',    key:'mind',    root:'Proto-Indo-European · men-',    category:'Human',             price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850607/1000033084-ezremove_ybzuzs.png' },
  { word:'Soul',    key:'soul',    root:'Proto-Germanic · saiwalō',      category:'Human',             price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850631/1000033052-ezremove_vx4rib.png' },
  { word:'Blood',   key:'blood',   root:'Proto-Indo-European · bhel-',   category:'Human',             price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850648/1000033063-ezremove_r22cph.png' },
  { word:'Breath',  key:'breath',  root:'Proto-Germanic · brǣþ',         category:'Human',             price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850631/1000033052-ezremove_vx4rib.png' },
  // Emotions
  { word:'Love',    key:'love',    root:'Proto-Indo-European · leubh-',  category:'Emotions',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776800798/grok_image_1776753853585_luk2yh.jpg' },
  { word:'Fear',    key:'fear',    root:'Proto-Germanic · feraz',        category:'Emotions',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850550/1000033096-ezremove_eb2gnu.png' },
  { word:'Joy',     key:'joy',     root:'Old French · joie',             category:'Emotions',          price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776800798/grok_image_1776753853585_luk2yh.jpg' },
  // Cosmos
  { word:'God',     key:'god',     root:'Proto-Germanic · ǵʰew-',        category:'Cosmos',            price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850550/1000033096-ezremove_eb2gnu.png' },
  { word:'Time',    key:'time',    root:'Proto-Indo-European · dī-',     category:'Cosmos',            price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030423/grok_image_1777030062742_2_f7k7eo.jpg' },
  { word:'Space',   key:'space',   root:'Latin · spatium',               category:'Cosmos',            price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850550/1000033096-ezremove_eb2gnu.png' },
  { word:'Truth',   key:'truth',   root:'Proto-Germanic · trewwþō',      category:'Cosmos',            price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030389/grok_image_1777030001969_2_mpmpu2.jpg' },
  // Nations & People
  { word:'Country', key:'country', root:'Latin · contra',                category:'Nations & People',  price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030357/grok_image_1777029510370_2_lilo5x.jpg' },
  { word:'India',   key:'india',   root:'Natural Origin · Sindhu',             category:'Nations & People',  price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1776850589/1000033069-ezremove_hz5p0s.png' },
  { word:'Mother',  key:'mother',  root:'Proto-Indo-European · méh₂tēr', category:'Nations & People',  price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030357/grok_image_1777029510370_2_lilo5x.jpg' },
  { word:'Father',  key:'father',  root:'Proto-Indo-European · ph₂tḗr',  category:'Nations & People',  price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030423/grok_image_1777030062742_2_f7k7eo.jpg' },
  { word:'Name',    key:'name',    root:'Proto-Indo-European · h₁nómn̥', category:'Nations & People',  price:49, img:'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto/v1777030357/grok_image_1777029510370_2_lilo5x.jpg' },
];

/* ── HELPERS ── */
function msGetPurchased() {
  try { return JSON.parse(localStorage.getItem('nwsb_meaning_purchased') || '[]'); } catch(e) { return []; }
}
window.msIsPurchased = function(key) {
  return msGetPurchased().some(function(p){ return p.word === key.toLowerCase(); });
};
function msMarkPurchased(key) {
  var list = msGetPurchased();
  if (!window.msIsPurchased(key)) {
    list.push({ word: key.toLowerCase(), purchasedAt: Date.now() });
    localStorage.setItem('nwsb_meaning_purchased', JSON.stringify(list));
  }
}

/* ── AI MEANING GENERATION (Claude API) ── */
async function msGenerateMeaning(key, wordDisplay) {
  var cached = localStorage.getItem('nwsb_meaning_cache_' + key);
  if (cached) return cached;
  try {
    var res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1000,
        messages: [{
          role: 'user',
          content: 'You are the Shabdapathy phonetic vibration science system. Reveal the TRUE HIDDEN MEANING of the word "' + wordDisplay + '" — not the dictionary definition, but the natural phonetic origin. Explain: which specific sounds the word is composed of, what each phoneme does inside the human body when spoken correctly, which organ or body system it activates, where this word existed as pure vibration before any civilization wrote it down, and what natural phenomenon it originally described through sound alone. Write in exactly 3 short punchy paragraphs. No bullet points. No Sanskrit references. No religious or spiritual references. Pure natural phonetic vibration science. Each paragraph maximum 3 sentences. Be specific, striking, and original. Do not start with the word itself.'
        }]
      })
    });
    var data = await res.json();
    var text = (data.content && data.content[0] && data.content[0].text) ? data.content[0].text : '';
    if (text) { localStorage.setItem('nwsb_meaning_cache_' + key, text); }
    return text || 'Could not decode meaning. Try again.';
  } catch(e) {
    return 'Decoding failed — check connection and try again.';
  }
}

/* ── DETAIL PANEL ── */
window.msShowDetail = async function(key, wordDisplay) {
  var dp = document.getElementById('msDetailPanel');
  var dw = document.getElementById('msDetailWord');
  var dc = document.getElementById('msDetailContent');
  if (!dp || !dc) return;
  dw.textContent = wordDisplay;
  dc.innerHTML = '<div class="ms-loading">Decoding vibration\u2026</div>';
  dp.classList.add('open');
  var text = await msGenerateMeaning(key, wordDisplay);
  var paras = text.split(/\n\n+/).filter(function(p){ return p.trim(); });
  dc.innerHTML = paras.map(function(p){ return '<p class="ms-para">' + p.trim() + '</p>'; }).join('');
  // Refresh card in grid to show cached first line
  msRenderStore();
};
window.msCloseDetail = function() {
  var dp = document.getElementById('msDetailPanel');
  if (dp) dp.classList.remove('open');
};
window.msOpenDetailFromPlayer = function(key, wordDisplay) {
  if (window.msIsPurchased(key)) { window.msShowDetail(key, wordDisplay); }
};

/* ── BUY FLOW ── */
window.msBuy = function(key, wordDisplay, price) {
  // Razorpay integration slot — simulated for now
  var confirmed = confirm('Unlock true meaning of "' + wordDisplay + '" for \u20b9' + price + '?\n\nThis is a one-time purchase. The meaning will be revealed here and in your player forever.');
  if (!confirmed) return;
  msMarkPurchased(key);
  msRenderStore();
  setTimeout(function(){ window.msShowDetail(key, wordDisplay); }, 80);
};

var MS_CARD_IMG = 'https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto/v1780065459/7562ed60-5b68-11f1-af5d-9196714121d3_y4f80z.png';

/* ── RENDER STORE GRID ── */
window.msRenderStore = function() {
  var container = document.getElementById('msMeaningGrid');
  if (!container) return;

  var purchased = msGetPurchased();
  var purchasedKeys = purchased.map(function(p){ return p.word; });

  // Group base meanings by category
  var cats = {};
  MS_BASE_MEANINGS.forEach(function(m) {
    if (!cats[m.category]) cats[m.category] = [];
    cats[m.category].push(m);
  });

  var html = '';

  function cardActions(id, name, price, img, isPur) {
    if (isPur) return '';
    var cartIds = (window.nssCart||[]).map(function(c){ return c.id; });
    var wishIds = (window.nssWishlist||[]).map(function(w){ return w.id; });
    var inCart  = cartIds.indexOf('ms-' + id) >= 0;
    var inWish  = wishIds.indexOf('ms-' + id) >= 0;
    var safeImg = (img||'').replace(/'/g,'');
    var safeName = (name||'').replace(/'/g,"\\'");
    return '<div class="nss-card-actions">' +
      '<div class="nss-card-action' + (inWish ? ' wishlisted' : '') + '" data-nss-wish="ms-' + id + '" ' +
        'onclick="event.stopPropagation();nssToggleWishlist({id:\'ms-' + id + '\',name:\'' + safeName + '\',type:\'Meaning\',price:' + price + ',img:\'' + safeImg + '\'})">' +
        '<svg width="11" height="11" viewBox="0 0 16 16" fill="' + (inWish ? 'rgba(220,80,80,0.9)' : 'none') + '" xmlns="http://www.w3.org/2000/svg">' +
          '<path d="M8 13.5S2 9.5 2 5.5A3 3 0 0 1 8 4.1 3 3 0 0 1 14 5.5C14 9.5 8 13.5 8 13.5Z" stroke="rgba(255,255,255,0.6)" stroke-width="1.2" stroke-linejoin="round"/>' +
        '</svg>' +
      '</div>' +
      '<div class="nss-card-action' + (inCart ? ' carted' : '') + '" data-nss-cart="ms-' + id + '" ' +
        'onclick="event.stopPropagation();nssAddToCart({id:\'ms-' + id + '\',name:\'' + safeName + '\',type:\'Meaning\',price:' + price + ',img:\'' + safeImg + '\'})">' +
        '<svg width="11" height="11" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">' +
          '<path d="M2 2h1.5l2 8h7l1.5-5.5H4.5" stroke="rgba(232,213,163,0.8)" stroke-width="1.2" stroke-linecap="square"/>' +
          '<circle cx="7" cy="12.5" r="1" fill="rgba(232,213,163,0.7)"/>' +
          '<circle cx="11" cy="12.5" r="1" fill="rgba(232,213,163,0.7)"/>' +
        '</svg>' +
      '</div>' +
    '</div>';
  }

  Object.keys(cats).forEach(function(cat) {
    html += '<div class="ms-cat-header"><span class="ms-cat-label">' + cat + '</span></div>';
    html += '<div class="ms-grid">';
    cats[cat].forEach(function(m) {
      var isPur = purchasedKeys.indexOf(m.key) !== -1;
      var cached = localStorage.getItem('nwsb_meaning_cache_' + m.key) || '';
      html += '<div class="ms-card' + (isPur ? ' unlocked' : '') + '" style="position:relative;" onclick="' +
        (isPur ? 'window.msShowDetail(\'' + m.key + '\',\'' + m.word + '\')' : 'window.msBuy(\'' + m.key + '\',\'' + m.word + '\',' + m.price + ')') +
        '">' +
        cardActions(m.key, m.word, m.price, MS_CARD_IMG, isPur) +
        '<div class="ms-card-img" style="background-image:url(\'' + MS_CARD_IMG + '\')"></div>' +
        '<div class="ms-card-overlay"></div>' +
        '<div class="ms-card-body">' +
        '<div class="ms-card-word">' + m.word + '</div>' +
        '<div class="ms-card-root">' + m.root + '</div>' +
        (isPur
          ? '<div class="ms-card-unlocked-badge"><svg width="8" height="7" viewBox="0 0 10 9" fill="none"><path d="M1 4L3.5 7L9 1" stroke="rgba(232,213,163,0.85)" stroke-width="1.5" stroke-linecap="square"/></svg>Unlocked</div>'
          : '<div class="ms-card-price">\u20b9' + m.price + '</div>') +
        '</div></div>';
    });
    html += '</div>';
  });

  // Your Words section — from Word Store purchases
  var wsPurchased = [];
  try { wsPurchased = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]'); } catch(e) {}
  if (wsPurchased.length > 0) {
    html += '<div class="ms-cat-header"><span class="ms-cat-label">Your Words</span><div class="ms-cat-sub">Words you own from The Word Atelier</div></div>';
    html += '<div class="ms-grid">';
    wsPurchased.forEach(function(p) {
      var key = p.word.toLowerCase();
      var isPur = purchasedKeys.indexOf(key) !== -1;
      html += '<div class="ms-card' + (isPur ? ' unlocked' : '') + '" style="position:relative;" onclick="' +
        (isPur ? 'window.msShowDetail(\'' + key + '\',\'' + p.word + '\')' : 'window.msBuy(\'' + key + '\',\'' + p.word + '\',29)') +
        '">' +
        cardActions(key, p.word, 29, MS_CARD_IMG, isPur) +
        '<div class="ms-card-img" style="background-image:url(\'' + MS_CARD_IMG + '\')"></div>' +
        '<div class="ms-card-overlay"></div>' +
        '<div class="ms-card-body">' +
        '<div class="ms-card-word">' + p.word + '</div>' +
        '<div class="ms-card-root">NowssB Word</div>' +
        (isPur
          ? '<div class="ms-card-unlocked-badge"><svg width="8" height="7" viewBox="0 0 10 9" fill="none"><path d="M1 4L3.5 7L9 1" stroke="rgba(232,213,163,0.85)" stroke-width="1.5" stroke-linecap="square"/></svg>Unlocked</div>'
          : '<div class="ms-card-price">\u20b929</div>') +
        '</div></div>';
    });
    html += '</div>';
  }

  container.innerHTML = html;
  if (typeof nssRefreshCardStates === 'function') nssRefreshCardStates();
};

/* ── INTRO TRANSITION ── */
window.msEnterFromIntro = function() {
  var intro = document.getElementById('msIntroPage');
  var mc    = document.getElementById('msMcontent');
  if (!intro || !mc) return;
  intro.classList.add('ms-intro-hidden');
  mc.style.display = 'flex';
  var vid = document.getElementById('msBannerImg');
  if (vid && vid.tagName === 'VIDEO') { try { vid.play(); } catch(e) {} }
  setTimeout(msRenderStore, 80);
  setTimeout(msInitParallax, 120);
};

// Parallax scroll on the 2:3 banner
window.msInitParallax = function() {
  var body  = document.getElementById('msMeaningBody');
  var img   = document.getElementById('msBannerImg');
  if (!body || !img) return;
  body.addEventListener('scroll', function() {
    var s = body.scrollTop;
    if (s < 0) return;
    img.style.transform = 'translateY(' + (s * 0.38) + 'px)';
  }, { passive: true });
};

})();
