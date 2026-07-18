

// ── NowssB API (Cloudflare Worker — free, universal) ───────
// Deploy worker.js to Cloudflare Workers and replace this URL
const NOWSSB_API       = 'https://nowssb-api.nowssb.workers.dev';
const GROQ_CHAT_URL    = NOWSSB_API + '/api/groq/complete';
const GROQ_WHISPER_URL = NOWSSB_API + '/api/groq/transcribe';
const CLAUDE_URL       = NOWSSB_API + '/api/claude/complete';
const GROQ_MODEL       = 'llama-3.3-70b-versatile';
// Legacy direct key — leave empty; all calls go through Worker
const GROQ_KEY         = '';
window._groqKey        = GROQ_KEY;
// ───────────────────────────────────────────────────────────

// AI Personas for pronunciation feedback
const GROQ_PERSONAS = {
  soundHealer:    { name: 'Sound Healer',    prompt: 'You are a compassionate sound healer who deeply understands phonetic vibration and its effect on the body.' },
  neuroscientist: { name: 'Neuroscientist',  prompt: 'You are a neuroscientist specializing in phonetic resonance and neurological effects of sound.' },
  philosopher:    { name: 'Philosopher',     prompt: 'You are a philosopher who understands that words carry ancient vibrations beyond their dictionary meanings.' },
  shaman:         { name: 'Shaman',          prompt: 'You are a shaman who reads the energy of spoken sound and its journey through the body.' }
};

// ── CORE HELPERS ────────────────────────────────────────────

async function groqChat(messages, systemPrompt, maxTokens = 400) {
  const res = await fetch(GROQ_CHAT_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: GROQ_MODEL,
      max_tokens: maxTokens,
      messages: messages,
      system: systemPrompt || undefined
    })
  });
  if (!res.ok) throw new Error('Groq LLM ' + res.status);
  const data = await res.json();
  return data.choices?.[0]?.message?.content || '';
}

// ── CLAUDE AI HELPER ────────────────────────────────────────
// Routes through the Cloudflare Worker — API key never touches the browser.
// model: 'claude-haiku-4-5' (default, fast+cheap) | 'claude-sonnet-4-6' | 'claude-opus-4-7'
// For Opus 4.7 pass thinking:{type:'adaptive'} — do NOT pass temperature.
async function callClaude(messages, { model = 'claude-haiku-4-5', max_tokens = 512, system, thinking } = {}) {
  const payload = { messages, model, max_tokens };
  if (system)   payload.system   = system;
  if (thinking) payload.thinking = thinking;
  const res = await fetch(CLAUDE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  if (!res.ok) throw new Error('Claude API ' + res.status);
  const data = await res.json();
  // Claude response: data.content is an array of blocks; first text block = the reply
  return data.content?.find(b => b.type === 'text')?.text || '';
}
// ───────────────────────────────────────────────────────────

// ── SMART AI FALLBACK ────────────────────────────────────────
// Tries Claude first. If Claude fails for any reason (quota, rate limit,
// network, key not set), automatically falls back to Groq LLaMA.
// Use this instead of calling callClaude() or groqChat() directly for
// all text-generation features.
async function callAI(messages, { model = 'claude-haiku-4-5', max_tokens = 400, system } = {}) {
  try {
    return await callClaude(messages, { model, max_tokens, system });
  } catch (claudeErr) {
    console.warn('[NowssB] Claude fallback → Groq:', claudeErr.message);
    return await groqChat(messages, system, max_tokens);
  }
}
// ───────────────────────────────────────────────────────────

async function groqWhisper(audioBlob) {
  // Convert blob to base64 for Worker transport
  const arrayBuf = await audioBlob.arrayBuffer();
  const bytes = new Uint8Array(arrayBuf);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) binary += String.fromCharCode(bytes[i]);
  const audio_base64 = btoa(binary);

  const res = await fetch(GROQ_WHISPER_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ audio_base64, model: 'whisper-large-v3-turbo' })
  });
  if (!res.ok) throw new Error('Whisper ' + res.status);
  const data = await res.json();
  return data.text || '';
}

