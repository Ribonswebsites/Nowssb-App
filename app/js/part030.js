
// ── Image URLs — swap these when Ribon shares the images ──
var WS_IMG_RESULT  = '';   // 3:2 main result image
var WS_IMG_UNAVAIL = '';   // unavailable tile image (3:2)
var WS_IMG_REQUEST = '';   // request tile image (3:2)
var WS_IMG_OWN     = '';   // own-your-word image (3:2)

// ══════════════════════════════════════════════════════
// CHARACTER IMAGE TEMPLATE POOL
// Add every new image Ribon gives you here.
// textColor: 'white' | 'gold' | 'silver'
// frame coords are detected AUTOMATICALLY — no manual work needed.
// Just add the URL and textColor. Detection runs once and is cached forever.
// ══════════════════════════════════════════════════════
var WS_CHAR_TEMPLATES = [
  // PASTE YOUR CLOUDINARY URLs HERE — example format:
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../tribal-warrior.jpg', textColor: 'white' },
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../roman-emperor.jpg',  textColor: 'gold'  },
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../zeus-lightning.jpg', textColor: 'gold'  },
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../white-suit.jpg',     textColor: 'white' },
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../egyptian-queen.jpg', textColor: 'gold'  },
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../purple-suit.jpg',    textColor: 'gold'  },
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../viking-thor.jpg',    textColor: 'silver'},
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../scientist.jpg',      textColor: 'white' },
  // { url: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v.../buddha.jpg',         textColor: 'gold'  },
];

// Cache key prefix for localStorage
var WS_FRAME_CACHE_KEY = 'nowssb_frame_v1_';

// Current word being shown
var _wsCharCurrentWord = '';
var _wsCharCurrentTemplate = null;

// ── Pick a random template (consistent per word using simple hash) ──
function _wsPickTemplate(word) {
  if (!WS_CHAR_TEMPLATES.length) return null;
  var hash = 0;
  for (var i = 0; i < word.length; i++) hash += word.charCodeAt(i);
  return WS_CHAR_TEMPLATES[hash % WS_CHAR_TEMPLATES.length];
}

// ── Main entry: show character image + word for searched word ──
function wsShowCharImage(word) {
  _wsCharCurrentWord = word;
  var tpl = _wsPickTemplate(word);
  if (!tpl) return; // no templates added yet
  _wsCharCurrentTemplate = tpl;

  var wrap    = document.getElementById('wsCharWrap');
  var img     = document.getElementById('wsCharImg');
  var overlay = document.getElementById('wsWordOverlay');
  var wordEl  = document.getElementById('wsWord3d');
  var detect  = document.getElementById('wsDetecting');

  // Reset state
  wrap.classList.add('show');
  wrap.classList.remove('loaded-img');
  img.classList.remove('loaded');
  wordEl.classList.remove('show');
  wordEl.textContent = word.toUpperCase();
  wordEl.className = 'ws-word-3d ' + (tpl.textColor || 'white');
  overlay.style.cssText = 'position:absolute;display:flex;align-items:center;justify-content:center;pointer-events:none;overflow:hidden;';

  // Load image
  img.src = tpl.url;

  // Check cache
  var cached = _wsGetFrameCache(tpl.url);
  if (cached) {
    // Already detected — position immediately on image load
    _wsCharCurrentTemplate._cachedFrame = cached;
    // (positioned in _wsOnCharImgLoad)
  } else {
    // Show detecting spinner
    detect.classList.add('show');
  }
}

// Called by img onload
function _wsOnCharImgLoad() {
  var tpl    = _wsCharCurrentTemplate;
  var word   = _wsCharCurrentWord;
  if (!tpl || !word) return;

  var cached = _wsGetFrameCache(tpl.url);
  if (cached) {
    // Instant — use cache
    _wsApplyFrameAndWord(cached, word, tpl.textColor);
  } else {
    // Auto-detect via Claude Vision API
    _wsDetectFrame(tpl.url, word, tpl.textColor);
  }
}

