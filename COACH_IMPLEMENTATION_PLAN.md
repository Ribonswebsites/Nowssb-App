# NowssB Personal Coach — Real Product Implementation Plan

## Product objective

NowssB Personal Coach must behave as a real, authenticated coaching product rather than a visual mockup. A signed-in person can ask questions in natural language, receive context-aware guidance, see conversation history after reopening the app, start concrete practice actions, and view metrics derived from completed practice data. The webview and native Flutter clients must use the same backend contract, the same Firebase identity, and the same Firestore conversation records.

> A response is not considered real if it is generated from the button label alone, uses fabricated progress, disappears on reload, exposes a model key in the client, or silently pretends to succeed when the AI service is not configured.

## Current audit findings

The repository is a static-first Cloudflare Pages application with Firebase Authentication and Firestore already present. The web coach currently replaces a placeholder element with an input and returns one hard-coded sentence from `part095-direct-neomorphic-sections.js`. The Flutter screen in `flutter_app/lib/screens/personal_coach.dart` calculates a fabricated percentage from session count and returns a local canned sentence; it does not call an AI service or persist chat history. The native project already contains an image abstraction, but the coach screen has no hero image of its own. The generated Flutter remote media map is empty, so remote R2 artwork cannot be assumed to exist in a native build.

The existing repository already has the right identity foundation: Firebase Auth exposes the current user and ID token, Firestore stores user-owned records, and Cloudflare Pages Functions validate Firebase bearer tokens. The implementation should extend those foundations rather than introduce a second login system or put provider credentials into JavaScript or Dart.

## Architecture options

| Approach | Tradeoffs | Cost | Setup complexity |
| --- | --- | --- | --- |
| Extend the existing Cloudflare Pages Functions and Firebase project | Lowest migration risk; webview and Flutter share one HTTPS API; requires one server-side LLM credential and deployment variables; Cloudflare Functions remain stateless and should persist all durable state in Firestore | Provider token usage plus existing hosting; no per-request Manus session is required | Medium |
| Move the coach backend into a managed full-stack application service | Easier structured server code, built-in server-side LLM helper and database conventions; requires migrating deployment, auth integration, routes, and data ownership | Service usage plus model token usage | High |
| Keep the UI static and call an AI provider directly from each client | Fastest demo but unsafe: keys can be extracted, history is difficult to secure, abuse controls are weak, and web/native behavior drifts | Provider token usage with likely abuse exposure | Low initially, high operational risk |

The implementation in this repository follows the first approach because it preserves the current Firebase identity, Firestore content, Cloudflare deployment, webview URL, and Flutter native client while removing the fake behavior.

## Real product behavior

The coach request includes the user's current message, a bounded conversation history, and a compact context snapshot generated from real local and Firestore-backed state. Context includes the authenticated user ID on the server, user profile fields allowed for coaching, today's date, completed session count, today's sessions, active routine, streak, selected words, and the current client name. The client never sends an arbitrary UID as authority; the server derives identity from the verified Firebase token.

The model must answer as a practical personal coach. It should first understand the person's intent, then give a concise answer, one immediate next action, and optional follow-up questions. It must not claim to have performed actions it did not perform. When a user asks to plan a day, the response should contain an actionable sequence. When a user asks about progress, it should use the supplied numbers and say when data is unavailable. When the user asks to begin practice, the response should include an explicit action intent that the client can render as a Start Practice button. Medical, crisis, financial, legal, and other high-risk requests require a respectful boundary and a recommendation to seek an appropriate qualified professional or emergency support when applicable.

The first release supports text chat and deterministic actions. It does not invent voice, calendar writes, reminders, purchases, or external account actions. Those features can be added only through explicit tool contracts and user confirmation.

## API contract

### `POST /api/coach`

The route requires `Authorization: Bearer <Firebase ID token>` and accepts JSON:

```json
{
  "message": "I missed three days. What should I do next?",
  "conversationId": "optional-existing-conversation-id",
  "history": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ],
  "context": {
    "client": "webview",
    "timezone": "Asia/Kolkata",
    "progress": {
      "todaySessions": 1,
      "totalSessions": 12,
      "streak": 3,
      "goalPercent": 40
    },
    "routine": {"name": "Morning Word Ritual", "wordCount": 6}
  }
}
```

The server validates the body, caps message and history size, verifies the token, strips untrusted identity fields, calls the configured OpenAI-compatible server-side model, and writes the user-owned conversation and messages. The response is:

```json
{
  "conversationId": "uid-scoped-id",
  "message": {
    "id": "message-id",
    "role": "assistant",
    "content": "...",
    "createdAt": "2026-08-27T00:00:00.000Z",
    "actions": [
      {"type": "start_practice", "label": "Start a focused practice"}
    ]
  },
  "usage": {"inputTokens": 0, "outputTokens": 0}
}
```

Usage is optional and is returned only when the provider exposes it. Errors are JSON, never a fake coach response:

```json
{"error":"AI service is not configured. Add COACH_LLM_API_URL and COACH_LLM_API_KEY on the server."}
```

### `GET /api/coach?conversationId=...`