// ── SCORING MATH ────────────────────────────────────────────

function levenshtein(a, b) {
  const m = a.length, n = b.length;
  const dp = Array.from({ length: m + 1 }, (_, i) =>
    Array.from({ length: n + 1 }, (_, j) => i === 0 ? j : j === 0 ? i : 0)
  );
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = a[i-1] === b[j-1] ? dp[i-1][j-1] : 1 + Math.min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]);
  return dp[m][n];
}

function phoneticSimilarity(heard, phonetic) {
  if (!heard || !phonetic) return 0;
  const a = heard.toLowerCase().replace(/[^a-z\s]/g, '').trim();
  const b = phonetic.toLowerCase().replace(/[·\-]/g, ' ').replace(/[^a-z\s]/g, '').trim();
  if (!a || !b) return 0;
  const aParts = a.split(/\s+/);
  const bParts = b.split(/\s+/).filter(Boolean);
  if (!bParts.length) return 0;

  let matched = 0;
  bParts.forEach(syl => {
    if (aParts.some(p => p.includes(syl) || syl.includes(p) || levenshtein(p, syl) <= 1)) matched++;
  });
  const sylScore     = (matched / bParts.length) * 100;
  const overallScore = Math.max(0, (1 - levenshtein(a, b) / Math.max(a.length, b.length, 1)) * 100);
  return Math.round(sylScore * 0.65 + overallScore * 0.35);
}

function scoreColor(s) {
  return s >= 80 ? '#7ddc8a' : s >= 55 ? '#e8d5a3' : '#ff6b6b';
}

function scoreLine(s) {
  return s >= 80 ? 'Excellent — pure resonance' : s >= 55 ? 'Good — keep refining the frequency' : 'Keep practicing — this vibration builds with repetition';
}

// ── FEATURE 1: PRONUNCIATION SCORING ───────────────────────

async function pwScoreRecording() {
  if (!_pwRecordingBlob) return;
  const w = PRACTICE_WORDS[_pwIdx];
  if (!w) return;

  const hint       = document.getElementById('spRecHint');
  const scoreWrap  = document.getElementById('spScoreWrap');
  const scoreNum   = document.getElementById('spScoreNum');

  if (hint)      hint.textContent = 'Scoring…';
  if (scoreNum)  { scoreNum.textContent = '…'; scoreNum.style.color = 'rgba(200,232,245,0.3)'; }

  try {
    const transcript = await groqWhisper(_pwRecordingBlob);
    const score      = phoneticSimilarity(transcript, w.phonetic);
    const color      = scoreColor(score);

    if (scoreNum) {
      scoreNum.textContent      = score;
      scoreNum.style.color      = color;
      scoreNum.style.textShadow = `0 0 24px ${color}50`;
    }
    if (hint) {
      hint.textContent = scoreLine(score);
      hint.style.color = color;
    }
    var sl = document.getElementById('spScoreLabel');
    if (sl) sl.textContent = 'Your score';
    _pwPhase = 'scored';
    _pwUpdateMainBtn();

    // Persona feedback loads after score — non-blocking
    pwPersonaFeedback(score, w, transcript);

  } catch(e) {
    console.error('Score error:', e);
    if (hint)     hint.textContent = 'Scoring unavailable — check connection';
    if (scoreNum) scoreNum.textContent = '—';
    _pwPhase = 'scored';
    _pwUpdateMainBtn();
  }
}

