/* NowssB Personal Coach API.
 *
 * POST /api/coach: authenticated chat completion + Firestore persistence.
 * GET  /api/coach: authenticated latest conversation history.
 *
 * Provider credentials are server-only Cloudflare Pages environment variables:
 * COACH_LLM_API_URL, COACH_LLM_API_KEY, COACH_LLM_MODEL.
 */

const PROJECT_ID = 'nowssb-34f1b';
const APP_ORIGINS = new Set(['https://nowssb.com', 'https://www.nowssb.com']);
const MAX_MESSAGE = 4000;
const MAX_HISTORY = 20;
const MAX_CONTEXT = 12000;
const MAX_OUTPUT = 1800;
const REQUEST_TIMEOUT_MS = 25000;
const enc = new TextEncoder();

const json = (body, status = 200, request) => {
  const headers = new Headers({
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  const origin = request && request.headers.get('Origin');
  if (!origin || APP_ORIGINS.has(origin)) {
    headers.set('Access-Control-Allow-Origin', origin || 'https://nowssb.com');
    headers.set('Vary', 'Origin');
  }
  return new Response(JSON.stringify(body), { status, headers });
};

const cors = (request) => {
  const origin = request.headers.get('Origin');
  if (origin && !APP_ORIGINS.has(origin)) return json({ error: 'Origin not allowed.' }, 403, request);
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': origin || 'https://nowssb.com',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Max-Age': '600',
      'Vary': 'Origin',
    },
  });
};

const b64urlToBytes = (value) => {
  const b64 = (value + '='.repeat((4 - (value.length % 4)) % 4))
    .replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
};

let certCache = { at: 0, certs: null };
async function googleCerts() {
  if (certCache.certs && Date.now() - certCache.at < 3600e3) return certCache.certs;
  const response = await fetch('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');
  if (!response.ok) throw new Error('firebase-certificates-unavailable');
  certCache = { at: Date.now(), certs: await response.json() };
  return certCache.certs;
}

function extractSpkiFromCert(der) {
  const oid = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01];
  for (let i = 0; i < der.length - oid.length; i += 1) {
    let hit = true;
    for (let j = 0; j < oid.length; j += 1) {
      if (der[i + j] !== oid[j]) { hit = false; break; }
    }
    if (!hit) continue;
    for (let start = i; start >= 2; start -= 1) {
      if (der[start] !== 0x30 || der[start + 1] !== 0x82) continue;
      const length = (der[start + 2] << 8) | der[start + 3];
      const end = start + 4 + length;
      if (end <= der.length && end - start > 200 && der[start + 4] === 0x30) {
        return der.slice(start, end);
      }
    }
  }
  return null;
}

async function verifyIdToken(token) {
  const parts = String(token || '').split('.');
  if (parts.length !== 3) return null;
  let header;
  let claims;
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[0])));
    claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[1])));
  } catch (_) {
    return null;
  }
  const now = Math.floor(Date.now() / 1000);
  if (header.alg !== 'RS256' || claims.aud !== PROJECT_ID ||
      claims.iss !== `https://securetoken.google.com/${PROJECT_ID}` ||
      !claims.sub || claims.exp <= now) return null;

  const certs = await googleCerts();
  const pem = certs[header.kid];
  if (!pem) return null;
  const der = b64urlToBytes(pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, ''));
  const spki = extractSpkiFromCert(der);
  if (!spki) return null;
  const key = await crypto.subtle.importKey(
    'spki', spki, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify'],
  );
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5', key, b64urlToBytes(parts[2]), enc.encode(`${parts[0]}.${parts[1]}`),
  );
  return valid ? claims : null;
}

function safeId(value) {
  return /^[A-Za-z0-9_-]{1,96}$/.test(String(value || '')) ? String(value) : null;
}

function cleanHistory(history) {
  if (!Array.isArray(history)) return [];
  return history.slice(-MAX_HISTORY).filter((item) => item &&
    (item.role === 'user' || item.role === 'assistant') &&
    typeof item.content === 'string' && item.content.trim().length > 0)
    .map((item) => ({ role: item.role, content: item.content.trim().slice(0, MAX_MESSAGE) }));
}

