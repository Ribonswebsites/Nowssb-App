
(function(){
'use strict';

/* Meaning Store prices are stored natively in INR (e.g. 49 = ₹49). Display
   converts to the user's detected local currency when available (see
   part052.js) — the raw INR number is still what's added to cart/charged. */
function msMoneyLabel(inr) {
  if (typeof window.nwsbFormatINR === 'function') return window.nwsbFormatINR(inr);
  return '₹' + inr;
}

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
  var k = key.toLowerCase();
  return msGetPurchased().some(function(p){ return (p.word||'').toLowerCase() === k; });
};
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

var MS_CARD_IMG = 'https://res.cloudinary.com/ds6duqabl/image/upload/q_auto/f_auto/v1780065459/7562ed60-5b68-11f1-af5d-9196714121d3_y4f80z.png';

/* ── BUY FLOW ─ a real product page inside the same full-page detail panel
   purchased words open into (#msDetailPanel): hero image, description,
   Add to Cart / Wishlist (the same cart+checkout every other purchase in
   the app goes through), request banner, disclaimer and footer. No
   separate popup/sheet, no instant fake-unlock ─ buying a meaning works
   exactly like buying anything else in the store. ── */
window.msBuy = function(key, wordDisplay, price, img) {
  var dp = document.getElementById('msDetailPanel');
  var dw = document.getElementById('msDetailWord');
  var dc = document.getElementById('msDetailContent');
  if (!dp || !dc) return;
  var wordSafe = wordDisplay.replace(/'/g, "\\'");
  dw.textContent = wordDisplay;

  var heroImg = img || MS_CARD_IMG;
  var itemId = 'ms-' + key;
  var cartIds = (window.nssCart || []).map(function(c){ return c.id; });
  var wishIds = (window.nssWishlist || []).map(function(w){ return w.id; });
  var inCart = cartIds.indexOf(itemId) >= 0;
  var inWish = wishIds.indexOf(itemId) >= 0;
  var safeImg = heroImg.replace(/'/g, '');
  var itemArgs = "{id:'" + itemId + "',name:'" + wordSafe + "',type:'Meaning',price:" + price + ",img:'" + safeImg + "'}";

  var buyNowArgs = "'" + itemId + "','" + wordSafe + "'," + price + ",'" + safeImg + "'";

  dc.innerHTML =
    '<div class="ms-locked-page">' +
      '<div class="nss-vid-banner" style="margin:0 0 20px;border-radius:16px !important;cursor:pointer;" onclick="SS&&SS.open(\'subscription\')">' +
        '<video class="nss-vid-banner-vid" autoplay muted loop playsinline preload="metadata" src="https://res.cloudinary.com/eenvubod/video/upload/f_auto,q_auto/v1784431622/grok_video_2026-07-19-08-55-10_omybbr.mp4"></video>' +
        '<div class="nss-vid-banner-fade"></div>' +
        '<div class="nss-vid-banner-pill-wrap">' +
          '<div class="nss-vid-banner-pill">' +
            '<img class="nss-vid-banner-pill-icon" decoding="async" loading="lazy" src="https://res.cloudinary.com/ds6duqabl/image/upload/f_auto,q_auto/v1779563284/ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png" alt="">' +
            '<span class="nss-vid-banner-pill-text">Subscribe Today</span>' +
          '</div>' +
        '</div>' +
      '</div>' +
      '<div class="rm-desc-banner">' +
        '<div class="rm-desc-banner-row">' +
          '<div class="rm-desc-banner-left"><div class="rm-desc-banner-logo"><img decoding="async" loading="lazy" src="' + MS_CAT_LOGO + '" alt=""></div></div>' +
          '<div class="rm-desc-banner-divider"></div>' +
          '<div class="rm-desc-banner-body">' +
            '<div class="rm-desc-banner-eyebrow" id="msBuyInfoLabel">What is a Meaning?</div>' +
            '<div class="rm-desc-banner-text" id="msBuyInfoText"></div>' +
          '</div>' +
        '</div>' +
        '<div class="rm-desc-banner-dots" id="msBuyInfoDots"></div>' +
      '</div>' +
      '<div class="ms-locked-hero-banner">' +
        '<div class="ms-locked-hero-imgwrap">' +
          '<img loading="lazy" decoding="async" src="' + heroImg + '" alt="">' +
          '<div class="ms-locked-hero-badge"><svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="2.2"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 018 0v4"/></svg>Locked</div>' +
        '</div>' +
        '<div class="ms-locked-hero-divider"></div>' +
        '<div class="ms-locked-hero-textcol">' +
          '<div class="ms-locked-hero-word">' + wordDisplay + '</div>' +
          '<div class="ms-locked-hero-blurb">' + msWordBlurb(key) + '</div>' +
        '</div>' +
      '</div>' +
      '<div class="ms-locked-info">' +
        '<div class="ms-locked-eyebrow">Sound Origin &amp; Vibration Study</div>' +
        '<div class="ms-locked-price">' + msMoneyLabel(price) + '</div>' +
        '<div class="ms-locked-desc">Every word carries a vibration that predates its dictionary definition. Unlock the true phonetic origin of &ldquo;' + wordDisplay + '&rdquo; — what the sound does inside your body, which organ it activates, and where it existed before anyone wrote it down.</div>' +
        '<div class="ms-locked-actions">' +
          '<div class="ms-locked-wish-btn' + (inWish ? ' wishlisted' : '') + '" data-nss-wish="' + itemId + '" onclick="nssToggleWishlist(' + itemArgs + ')" aria-label="Wishlist">' +
            '<svg width="18" height="18" viewBox="0 0 16 16" fill="' + (inWish ? 'rgba(220,80,80,0.9)' : 'none') + '"><path d="M8 13.5S2 9.5 2 5.5A3 3 0 0 1 8 4.1 3 3 0 0 1 14 5.5C14 9.5 8 13.5 8 13.5Z" stroke="rgba(255,255,255,0.7)" stroke-width="1.2" stroke-linejoin="round"/></svg>' +
          '</div>' +
          '<button class="ms-locked-cart-btn' + (inCart ? ' carted' : '') + '" data-nss-cart="' + itemId + '" onclick="nssAddToCart(' + itemArgs + ')">' +
            '<span class="ms-locked-cart-btn-add"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#060c18" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1.3"/><circle cx="18" cy="21" r="1.3"/><path d="M2.5 3.5h2.3l1.9 10.5a1.2 1.2 0 0 0 1.2 1h8.2a1.2 1.2 0 0 0 1.2-.95L19 7.5H6"/></svg>Add to Cart · ' + msMoneyLabel(price) + '</span>' +
            '<span class="ms-locked-cart-btn-in"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>In Cart</span>' +
          '</button>' +
        '</div>' +
        '<button class="ms-locked-buynow-btn" onclick="window.msBuyNow(' + buyNowArgs + ')">Buy Now <span style="opacity:.6;">→</span></button>' +
      '</div>' +
      '<div class="rm-req-banner" onclick="msOpenMeaningRequest()">' +
        '<div class="rm-req-banner-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#e8d5a3" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg></div>' +
        '<div class="rm-req-banner-text">' +
          '<div class="rm-req-banner-eyebrow">Can&rsquo;t find your meaning?</div>' +
          '<div class="rm-req-banner-title">Request a Meaning</div>' +
          '<div class="rm-req-banner-sub">Personally decoded &amp; delivered within 48 hours.</div>' +
        '</div>' +
        '<button class="rm-req-banner-btn" onclick="event.stopPropagation();msOpenMeaningRequest()">Request' +
          '<svg width="13" height="13" viewBox="0 0 14 14" fill="none"><path d="M3 7H11M7 3L11 7L7 11" stroke="#060c18" stroke-width="1.8" stroke-linecap="square"/></svg>' +
        '</button>' +
      '</div>' +
      '<div class="rm-disclaimer">' +
        '<div class="rm-disclaimer-title">Disclaimer &amp; Confidentiality</div>' +
        '<div class="rm-disclaimer-text">Meanings, phonetic breakdowns and healing associations shared here are for educational and wellness purposes only — they are not medical advice and do not replace professional diagnosis or treatment. Requested and purchased meanings, and any information you share with us, are kept strictly confidential and are never sold or shared with third parties.</div>' +
      '</div>' +
      '<div class="rm-footer">' +
        '<div class="rm-footer-brand"><span class="b">Nowss</span><span class="t">B</span></div>' +
        '<div class="rm-footer-copy">© 2026 Adv. Sanjaykumar Gadge · Shabdapathy</div>' +
      '</div>' +
    '</div>';

  dp.classList.add('open');
  msBuyInfoBannerCycle();
};

// "What is a Meaning? / How You'll Receive It" — same rotating dot-carousel
// banner already used for the store's own description banner (rm-desc-banner),
// just cycling between these two cards instead of numbered steps. Rebuilt
// fresh every time msBuy() runs, so the old timer is always cleared first —
// otherwise it keeps painting into DOM nodes msBuy() just replaced.
var MS_BUY_INFO_STEPS = [
  { label: 'What is a Meaning?', text: 'The true phonetic origin of this word — its natural-origin root, the organ it activates, and the vibration it carries in the body.' },
  { label: 'How You’ll Receive It', text: 'Unlocked instantly in your library after purchase — no waiting, available offline anytime.' }
];
var _msBuyInfoTimer = null;
function msBuyInfoBannerCycle() {
  if (_msBuyInfoTimer) { clearInterval(_msBuyInfoTimer); _msBuyInfoTimer = null; }
  var labelEl = document.getElementById('msBuyInfoLabel');
  var textEl  = document.getElementById('msBuyInfoText');
  var dotsEl  = document.getElementById('msBuyInfoDots');
  if (!labelEl || !textEl) return;
  dotsEl.innerHTML = MS_BUY_INFO_STEPS.map(function (_, i) { return '<span class="rm-desc-dot" data-i="' + i + '"></span>'; }).join('');
  var idx = 0;
  function paint() {
    var step = MS_BUY_INFO_STEPS[idx % MS_BUY_INFO_STEPS.length];
    labelEl.textContent = step.label;
    textEl.textContent = step.text;
    textEl.classList.remove('dash-in');
    void textEl.offsetWidth;
    textEl.classList.add('dash-in');
    Array.from(dotsEl.querySelectorAll('.rm-desc-dot')).forEach(function (d, i) {
      d.classList.toggle('on', i === idx % MS_BUY_INFO_STEPS.length);
    });
    idx++;
  }
  paint();
  _msBuyInfoTimer = setInterval(paint, 3500);
}

/* Buy Now — adds to cart if needed, then jumps straight to checkout. */
window.msBuyNow = function(itemId, name, price, img) {
  if (typeof nssAddToCart === 'function') nssAddToCart({ id: itemId, name: name, type: 'Meaning', price: price, img: img });
  if (typeof openSub === 'function') openSub('checkout');
};

/* ── Category banners — same black-banner-with-logo-and-divider treatment
   as the Word Atelier (reuses its rm-cat-banner* CSS directly). ── */
var MS_CAT_LOGO = 'https://res.cloudinary.com/eenvubod/image/upload/v1784460474/file_00000000854881fa9a548a68fae59c15_w1utya.png';
var MS_CAT_SUB = {
  'Elements':          'The original sounds of the natural world',
  'Human':              'The truth of body, mind and soul',
  'Emotions':           'What every feeling really means',
  'Cosmos':             'Origins beyond understanding',
  'Nations & People':   'The people and places behind the words'
};

/* ── Signature meaning — the most expensive item in each category, same
   gold-glassmorphism treatment and shared product image as the Word
   Atelier's signature words. ── */
var MS_SIGNATURE = {
  'Elements':          { key:'elementssignature', word:'Elements Signature',        root:'Most Exclusive' },
  'Human':              { key:'humansignature',     word:'Human Signature',          root:'Most Exclusive' },
  'Emotions':           { key:'emotionssignature',  word:'Emotions Signature',       root:'Most Exclusive' },
  'Cosmos':             { key:'cosmossignature',    word:'Cosmos Signature',         root:'Most Exclusive' },
  'Nations & People':   { key:'nationssignature',   word:'Nations Signature',        root:'Most Exclusive' }
};
var MS_SIGNATURE_IMG = 'https://res.cloudinary.com/eenvubod/image/upload/v1784460713/file_000000008eb081fba87f16fe9146e413_mk9wbe.png';
var MS_SIGNATURE_PRICE = 299;

/* ── One-line plain-language blurb per word, shown next to the product
   image on the buy page. Keyed by the same lowercase key as everything
   else — falls back to a generic line for anything not listed here
   (e.g. words bought over from the Word Atelier in "Your Words"). ── */
var MS_WORD_BLURB = {
  earth:   'Earth is the place where we live — solid ground beneath every step.',
  water:   'Water is what moves through everything alive, the first thing the body remembers.',
  fire:    'Fire is the spark that turns still matter into motion and light.',
  sun:     'Sun is the source every living rhythm on this planet keeps time by.',
  moon:    'Moon is the quiet pull that shapes tides, sleep, and the turning of months.',
  light:   'Light is what makes anything visible at all — the first sense to arrive.',
  dark:    'Dark is the space light hasn&rsquo;t reached yet — rest, depth, the unseen.',
  body:    'Body is the vessel every sound, breath, and feeling moves through.',
  mind:    'Mind is the quiet voice that names, remembers, and decides.',
  soul:    'Soul is the part of you that stays the same through every change.',
  blood:   'Blood is the current that carries life to every corner of the body.',
  breath:  'Breath is the one rhythm that never stops until everything else does.',
  love:    'Love is the pull that makes distance feel like the wrong direction.',
  fear:    'Fear is the body&rsquo;s oldest warning, still firing long after the danger is real.',
  joy:     'Joy is what the body does when nothing needs fixing anymore.',
  god:     'God is the word every culture reaches for when explaining feels impossible.',
  time:    'Time is the one thing spent by everyone, saved by no one.',
  space:   'Space is the distance that makes it possible for anything to move at all.',
  truth:   'Truth is what&rsquo;s still standing after everything false has been said.',
  country: 'Country is the shared ground a people agree to call home.',
  india:   'India is the ancient root many of these very sounds first grew from.',
  mother:  'Mother is the first voice, the first shape, the first safety.',
  father:  'Father is the first structure — the one who shows what holding steady looks like.',
  name:    'Name is the sound a person is called back to, again and again.',
  elementssignature: 'The complete elemental set — every natural force, one origin story.',
  humansignature:    'The full human story — body, mind and soul in one unlocked meaning.',
  emotionssignature: 'Every core feeling, decoded to its first phonetic root.',
  cosmossignature:   'The largest ideas we have words for, traced back to pure sound.',
  nationssignature:  'Where a people, a land and a name become one meaning.'
};
function msWordBlurb(key) {
  return MS_WORD_BLURB[key] || 'A word carrying its own natural-origin vibration and history.';
}

/* ── RENDER STORE GRID ── */
window.msRenderStore = function() {
  var container = document.getElementById('msMeaningGrid');
  if (!container) return;

  var purchased = msGetPurchased();
  var purchasedKeys = purchased.map(function(p){ return (p.word||'').toLowerCase(); });

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
    html += '<div class="rm-cat-banner">';
    html += '<div class="rm-cat-banner-logo"><img decoding="async" loading="lazy" src="' + MS_CAT_LOGO + '" alt=""></div>';
    html += '<div class="rm-cat-banner-divider"></div>';
    html += '<div class="rm-cat-banner-text">';
    html += '<div class="rm-cat-banner-title">' + cat + '</div>';
    html += '<div class="rm-cat-banner-sub">' + (MS_CAT_SUB[cat] || '') + '</div>';
    html += '</div>';
    html += '</div>';
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
          : '<div class="ms-card-price">' + msMoneyLabel(m.price) + '</div>') +
        '</div></div>';
    });
    var sig = MS_SIGNATURE[cat];
    if (sig) {
      var sigIsPur = purchasedKeys.indexOf(sig.key) !== -1;
      html += '<div class="ms-card ms-card-signature' + (sigIsPur ? ' unlocked' : '') + '" style="position:relative;" onclick="' +
        (sigIsPur ? 'window.msShowDetail(\'' + sig.key + '\',\'' + sig.word + '\')' : 'window.msBuy(\'' + sig.key + '\',\'' + sig.word + '\',' + MS_SIGNATURE_PRICE + ',\'' + MS_SIGNATURE_IMG + '\')') +
        '">' +
        '<span class="ms-card-signature-tag">Signature</span>' +
        cardActions(sig.key, sig.word, MS_SIGNATURE_PRICE, MS_SIGNATURE_IMG, sigIsPur) +
        '<div class="ms-card-img" style="background-image:url(\'' + MS_SIGNATURE_IMG + '\')"></div>' +
        '<div class="ms-card-overlay"></div>' +
        '<div class="ms-card-body">' +
        '<div class="ms-card-word">' + sig.word + '</div>' +
        '<div class="ms-card-root">' + sig.root + '</div>' +
        (sigIsPur
          ? '<div class="ms-card-unlocked-badge"><svg width="8" height="7" viewBox="0 0 10 9" fill="none"><path d="M1 4L3.5 7L9 1" stroke="rgba(232,213,163,0.85)" stroke-width="1.5" stroke-linecap="square"/></svg>Unlocked</div>'
          : '<div class="ms-card-price">' + msMoneyLabel(MS_SIGNATURE_PRICE) + '</div>') +
        '</div></div>';
    }
    html += '</div>';
  });

  // Your Words section — from Word Store purchases
  var wsPurchased = [];
  try { wsPurchased = JSON.parse(localStorage.getItem('nwsb_purchased') || '[]'); } catch(e) {}
  if (wsPurchased.length > 0) {
    html += '<div class="rm-cat-banner">';
    html += '<div class="rm-cat-banner-logo"><img decoding="async" loading="lazy" src="' + MS_CAT_LOGO + '" alt=""></div>';
    html += '<div class="rm-cat-banner-divider"></div>';
    html += '<div class="rm-cat-banner-text">';
    html += '<div class="rm-cat-banner-title">Your Words</div>';
    html += '<div class="rm-cat-banner-sub">Words you own from The Word Atelier</div>';
    html += '</div>';
    html += '</div>';
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
          : '<div class="ms-card-price">' + msMoneyLabel(29) + '</div>') +
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
  msVidBannerCycle();
  msDescBannerCycle();
  window.msStoreBgSync();
};