async function pwPersonaFeedback(score, word, transcript) {
  // AI persona feedback is a Resonance-and-up feature — skip quietly (no
  // modal spam after every word) for anyone below that, but still route
  // truly expired users through the normal expired-trial overlay.
  if (window.GATE && !window.GATE.isResonance()) {
    if (window.GATE.tier() === 'expired') window.GATE.check('resonance');
    return;
  }
  const personaKey  = window._userPersona || 'soundHealer';
  const persona     = GROQ_PERSONAS[personaKey] || GROQ_PERSONAS.soundHealer;
  const personaWrap = document.getElementById('spPersonaWrap');
  const personaName = document.getElementById('spPersonaName');
  const personaText = document.getElementById('spPersonaText');

  if (!personaWrap) return;
  personaWrap.style.display = 'block';
  if (personaName) personaName.textContent = persona.name;
  if (personaText) personaText.textContent  = '…';

  const userMsg = `The user practiced the NowssB healing word "${word.word}" (phonetic: ${word.phonetic}, organ: ${word.organ}, benefit: ${word.benefit}). Pronunciation score: ${score}/100. They said: "${transcript}". Give your feedback in 2-3 sentences.`;
  const sysMsg  = persona.prompt + ' Give short, encouraging feedback on their NowssB healing word pronunciation. Stay in character. No emojis.';

  try {
    const feedback = await callAI(
      [{ role: 'user', content: userMsg }],
      { model: 'claude-haiku-4-5', max_tokens: 150, system: sysMsg }
    );
    if (personaText) personaText.textContent = (feedback || '').trim();
  } catch(e) {
    if (personaText) personaText.textContent = 'Every repetition deepens the frequency. Keep going.';
  }
}

// ── FEATURE 2: SESSION-END SENTENCE ────────────────────────

async function pwAutoSentence() {
  if (!PRACTICE_WORDS || !PRACTICE_WORDS.length) return;

  const userName  = window._userName || window._currentUser?.displayName || '';
  const hour      = new Date().getHours();
  const timeLabel = hour < 10 ? 'morning' : hour < 17 ? 'midday' : hour < 20 ? 'evening' : 'night';
  const wordNames = PRACTICE_WORDS.map(w => w.word).join(', ');
  const wordInfo  = PRACTICE_WORDS.map(w => `${w.word} (${w.meaning}, heals ${w.organ})`).join('; ');

  const btn = document.getElementById('pwCompleteBtn');
  if (btn) { btn.textContent = 'Building your Shabdapathy sentence…'; btn.style.opacity = '0.55'; }

  try {
    const raw = await callAI(
      [{ role: 'user', content: `Build a healing sentence using ALL of these words: ${wordNames}. Details: ${wordInfo}.${userName ? ' User name: ' + userName + '.' : ''} Time of day: ${timeLabel}.` }],
      {
        model: 'claude-haiku-4-5',
        max_tokens: 500,
        system: `You are a Shabdapathy sentence builder for the NowssB healing app.
Given natural origin healing words, create ONE beautiful healing sentence in English that uses ALL the given words naturally.
The sentence should feel personal, poetic, and intentional — matched to the time of day.
Respond ONLY as valid JSON, no preamble, no markdown backticks:
{"sentence":"...","highlights":[{"word":"WORD","meaning":"meaning under 8 words"}]}
Every given word MUST appear in the sentence. Highlights must match exact case.`
      }
    );

    const clean       = raw.replace(/```json|```/g, '').trim();
    const sentenceData = JSON.parse(clean);

    if (btn) { btn.textContent = 'Practice Complete'; btn.style.opacity = '1'; }

    // Launch in existing sentence player
    if (typeof launchSentencePlayer === 'function') {
      setTimeout(() => launchSentencePlayer(sentenceData, 'Practice Complete'), 500);
    }

    // Save to Sound Library
    if (typeof window.slAddSentence === 'function') {
      const routineName = (typeof getActiveRoutine === 'function' && getActiveRoutine())
        ? getActiveRoutine().name : 'Session';
      window.slAddSentence(sentenceData.sentence, PRACTICE_WORDS.map(w => w.word), routineName);
    }

  } catch(e) {
    console.error('Auto sentence error:', e);
    if (btn) { btn.textContent = 'Practice Complete'; btn.style.opacity = '1'; }
  }
}

// ── FEATURE 3: AI WORD ORIGIN (Real Meaning screen) ────────

