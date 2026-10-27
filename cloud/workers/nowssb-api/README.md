# nowssb-api Worker (deployed source)

Exact source of the Cloudflare Worker `nowssb-api` (https://nowssb-api.ribonpatil2.workers.dev).
Main module `worker.js`, compatibility_date 2026-08-23. Secrets (set in Cloudflare only):
GROQ_API_KEY, RESEND_API_KEY, SUPPORT_TO_EMAIL. There is no Workers AI binding, so
/api/assistant/chat (Personal Coach + Support) uses Groq when `env.AI` is absent.
Keep this file in sync with every deploy.
