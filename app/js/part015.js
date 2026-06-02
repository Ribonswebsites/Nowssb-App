
// ══ WORD LIBRARY DATA — extended with genre tags ══
const WL_GENRE_MAP = {
  'AAROGYA':   { genre: 'immunity',   label: 'Immunity'   },
  'PRANA':     { genre: 'energy',     label: 'Energy'     },
  'SHAKTI':    { genre: 'confidence', label: 'Confidence' },
  // Extended fallbacks for any future words:
  'DEFAULT':   { genre: 'healing',    label: 'Healing'    }
};
// Genre for each PRACTICE_WORD — auto-assigned if not in map
function wlGetGenre(word) {
  return WL_GENRE_MAP[word] || WL_GENRE_MAP['DEFAULT'];
}

// ── State ──
let _wlActiveTab    = 'playlist';
let _wlActiveGenre  = 'all';
let _wlMood         = 'healing';
let _wlSelected     = new Set();
let _wlSentenceData = null;
let _wlSpeaking     = false;

const _wlBanners = [
  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777884920/grok_image_1777884641742_yowydl.jpg',
  'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777884965/grok_image_1777884736477_wbarcd.jpg'
];
let _wlBannerIdx = 0;
let _wlBannerTimer = null;

function _wlStartBanner() {
  const el = document.getElementById('wlBannerImg');
  if (!el) return;
  el.style.backgroundImage = "url('" + _wlBanners[0] + "')";
  _wlBannerIdx = 0;
  if (window._wlBannerTimer) { clearInterval(window._wlBannerTimer); window._wlBannerTimer = null; }
  window._wlBannerTimer = setInterval(() => {
    const el2 = document.getElementById('wlBannerImg');
    if (!el2) return;
    el2.style.opacity = '0';
    setTimeout(() => {
      _wlBannerIdx = (_wlBannerIdx + 1) % _wlBanners.length;
      el2.style.backgroundImage = "url('" + _wlBanners[_wlBannerIdx] + "')";
      el2.style.opacity = '1';
    }, 700);
  }, 4000);
}

function _wlStopBanner() {
  if (window._wlBannerTimer) { clearInterval(window._wlBannerTimer); window._wlBannerTimer = null; }
}

function openWalkmanLib() {
  const ov = document.getElementById('wlOverlay');
  if (!ov) return;
  ov.classList.add('open');
  _wlStartBanner();
  // Apply current genre bg image immediately on open
  const sheet = document.getElementById('wlSheet');
  if (sheet) {
    const img = _wlGenreImages[_wlActiveGenre] || _wlGenreImages['all'];
    sheet.style.backgroundImage = `url('${img}')`;
    sheet.style.opacity = '1';
  }
  wlRenderPlaylist();
  wlRenderPickGrid();
}
function closeWalkmanLib() {
  const ov = document.getElementById('wlOverlay');
  if (ov) ov.classList.remove('open');
  _wlStopBanner();
}
function wlOverlayClick(e) {
  if (e.target === document.getElementById('wlOverlay')) closeWalkmanLib();
}

function wlSwitchTab(tab) {
  _wlActiveTab = tab;
  document.getElementById('wlPanePlaylist').classList.toggle('active', tab === 'playlist');
  document.getElementById('wlPaneBuild').classList.toggle('active', tab === 'build');
  document.getElementById('wlTabPlaylist').classList.toggle('active', tab === 'playlist');
  document.getElementById('wlTabBuild').classList.toggle('active', tab === 'build');
  const pill = document.getElementById('wlTabPill');
  if (pill) pill.classList.toggle('right', tab === 'build');
}

// ── GENRE → BG IMAGE MAP ──
// Swap these URLs after uploading your 8 images to Cloudinary:
//   all        → white-coat-phonetics (image 4)
//   immunity   → red-hair-shields     (image 3)
//   energy     → white-suit-arms-up   (image 2)
//   mind       → purple-neural        (image 9)
//   confidence → power-couple-gold    (image 8)
//   fitness    → gym-couple-green     (image 7)
//   calm       → floating-blonde      (image 6)
//   healing    → lotus-mandala-light  (image 5)
const _wlGenreImages = {
  all:        'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777892128/grok_image_1777891642236_lacz8v.jpg',
  immunity:   'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777888701/grok_image_1777888420816_bkrtzw.jpg',
  energy:     'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777888700/grok_image_1777887443893_xvupmc.jpg',
  mind:       'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777888700/grok_image_1777887770266_zyexqb.jpg',
  confidence: 'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777888700/grok_image_1777887913840_z9mkmd.jpg',
  fitness:    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777888701/grok_image_1777887990036_wmmmjt.jpg',
  calm:       'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777888700/grok_image_1777888044011_sx7km5.jpg',
  healing:    'https://res.cloudinary.com/dfc8lwj22/image/upload/q_auto/f_auto/v1777888700/grok_image_1777888311729_kmtnzu.jpg',
};