// Description banner — rotates the intro overview, then each step, one at
// a time, dash-in from the right (same treatment as the video banner's
// cycling tagline). Dots track progress.
var MS_DESC_STEPS = [
  { label: 'Overview · 1/2', badge: '★', text: 'Every word carries a vibration that predates its dictionary definition. Unlock the true phonetic origin — what the sound does inside your body.' },
  { label: 'Overview · 2/2', badge: '★', text: 'Which organ it activates, and where this word existed before anyone wrote it down. Nothing here is free — every meaning is a one-time unlock, yours forever.' },
  { label: 'Step 1', badge: '1', text: 'Every word carries a vibration that predates its dictionary definition.' },
  { label: 'Step 2', badge: '2', text: 'Unlock the true phonetic origin — what the sound does inside your body.' },
  { label: 'Step 3', badge: '3', text: 'Discover which organ it activates, and where it existed before anyone wrote it down.' },
  { label: 'Step 4', badge: '4', text: 'Every meaning is a one-time unlock, yours forever.' }
];
var _msDescTimer = null;
function msDescBannerCycle() {
  var labelEl = document.getElementById('msDescStepLabel');
  var textEl  = document.getElementById('msDescStepText');
  var badgeEl = document.getElementById('msDescStepBadge');
  var dotsEl  = document.getElementById('msDescDots');
  if (!labelEl || !textEl) return;
  if (dotsEl && !dotsEl.dataset.built) {
    dotsEl.innerHTML = MS_DESC_STEPS.map(function (_, i) { return '<span class="rm-desc-dot" data-i="' + i + '"></span>'; }).join('');
    dotsEl.dataset.built = '1';
  }
  if (_msDescTimer) return;
  var idx = 0;
  function paint() {
    var step = MS_DESC_STEPS[idx % MS_DESC_STEPS.length];
    labelEl.textContent = step.label;
    textEl.textContent = step.text;
    if (badgeEl) badgeEl.textContent = step.badge;
    textEl.classList.remove('dash-in');
    void textEl.offsetWidth;
    textEl.classList.add('dash-in');
    if (dotsEl) {
      Array.from(dotsEl.querySelectorAll('.rm-desc-dot')).forEach(function (d, i) {
        d.classList.toggle('on', i === idx % MS_DESC_STEPS.length);
      });
    }
    idx++;
  }
  paint();
  _msDescTimer = setInterval(paint, 3500);
}