function normalizeContext(input) {
  if (!input || typeof input !== 'object') return {};
  const progress = input.progress && typeof input.progress === 'object' ? input.progress : {};
  const routine = input.routine && typeof input.routine === 'object' ? input.routine : {};
  return {
    client: input.client === 'flutter' ? 'flutter' : 'webview',
    timezone: typeof input.timezone === 'string' ? input.timezone.slice(0, 80) : 'UTC',
    progress: {
      todaySessions: Number.isFinite(Number(progress.todaySessions)) ? Math.max(0, Math.min(1000, Number(progress.todaySessions))) : null,
      totalSessions: Number.isFinite(Number(progress.totalSessions)) ? Math.max(0, Math.min(100000, Number(progress.totalSessions))) : null,
      streak: Number.isFinite(Number(progress.streak)) ? Math.max(0, Math.min(3650, Number(progress.streak))) : null,
      goalPercent: Number.isFinite(Number(progress.goalPercent)) ? Math.max(0, Math.min(100, Number(progress.goalPercent))) : null,
    },
    routine: {
      name: typeof routine.name === 'string' ? routine.name.slice(0, 120) : null,
      wordCount: Number.isFinite(Number(routine.wordCount)) ? Math.max(0, Math.min(1000, Number(routine.wordCount))) : null,
    },
  };
}

function parseModelContent(content) {
  const raw = typeof content === 'string' ? content.trim() : '';
  if (!raw) return { content: 'I could not generate a response. Please try again.', actions: [] };
  try {
    const parsed = JSON.parse(raw);
    const answer = typeof parsed.content === 'string' ? parsed.content.trim() : '';
    const actions = Array.isArray(parsed.actions) ? parsed.actions.filter((action) =>
      action && action.type === 'start_practice' && typeof action.label === 'string')
      .slice(0, 3).map((action) => ({ type: 'start_practice', label: action.label.slice(0, 80) })) : [];
    return { content: answer || raw, actions };
  } catch (_) {
    return { content: raw, actions: [] };
  }
}

function firestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number' && Number.isInteger(value)) return { integerValue: String(value) };
  if (typeof value === 'number') return { doubleValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(firestoreValue) } };
  if (typeof value === 'object') {
    const fields = {};
    Object.entries(value).forEach(([key, item]) => { fields[key] = firestoreValue(item); });
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

function fromFirestoreValue(value) {
  if (!value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(fromFirestoreValue);
  if ('mapValue' in value) return Object.fromEntries(Object.entries(value.mapValue.fields || {}).map(([k, v]) => [k, fromFirestoreValue(v)]));
  return null;
}

function fromDocument(document) {
  const fields = Object.fromEntries(Object.entries(document.fields || {}).map(([key, value]) => [key, fromFirestoreValue(value)]));
  return { id: document.name.split('/').pop(), ...fields };
}

function firestoreBase() {
  return `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
}

async function firestoreWrite(token, path, values) {
  const response = await fetch(`${firestoreBase()}/${path}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(values).map(([key, value]) => [key, firestoreValue(value)])) }),
  });
  if (!response.ok) throw new Error(`firestore-write-${response.status}`);
  return response.json();
}

async function firestoreGetLatestConversation(token, uid, conversationId) {
  const safeUid = encodeURIComponent(uid);
  let id = safeId(conversationId);
  if (!id) {
    const response = await fetch(`${firestoreBase()}/users/${safeUid}/coachConversations?pageSize=1&orderBy=updatedAt%20desc`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!response.ok) return null;
    const data = await response.json();
    const first = (data.documents || [])[0];
    if (!first) return null;
    id = first.name.split('/').pop();
  }
  const response = await fetch(`${firestoreBase()}/users/${safeUid}/coachConversations/${encodeURIComponent(id)}/messages?pageSize=50&orderBy=createdAt`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) return null;
  const data = await response.json();
  return { conversationId: id, messages: (data.documents || []).map(fromDocument) };
}