// ── AUTO-DETECT the rectangle frame using Claude Vision API ──
async function _wsDetectFrame(imageUrl, word, textColor) {
  var detect = document.getElementById('wsDetecting');
  detect.classList.add('show');

  try {
    var response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 120,
        messages: [{
          role: 'user',
          content: [
            {
              type: 'image',
              source: { type: 'url', url: imageUrl }
            },
            {
              type: 'text',
              text: 'This image shows a character holding an empty rectangular frame/box. Find that empty rectangle. Return ONLY valid JSON, nothing else, no explanation:\n{"top":NUMBER,"left":NUMBER,"w":NUMBER,"h":NUMBER}\nWhere each number is a percentage (0-100) of image dimensions. top=distance from top, left=distance from left, w=width, h=height.'
            }
          ]
        }]
      })
    });

    var data = await response.json();
    var raw  = (data.content && data.content[0] && data.content[0].text) || '';
    var clean = raw.replace(/```json|```/g, '').trim();

    // Extract JSON even if there's extra text
    var match = clean.match(/\{[^}]+\}/);
    if (!match) throw new Error('no json');
    var frame = JSON.parse(match[0]);

    // Validate
    if (typeof frame.top !== 'number') throw new Error('invalid');

    // Cache it forever
    _wsSetFrameCache(imageUrl, frame);
    _wsApplyFrameAndWord(frame, word, textColor);

  } catch(e) {
    // Fallback: use a safe default center position that works for most images
    var fallback = { top: 43, left: 9, w: 82, h: 14 };
    _wsSetFrameCache(imageUrl, fallback);
    _wsApplyFrameAndWord(fallback, word, textColor);
  }

  detect.classList.remove('show');
}

// ── Position overlay + render word ──
function _wsApplyFrameAndWord(frame, word, textColor) {
  var detect  = document.getElementById('wsDetecting');
  var overlay = document.getElementById('wsWordOverlay');
  var wordEl  = document.getElementById('wsWord3d');

  detect.classList.remove('show');

  // Position the overlay div exactly over the rectangle frame
  overlay.style.top    = frame.top  + '%';
  overlay.style.left   = frame.left + '%';
  overlay.style.width  = frame.w    + '%';
  overlay.style.height = frame.h    + '%';

  wordEl.textContent = word.toUpperCase();
  wordEl.className = 'ws-word-3d ' + (textColor || 'white');

  // Auto-fit font size to fill the frame
  requestAnimationFrame(function() {
    _wsFitWord(wordEl, overlay);
    wordEl.classList.add('show');
  });
}

// Auto-scale font so the word always fills the rectangle without overflowing
function _wsFitWord(wordEl, overlay) {
  var frameW = overlay.offsetWidth;
  var frameH = overlay.offsetHeight;
  if (!frameW || !frameH) return;

  var size = Math.floor(frameH * 0.68);
  wordEl.style.fontSize = size + 'px';

  // Shrink until fits
  var max = 200;
  while (size > 8 && max-- > 0) {
    if (wordEl.scrollWidth <= frameW * 0.88 && wordEl.scrollHeight <= frameH * 0.84) break;
    size -= 1;
    wordEl.style.fontSize = size + 'px';
  }
}

// ── LocalStorage frame cache ──
function _wsGetFrameCache(url) {
  try {
    var key  = WS_FRAME_CACHE_KEY + btoa(url).slice(0, 40);
    var item = localStorage.getItem(key);
    return item ? JSON.parse(item) : null;
  } catch(e) { return null; }
}
function _wsSetFrameCache(url, frame) {
  try {
    var key = WS_FRAME_CACHE_KEY + btoa(url).slice(0, 40);
    localStorage.setItem(key, JSON.stringify(frame));
  } catch(e) {}
}

function _wsSetImg(elId, url) {
  var el = document.getElementById(elId);
  if (!el) return;
  if (url) {
    el.src = url;
    el.style.display = 'block';
    el.parentElement && el.parentElement.classList && el.parentElement.classList.remove('ws-result-img-placeholder-only');
  } else {
    el.style.display = 'none';
  }
}

function wsPageSearchWord(word) {
  var inp = document.getElementById('wsPageInput');
  if (inp) inp.value = word;
  wsPageSearch();
}

// Track current word for request/buy
var _wsCurrentWord = '';