// ── PLAYLIST ──
function wlFilterGenre(genre) {
  _wlActiveGenre = genre;
  document.querySelectorAll('.wl-genre-pill').forEach(p => {
    p.classList.toggle('active', p.dataset.genre === genre);
  });

  // Fade out → swap bg image on entire sheet → fade in
  const sheet = document.getElementById('wlSheet');
  if (sheet) {
    sheet.style.opacity = '0';
    setTimeout(() => {
      const img = _wlGenreImages[genre] || _wlGenreImages['all'];
      sheet.style.backgroundImage = `url('${img}')`;
      sheet.style.opacity = '1';
    }, 220);
  }

  wlRenderPlaylist();
}

function wlRenderPlaylist() {
  const list = document.getElementById('wlTrackList');
  if (!list) return;
  const words = _wlActiveGenre === 'all'
    ? PRACTICE_WORDS
    : PRACTICE_WORDS.filter(w => wlGetGenre(w.word).genre === _wlActiveGenre);

  if (words.length === 0) {
    list.innerHTML = `<div style="position:relative;z-index:1;text-align:center;padding:48px 0;font-size:12px;color:rgba(255,255,255,0.55);line-height:1.9;letter-spacing:1px;">No words in this genre yet.<br><span style="font-size:10px;opacity:0.6;">More coming soon.</span></div>`;
    return;
  }

  list.innerHTML = words.map((w, i) => {
    const globalIdx = PRACTICE_WORDS.indexOf(w);
    const gInfo = wlGetGenre(w.word);
    const isCurrent = globalIdx === _pwIdx;
    return `
      <div class="wl-track${isCurrent ? ' current-playing' : ''}" onclick="wlJumpToWord(${globalIdx})">
        <div class="wl-track-num">${isCurrent
          ? `<svg width="10" height="10" viewBox="0 0 12 12" fill="none"><path d="M2 2L10 6L2 10V2Z" fill="rgba(200,232,245,0.9)"/></svg>`
          : String(i + 1).padStart(2, '0')}</div>
        <div class="wl-track-disc">
          <div class="wl-track-disc-inner">${w.word.charAt(0)}</div>
        </div>
        <div class="wl-track-info">
          <div class="wl-track-word">${w.word}</div>
          <div class="wl-track-phonetic">${w.phonetic}</div>
        </div>
        <div class="wl-track-right">
          <div class="wl-track-genre wl-genre-${gInfo.genre}">${gInfo.label}</div>
          <div class="wl-track-organ">${w.organ}</div>
        </div>
      </div>`;
  }).join('');
}

function wlJumpToWord(idx) {
  _pwIdx = idx;
  closeWalkmanLib();
  setTimeout(() => renderPractice(), 50);
}

// ── BUILD ──
function wlSetMood(mood) {
  _wlMood = mood;
  document.querySelectorAll('.wl-mood-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.mood === mood);
  });
}

function wlRenderPickGrid() {
  const grid = document.getElementById('wlPickGrid');
  if (!grid) return;
  grid.innerHTML = PRACTICE_WORDS.map((w, i) => {
    const gInfo = wlGetGenre(w.word);
    const sel = _wlSelected.has(i);
    return `
      <div class="wl-pick-track${sel ? ' selected' : ''}" onclick="wlTogglePick(${i})" data-pickidx="${i}">
        <div class="wl-pick-check">
          ${sel ? `<svg width="9" height="7" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="rgba(232,213,163,0.9)" stroke-width="1.5" stroke-linecap="square"/></svg>` : ''}
        </div>
        <div class="wl-pick-info">
          <div class="wl-pick-word">${w.word}</div>
          <div class="wl-pick-origin">${w.origin} · ${w.organ}</div>
        </div>
        <div class="wl-pick-genre-tag wl-genre-${gInfo.genre}">${gInfo.label}</div>
      </div>`;
  }).join('');
  wlUpdatePickCounter();
}

function wlTogglePick(idx) {
  if (_wlSelected.has(idx)) {
    _wlSelected.delete(idx);
  } else {
    if (_wlSelected.size >= 5) {
      // Flash counter
      const ctr = document.getElementById('wlPickCounter');
      if (ctr) { ctr.style.color = 'rgba(255,100,100,0.8)'; setTimeout(() => { ctr.style.color = ''; }, 600); }
      return;
    }
    _wlSelected.add(idx);
  }
  // Update just the clicked row
  const track = document.querySelector(`.wl-pick-track[data-pickidx="${idx}"]`);
  const w = PRACTICE_WORDS[idx];
  const gInfo = wlGetGenre(w.word);
  const sel = _wlSelected.has(idx);
  if (track) {
    track.classList.toggle('selected', sel);
    const check = track.querySelector('.wl-pick-check');
    if (check) check.innerHTML = sel
      ? `<svg width="9" height="7" viewBox="0 0 10 8" fill="none"><path d="M1 4L3.5 6.5L9 1" stroke="rgba(232,213,163,0.9)" stroke-width="1.5" stroke-linecap="square"/></svg>`
      : '';
    const ww = track.querySelector('.wl-pick-word');
    if (ww) ww.style.color = sel ? 'var(--accent-gold)' : '';
  }
  wlUpdatePickCounter();
  const btn = document.getElementById('wlBuildBtn');
  if (btn) btn.disabled = _wlSelected.size < 2;
}