async function groqWordSearch(val) {
  const word         = val.charAt(0).toUpperCase() + val.slice(1);
  const featureWord  = document.getElementById('rmFeatureWord');
  const featureRoot  = document.getElementById('rmFeatureRoot');
  const meaningText  = document.getElementById('rmMeaningText');
  const chips        = document.getElementById('rmSoundChips');
  const meaningPanel = document.getElementById('rmMeaningPanel');
  const soundPanel   = document.getElementById('rmSoundPanel');
  const rmBg         = document.getElementById('rmBg');
  const charWrap     = document.getElementById('rmdCharWrap');

  // Store for actions
  window._rmdCurrentKey  = val.toLowerCase();
  window._rmdCurrentWord = word;

  // Pick a random banner + char image
  const validBanners = DETAIL_BANNER_IMAGES.filter(b => b && !b.startsWith('TODO'));
  const bannerImg = document.getElementById('rmdBannerImg');
  if (bannerImg && validBanners.length) bannerImg.src = validBanners[Math.floor(Math.random() * validBanners.length)];

  const validChars = CHAR_FRAME_IMAGES.filter(c => c.src && !c.src.startsWith('TODO'));
  const charImg    = document.getElementById('rmdCharImg');
  const frameOvl   = document.getElementById('rmdFrameOverlay');
  if (validChars.length && charImg && frameOvl) {
    const pick = validChars[Math.floor(Math.random() * validChars.length)];
    charImg.src = pick.src;
    const fb = pick.frameBox;
    frameOvl.style.top = fb.top+'%'; frameOvl.style.left = fb.left+'%';
    frameOvl.style.width = fb.width+'%'; frameOvl.style.height = fb.height+'%';
    if (charWrap) charWrap.style.display = '';
  }

  if (featureWord)  featureWord.textContent  = word;
  if (featureRoot)  featureRoot.textContent  = 'Decoding natural origin…';
  if (meaningText)  meaningText.innerHTML    = '<span style="opacity:0.35;font-style:italic;">Tracing the root frequency of this word…</span>';
  if (meaningPanel) meaningPanel.style.display = 'block';
  if (soundPanel)   soundPanel.style.display   = 'block';
  if (chips)        chips.innerHTML = '';

  // Reset buy button for unknown word
  var buyBtn = document.getElementById('rmdBuyBtn');
  if (buyBtn) { buyBtn.disabled = false; buyBtn.textContent = 'Buy · $0.49'; buyBtn.style.opacity = ''; }

  // Switch to detail view
  const libEl = document.getElementById('rmLibraryContent');
  const detEl = document.getElementById('rmDetailView');
  if (libEl) libEl.style.display = 'none';
  if (detEl) detEl.style.display = 'block';

  const scrollEl = document.getElementById('rmSubBody');
  if (scrollEl) scrollEl.scrollTop = 0;

  try {
    const raw = await callAI(
      [{ role: 'user', content: `Decode the natural phonetic origin of the word: "${word}"` }],
      {
        model: 'claude-haiku-4-5',
        max_tokens: 600,
        system: `You are a Shabdapathy expert in the NowssB app — Natural Origin Word Sound Science.
You decode words by tracing their phonetic roots to natural sounds (breath, water, fire, earth).
This is NOT religion, NOT only Sanskrit, NOT spirituality. It is phonetic vibration science — any language, any era.
Write in a scientific yet poetic voice. Never use emojis.

Respond ONLY as valid JSON, no preamble, no backticks:
{
  "root": "Language family · Root word",
  "meaning": "3-4 sentences on natural origin and phonetic healing properties. Mention which consonants/vowels activate which organs or systems.",
  "sounds": [{"letter":"A","meaning":"one word"},{"letter":"B","meaning":"one word"}]
}
sounds = one entry per letter in the word. Each meaning = 1 word only.`
      }
    );

    const clean = raw.replace(/```json|```/g, '').trim();
    const data  = JSON.parse(clean);

    if (featureRoot) featureRoot.textContent = data.root || 'Natural Origin · Decoded';
    if (meaningText) meaningText.innerHTML = _sanitizeHtml(data.meaning) || '';
    if (rmBg)        rmBg.style.backgroundImage = '';

    if (chips && Array.isArray(data.sounds)) {
      chips.innerHTML = '';
      data.sounds.forEach(s => {
        chips.innerHTML += `<div class="rm-sound-chip"><span class="rm-chip-letter">${_sanitizeHtml(s.letter)}</span><span class="rm-chip-meaning">${_sanitizeHtml(s.meaning)}</span></div>`;
      });
    }

  } catch(e) {
    console.error('Word search error:', e);
    if (featureRoot) featureRoot.textContent = 'Natural Origin · Being Decoded';
    if (meaningText) meaningText.innerHTML = `The word <em>${word}</em> carries a vibrational signature that predates all dictionaries. Its phonetic blueprint is being catalogued in the NOWSBANSIU system.`;
    if (chips) {
      chips.innerHTML = '';
      [...word.toUpperCase()].forEach(l => {
        chips.innerHTML += `<div class="rm-sound-chip"><span class="rm-chip-letter">${l}</span><span class="rm-chip-meaning">Origin</span></div>`;
      });
    }
  }
}

