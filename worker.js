/**
 * NowssB Universal API — Cloudflare Worker
 *
 * Secrets are configured in Cloudflare, never in this repository or a client.
 * Deploy with Wrangler or the Cloudflare dashboard.
 */

const ALLOWED_ORIGINS = new Set([
  'https://nowssb.com',
  'https://www.nowssb.com',
  'https://ribonswebsites.github.io',
  'http://localhost',
  'https://localhost',
  'capacitor://localhost',
  'ionic://localhost',
  'http://localhost:3000',
  'http://localhost:5173',
  'http://127.0.0.1:5500',
  'http://127.0.0.1:5173',
]);

const CHAT_MODELS = new Set([
  'openai/gpt-oss-20b',
  'openai/gpt-oss-120b',
  'qwen/qwen3.6-27b',
  'groq/compound',
  'groq/compound-mini',
]);
const WHISPER_MODELS = new Set(['whisper-large-v3-turbo', 'whisper-large-v3']);
const MAX_AUDIO_BYTES = 25 * 1024 * 1024;
const MAX_MESSAGES = 40;
const MAX_MESSAGE_CHARS = 12000;

function corsHeaders(origin) {
  const allowed = ALLOWED_ORIGINS.has(origin) ? origin : 'https://nowssb.com';
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-NowssB-Client',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}

function json(data, status = 200, origin = '') {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
      ...corsHeaders(origin),
    },
  });
}

function err(message, status = 400, origin = '') {
  return json({ error: message }, status, origin);
}

function clampString(value, max) {
  return typeof value === 'string' ? value.slice(0, max) : '';
}

function modelOrDefault(value, allowed, fallback) {
  return typeof value === 'string' && allowed.has(value) ? value : fallback;
}

function decodeBase64Audio(value) {
  if (typeof value !== 'string' || !value) throw new Error('audio_base64 required');
  const raw = value.replace(/^data:[^;]+;base64,/, '');
  if (!/^[A-Za-z0-9+/=_\s]+$/.test(raw)) throw new Error('invalid audio_base64');
  const estimatedBytes = Math.floor(raw.replace(/\s/g, '').length * 0.75);
  if (estimatedBytes <= 0 || estimatedBytes > MAX_AUDIO_BYTES) throw new Error('audio file is empty or too large');
  const binary = atob(raw);
  const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));
  if (bytes.byteLength > MAX_AUDIO_BYTES) throw new Error('audio file is too large');
  return bytes;
}

function audioExtension(mime) {
  const value = String(mime || '').toLowerCase().split(';')[0];
  return {
    'audio/webm': 'webm',
    'audio/wav': 'wav',
    'audio/x-wav': 'wav',
    'audio/m4a': 'm4a',
    'audio/mp4': 'm4a',
    'audio/ogg': 'ogg',
    'audio/mpeg': 'mp3',
    'audio/flac': 'flac',
  }[value] || 'webm';
}