// Meaning Store's own backdrop — mirrors rmStoreBgSync() in part012.js
// exactly: same custom Fashion background if the user has picked one
// (via this screen's own customize icon or anywhere else it's exposed),
// otherwise left at the plain default. #msBg already carries the
// app-wide .sub-screen-bg dark gradient overlay.
window.msStoreBgSync = function() {
  var bg = document.getElementById('msBg');
  if (!bg) return;
  var custom = null;
  try { custom = localStorage.getItem('nwsb_fashion_bg_custom'); } catch (e) {}
  if (custom === '__black__') {
    bg.style.backgroundImage = 'none';
    bg.style.backgroundColor = '#000';
  } else if (custom) {
    bg.style.backgroundImage = "url('" + custom + "')";
    bg.style.backgroundColor = '';
  } else {
    bg.style.backgroundImage = '';
    bg.style.backgroundColor = '';
  }
};

// Video banner text — icon stays fixed, only the tagline cycles (mirrors
// nssVidBannerCycle() in part012.js).
var MS_VID_BANNER_TAGLINES = ['Buy Meanings', 'Request Meanings', 'Build Your Library', 'Heal with Sound'];
var _msVidBannerTimer = null;
function msVidBannerCycle() {
  var el = document.getElementById('msVidBannerText');
  if (!el || _msVidBannerTimer) return;
  var idx = 0;
  function paint() {
    el.textContent = MS_VID_BANNER_TAGLINES[idx % MS_VID_BANNER_TAGLINES.length];
    el.classList.remove('dash-in');
    void el.offsetWidth;
    el.classList.add('dash-in');
    idx++;
  }
  paint();
  _msVidBannerTimer = setInterval(paint, 3000);
}

