/**
 * NowssB Universal API — Cloudflare Worker
 *
 * Free tier: 100,000 requests/day, zero cold starts, global edge network
 * Deploy: wrangler deploy  OR  paste into Cloudflare Dashboard → Workers
 *
 * Required Secrets (set via wrangler secret put OR CF Dashboard):
 *   GROQ_API_KEY         — from console.groq.com
 *   RAZORPAY_KEY_ID      — from Razorpay Dashboard
 *   RAZORPAY_KEY_SECRET  — from Razorpay Dashboard (NEVER in frontend)
 *   ELEVENLABS_API_KEY   — from elevenlabs.io
 *   ANTHROPIC_API_KEY    — from console.anthropic.com (NEVER in frontend)
 *
 * Endpoints:
 *   POST /api/groq/transcribe   — Groq Whisper (pronunciation scoring)
 *   POST /api/groq/complete     — Groq LLM (sentence gen, daily prescription, AI feedback)
 *   POST /api/razorpay/order        — Create Razorpay order (server-side, returns order_id)
 *   POST /api/razorpay/subscription — Create Razorpay subscription (auto-pay, returns subscription_id)
 *   POST /api/elevenlabs/speak      — ElevenLabs TTS (generate word audio)
 *   POST /api/claude/complete       — Claude AI (persona feedback, onboarding, conversation mode)
 *   GET  /api/health                — health check
 *
 * Razorpay subscription plan IDs (set as env vars):
 *   RAZORPAY_PLAN_RESONANCE_MONTHLY   — plan_id for Resonance monthly $4.99
 *   RAZORPAY_PLAN_RESONANCE_YEARLY    — plan_id for Resonance yearly $49.99
 *   RAZORPAY_PLAN_FREQUENCY_MONTHLY   — plan_id for Frequency monthly $9.99
 *   RAZORPAY_PLAN_FREQUENCY_YEARLY    — plan_id for Frequency yearly $99.99
 *   RAZORPAY_PLAN_FREQUENCYX_MONTHLY  — plan_id for Frequency X monthly $19.99
 *   RAZORPAY_PLAN_FREQUENCYX_YEARLY   — plan_id for Frequency X yearly $199.99
 */

const ALLOWED_ORIGINS = [
  'https://nowssb.com',
  'https://www.nowssb.com',
  'https://ribonswebsites.github.io',
  'http://localhost:3000',
  'http://127.0.0.1:5500',
];

// ── CORS ─────────────────────────────────────────────────────────────────────
function corsHeaders(origin) {
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}

function json(data, status = 200, origin = '') {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) },
  });
}

function err(msg, status = 400, origin = '') {
  return json({ error: msg }, status, origin);
}