// ── FEATURE 4: AI HOME WORD SEARCH ─────────────────────────

async function groqHomeSearch(val) {
  const word      = val.charAt(0).toUpperCase() + val.slice(1);
  const result    = document.getElementById('wordSearchResult');
  const wsrWord   = document.getElementById('wsrWord');
  const wsrOrigin = document.getElementById('wsrOrigin');
  const wsrMeaning = document.getElementById('wsrMeaning');

  if (wsrWord)    wsrWord.textContent    = word;
  if (wsrOrigin)  wsrOrigin.textContent  = 'Decoding origin…';
  if (wsrMeaning) wsrMeaning.textContent = '';
  if (result)     result.classList.add('show');

  try {
    const raw = await callAI(
      [{ role: 'user', content: `Natural phonetic origin of the word: "${word}"` }],
      {
        model: 'claude-haiku-4-5',
        max_tokens: 180,
        system: `You are a Shabdapathy expert. Decode the natural phonetic origin of any word in 2 sentences.
Respond ONLY as valid JSON, no preamble, no backticks:
{"origin":"Language · Root word","meaning":"2 sentence explanation of phonetic origin and body activation"}`
      }
    );
    const clean = raw.replace(/```json|```/g, '').trim();
    const data  = JSON.parse(clean);
    if (wsrOrigin)  wsrOrigin.textContent  = data.origin  || 'Natural Origin · Decoded';
    if (wsrMeaning) wsrMeaning.textContent = data.meaning || '';
  } catch(e) {
    if (wsrOrigin)  wsrOrigin.textContent  = 'Etymology · Being Researched';
    if (wsrMeaning) wsrMeaning.textContent = `"${word}" carries unique vibrational signatures being catalogued in the Shabdapathy system.`;
  }
}

// ── REROUTE EXISTING SENTENCE BUILDERS TO GROQ ─────────────
// The old versions called the Anthropic API directly.
// These overrides replace them with Groq calls.

