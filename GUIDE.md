# NowssB — Complete Product & Developer Guide
**Version 6.0 — Updated May 2026**
CEO: Sanjay Kumar Gadge · Developer: Ribon

---

## Table of Contents

1. [What is NowssB](#1-what-is-nowssb)
2. [Design & Brand Rules — NEVER BREAK THESE](#2-design--brand-rules--never-break-these)
3. [Current File Structure](#3-current-file-structure)
4. [Firebase Project](#4-firebase-project)
5. [App — index.html — Screens & Navigation](#5-app--indexhtml--screens--navigation)
6. [The Admin Panel — admin.html](#6-the-admin-panel--adminhtml)
7. [Theme System (Fashion Home)](#7-theme-system-fashion-home)
8. [Subscription Tiers](#8-subscription-tiers)
9. [Deployment — Web](#9-deployment--web)
10. [Web Performance — Making It Fast](#10-web-performance--making-it-fast)
11. [Deployment — Android APK via Capacitor](#11-deployment--android-apk-via-capacitor)
12. [Admin APK & Push Notifications](#12-admin-apk--push-notifications)
13. [Known Issues & Warnings](#13-known-issues--warnings)
14. [What's Built vs Missing](#14-whats-built-vs-missing)
15. [Development Roadmap](#15-development-roadmap)
16. [Passwords & Keys](#16-passwords--keys)

---

## 1. What is NowssB

**NOWSBANSIU** = Natural Origin Word Sound Science Bharata/Bansiu

NowssB is a personalized daily word & sentence practice app built on **Shabdapathy** — healing through correct pronunciation of natural origin words.

**Core philosophy:** Every word has a natural origin vibration. When pronounced correctly — with the exact mouth position, breath, and resonance — it creates a specific frequency that affects specific organs and systems in the body. Sound before definition. Vibration before meaning. **Word without dictionary.**

**CRITICAL — Read this first:**
- NOT Sanskrit. NOT sacred words. NOT ancient scriptures. NOT religion. NOT spirituality.
- The words are natural origin words from ANY language, ANY culture, ANY era.
- The science is phonetic vibration and its effect on the human body.
- Any reference to Sanskrit, sacred, ancient wisdom, Vedic, holy, or spiritual in the UI must be removed.
- "Vedic Scholar" and "Sanskrit Scholar" removed from AI personas.

**Brand tagline:** *"Healing is Fashion. NowssB is the new fitness."*

**Positioning:** Healing is not alternative medicine. It is identity. It is lifestyle. It is fashion.

**Target market:** Same audience as Calm, Headspace, fitness apps — unique hook is natural word origin science.

**One-line pitch:** Spotify meets sound healing, with AI pronunciation coaching built in.

**Live URL:** https://nowssb.com

---

## 2. Design & Brand Rules — NEVER BREAK THESE

### Visual Rules
- NO emojis ever — SVG icons only, always
- NO serif fonts ever
- NO centered layouts — left-aligned always (exceptions: hero title and player disc)
- NO repeated images anywhere
- Background: deep cosmic dark `#060c18`
- Accent gold: `#e8d5a3`
- Accent light: `#c8e8f5`
- Typography: DM Sans only, dual weight 200→800, white→gold
- Effects: glassmorphism, GSAP ScrollTrigger, magnetic hover, hero parallax, liquid shimmer
- Rainbow: only as faint LED shimmer on buttons, never dominant
- Logo: rainbow conic-gradient ring + infinity symbol
- Style: iOS / studio quality, cinematic, never generic, never AI-looking
- Zero border-radius on square sections — use sharp corners (iOS style)
- All blur values capped at **14px max** — no exceptions
- Particle count maximum **8** — never increase

### Image Rules
- Every new section needs its own unique banner + background image from Ribon — never reuse images across sections
- Never add any image without Ribon approval
- Cloudinary CDN (account: `dfc8lwj22`) for all web images — **old account `dkzxw33ln` is RETIRED**
- Cloudflare R2 for all audio and video
- NO Firebase Storage — use Cloudflare R2 for all media

### Performance Rules — NEVER BREAK THESE
- NEVER reduce image or video quality — upscale using Cloudinary `e_upscale/q_100/f_auto/`
- NEVER remove design elements to improve speed — optimize the code underneath instead
- All animation intervals must be gated to their screen only — never run on inactive screens

### Brand Language Rules
- Never use "Premium" or "VIP" — use tier names: Starter / Resonance / Frequency
- Never reference Sanskrit, sacred, ancient wisdom, Vedic, holy, spiritual — not what NowssB is
- Subscription unlocks features. Words unlock sentences. Both together = the full experience.

---

## 3. Current File Structure

```
/Nowssb-App/
├── index.html          ← THE entire main app (~22,500 lines, single-file SPA)
├── admin.html          ← CEO admin panel (password protected)
├── admin-dev.html      ← Developer admin variant
├── worker.js           ← Cloudflare Worker (Razorpay order_id server)
├── GUIDE.md            ← This file
├── assets/             ← Static assets
└── components/         ← Component files
```

**Single-file SPA:** The entire app — all HTML, CSS, JavaScript, all screens — lives in `index.html`. This is intentional during development. The Capacitor build uses a Vite build pipeline to process it before wrapping.

**Play Store path:**
```
Current HTML → Performance optimized → Vite build → Capacitor wrap → Play Store
```

---

## 4. Firebase Project

| Setting | Value |
|---|---|
| Project ID | `nowssb-34f1b` |
| Auth Domain | `nowssb-34f1b.firebaseapp.com` (config) / `nowssb.com` (in authDomain) |
| API Key | `AIzaSyBly5XnqNnpVom11thjlvT5q_BfxNJBfgQ` |
| App ID | `1:1024709686012:web:20d425060043141a0b5d79` |
| Firestore DB | Default (us-central1) |
| Auth Methods | Google, Email/Password, Phone OTP |
| Firebase owner | wodbhailog@gmail.com |
| Authorized domains | nowssb.com, nowssb-app.pages.dev, ribonswebsites.github.io |

**Pending Firebase setup:**
- Enable Phone auth in Firebase Console → Auth → Sign-in method → Phone
- Add ribonpatil32@gmail.com as backup owner in Firebase

### Firestore Collections

| Collection | Purpose |
|---|---|
| `users/{uid}` | User profiles, tier, subscription, blocked status |
| `words/{wordId}` | Master word library (to be populated by client) |
| `submissions/{id}` | CEO-submitted word drafts (pending review) |
| `chats/{chatId}` | Chat thread metadata |
| `chats/{chatId}/messages/{id}` | Individual messages |
| `wordRequests/{id}` | Custom word requests |

### Key user document fields

```
uid                  string   Firebase Auth UID
email                string   User's email
displayName          string
gender               'male' | 'female' | 'other'
onboardingDone       boolean
isPro                boolean  legacy — tier field is source of truth
tier                 'resonance' | 'frequency' | 'frequencyX' | null
subscriptionType     'razorpay' | 'admin_grant'
subscriptionBilling  'monthly' | 'yearly'
subscriptionStart    ISO string
subscriptionEnd      ISO string
subscriptionPaymentId string
trialStartDate       ISO string
trialEndDate         ISO string
ownedWords           string[]  words the user has acquired
adminGifts           array     words gifted by admin with notes
blocked              boolean   if true, user is signed out on login
blockedAt            ISO string
blockedBy            string
bannerUrl            R2 path
avatarUrl            R2 path
bio                  string (max 150)
isPublic             boolean
allowRatings         boolean
createdAt            ISO string
```

---

## 5. App — index.html — Screens & Navigation

### All Screens

| Screen ID | What it is |
|---|---|
| `#splash` | Animated intro (4.2s), auto-advances |
| `#login` | Auth — Google, Email, Phone tabs |
| `#signup2` | Onboarding quiz / personalization |
| `#home-nm` | **Normal home** — default landing screen (neumorphic) |
| `#home` | **Fashion home** — dark glassmorphism with hero images |
| Sub-screens (via `openSub()`) | Practice, Routines, Sound Library, Word Store, etc. |

### Home Screen Logic

- **Default on launch:** `#home-nm` (normal home)
- **If user previously chose Fashion home:** `#home` loads instead
- Preference stored in `localStorage('nwsb_home_mode')`:
  - `'nm'` → normal home (default)
  - `'home'` → Fashion home
- "Fashion Mode" button on `#home-nm` switches to `#home` and saves the preference
- Sun icon on `#home` switches back to `#home-nm` and saves preference as `'nm'`

### Navigation

```js
goTo('screen-id')        // Navigate to any screen
openSub(id)              // Open a sub-screen panel
_doNavigate('home')      // Auth-triggered navigation — respects nwsb_home_mode
```

### Key Global Functions

| Function | Purpose |
|---|---|
| `goTo(dest)` | Navigate to a screen |
| `openSub(id)` | Open a sub-screen panel |
| `setNwsbTheme(theme, explicit)` | Apply Fashion home theme |
| `setBE(style, explicit)` | Legacy alias → calls setNwsbTheme |
| `showFashionHomeIntro()` | Show Black Edition cinematic intro |
| `_doNavigate(dest)` | Auth-triggered navigation (respects home preference) |

### Key localStorage Keys

| Key | Values | Purpose |
|---|---|---|
| `nwsb_home_mode` | `'nm'` / `'home'` | Which home screen loads on startup |
| `nwsb_theme` | `'default'` / `'black'` / `'neo'` / `'glass-black'` | Fashion home theme |
| `nwsb_intros` | `'always'` / `'once'` | Whether section intro screens always show |
| `nwsb_done` | `'1'` | Onboarding tour completed |

### Word Player (Walkman)

Style: Sony Walkman + glassmorphism. Fixed layout, no scrolling. 5 tabs:
- **Listen** — plays ElevenLabs audio, phonetic chips light up per syllable
- **Record** — mic → Groq Whisper → similarity score + AI persona feedback
- **Repeat** — x3 / x7 / x21 rep counter
- **Meaning** — organ, benefit, origin
- **Guide** — mouth position, resonance point, common mistake, practice tip

After completing all words in a routine session, a sentence is auto-generated via Groq LLM and plays in the same player. Word-by-word highlight. This is NOT a separate screen.

### Routine System

- 5 routine slots per user (Morning, Midday, Afternoon, Evening, Night — user can rename)
- Today's Practice card on home reads current time → shows matching routine
- Routine detail: Words tab | Library tab | History tab

### Health Journey

- Male: 10 categories (Fitness & Muscle, Heart Health, Skin & Glow, Gut Health, Liver Detox, Mental Clarity, Testosterone & Hormones, Immunity Boost, Lung & Breath, Kidney & Bladder)
- Female: 10 categories (Fitness & Tone, Heart Health, Skin & Glow, Gut Health, Liver Detox, Hormonal Balance, Mental Clarity, Hair Health, Immunity Boost, Reproductive Wellness)

### Placeholder Words — REMOVE ALL

Current words in MASTER_WORD_LIBRARY (AAROGYA, PRANA, SHAKTI, ANANDA, SOMA, TEJAS, OJAS, VATA, PITTA, KAPHA, SURYA, CHANDRA) are placeholders only. They will be deleted when the client provides real words. Do not build permanent UI around them.

---

## 6. The Admin Panel — admin.html

**URL:** `https://nowssb.com/admin.html`
**Password:** `sanjay_nowssb_2026`

The admin panel is a completely separate HTML file. It has its own Firebase connection (named instance `'admin-panel'`) and does not share code with the main app.

### What the Admin Can Do

#### Word Studio
- Record word pronunciation via microphone
- Fill in all word details (phonetic, organ, benefit, meaning, hold times, category)
- Auto-generates ElevenLabs notation and breath guide
- Submit word → saved to Firestore `submissions` collection with Pending status
- View submitted words with review status (Pending / Approved / Needs Edit)

#### Instagram Link
- Editable Instagram handle field
- Tap to open NowssB Instagram profile directly
- Handle persists in localStorage

#### User Access Control (Firebase connected)
- **Search** any user by email address or Firebase UID
- **View** their name, current tier, word count, join date
- **Grant** free subscription at any tier (Resonance / Frequency / Frequency X)
- **Revoke** access — strips subscription, returns user to free tier
- **Block** a user — user is immediately signed out on next login and sees suspension message
- **Unblock** a user — restores access

#### Send Word to User (Firebase connected)
- Find any user by email or UID
- Send them any word — adds to their `ownedWords` array in Firestore
- Optional gift note saved to `adminGifts` field

---

## 7. Theme System (Fashion Home)

The Fashion `#home` screen has 4 visual themes, selectable from **Settings → Black Edition**:

| Theme | Body class | What changes |
|---|---|---|
| **Default** | `nwsb-theme-default` | Glassmorphism — `rgba` header/nav/drawer + `backdrop-filter`. Background images visible. |
| **Black** | `nwsb-theme-black` | Everything solid `#000`. Background images hidden. Cinematic intro plays on first selection. |
| **Neo** | `nwsb-theme-neo` | Deep neumorphic `#0d0d0d` with `box-shadow` depth. Background images hidden. |
| **Glass Black** | `nwsb-theme-glass-black` | `rgba(0,0,0,0.6–0.78)` + `blur(32px)` — dark tinted glassmorphism. Background images visible. |

**Key rules:**
- All theme CSS is scoped to `body.fashion-home-active.nwsb-theme-*`
- `body.fashion-home-active` is only present when `#home` is the active screen
- Themes **never affect** `#home-nm` or any other screen
- Theme persists via `localStorage('nwsb_theme')` until explicitly changed
- The Black Edition cinematic intro only shows when user explicitly selects Black — never on page load

**JS:**
```js
setNwsbTheme('default')       // glassmorphism (default)
setNwsbTheme('black', true)   // solid black + shows intro once per session
setNwsbTheme('neo')           // neumorphism
setNwsbTheme('glass-black')   // dark blur glass
```

---

## 8. Subscription Tiers

### Tier Structure

```
FREE TRIAL — 15 days, full Frequency access, no card required
     ↓ trial expires
RESONANCE    $4.99/month · $49.99/year  — 5 words/week
FREQUENCY    $9.99/month · $99.99/year  — 10 words/week
FREQUENCY X  $19.99/month · $199.99/year — 20 words/week + free Blue verification
```

No permanent free tier. After trial expires, app is locked until a plan is chosen.

**Note:** Each tier caps how many *new* words a user can start practicing per week (5/10/20 — see `GATE.wordsPerWeek()` in `app/js/part045.js`), enforced client-side by `nwsb_words_this_week` in localStorage. Subscribing to Frequency X also auto-grants the Blue verification badge (`_onSubscriptionSuccess()` in `app/js/part045.js`), mirroring the same grant path used by a Verification Store purchase.

### Feature Comparison

| Feature | Resonance | Frequency | Frequency X |
|---|---|---|---|
| New words per week | 5 | 10 | 20 |
| All 5 player modes | ✓ | ✓ | ✓ |
| AI pronunciation scoring | ✓ | ✓ | ✓ |
| All health categories | ✓ | ✓ | ✓ |
| Sound Bath Mode | ✓ | ✓ | ✓ |
| AI persona feedback | ✓ | ✓ | ✓ |
| Word Atelier (10/mo) | ✓ | ✓ | ✓ |
| Chat + community | ✓ | ✓ | ✓ |
| Voice Resonance Score | ✗ | ✓ | ✓ |
| Sentence Alchemy | ✗ | ✓ | ✓ |
| Premium certificates | ✗ | ✓ | ✓ |
| Unlimited Word Atelier | ✗ | ✓ | ✓ |
| Custom words (2/mo) | ✗ | ✓ | ✓ |
| Home customization | ✗ | ✓ | ✓ |
| ElevenLabs premium voice | ✗ | ✗ | ✓ |
| Custom words (5/mo) | ✗ | ✗ | ✓ |
| Word Drop 48h early | ✗ | ✗ | ✓ |
| Frequency X community | ✗ | ✗ | ✓ |
| Free Blue verification badge | ✗ | ✗ | ✓ |

### Payment
- **Gateway:** Razorpay
- **Key location:** `index.html` — search `rzp_live_REPLACE_WITH_YOUR_KEY`
- **Server:** `worker.js` (Cloudflare Worker) — generates `order_id` for Razorpay
- **Post-payment:** `chkHandleSuccess()` — writes tier + subscription fields to Firestore

---

## 9. Deployment — Web

**Host:** Cloudflare Pages
**Domain:** nowssb.com (GoDaddy → Cloudflare nameservers: athena.ns + steven.ns)
**GitHub repo:** Ribonswebsites/Nowssb-App (main branch)
**Deploy:** Push to GitHub → Cloudflare Pages auto-deploys

Files deployed:
- `index.html` — main app
- `admin.html` — admin panel (accessed at `/admin.html`)
- `worker.js` — deployed separately as a Cloudflare Worker

---

## 10. Web Performance — Making It Fast

### Why the App Feels Slow Right Now

The app runs as a single ~22,500-line HTML file. Everything loads at once before anything shows. This is the #1 performance problem.

Other contributing factors:
- Firebase Spark (free) plan has slower cold starts than paid (Blaze) plan
- No user traffic yet = no CDN edge cache warming
- Google Sign-in on web uses a browser popup/redirect — inherently slower than native

This is normal at pre-launch stage. Ship first, then tune based on real data.

### Why Google Sign-In Looks Different on Android

On the web, Firebase Auth uses `signInWithPopup` / `signInWithRedirect` which opens a browser popup. Apps like Manus use Android's **Credential Manager API** — it talks directly to Google Play Services on the device, no browser, no network round-trip. That's why it's instant and shows a clean bottom sheet. **You cannot get the native UI in a web browser — it's an Android OS feature.**

Fix: Convert to Capacitor APK (see Section 11) and use the native Google Auth plugin. Login will automatically look and work like Manus.

For the **web version**, the best improvement is **Google One Tap**:
```html
<script src="https://accounts.google.com/gsi/client" async></script>
```

### Quick Web Performance Wins

**1. Lazy load all non-critical images**
```html
<img loading="lazy" src="..." alt="">
```

**2. Cloudinary image sizing — always use transformation parameters**
```
/w_400,q_auto,f_auto/   ← mobile images
/w_800,q_auto,f_auto/   ← desktop/tablet
/w_1200,q_auto,f_auto/  ← full-width hero
```
`f_auto` serves WebP. `q_auto` picks best quality/size balance.

**3. Animation intervals gated to screen** — already done (hero bg, tagline intervals only run when home is active)

### Vite Build Before Capacitor

Before the Capacitor build, run through Vite to bundle and optimize:
```
Current HTML → Performance optimized → Vite build → Capacitor wrap → Play Store
```
This is different from "splitting into multiple files" for the web. The built output is still served as a single optimized bundle. The source stays in one file during development.

---

## 11. Deployment — Android APK via Capacitor

The main app will be converted to a native Android APK using **Capacitor** — wraps the web app in a native Android WebView shell. No code rewriting needed.

### Step-by-Step Process

**Step 1 — Initialize Capacitor**
```bash
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init NowssB com.nowssb.app --web-dir dist
npx cap add android
```

**Step 2 — Configure capacitor.config.json**
```json
{
  "appId": "com.nowssb.app",
  "appName": "NowssB",
  "webDir": "dist",
  "android": {
    "minSdkVersion": 22
  }
}
```

**Step 3 — Build**
```bash
npm run build          # Vite build → dist/
npx cap sync           # copies dist/ into Android project
npx cap open android   # opens Android Studio
```
In Android Studio: Build → Generate Signed APK/AAB → upload to Play Store.

**Step 4 — Play Store**
- Create app listing in Google Play Console
- Upload AAB (Android App Bundle)
- Category: Health & Fitness

**Important Capacitor notes:**
- Firebase works as-is (uses HTTP, not native SDK)
- Replace `signInWithPopup` with `@codetrix-studio/capacitor-google-auth` for native Google Auth (bottom sheet, instant — see Section 13)
- Microphone permission: add to `AndroidManifest.xml`
- Razorpay JS checkout is unreliable inside WebViews — needs Razorpay Android SDK (see Section 13)

---

## 12. Admin APK & Push Notifications

The admin panel (`admin.html`) will also become a **separate Capacitor APK** on Sanjay's phone. It receives **push notifications** from Firebase Cloud Messaging (FCM) whenever something happens in the main app.

### Architecture

```
User action (purchase, word request, new signup)
    ↓
Firestore document updated
    ↓
Firebase Cloud Messaging (FCM) triggered
    ↓
Admin's phone receives push notification
    ↓
Tap notification → Admin APK opens to relevant section
```

### How the Admin APK Differs from Main App

| | Main App | Admin App |
|---|---|---|
| Who uses it | All users | Sanjay only |
| Play Store | Public listing | NOT on public Play Store |
| Distribution | Play Store download | Sideload directly on Sanjay's phone |
| Notifications | User-facing (practice reminders) | Admin-facing (new orders, submissions) |
| Entry point | `index.html` | `admin.html` |

### Distribution: Sideloading (Recommended for Admin)

No Play Store needed for admin app:
1. Build admin APK in Android Studio
2. Copy APK to Sanjay's phone
3. Enable "Install from unknown sources" on the phone
4. Install directly

OR use **Play Store Internal Testing track** — private Play Store listing only Sanjay can see.

### Setting Up FCM Notifications

**Step 1 — Add Capacitor Firebase Messaging plugin:**
```bash
npm install @capacitor-firebase/messaging
npx cap sync
```

**Step 2 — Add `google-services.json`** (download from Firebase Console → Project Settings → Android app) to `android/app/`

**Step 3 — Notification triggers** (events that send admin notifications):

| Event | Notification text |
|---|---|
| New user registered | "New user: [name] just joined" |
| Subscription purchased | "New subscription: [tier] — ₹[amount]" |
| Custom word request submitted | "Word request from [user]: [word]" |

**Step 4 — Register FCM token** in admin app on first launch, save to Firestore `admin/tokens`.

**Step 5 — Send notification** from Cloudflare Worker using FCM HTTP v1 API:
```js
await fetch('https://fcm.googleapis.com/v1/projects/nowssb-34f1b/messages:send', {
  method: 'POST',
  headers: { Authorization: 'Bearer ' + accessToken },
  body: JSON.stringify({
    message: {
      token: adminFcmToken,
      notification: { title: 'New Subscription', body: 'Frequency — ₹699' }
    }
  })
});
```

### Both Web + APK Coexist

The admin panel works as both:
- **Web:** `nowssb.com/admin.html` — full functionality in any browser
- **APK:** Native Android app on Sanjay's phone — same functionality + push notifications

Both read and write to the same Firestore.

---

## 13. Known Issues & Warnings

### 1. Firebase Dynamic Links — Shutting Down
**Impact:** Email link sign-in for mobile will break.
**Status:** Firebase Dynamic Links is deprecated and shutting down. If email link authentication is used for mobile sign-in, it will stop working.
**Fix:** Remove email link auth flow, or migrate to Firebase Hosting-based redirect links. For the APK, native deep links via Capacitor (`@capacitor/app`) can replace this.

### 2. Razorpay JS Checkout Unreliable in WebViews
**Impact:** Payments may silently fail inside the Capacitor APK.
**Status:** Razorpay's JavaScript checkout (`https://checkout.razorpay.com/v1/checkout.js`) is not designed for Android WebViews — it opens a popup that gets blocked or silently fails.
**Fix before APK build:** Integrate the **Razorpay Android SDK** via a Capacitor plugin or use Razorpay's Cordova/Capacitor plugin. The web version (browser) is fine.

### 3. Admin Password in Plain Text
**Impact:** Anyone who views `admin.html` source can see the password.
**Status:** `admin.html` line 334: `var CEO_PW = 'sanjay_nowssb_2026';` — plain text.
**Fix before APK/public deployment:** Replace with Firebase Admin Auth. Create a dedicated Firebase Auth user with admin role. The password is never in source code.

### 4. `signInWithPopup` Must Be Replaced Before Capacitor Build
**Impact:** Google Sign-in will not work in the Capacitor APK using the web flow.
**Status:** The current Google sign-in uses `signInWithPopup` / `signInWithRedirect` — these require a real browser and don't work inside Capacitor's WebView.
**Fix before APK build:**
```bash
npm install @codetrix-studio/capacitor-google-auth
```
Replace the `signInWithPopup` call with the Capacitor Google Auth plugin. The web build continues using the existing flow.

### 5. Groq API Key is Placeholder
**Impact:** All AI features (pronunciation scoring, persona feedback, sentence generation) return errors.
**Status:** `index.html` — search `PASTE_YOUR_GROQ_KEY_HERE` — placeholder, not wired.
**Fix:** Replace with real Groq API key. Free tier: 2,000 requests/day. Rotate across multiple Groq accounts (6,000–8,000 free checks/day) for early stage.

### 6. Razorpay Live Key is Placeholder
**Impact:** All payments fail.
**Status:** `index.html` — search `rzp_live_REPLACE_WITH_YOUR_KEY` — placeholder.
**Fix:** Replace with real Razorpay live key. Also requires `worker.js` Cloudflare Worker to generate `order_id` server-side.

### 7. `chkHandleSuccess()` Not Defined
**Impact:** After successful Razorpay payment, nothing happens — no tier granted, no Firestore write.
**Status:** The function is called in the payment flow but not implemented.
**Fix:** Implement `chkHandleSuccess()` to: write tier + subscription fields to Firestore, update `window._userDataCache`, hide promo bars, show success screen.

---

## 14. What's Built vs Missing

### Fully Working
- Firebase Auth (Google, Email, Phone OTP)
- Word Player (Listen, Speak, Library modes) with Groq Whisper hooks
- Health Journey (16+ categories per gender)
- Streak tracking (Firestore-connected)
- Settings UI (all toggles, preferences)
- Subscription panel UI (3 tiers, billing toggle)
- People/Social screen UI (Instagram-style)
- Fashion home with 4 themes (Default, Black, Neo, Glass Black)
- Admin panel (word studio + user management + Instagram link)
- Blocked user enforcement on login
- Theme system with localStorage persistence

### Partially Built (UI exists, logic incomplete)

| Feature | What's There | What's Missing |
|---|---|---|
| Razorpay payments | Checkout UI | Real key + Worker `order_id` + `chkHandleSuccess()` |
| Groq AI | All function hooks | Real API key |
| Word Store | Product listings, cart | Actual payment processing |
| Chat | UI panel, message input | Firestore real-time listener |
| People Search | 8 hardcoded profiles | Real Firestore user query |
| Community Rating | Submit button | Star UI + Firestore write |
| Subscription gates | Tier UI only | Actual `GATE.check()` enforcement |

### Not Built Yet
- Sound Bath Mode (Sleep / Focus / Healing)
- Healing Body Map (SVG organ visualization)
- Voice Resonance Score (Web Audio API waveform comparison)
- AI Daily Word Prescription on home screen (Groq)
- ElevenLabs audio per word (using Web Speech API currently)
- Firebase Cloud Messaging (no push notifications yet)
- Word Mastery Certificate generation logic
- `chkHandleSuccess()` post-payment Firestore write
- Sentence Alchemy auto-play after session (Groq)
- NowssB Score system (Clarity × Dedication × Resonance composite)
- Custom word request flow (user side)
- Client admin panel (`nowssb.com/admin/client`) — currently one combined admin

---

## 15. Development Roadmap

### Phase 1 — Make It Sellable (Immediate)
1. Wire Razorpay real key + Worker `order_id` + implement `chkHandleSuccess()`
2. Add `GATE.check()` subscription enforcement on key features (Speak mode, AI feedback, Sound Bath)
3. Add `trialStartDate` / `trialEndDate` to `saveUser()` Firestore write
4. Fix Chat — wire Firestore real-time listener for messages
5. Wire Groq API key — test AI pronunciation scoring end-to-end
6. Fix People Search — real Firestore query on public users
7. Replace all placeholder words when client provides real words

### Phase 2 — Premium Features
8. AI Daily Word Prescription on home screen (Groq)
9. Sentence Alchemy auto-play at session end (Groq + player word highlight)
10. ElevenLabs voice per word (replace Web Speech API)
11. Word Mastery Certificates (HTML canvas generation)
12. Voice Resonance Score (Web Audio API waveform)
13. NowssB Score system (Clarity / Dedication / Resonance composite)
14. Community rating 1-5 star UI + Firestore write

### Phase 3 — Premium AI & Social
15. Sound Bath Mode (Sleep / Focus / Healing)
16. Healing Body Map (SVG organ visualization)
17. AI Conversation Mode per word (Groq chat)
18. Cinematic onboarding → Groq AI conversation (replace form)
19. Chat notifications (unread count badge)
20. Custom word request flow (user side: search, pay ₹200, waiting screen)

### Phase 4 — App Build
21. Vite build pipeline setup
22. Capacitor project setup for main app
23. Replace `signInWithPopup` with `@codetrix-studio/capacitor-google-auth`
24. Add Razorpay Android SDK (replaces JS checkout in WebView)
25. Android build → Play Store submission
26. Admin Capacitor project setup + FCM integration
27. Sideload admin APK on Sanjay's phone

### Phase 5 — Growth
28. Firebase Cloud Messaging for user notifications (routine reminders)
29. Shareable Word Mastery Certificates (canvas PNG → Instagram)
30. Word Drop scarcity mechanic (limited monthly releases + waitlist)
31. Referral system (Firestore referral codes)
32. Leaderboard on home screen
33. 50-100 background videos from Ribon → Cloudflare R2
34. ElevenLabs client voice clone setup (client records 2-3 min sample once)
35. Clean up all old Cloudinary account (`dkzxw33ln`) URLs

---

## 16. Passwords & Keys

| Item | Value | Location |
|---|---|---|
| Admin panel password | `sanjay_nowssb_2026` | `admin.html` line 334 |
| Firebase project | `nowssb-34f1b` | Already wired in both `index.html` and `admin.html` |
| Groq API key | **NEEDS TO BE ADDED** | `index.html` — search `PASTE_YOUR_GROQ_KEY_HERE` |
| Razorpay live key | **NEEDS TO BE ADDED** | `index.html` — search `rzp_live_REPLACE_WITH_YOUR_KEY` |
| ElevenLabs API key | **NEEDS TO BE ADDED** | `index.html` — search for ElevenLabs config |

**Before APK release:** Admin password must be replaced with Firebase Admin Auth. The password must never be in source code in a distributed APK.

---

*Version 6.0 — May 2026*
*Developer: Ribon (ribonswebsites)*
*CEO: Sanjay Kumar Gadge*