async function wsPageSearch() {
  var inp = document.getElementById('wsPageInput');
  var val = inp ? inp.value.trim() : '';
  if (!val) return;
  inp.blur();

  _wsCurrentWord = val;
  var word = val.charAt(0).toUpperCase() + val.slice(1);

  var result   = document.getElementById('wsPageResult');
  var imgBlock = document.getElementById('wsResultImgBlock');
  var actionRow= document.getElementById('wsActionRow');
  var ownWord  = document.getElementById('wsOwnWord');
  var wdEl     = document.getElementById('wsPageWord');
  var origEl   = document.getElementById('wsPageOrigin');
  var meanEl   = document.getElementById('wsPageMeaning');
  var eyeEl    = document.getElementById('wsPageEyebrow');
  var unavailWd= document.getElementById('wsUnavailWord');
  var requestWd= document.getElementById('wsRequestWord');
  var ownTitle = document.getElementById('wsOwnWordTitle');

  // Reset & show loading
  if (wdEl)   wdEl.textContent   = word;
  if (origEl) origEl.innerHTML   = '<span class="ws-result-loading">Decoding origin…</span>';
  if (meanEl) meanEl.textContent = '';
  if (eyeEl)  eyeEl.textContent  = 'Shabdapathy';
  if (unavailWd) unavailWd.textContent = word;
  if (requestWd) requestWd.textContent = word;
  if (ownTitle)  ownTitle.textContent  = word;

  // Show result card immediately
  if (result)   result.classList.add('show');
  // Hide extras until content loads
  if (imgBlock) imgBlock.classList.remove('show');
  if (actionRow)actionRow.classList.remove('show');
  if (ownWord)  ownWord.classList.remove('show');

  // Scroll result into view
  setTimeout(function(){ if (result) result.scrollIntoView({ behavior:'smooth', block:'nearest' }); }, 80);

  // Set images now (empty = hidden automatically by _wsSetImg)
  _wsSetImg('wsResultImgEl', WS_IMG_RESULT);
  _wsSetImg('wsUnavailImg',  WS_IMG_UNAVAIL);
  _wsSetImg('wsRequestImg',  WS_IMG_REQUEST);
  _wsSetImg('wsOwnWordImg',  WS_IMG_OWN);

  // Check local WORD_DB first
  var data = (typeof WORD_DB !== 'undefined') ? WORD_DB[val.toLowerCase()] : null;
  if (data) {
    if (origEl) origEl.textContent = data.origin  || 'Natural Origin · Decoded';
    if (meanEl) meanEl.textContent = data.meaning || '';
  } else {
    // AI fallback
    try {
      var raw = await callAI(
        [{ role:'user', content:'Natural phonetic origin of the word: "' + word + '"' }],
        { model:'claude-haiku-4-5', max_tokens:200, system:'You are a Shabdapathy expert. Decode the natural phonetic origin of any word in 2 sentences.\nRespond ONLY as valid JSON, no preamble, no backticks:\n{"origin":"Language · Root word","meaning":"2 sentence explanation of phonetic origin and body activation"}' }
      );
      var clean = raw.replace(/```json|```/g,'').trim();
      var parsed = JSON.parse(clean);
      if (origEl) origEl.textContent = parsed.origin  || 'Natural Origin · Decoded';
      if (meanEl) meanEl.textContent = parsed.meaning || '';
    } catch(e) {
      if (origEl) origEl.textContent = 'Etymology · Being Researched';
      if (meanEl) meanEl.textContent = '"' + word + '" carries unique vibrational signatures being catalogued in the Shabdapathy system.';
    }
  }

  // Show image + action tiles after content loads
  // Word availability check: if data exists in WORD_DB it's "in library"
  // If it's in store it could be bought — for now default = not available in store
  var isInStore = false; // future: check Firestore word store

  if (imgBlock) imgBlock.classList.add('show');
  setTimeout(function() {
    if (actionRow) actionRow.classList.add('show');
    if (isInStore && ownWord) ownWord.classList.add('show');
  }, 120);

  // Show character image with word automatically inside the rectangle frame
  wsShowCharImage(word);
}

// ── Request word flow ──
function wsRequestThisWord() {
  if (!_wsCurrentWord) return;
  var word = _wsCurrentWord.charAt(0).toUpperCase() + _wsCurrentWord.slice(1);
  // TODO: open payment $2.99 — wire up when payment is ready
  // For now show confirmation sheet
  _wsShowRequestSheet(word);
}