Returns the latest 50 messages for the authenticated user's conversation. A conversation ID is accepted only when it is owned by the verified user. The route returns an empty list for a new user and never lists another user's records.

### Firestore shape

```text
users/{uid}/coachConversations/{conversationId}
  title: string
  createdAt: timestamp
  updatedAt: timestamp
  lastMessagePreview: string

users/{uid}/coachConversations/{conversationId}/messages/{messageId}
  role: "user" | "assistant"
  content: string
  createdAt: timestamp
  client: "webview" | "flutter"
  actionTypes: string[]
```

Firestore rules must allow the signed-in owner to read and create their own coach records, allow only the owner to update/delete them, and deny all cross-user access. The server still validates ownership because API security must not rely solely on a client rule.

## Server-side model configuration

The Cloudflare Pages environment must define these encrypted variables:

```text
COACH_LLM_API_URL=https://<provider-compatible-endpoint>/v1/chat/completions
COACH_LLM_API_KEY=<server-only-secret>
COACH_LLM_MODEL=<provider-model-id>
FIREBASE_PROJECT_ID=nowssb-34f1b
```

The default model should be a fast, capable workhorse selected by the deployment owner. The model ID must be configurable rather than hard-coded. The browser and Flutter client must never receive the API key, provider URL, or hidden system prompt. Rate limiting should be added at the edge or through a durable counter before public launch; the first implementation must still enforce a body-size limit, history limit, timeout, and per-request maximum output.

## Webview implementation requirements

The webview coach must load the existing visual widget but replace the canned `respond()` function with an authenticated fetch to `/api/coach`. It must obtain a fresh Firebase ID token from the existing Auth instance, render user and coach bubbles, show a real loading state, disable duplicate submission, handle offline and server errors explicitly, restore the latest conversation when the overlay opens, and render returned action buttons. The dashboard cards must display actual dashboard state from `part094-dashboard-live.js`; hard-coded `68%`, `7 / 10`, and generic status copy must not remain as authoritative values.

The webview must keep the current visual direction: black/graphite background, strong white type, restrained borders, generous spacing, and the supplied orb/line-art language. The interface should be improved through semantic CSS and stateful components, not by adding another static screenshot. Every chip is an actual prompt that reaches the API. The close button, enter key, submit button, error retry, and Start Practice action must all work.

## Flutter implementation requirements

The Flutter coach must use the same `/api/coach` endpoint and Firebase ID token. Add an HTTP client dependency, create a typed `CoachApi` service, create typed message/action models, and keep persistence in Firestore under the authenticated user. The screen must observe `PracticeProgress.instance`, call `start()` before reading data, calculate goal percentage from completed words in the active set rather than `sessions * 10`, and refresh after a native practice completion.

The native UI must show a scrollable conversation, an input composer, quick prompts, a real loading indicator, retryable errors, and returned action buttons. A new user sees a truthful empty state; an offline user sees an offline message and can retry. Do not fabricate an assistant answer when the API is unreachable.

Add the bundled asset `assets/coach/coach-orb.png` to the Flutter asset declarations and render it in the hero card. The asset is transparent and monochrome so it composites cleanly over the black card. The normal webview may use the same asset through a repository path or web URL, but Flutter must not depend on a missing remote media-map entry for this hero image.

## Security and privacy requirements

All coach API calls require a valid Firebase ID token. The server verifies signature, issuer, audience, expiry, and subject. The server must never trust a client-supplied UID, email, progress total, role, or conversation owner. Client context is advisory and should be bounded; authoritative server-side Firestore values should be preferred when available. User messages are private user data and should not be logged in plaintext. Error logs should contain a request correlation ID and safe error category, not the message body or token. Provider secrets remain encrypted deployment variables and are never committed.

The coach is a wellness/productivity assistant, not a medical or emergency service. Its system instructions must avoid diagnosis, medication instructions, dangerous challenges, coercion, shame, and false certainty. It must encourage professional help for high-risk situations and handle crisis language with an appropriate safety response.

## Acceptance criteria

| Area | Definition of done |
| --- | --- |
| Authentication | Signed-out users are prompted to sign in; signed-in users receive a valid-token request; another user cannot read a conversation by changing its ID |
| AI response | A real user message reaches the server model and returns a context-aware response; no canned fallback is presented as AI |
| Persistence | Closing/reopening the coach restores the latest messages; webview and Flutter see the same user conversation |
| Progress | Metrics are derived from actual practice records and update after completion; no fabricated `sessions * 10` progress remains |
| Actions | A returned `start_practice` action starts the existing practice flow; failed requests do not trigger actions |
| Failure states | Missing configuration, expired auth, offline, timeout, provider error, empty message, and rate limit are visible and retryable |
| Flutter visuals | The hero orb asset exists in the bundle, is declared in `pubspec.yaml`, and is rendered in the coach hero card |
| Regression safety | Existing Node tests remain green; new API contract tests validate auth/validation/response behavior; Flutter analyzer/tests pass in a Flutter-enabled environment |

## Master prompt for a coding agent