async function providerCompletion(env, messages) {
  if (!env.COACH_LLM_API_URL || !env.COACH_LLM_API_KEY || !env.COACH_LLM_MODEL) {
    const error = new Error('coach-provider-not-configured');
    error.status = 503;
    throw error;
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(env.COACH_LLM_API_URL, {
      method: 'POST',
      signal: controller.signal,
      headers: { Authorization: `Bearer ${env.COACH_LLM_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: env.COACH_LLM_MODEL,
        messages,
        max_tokens: MAX_OUTPUT,
        temperature: 0.5,
        response_format: { type: 'json_object' },
      }),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      const error = new Error('coach-provider-error');
      error.status = response.status >= 500 ? 502 : 400;
      throw error;
    }
    return data.choices?.[0]?.message?.content || '';
  } finally {
    clearTimeout(timer);
  }
}

const systemPrompt = `You are NowssB Personal Coach, a practical and compassionate productivity and learning coach.
Answer the user's actual question, not just the button label. Use the supplied progress context when present, distinguish facts from assumptions, and never claim to have completed an action you did not complete. Give a clear answer followed by one small next step. Keep most answers under 180 words unless detail is necessary. Do not shame, manipulate, diagnose, prescribe medication, give dangerous instructions, or pretend to be a human. For medical, legal, financial, or crisis situations, state the boundary and direct the user to an appropriate qualified professional or emergency support.
Return JSON only with this shape: {"content":"string","actions":[{"type":"start_practice","label":"string"}]}. Use an empty actions array unless starting a practice session is clearly the useful next step. Never include markdown fences around the JSON.`;

async function postCoach(request, env) {
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return json({ error: 'Sign in first.' }, 401, request);
  let claims;
  try { claims = await verifyIdToken(auth.slice(7)); }
  catch (_) { return json({ error: 'Could not verify your sign-in.' }, 503, request); }
  if (!claims) return json({ error: 'That sign-in is not valid.' }, 401, request);

  const contentLength = Number(request.headers.get('Content-Length') || 0);
  if (contentLength > 50000) return json({ error: 'Request is too large.' }, 413, request);
  let body;
  try { body = await request.json(); } catch (_) { return json({ error: 'Send valid JSON.' }, 400, request); }
  const message = typeof body.message === 'string' ? body.message.trim() : '';
  if (!message) return json({ error: 'Write a message first.' }, 400, request);
  if (message.length > MAX_MESSAGE) return json({ error: `Message must be ${MAX_MESSAGE} characters or fewer.` }, 400, request);
  const history = cleanHistory(body.history);
  const context = normalizeContext(body.context);
  if (JSON.stringify(context).length > MAX_CONTEXT) return json({ error: 'Context is too large.' }, 400, request);

  const conversationId = safeId(body.conversationId) || crypto.randomUUID();
  const now = new Date().toISOString();
  const userMessageId = crypto.randomUUID();
  const assistantMessageId = crypto.randomUUID();
  const modelMessages = [
    { role: 'system', content: `${systemPrompt}\nCurrent context (advisory, not identity authority): ${JSON.stringify(context)}` },
    ...history,
    { role: 'user', content: message },
  ];

  let modelContent;
  try { modelContent = await providerCompletion(env, modelMessages); }
  catch (error) {
    if (error.name === 'AbortError') return json({ error: 'The coach took too long to respond. Please try again.' }, 504, request);
    if (error.message === 'coach-provider-not-configured') return json({ error: 'AI service is not configured on the server yet.' }, 503, request);
    console.error('coach-provider-failure', error.message || 'unknown');
    return json({ error: 'The coach is temporarily unavailable. Please try again.' }, error.status || 502, request);
  }
  const parsed = parseModelContent(modelContent);
  if (!parsed.content) return json({ error: 'The coach returned an empty response. Please try again.' }, 502, request);

  try {
    const token = auth.slice(7);
    const uidPath = encodeURIComponent(claims.sub);
    await firestoreWrite(token, `users/${uidPath}/coachConversations/${encodeURIComponent(conversationId)}`, {
      title: message.slice(0, 80), updatedAt: now, lastMessagePreview: parsed.content.slice(0, 160),
    });
    await firestoreWrite(token, `users/${uidPath}/coachConversations/${encodeURIComponent(conversationId)}/messages/${encodeURIComponent(userMessageId)}`, {
      role: 'user', content: message, createdAt: now, client: context.client, actionTypes: [],
    });
    await firestoreWrite(token, `users/${uidPath}/coachConversations/${encodeURIComponent(conversationId)}/messages/${encodeURIComponent(assistantMessageId)}`, {
      role: 'assistant', content: parsed.content, createdAt: new Date(Date.now() + 1).toISOString(), client: context.client, actionTypes: parsed.actions.map((action) => action.type),
    });
  } catch (error) {
    console.error('coach-persistence-failure', error.message || 'unknown');
    return json({ error: 'The coach answered, but the conversation could not be saved. Please retry.' }, 502, request);
  }

  return json({
    conversationId,
    message: { id: assistantMessageId, role: 'assistant', content: parsed.content, createdAt: new Date(Date.now() + 1).toISOString(), actions: parsed.actions },
  }, 200, request);
}

async function handle(context) {
  const { request, env } = context;
  if (request.method === 'OPTIONS') return cors(request);
  if (request.method === 'POST') return postCoach(request, env);
  if (request.method === 'GET') {
    const auth = request.headers.get('Authorization') || '';
    if (!auth.startsWith('Bearer ')) return json({ error: 'Sign in first.' }, 401, request);
    let claims;
    try { claims = await verifyIdToken(auth.slice(7)); }
    catch (_) { return json({ error: 'Could not verify your sign-in.' }, 503, request); }
    if (!claims) return json({ error: 'That sign-in is not valid.' }, 401, request);
    const data = await firestoreGetLatestConversation(auth.slice(7), claims.sub, new URL(request.url).searchParams.get('conversationId'));
    return json(data || { conversationId: null, messages: [] }, 200, request);
  }
  return json({ error: 'GET, POST, or OPTIONS only.' }, 405, request);
}

export async function onRequest(context) {
  return handle(context);
}