// ── Request-a-meaning flow — mirrors rmOpenWordRequest()/rmConfirmWordRequest()
// in part012.js, with Meaning-flavored copy and ₹ pricing.
window.msOpenMeaningRequest = function() {
  var existing = document.getElementById('msReqSheet');
  if (existing) existing.remove();
  var sheet = document.createElement('div');
  sheet.id = 'msReqSheet';
  sheet.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;align-items:flex-end;background:rgba(0,0,0,0.72);';
  sheet.innerHTML = '<div style="width:100%;background:#0e1828;border-top:1px solid rgba(232,213,163,0.2);padding:32px 24px max(env(safe-area-inset-bottom,28px),28px);font-family:\'DM Sans\',sans-serif;box-sizing:border-box;">' +
    '<div style="font-size:10px;font-weight:500;letter-spacing:3px;text-transform:uppercase;color:rgba(232,213,163,0.6);margin-bottom:12px;">Request a Meaning</div>' +
    '<div style="font-size:22px;font-weight:800;color:#fff;margin-bottom:8px;">Any word. Its true meaning.</div>' +
    '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.5);line-height:1.6;margin-bottom:20px;">Type any word or name — our team personally decodes its phonetic origin, healing intention and hidden meaning, delivered to your library within 48 hours.</div>' +
    '<input id="msReqInput" type="text" placeholder="Type a word…" style="width:100%;box-sizing:border-box;background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.14);color:#fff;font-family:\'DM Sans\',sans-serif;font-size:15px;padding:14px 16px;margin-bottom:16px;outline:none;">' +
    '<button onclick="msConfirmMeaningRequest()" style="width:100%;background:#e8d5a3;border:none;cursor:pointer;font-family:\'DM Sans\',sans-serif;font-size:14px;font-weight:700;color:#060c18;padding:16px 20px;letter-spacing:0.5px;margin-bottom:12px;display:flex;align-items:center;justify-content:space-between;">Request · ₹199 <span style="opacity:0.5;font-weight:400;">48 hrs delivery</span></button>' +
    '<button onclick="document.getElementById(\'msReqSheet\').remove()" style="width:100%;background:none;border:1px solid rgba(255,255,255,0.12);cursor:pointer;font-family:\'DM Sans\',sans-serif;font-size:13px;font-weight:400;color:rgba(255,255,255,0.45);padding:14px 20px;">Cancel</button>' +
    '</div>';
  sheet.onclick = function(e){ if (e.target === sheet) sheet.remove(); };
  document.body.appendChild(sheet);
  setTimeout(function() { var inp = document.getElementById('msReqInput'); if (inp) inp.focus(); }, 50);
};