```text
You are implementing NowssB Personal Coach in the existing repository, not creating a static mockup. Work in the checked-out repository exactly as it exists. Preserve the existing Firebase Authentication, Firestore, Cloudflare Pages Functions, WebView shell, and native Flutter architecture. Do not introduce a second auth system and do not put any model API key in browser JavaScript, HTML, or Dart.

Goal: replace the fake coach responses and fabricated progress with a real authenticated AI personal coach shared by the webview and Flutter clients.

First audit the current implementation. The web coach is in app/widgets/personal-coach.html and app/js/part095-direct-neomorphic-sections.js. The native screen is flutter_app/lib/screens/personal_coach.dart. Existing Firebase configuration and auth globals are in app/js/firebase.module.js. Existing Cloudflare bearer-token verification conventions are in functions/api/users.js. Existing live dashboard metrics are in app/js/part094-dashboard-live.js. Existing native practice truth is in flutter_app/lib/data/practice_progress.dart. Do not delete unrelated NowssB learning, store, notification, or content behavior.

Implement a secure Cloudflare Pages API at POST /api/coach and GET /api/coach. POST must require Authorization: Bearer Firebase ID token, validate a bounded JSON body, derive uid from verified token, assemble bounded progress/profile context, call an OpenAI-compatible server-side chat completion using COACH_LLM_API_URL, COACH_LLM_API_KEY, and COACH_LLM_MODEL, and persist the user and assistant messages under users/{uid}/coachConversations/{conversationId}. GET must return only the authenticated user’s latest conversation messages. Use structured JSON output when supported, with content plus optional action objects such as start_practice. If provider configuration is missing or the provider fails, return a truthful JSON error and never generate a fake coach response.

Use a clear coach system instruction. The coach should be practical, concise, empathetic, action-oriented, progress-aware, honest about missing data, and safe. It must not claim to have performed actions, diagnose medical conditions, provide dangerous instructions, or pretend to be a human. It should answer the question, explain what to do next, and offer a concrete action. For crisis or high-risk language, provide a supportive safety response and encourage immediate qualified help. Treat client-provided context as advisory and never trust client uid or ownership fields.

Update Firestore rules for user-owned coach conversations and messages. Keep records private. Add validation for max message length, max history items, max output tokens, supported roles, conversation ID format, content type, and request method. Add timeout handling, correlation IDs, safe logs, CORS only for the actual app origin, and no token/message logging.

Replace the webview’s wirePersonalCoach canned respond() implementation with real authenticated fetch calls. Reuse the existing Firebase Auth instance/current user and get a fresh ID token. Render a truthful chat timeline with user and assistant bubbles, restore history when the overlay opens, show loading/empty/offline/error states, prevent duplicate sends, support Enter and quick prompts, render returned action buttons, and invoke the existing practice flow for start_practice. Keep the supplied black/graphite design but make the data and state real. Connect dashboard cards to actual state from part094-dashboard-live.js; remove authoritative hard-coded progress values.

Replace flutter_app/lib/screens/personal_coach.dart with a production-quality native Flutter implementation. Add a typed CoachApi service and typed CoachMessage/CoachAction models. Obtain FirebaseAuth.instance.currentUser.getIdToken(), call the same HTTPS endpoint, persist/read conversation history from the same Firestore path, and show real loading/error/retry states. Observe PracticeProgress.instance and call start() before reading it. Compute progress from actual completed words in the selected set, not totalSessions * 10. Render the missing transparent asset assets/coach/coach-orb.png in the hero card, declare the asset in pubspec.yaml, and keep the existing practice player navigation working.

Add automated tests for request validation, auth failure, provider-not-configured failure, successful response shape, conversation ownership, and the web/Flutter action contract. Run existing Node tests. If Flutter is unavailable in the environment, still run static checks where possible and state that Flutter device/analyzer execution is pending rather than claiming it passed.

At the end, provide: changed files, deployment environment variables, Firestore rule changes, local run commands, production deployment steps, known limitations, and a short manual QA checklist. Never describe a static placeholder as working. Never silently fall back to canned AI text.
```

## Deployment checklist

The deployment owner must add the encrypted model variables to the Cloudflare Pages project, redeploy, and test with a real signed-in account. The Flutter Android build must include the generated Firebase configuration and the new coach asset. A production smoke test must cover sign-in, first chat, reopening history, starting practice from an assistant action, offline retry, another-user access denial, and a provider failure. If a provider is not selected yet, the API should remain disabled with a clear configuration error rather than pretend to be intelligent.

## Implementation status in this checkout

The real coach endpoint now exists at `functions/api/coach.js`, the owner-only Firestore rules are present, the webview sends authenticated requests and restores history, and the Flutter client has a typed API service, native conversation UI, truthful metrics, and a bundled transparent hero asset. Contract tests cover the cross-client wiring and all existing Node tests remain green.

The remaining production step is deployment configuration: add the encrypted `COACH_LLM_API_URL`, `COACH_LLM_API_KEY`, and `COACH_LLM_MODEL` variables to the Cloudflare Pages project, publish the Firestore rules, and build Flutter in an environment with Flutter installed. Without those server variables, the API intentionally returns a clear configuration error instead of pretending to be an AI coach.