// ── MAIN HANDLER ─────────────────────────────────────────────────────────────
export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') || '';
    const url = new URL(request.url);
    const path = url.pathname;

    // Preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    // Health check
    if (path === '/api/health') {
      return json({ status: 'ok', ts: Date.now() }, 200, origin);
    }

    // POST only beyond this point
    if (request.method !== 'POST') {
      return err('Method not allowed', 405, origin);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return err('Invalid JSON body', 400, origin);
    }

    // ── Groq Whisper: pronunciation scoring ──────────────────────────────────
    if (path === '/api/groq/transcribe') {
      /*
       * Expects multipart/form-data OR JSON { audio_base64, model }
       * Returns { text, segments } from Groq Whisper
       */
      const { audio_base64, model = 'whisper-large-v3-turbo' } = body;
      if (!audio_base64) return err('audio_base64 required', 400, origin);

      // Convert base64 → Blob for Groq multipart upload
      const binary = atob(audio_base64.replace(/^data:[^;]+;base64,/, ''));
      const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));
      const blob = new Blob([bytes], { type: 'audio/webm' });

      const form = new FormData();
      form.append('file', blob, 'recording.webm');
      form.append('model', model);
      form.append('response_format', 'verbose_json');
      form.append('language', 'hi'); // default Hindi; frontend can override

      const groqRes = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
        method: 'POST',
        headers: { Authorization: `Bearer ${env.GROQ_API_KEY}` },
        body: form,
      });

      if (!groqRes.ok) {
        const errText = await groqRes.text();
        return err(`Groq transcription failed: ${errText}`, 502, origin);
      }

      const data = await groqRes.json();
      return json(data, 200, origin);
    }

    // ── Groq LLM: text generation ─────────────────────────────────────────────
    if (path === '/api/groq/complete') {
      /*
       * Expects { messages, model?, max_tokens?, temperature? }
       * Returns Groq chat completion response
       * Used for: sentence alchemy, daily prescription, AI persona feedback,
       *           cinematic onboarding, conversation mode
       */
      const {
        messages,
        model = 'llama-3.1-8b-instant',
        max_tokens = 512,
        temperature = 0.8,
        system,
      } = body;

      if (!messages || !Array.isArray(messages)) {
        return err('messages array required', 400, origin);
      }

      const payload = {
        model,
        messages: system
          ? [{ role: 'system', content: system }, ...messages]
          : messages,
        max_tokens,
        temperature,
      };

      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.GROQ_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!groqRes.ok) {
        const errText = await groqRes.text();
        return err(`Groq completion failed: ${errText}`, 502, origin);
      }

      const data = await groqRes.json();
      return json(data, 200, origin);
    }

    // ── Razorpay: create order (server-side only) ─────────────────────────────
    if (path === '/api/razorpay/order') {
      /*
       * Expects { amount, currency?, notes? }
       * amount in the currency's minor unit ($1 = 100 cents). App is universal → USD.
       * Returns { id, amount, currency } — pass id to Razorpay checkout in frontend
       */
      const { amount, currency = 'USD', notes = {} } = body;
      if (!amount || isNaN(amount) || amount < 50) {
        return err('amount (in minor units) required, min 50', 400, origin);
      }

      const credentials = btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
      const rzpRes = await fetch('https://api.razorpay.com/v1/orders', {
        method: 'POST',
        headers: {
          Authorization: `Basic ${credentials}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: Math.round(amount),
          currency,
          receipt: `nwsb_${Date.now()}`,
          notes,
        }),
      });

      if (!rzpRes.ok) {
        const errText = await rzpRes.text();
        return err(`Razorpay order creation failed: ${errText}`, 502, origin);
      }

      const order = await rzpRes.json();
      // Only return what the frontend needs — never expose Key Secret
      return json({ id: order.id, amount: order.amount, currency: order.currency }, 200, origin);
    }

    // ── Razorpay: create subscription (auto-pay) ─────────────────────────────
    if (path === '/api/razorpay/subscription') {
      /*
       * Expects { tier, billing, email, total_count? }
       * tier: 'resonance' | 'frequency' | 'frequencyX'
       * billing: 'monthly' | 'yearly'
       * Returns { subscription_id } — pass to Razorpay checkout in frontend
       *
       * The subscription starts after the 7-day trial period.
       * Razorpay collects the mandate/card during checkout but first charge
       * happens at start_at (7 days from now).
       */
      const { tier, billing = 'monthly', email = '', total_count = 12 } = body;
      if (!tier) return err('tier required', 400, origin);

      const planMap = {
        resonance_monthly:   env.RAZORPAY_PLAN_RESONANCE_MONTHLY,
        resonance_yearly:    env.RAZORPAY_PLAN_RESONANCE_YEARLY,
        frequency_monthly:   env.RAZORPAY_PLAN_FREQUENCY_MONTHLY,
        frequency_yearly:    env.RAZORPAY_PLAN_FREQUENCY_YEARLY,
        frequencyX_monthly:  env.RAZORPAY_PLAN_FREQUENCYX_MONTHLY,
        frequencyX_yearly:   env.RAZORPAY_PLAN_FREQUENCYX_YEARLY,
      };
      const planId = planMap[`${tier}_${billing}`];
      if (!planId) return err(`No plan configured for ${tier}/${billing}`, 400, origin);

      // Trial ends in 7 days — auto-charge starts then
      const trialEndUnix = Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60;

      const credentials = btoa(`${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`);
      const rzpRes = await fetch('https://api.razorpay.com/v1/subscriptions', {
        method: 'POST',
        headers: {
          Authorization: `Basic ${credentials}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          plan_id: planId,
          total_count: billing === 'yearly' ? 5 : total_count,
          quantity: 1,
          start_at: trialEndUnix,
          customer_notify: 1,
          notes: { email, tier, billing },
        }),
      });

      if (!rzpRes.ok) {
        const errText = await rzpRes.text();
        return err(`Razorpay subscription creation failed: ${errText}`, 502, origin);
      }

      const sub = await rzpRes.json();
      return json({ subscription_id: sub.id, start_at: trialEndUnix }, 200, origin);
    }

    // ── ElevenLabs: text-to-speech ────────────────────────────────────────────
    if (path === '/api/elevenlabs/speak') {
      /*
       * Expects { text, voice_id?, model_id? }
       * Returns audio/mpeg binary (pass through as base64 for frontend Web Audio)
       * Pre-generated audio should be stored in Cloudflare R2 to avoid regenerating
       */
      const {
        text,
        voice_id = 'pNInz6obpgDQGcFmaJgB', // Adam (ElevenLabs default male)
        model_id = 'eleven_multilingual_v2',
        stability = 0.5,
        similarity_boost = 0.75,
      } = body;

      if (!text) return err('text required', 400, origin);

      const elRes = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice_id}`, {
        method: 'POST',
        headers: {
          'xi-api-key': env.ELEVENLABS_API_KEY,
          'Content-Type': 'application/json',
          Accept: 'audio/mpeg',
        },
        body: JSON.stringify({
          text,
          model_id,
          voice_settings: { stability, similarity_boost },
        }),
      });

      if (!elRes.ok) {
        const errText = await elRes.text();
        return err(`ElevenLabs failed: ${errText}`, 502, origin);
      }

      // Stream audio bytes directly back
      const audioBuffer = await elRes.arrayBuffer();
      const base64Audio = btoa(String.fromCharCode(...new Uint8Array(audioBuffer)));
      return json({ audio_base64: base64Audio, format: 'audio/mpeg' }, 200, origin);
    }

    // ── Claude AI: general completion ─────────────────────────────────────────
    if (path === '/api/claude/complete') {
      /*
       * Expects { messages, model?, max_tokens?, system?, thinking? }
       * model defaults to claude-haiku-4-5 (fastest, cheapest — good for per-word AI)
       * Use claude-sonnet-4-6 for conversation mode (richer responses)
       * Use claude-opus-4-7 with thinking:{type:'adaptive'} for complex reasoning
       * Returns Claude Messages API response
       * Used for: AI persona feedback, daily prescription, conversation mode, onboarding
       */
      const {
        messages,
        model = 'claude-haiku-4-5',
        max_tokens = 512,
        system,
        thinking,
      } = body;

      if (!messages || !Array.isArray(messages)) {
        return err('messages array required', 400, origin);
      }

      const payload = { model, max_tokens, messages };
      if (system) payload.system = system;
      // thinking only works on Opus 4.7/4.6/Sonnet 4.6 — pass through as-is
      if (thinking) payload.thinking = thinking;

      const claudeRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!claudeRes.ok) {
        const errText = await claudeRes.text();
        return err(`Claude API failed: ${errText}`, 502, origin);
      }

      const data = await claudeRes.json();
      return json(data, 200, origin);
    }

    return err('Not found', 404, origin);
  },
};