window.pwLibBuildSentence = async function() {
  // _libSelected is the module-level Set in the practice player script block
  // We expose it via window here; the original function at line ~6944 is the fallback
  const sel = window._libSelected || (typeof _libSelected !== 'undefined' ? _libSelected : null);
  if (!sel || sel.size < 2) return;
  const btn        = document.getElementById('spLibBuildBtn');
  const resultEl   = document.getElementById('spLibResult');
  const sentenceEl = document.getElementById('spLibSentenceText');

  const selected  = [...sel].map(i => PRACTICE_WORDS[i]);
  const wordNames = selected.map(w => w.word).join(', ');
  const wordInfo  = selected.map(w => `${w.word} (${w.meaning}, heals ${w.organ})`).join('; ');

  if (btn) { btn.disabled = true; btn.innerHTML = '<span class="sp-lib-spinner"></span> Building…'; }
  if (resultEl) resultEl.style.display = 'none';

  try {
    const raw = await callAI(
      [{ role: 'user', content: `Create a healing sentence using these Shabdapathy words: ${wordNames}. Details: ${wordInfo}.` }],
      {
        model: 'claude-haiku-4-5',
        max_tokens: 500,
        system: `You are a Shabdapathy sentence builder for the NowssB healing app.
Create one beautiful, meaningful healing sentence in English using ALL the given words.
Respond ONLY as valid JSON, no preamble, no backticks:
{"sentence":"...","highlights":[{"word":"WORD","meaning":"short 8-word meaning"}]}
Every word that appears in the sentence must be in highlights with exact case match.`
      }
    );
    const clean = raw.replace(/```json|```/g, '').trim();
    const data  = JSON.parse(clean);

    let rendered = data.sentence;
    (data.highlights || []).forEach(h => {
      const safe = h.word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      rendered = rendered.replace(
        new RegExp(`\\b${safe}\\b`, 'gi'),
        `<span class="sp-lib-word-hl" onclick="pwLibShowMeaning('${h.word.replace(/'/g,"\\'")}','${(h.meaning||'').replace(/'/g,"\\'")}')">$&</span>`
      );
    });
    if (sentenceEl) sentenceEl.innerHTML = rendered;
    if (resultEl)   resultEl.style.display = 'block';
    window._libSentenceData = data;

  } catch(e) {
    console.error('Lib sentence error:', e);
    if (sentenceEl) sentenceEl.textContent = 'Could not generate sentence. Check your connection.';
    if (resultEl)   resultEl.style.display = 'block';
  }

  if (btn) {
    btn.disabled = false;
    btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M2 8h12M9 3l5 5-5 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="square"/></svg> Build Sentence';
  }
};

window.wlBuildSentence = async function() {
  if (!window._wlSelected || window._wlSelected.size < 2) return;
  const btn       = document.getElementById('wlBuildBtn');
  const selected  = [...window._wlSelected].map(i => PRACTICE_WORDS[i]);
  const wordNames = selected.map(w => w.word).join(', ');
  const wordInfo  = selected.map(w => `${w.word} (${w.meaning}, heals ${w.organ})`).join('; ');
  const mood      = window._wlMood || 'healing';

  if (btn) { btn.disabled = true; btn.innerHTML = '<span style="display:inline-block;width:12px;height:12px;border:1.5px solid rgba(232,213,163,0.3);border-top-color:var(--accent-gold);border-radius:50%;animation:libSpin 0.7s linear infinite;vertical-align:middle;margin-right:8px;"></span>Building…'; }

  try {
    const raw = await callAI(
      [{ role: 'user', content: `Create a ${mood}-focused healing sentence using these Shabdapathy words: ${wordNames}. Details: ${wordInfo}.` }],
      {
        model: 'claude-haiku-4-5',
        max_tokens: 500,
        system: `You are a Shabdapathy sentence builder for the NowssB healing app.
Mood/intent: "${mood}". Create one beautiful healing sentence using ALL the given words.
Respond ONLY as valid JSON, no preamble, no backticks:
{"sentence":"...","highlights":[{"word":"WORD","meaning":"short 8-word meaning","genre":"genre name"}]}
Every word that appears in the sentence must be in highlights with exact case match.`
      }
    );
    const clean = raw.replace(/```json|```/g, '').trim();
    const data  = JSON.parse(clean);
    window._wlSentenceData = data;

    if (typeof closeWalkmanLib === 'function') closeWalkmanLib();
    if (!document.getElementById('sub-practice').classList.contains('active')) {
      if (typeof openSub === 'function') openSub('practice');
    }
    setTimeout(() => {
      if (typeof launchSentencePlayer === 'function') launchSentencePlayer(data, mood.charAt(0).toUpperCase() + mood.slice(1));
    }, 80);

  } catch(e) {
    console.error('WL sentence error:', e);
    const resultBox  = document.getElementById('wlResultBox');
    const resultText = document.getElementById('wlResultText');
    if (resultText) resultText.textContent = 'Could not generate sentence. Check your connection.';
    if (resultBox)  resultBox.classList.add('show');
  }

  if (btn) {
    btn.disabled = false;
    btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 16 16" fill="none"><path d="M2 8h12M9 3l5 5-5 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="square"/></svg> Build Sentence';
  }
};

console.log('%cNowssB Groq Engine ready ✓', 'color:#e8d5a3;font-weight:800;font-size:13px;');