function wlUpdatePickCounter() {
  const ctr = document.getElementById('wlPickCounter');
  if (ctr) ctr.innerHTML = `Selected: <span>${_wlSelected.size}</span> / 5`;
}

async function wlBuildSentence() {
  if (_wlSelected.size < 2) return;
  const btn = document.getElementById('wlBuildBtn');

  if (btn) { btn.disabled = true; btn.innerHTML = '<span style="display:inline-block;width:12px;height:12px;border:1.5px solid rgba(232,213,163,0.3);border-top-color:var(--accent-gold);border-radius:50% !important;animation:libSpin 0.7s linear infinite;vertical-align:middle;margin-right:8px;"></span>Building…'; }

  const selectedWords = [..._wlSelected].map(i => PRACTICE_WORDS[i]);
  const wordNames = selectedWords.map(w => w.word).join(', ');
  const wordInfo = selectedWords.map(w => `${w.word} (${w.meaning}, heals: ${w.organ}, genre: ${wlGetGenre(w.word).label})`).join('; ');

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1000,
        system: `You are a Shabdapathy sentence builder for the NowssB healing app. The user wants a sentence with intent/mood: "${_wlMood}". Given natural-origin healing words, create one beautiful, meaningful healing sentence in English that weaves the given words naturally. The sentence should feel poetic, personal, and intentional — resonating with the chosen mood. Respond ONLY with a JSON object — no preamble, no markdown — in this exact format: {"sentence":"...","highlights":[{"word":"WORD","meaning":"short 8-word meaning","genre":"genre name"}]}. The highlights array must include every given word that appears in the sentence with exact case match.`,
        messages: [{
          role: 'user',
          content: `Create a ${_wlMood}-focused healing sentence using these Shabdapathy words: ${wordNames}. Word details: ${wordInfo}.`
        }]
      })
    });
    const data = await response.json();
    const raw = data.content?.find(b => b.type === 'text')?.text || '';
    const clean = raw.replace(/```json|```/g, '').trim();
    _wlSentenceData = JSON.parse(clean);

    // ── Close overlay, open sentence player ──
    closeWalkmanLib();
    // Make sure practice sub-screen is open
    if (!document.getElementById('sub-practice').classList.contains('active')) {
      openSub('practice');
    }
    setTimeout(() => launchSentencePlayer(_wlSentenceData, _wlMood.charAt(0).toUpperCase() + _wlMood.slice(1)), 80);

  } catch(e) {
    console.error('WL sentence error:', e);
    // Show error inline in overlay
    const resultBox = document.getElementById('wlResultBox');
    const resultText = document.getElementById('wlResultText');
    if (resultText) resultText.textContent = 'Could not generate sentence. Check your connection.';
    if (resultBox) resultBox.classList.add('show');
  }

  if (btn) {
    btn.disabled = false;
    btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M2 8h12M9 3l5 5-5 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="square"/></svg> Build Sentence';
  }
}

function wlShowMeaning(word, meaning, genre) {
  const pop = document.getElementById('wlMeaningPop');
  if (!pop) return;
  const genreClass = genre ? `wl-genre-${genre.toLowerCase()}` : '';
  pop.innerHTML = `<strong style="color:var(--accent-gold);letter-spacing:1px;">${_sanitizeHtml(word)}</strong>
    ${genre ? `<span class="wl-track-genre ${genreClass}" style="margin-left:8px;vertical-align:middle;">${_sanitizeHtml(genre)}</span>` : ''}
    <br><span style="color:rgba(255,255,255,0.62);">${_sanitizeHtml(meaning)}</span>`;
  pop.classList.add('show');
}

function wlPlaySentence() {
  if (!_wlSentenceData || !_wlSentenceData.sentence) return;
  if (_wlSpeaking) { window.speechSynthesis.cancel(); _wlSpeaking = false; return; }
  const utt = new SpeechSynthesisUtterance(_wlSentenceData.sentence);
  utt.rate = 0.82*(window._pwSpeed||1); utt.pitch = _pwVoice === 'F' ? 1.1 : 0.85;
  utt.onend = () => { _wlSpeaking = false; };
  _wlSpeaking = true;
  window.speechSynthesis.speak(utt);
}