function _wsShowRequestSheet(word) {
  var existing = document.getElementById('wsRequestSheet');
  if (existing) existing.remove();
  var sheet = document.createElement('div');
  sheet.id = 'wsRequestSheet';
  sheet.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;align-items:flex-end;background:rgba(0,0,0,0.72);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);';
  sheet.innerHTML = '<div style="width:100%;background:#0e1828;border-top:1px solid rgba(200,232,245,0.14);padding:32px 24px max(env(safe-area-inset-bottom,28px),28px);font-family:\'DM Sans\',sans-serif;">' +
    '<div style="font-size:10px;font-weight:500;letter-spacing:3px;text-transform:uppercase;color:rgba(232,213,163,0.6);margin-bottom:12px;">Own Your Word</div>' +
    '<div style="font-size:28px;font-weight:800;color:#fff;margin-bottom:8px;">' + word + '</div>' +
    '<div style="font-size:14px;font-weight:300;color:rgba(255,255,255,0.5);line-height:1.6;margin-bottom:24px;">Your word will be personally crafted with phonetic breakdown, natural origin, organ activation, and healing intention — delivered to your library within 48 hours. Yours alone. Nobody else gets this word.</div>' +
    '<button onclick="wsConfirmRequest(\'' + word + '\')" style="width:100%;background:#e8d5a3;border:none;cursor:pointer;font-family:\'DM Sans\',sans-serif;font-size:14px;font-weight:700;color:#060c18;padding:16px 20px;letter-spacing:0.5px;margin-bottom:12px;display:flex;align-items:center;justify-content:space-between;">Request · $2.99 <span style="opacity:0.5;font-weight:400;">48 hrs delivery</span></button>' +
    '<button onclick="document.getElementById(\'wsRequestSheet\').remove()" style="width:100%;background:none;border:1px solid rgba(255,255,255,0.12);cursor:pointer;font-family:\'DM Sans\',sans-serif;font-size:13px;font-weight:400;color:rgba(255,255,255,0.45);padding:14px 20px;">Cancel</button>' +
    '</div>';
  sheet.onclick = function(e){ if(e.target===sheet) sheet.remove(); };
  document.body.appendChild(sheet);
}

function wsConfirmRequest(word) {
  var sheet = document.getElementById('wsRequestSheet');
  if (sheet) sheet.remove();
  // TODO: integrate payment $2.99 here
  // Show waiting state
  var waiting = document.createElement('div');
  waiting.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:rgba(6,12,24,0.95);font-family:\'DM Sans\',sans-serif;flex-direction:column;gap:16px;';
  waiting.innerHTML = '<div style="width:48px;height:48px;border-radius:50%;border:2px solid rgba(232,213,163,0.2);border-top-color:#e8d5a3;animation:wsSpinAnim 0.8s linear infinite;"></div>' +
    '<div style="font-size:13px;font-weight:300;color:rgba(255,255,255,0.6);letter-spacing:1px;">Processing request…</div>';
  document.body.appendChild(waiting);
  setTimeout(function() {
    waiting.remove();
    _wsShowSuccessSheet(word);
  }, 1800);
}

function _wsShowSuccessSheet(word) {
  var sheet = document.createElement('div');
  sheet.style.cssText = 'position:fixed;inset:0;z-index:9999;display:flex;align-items:flex-end;background:rgba(0,0,0,0.72);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);';
  sheet.innerHTML = '<div style="width:100%;background:#0e1828;border-top:1px solid rgba(232,213,163,0.2);padding:32px 24px max(env(safe-area-inset-bottom,28px),28px);font-family:\'DM Sans\',sans-serif;">' +
    '<div style="width:40px;height:40px;border-radius:50%;background:rgba(232,213,163,0.12);border:1px solid rgba(232,213,163,0.3);display:flex;align-items:center;justify-content:center;margin-bottom:20px;">' +
    '<svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M4 9l4 4 6-7" stroke="#e8d5a3" stroke-width="1.5" stroke-linecap="square"/></svg></div>' +
    '<div style="font-size:10px;font-weight:500;letter-spacing:3px;text-transform:uppercase;color:rgba(232,213,163,0.6);margin-bottom:10px;">Request placed</div>' +
    '<div style="font-size:26px;font-weight:800;color:#fff;margin-bottom:8px;">' + word + ' is being crafted.</div>' +
    '<div style="font-size:14px;font-weight:300;color:rgba(255,255,255,0.45);line-height:1.6;margin-bottom:28px;">Your word will arrive in your library within 48 hours. You will be notified the moment it is ready.</div>' +
    '<button onclick="this.parentElement.parentElement.remove()" style="width:100%;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.1);cursor:pointer;font-family:\'DM Sans\',sans-serif;font-size:13px;font-weight:400;color:rgba(255,255,255,0.6);padding:14px 20px;">Done</button>' +
    '</div>';
  sheet.onclick = function(e){ if(e.target===sheet) sheet.remove(); };
  document.body.appendChild(sheet);
}

// ── Buy word flow (when word is in store) ──
function wsBuyThisWord() {
  if (!_wsCurrentWord) return;
  var word = _wsCurrentWord.charAt(0).toUpperCase() + _wsCurrentWord.slice(1);
  // TODO: Razorpay purchase flow
  alert('Purchase flow coming soon for: ' + word);
}