function normalise(value) {
  return String(value || '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[·\-_/]/g, ' ')
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function levenshtein(a, b) {
  const m = a.length;
  const n = b.length;
  const prev = Array.from({ length: n + 1 }, (_, i) => i);
  for (let i = 1; i <= m; i++) {
    const row = [i];
    for (let j = 1; j <= n; j++) {
      row[j] = a[i - 1] === b[j - 1]
        ? prev[j - 1]
        : 1 + Math.min(prev[j], row[j - 1], prev[j - 1]);
    }
    for (let j = 0; j <= n; j++) prev[j] = row[j];
  }
  return prev[n];
}

function similarity(heard, target) {
  const a = normalise(heard);
  const b = normalise(target);
  if (!a || !b) return 0;
  const score = (1 - levenshtein(a, b) / Math.max(a.length, b.length, 1)) * 100;
  return Math.max(0, Math.min(100, Math.round(score)));
}

function syllableMatch(heard, phonetic) {
  const heardParts = normalise(heard).split(' ').filter(Boolean);
  const targetParts = String(phonetic || '')
    .split(/[·\-\s]+/)
    .map(normalise)
    .filter(Boolean);
  const matches = targetParts.map(target => {
    let best = 999;
    heardParts.forEach(part => {
      best = Math.min(best, levenshtein(part, target) / Math.max(part.length, target.length, 1));
    });
    return { syllable: target, matched: best <= 0.34 };
  });
  return { matches, matched: matches.filter(x => x.matched).length, total: matches.length };
}

function scoreAttempt(transcript, target, phonetic) {
  const wordScore = similarity(transcript, target);
  const phoneticScore = phonetic ? similarity(transcript, phonetic) : 0;
  const syllables = syllableMatch(transcript, phonetic);
  const syllableScore = syllables.total ? Math.round(syllables.matched / syllables.total * 100) : 0;
  const phoneticComposite = phoneticScore * 0.65 + syllableScore * 0.35;
  // Whisper often returns a correctly spoken multi-syllable word as one token.
  // A whole-word match is therefore authoritative; syllable marks remain
  // diagnostic rather than a penalty that can overturn the word match.
  const score = phonetic
    ? Math.max(0, Math.min(100, Math.round(Math.max(wordScore, phoneticComposite))))
    : wordScore;
  return { score, wordScore, phoneticScore, syllableScore, ...syllables };
}

async function groqTranscribe(env, body) {
  if (!env.GROQ_API_KEY) throw new Error('Groq is not configured');
  const bytes = decodeBase64Audio(body.audio_base64);
  const mime = body.mime_type || 'audio/webm';
  const form = new FormData();
  form.append('file', new Blob([bytes], { type: mime }), `recording.${audioExtension(mime)}`);
  form.append('model', modelOrDefault(body.model, WHISPER_MODELS, 'whisper-large-v3-turbo'));
  form.append('response_format', 'verbose_json');
  form.append('temperature', '0');
  if (body.language) form.append('language', clampString(body.language, 10));
  if (body.prompt) form.append('prompt', clampString(body.prompt, 1000));

  const response = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${env.GROQ_API_KEY}` },
    body: form,
  });
  if (!response.ok) {
    console.error('Groq transcription upstream error', response.status);
    throw new Error('Groq transcription failed');
  }
  return response.json();
}

async function groqComplete(env, body) {
  if (!env.GROQ_API_KEY) throw new Error('Groq is not configured');
  if (!Array.isArray(body.messages) || body.messages.length === 0 || body.messages.length > MAX_MESSAGES) {
    throw new Error('messages array required');
  }
  const messages = body.messages.map(message => ({
    role: ['system', 'user', 'assistant'].includes(message?.role) ? message.role : 'user',
    content: clampString(message?.content, MAX_MESSAGE_CHARS),
  }));
  const model = modelOrDefault(body.model, CHAT_MODELS, 'openai/gpt-oss-20b');
  // Reasoning models spend part of the budget before producing visible text.
  // Keep a useful floor for the app’s short feedback and JSON responses.
  const maxTokens = Math.max(256, Math.min(Number(body.max_completion_tokens || body.max_tokens || 512), 4096));
  const temperature = Math.max(0, Math.min(Number(body.temperature ?? 0.4), 2));
  const payload = {
    model,
    messages: body.system
      ? [{ role: 'system', content: clampString(body.system, MAX_MESSAGE_CHARS) }, ...messages]
      : messages,
    max_completion_tokens: maxTokens,
    temperature,
  };
  if (model.startsWith('openai/gpt-oss-')) payload.reasoning_effort = 'low';
  if (body.response_format?.type === 'json_object') payload.response_format = { type: 'json_object' };

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.GROQ_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    console.error('Groq completion upstream error', response.status);
    throw new Error('Groq completion failed');
  }
  return response.json();
}

function basicAuth(env) {
  return btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') || '';
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders(origin) });
    if (path === '/api/health' && request.method === 'GET') {
      return json({ status: 'ok', groqConfigured: Boolean(env.GROQ_API_KEY), version: '2.0.0', ts: Date.now() }, 200, origin);
    }
    if (request.method !== 'POST') return err('Method not allowed', 405, origin);

    let body;
    try {
      body = await request.json();
    } catch {
      return err('Invalid JSON body', 400, origin);
    }

    try {
      if (path === '/api/groq/transcribe') {
        const data = await groqTranscribe(env, body);
        return json(data, 200, origin);
      }

      if (path === '/api/groq/score') {
        const target = clampString(body.target, 200);
        const phonetic = clampString(body.phonetic, 500);
        if (!target) return err('target required', 400, origin);
        const transcription = await groqTranscribe(env, body);
        const result = scoreAttempt(transcription.text || '', target, phonetic);
        return json({
          ...result,
          transcript: transcription.text || '',
          target,
          phonetic,
          segments: transcription.segments || [],
        }, 200, origin);
      }

      if (path === '/api/groq/complete') {
        const data = await groqComplete(env, body);
        return json(data, 200, origin);
      }

      if (path === '/api/razorpay/order') {
        if (!env.RAZORPAY_KEY_ID || !env.RAZORPAY_KEY_SECRET) return err('Payments are not configured', 503, origin);
        const { amount, currency = 'USD', notes = {} } = body;
        if (!amount || isNaN(amount) || amount < 50) return err('amount (in minor units) required, min 50', 400, origin);
        const response = await fetch('https://api.razorpay.com/v1/orders', {
          method: 'POST',
          headers: { Authorization: `Basic ${basicAuth(env)}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({ amount: Math.round(amount), currency, receipt: `nwsb_${Date.now()}`, notes }),
        });
        if (!response.ok) return err('Razorpay order creation failed', 502, origin);
        const order = await response.json();
        return json({ id: order.id, amount: order.amount, currency: order.currency }, 200, origin);
      }

      if (path === '/api/elevenlabs/speak') {
        if (!env.ELEVENLABS_API_KEY) return err('Audio generation is not configured', 503, origin);
        const { text, voice_id = 'pNInz6obpgDQGcFmaJgB', model_id = 'eleven_multilingual_v2', stability = 0.5, similarity_boost = 0.75 } = body;
        if (!text) return err('text required', 400, origin);
        const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice_id}`, {
          method: 'POST',
          headers: { 'xi-api-key': env.ELEVENLABS_API_KEY, 'Content-Type': 'application/json', Accept: 'audio/mpeg' },
          body: JSON.stringify({ text: clampString(text, 5000), model_id, voice_settings: { stability, similarity_boost } }),
        });
        if (!response.ok) return err('Audio generation failed', 502, origin);
        const audio = new Uint8Array(await response.arrayBuffer());
        let binary = '';
        for (let i = 0; i < audio.length; i += 0x8000) binary += String.fromCharCode(...audio.subarray(i, i + 0x8000));
        return json({ audio_base64: btoa(binary), format: 'audio/mpeg' }, 200, origin);
      }

      if (path === '/api/claude/complete') {
        if (!env.ANTHROPIC_API_KEY) return err('Claude is not configured', 503, origin);
        const { messages, model = 'claude-haiku-4-5', max_tokens = 512, system, thinking } = body;
        if (!Array.isArray(messages) || !messages.length) return err('messages array required', 400, origin);
        const payload = { model, max_tokens, messages };
        if (system) payload.system = system;
        if (thinking) payload.thinking = thinking;
        const response = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: { 'x-api-key': env.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01', 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        if (!response.ok) return err('Claude API failed', 502, origin);
        return json(await response.json(), 200, origin);
      }

      return err('Not found', 404, origin);
    } catch (error) {
      console.error('NowssB API error', path, error?.message || error);
      const status = error?.message === 'Groq is not configured' ? 503 : 400;
      return err(error?.message || 'Request failed', status, origin);
    }
  },
};