window.msConfirmMeaningRequest = function() {
  var inp = document.getElementById('msReqInput');
  var word = inp ? inp.value.trim() : '';
  if (!word) { if (inp) inp.style.borderColor = 'rgba(255,100,100,0.6)'; return; }
  word = word.charAt(0).toUpperCase() + word.slice(1);
  var sheet = document.getElementById('msReqSheet');
  if (sheet) sheet.remove();
  // TODO: integrate payment ₹199 here — same placeholder pattern as
  // rmConfirmWordRequest() in part012.js until Razorpay is wired up.
  var waiting = document.createElement('div');
  waiting.id = 'msReqWaiting';
  waiting.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:rgba(6,12,24,0.95);font-family:\'DM Sans\',sans-serif;flex-direction:column;gap:16px;';
  waiting.innerHTML = '<div style="width:48px;height:48px;border-radius:50%;border:2px solid rgba(232,213,163,0.2);border-top-color:#e8d5a3;animation:wsSpinAnim 0.8s linear infinite;"></div>' +
    '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.6);letter-spacing:1px;">Decoding request…</div>';
  document.body.appendChild(waiting);
  setTimeout(function() {
    var w = document.getElementById('msReqWaiting');
    if (w) w.remove();
    if (typeof _wsShowSuccessSheet === 'function') _wsShowSuccessSheet(word);
  }, 1800);
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
