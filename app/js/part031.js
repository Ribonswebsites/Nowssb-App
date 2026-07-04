
// ── MS image URLs — swap when Ribon shares images ──
// Reuses the same WS_IMG_* vars defined in word-search script above
// Override here if meaning-search needs different images:
// var MS_IMG_RESULT  = '';
// var MS_IMG_UNAVAIL = '';
// var MS_IMG_REQUEST = '';
// var MS_IMG_OWN     = '';

var _msCurrentWord = '';

function msPageSearchWord(word) {
  var inp = document.getElementById('msPageInput');
  if (inp) inp.value = word;
  msPageSearch();
}

async function msPageSearch() {
  var inp = document.getElementById('msPageInput');
  var val = inp ? inp.value.trim() : '';
  if (!val) return;
  inp.blur();

  _msCurrentWord = val;
  var word = val.charAt(0).toUpperCase() + val.slice(1);

  var result    = document.getElementById('msPageResult');
  var imgBlock  = document.getElementById('msResultImgBlock');
  var actionRow = document.getElementById('msActionRow');
  var ownWord   = document.getElementById('msOwnWord');
  var wdEl      = document.getElementById('msPageWord');
  var origEl    = document.getElementById('msPageOrigin');
  var meanEl    = document.getElementById('msPageMeaning');
  var eyeEl     = document.getElementById('msPageEyebrow');
  var unavailWd = document.getElementById('msUnavailWord');
  var requestWd = document.getElementById('msRequestWord');
  var ownTitle  = document.getElementById('msOwnWordTitle');

  // Reset & loading state
  if (wdEl)   wdEl.textContent   = word;
  if (origEl) origEl.innerHTML   = '<span class="ws-result-loading">Decoding origin…</span>';
  if (meanEl) meanEl.textContent = '';
  if (eyeEl)  eyeEl.textContent  = 'Shabdapathy';
  if (unavailWd) unavailWd.textContent = word;
  if (requestWd) requestWd.textContent = word;
  if (ownTitle)  ownTitle.textContent  = word;

  if (result)    result.classList.add('show');
  var _mrp = document.getElementById('msResultPage'); if (_mrp) { _mrp.classList.add('show'); _mrp.scrollTop = 0; }
  if (imgBlock)  imgBlock.classList.remove('show');
  if (actionRow) actionRow.classList.remove('show');
  if (ownWord)   ownWord.classList.remove('show');

  // Set images
  function _msSetImg(elId, url) {
    var el = document.getElementById(elId);
    if (!el) return;
    if (url) { el.src = url; el.style.display = 'block'; }
    else { el.style.display = 'none'; }
  }
  var msImgResult  = (typeof MS_IMG_RESULT  !== 'undefined' ? MS_IMG_RESULT  : null) || (typeof WS_IMG_RESULT  !== 'undefined' ? WS_IMG_RESULT  : '');
  var msImgUnavail = (typeof MS_IMG_UNAVAIL !== 'undefined' ? MS_IMG_UNAVAIL : null) || (typeof WS_IMG_UNAVAIL !== 'undefined' ? WS_IMG_UNAVAIL : '');
  var msImgRequest = (typeof MS_IMG_REQUEST !== 'undefined' ? MS_IMG_REQUEST : null) || (typeof WS_IMG_REQUEST !== 'undefined' ? WS_IMG_REQUEST : '');
  var msImgOwn     = (typeof MS_IMG_OWN     !== 'undefined' ? MS_IMG_OWN     : null) || (typeof WS_IMG_OWN     !== 'undefined' ? WS_IMG_OWN     : '');
  _msSetImg('msResultImgEl', msImgResult);
  _msSetImg('msUnavailImg',  msImgUnavail);
  _msSetImg('msRequestImg',  msImgRequest);
  _msSetImg('msOwnWordImg',  msImgOwn);

  // AI decode
  var data = (typeof WORD_DB !== 'undefined') ? WORD_DB[val.toLowerCase()] : null;
  if (data) {
    if (origEl) origEl.textContent = data.origin  || 'Natural Origin · Decoded';
    if (meanEl) meanEl.textContent = data.meaning || '';
  } else {
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

  // Show image + tiles
  if (imgBlock) imgBlock.classList.add('show');
  setTimeout(function() {
    if (actionRow) actionRow.classList.add('show');
  }, 120);
}

function msRequestThisWord() {
  if (!_msCurrentWord) return;
  var word = _msCurrentWord.charAt(0).toUpperCase() + _msCurrentWord.slice(1);
  // Re-use the word search request sheet (same flow)
  if (typeof _wsShowRequestSheet === 'function') {
    _wsShowRequestSheet(word);
  }
}

function msBuyThisWord() {
  if (!_msCurrentWord) return;
  var word = _msCurrentWord.charAt(0).toUpperCase() + _msCurrentWord.slice(1);
  alert('Purchase flow coming soon for: ' + word);
}
