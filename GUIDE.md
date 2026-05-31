# NowssB — Complete Product & Developer Guide
**Version 4.0 — Updated May 2026**
CEO: Sanjay Kumar Gadge · Developer: Ribon

---

## Table of Contents

1. [What is NowssB](#1-what-is-nowssb)
2. [Current File Structure](#2-current-file-structure)
3. [Firebase Project](#3-firebase-project)
4. [The App — index.html](#4-the-app--indexhtml)
5. [The Admin Panel — admin.html](#5-the-admin-panel--adminhtml)
6. [Theme System (Fashion Home)](#6-theme-system-fashion-home)
7. [Subscription Tiers](#7-subscription-tiers)
8. [Deployment — Web](#8-deployment--web)
9. [Deployment — Android APK via Capacitor](#9-deployment--android-apk-via-capacitor)
10. [Admin APK & Push Notifications](#10-admin-apk--push-notifications)
11. [What's Built vs Missing](#11-whats-built-vs-missing)
12. [Development Roadmap](#12-development-roadmap)
13. [Passwords & Keys](#13-passwords--keys)

---

## 1. What is NowssB

NowssB (Natural Origin Word Sound Science Biology) is a healing word-practice app. Users learn to pronounce ancient healing words using breath techniques, resonance science, and AI feedback. Each word targets a specific organ or body system.

**Core concept:** Words are not symbols — they are sounds. The correct pronunciation of specific words creates vibrations that heal the body.

**Brand tagline:** *Healing is Fashion.*

**Live URL:** https://nowssb.com

---

## 2. Current File Structure

```
/Nowssb-App/
├── index.html          ← THE entire main app (~22,500 lines, single-file SPA)
├── admin.html          ← CEO admin panel (password protected)
├── admin-dev.html      ← Developer admin variant
├── worker.js           ← Cloudflare Worker (Razorpay order_id server)
├── assets/             ← Static assets
└── components/         ← Component files
```

**Single-file SPA:** The entire app — all HTML, CSS, JavaScript, all screens — lives in `index.html`. This is intentional during development. Before the Capacitor build, this file will be split into a proper `src/` folder structure.

---

## 3. Firebase Project

| Setting | Value |
|---|---|
| Project ID | `nowssb-34f1b` |
| Auth Domain | `nowssb-34f1b.firebaseapp.com` |
| API Key | `AIzaSyBly5XnqNnpVom11thjlvT5q_BfxNJBfgQ` |
| App ID | `1:1024709686012:web:20d425060043141a0b5d79` |
| Firestore DB | Default (us-central1) |
| Auth Methods | Google, Email/Password, Phone OTP |

**Firestore Collections:**

| Collection | Purpose |
|---|---|
| `users/{uid}` | User profiles, tier, subscription, blocked status |
| `words/{wordId}` | Master word library (to be populated) |
| `submissions/{id}` | CEO-submitted word drafts (pending review) |

**Key user document fields:**

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
createdAt            ISO string
```

---

## 4. The App — index.html

### Screens

| Screen ID | What it is |
|---|---|
| `#splash` | Loading / intro animation |
| `#login` | Auth screen (Google, Email, Phone) |
| `#signup2` | Onboarding quiz |
| `#home-nm` | **Normal home** (default landing screen) — neumorphic light |
| `#home` | **Fashion home** — dark glassmorphism with hero images |
| `#home-nm` sub-screens | Practice, Routines, Sound Library, Word Store, etc. |

### Home Screen Logic

- **Default on launch:** `#home-nm` (normal home)
- **If user previously chose Fashion home:** `#home` (Fashion) loads instead
- Preference stored in `localStorage('nwsb_home_mode')`:
  - `'nm'` → normal home (default)
  - `'home'` → Fashion home
- The "Fashion Mode" button on `#home-nm` switches to `#home` and saves the preference
- The sun icon on `#home` switches back to `#home-nm`

### Navigation

```js
goTo('screen-id')        // Navigate to any screen
_doNavigate('home')      // Used by auth — respects nwsb_home_mode preference
```

### Key Global Functions

| Function | Purpose |
|---|---|
| `goTo(dest)` | Navigate to a screen |
| `openSub(id)` | Open a sub-screen panel |
| `setNwsbTheme(theme, explicit)` | Apply Fashion home theme |
| `setBE(style, explicit)` | Legacy alias → calls setNwsbTheme |
| `showFashionHomeIntro()` | Show the Black Edition cinematic intro overlay |
| `_doNavigate(dest)` | Auth-triggered navigation (respects home preference) |

### Key localStorage Keys

| Key | Values | Purpose |
|---|---|---|
| `nwsb_home_mode` | `'nm'` / `'home'` | Which home screen loads on startup |
| `nwsb_theme` | `'default'` / `'black'` / `'neo'` / `'glass-black'` | Fashion home theme |
| `nwsb_intros` | `'always'` / `'once'` | Whether section intro screens always show |
| `nwsb_done` | `'1'` | Onboarding tour completed |

---

## 5. The Admin Panel — admin.html

**URL:** `https://nowssb.com/admin.html`
**Password:** `sanjay_nowssb_2026`

The admin panel is a completely separate HTML file. It has its own Firebase connection and does not share code with the main app.

### What the Admin Can Do

#### Word Studio (existing)
- Record the word pronunciation via microphone
- Fill in all word details (phonetic, organ, benefit, meaning, hold times, category)
- Auto-generates ElevenLabs pronunciation notation and breath guide
- Submit word for developer review → saved to Firestore `submissions` collection
- View submitted words with their review status (Pending / Approved / Needs Edit)

#### Instagram Link (new)
- Editable Instagram handle field
- Tap to open the NowssB Instagram profile directly
- Handle persists in localStorage

#### User Access Control (new — Firebase connected)
- **Search** any user by email address or Firebase UID
- **View** their name, current tier, word count, join date
- **Grant** free subscription at any tier (Resonance / Frequency / Frequency X) — writes to Firestore immediately
- **Revoke** access — strips subscription, returns user to free tier
- **Block** a user — user is immediately signed out on next login attempt and sees a suspension message
- **Unblock** a user — restores access

#### Send Word to User (new — Firebase connected)
- Find any user by email or UID
- Send them any word directly — adds to their `ownedWords` array in Firestore
- Optional gift note saved to `adminGifts` field
- User sees the word in their library on next app open

---

## 6. Theme System (Fashion Home)

The Fashion `#home` screen has 4 visual themes, selectable from **Settings → Black Edition**:

| Theme | Body class | What changes |
|---|---|---|
| **Default** | `nwsb-theme-default` | Glassmorphism — `rgba` header/nav/drawer + `backdrop-filter`. Background images visible. This is the default. |
| **Black** | `nwsb-theme-black` | Everything solid `#000`. Background images hidden. Cinematic intro plays on first selection. |
| **Neo** | `nwsb-theme-neo` | Deep neumorphic `#0d0d0d` with `box-shadow` depth on all surfaces. Background images hidden. |
| **Glass Black** | `nwsb-theme-glass-black` | `rgba(0,0,0,0.6–0.78)` + `blur(32px)` — dark tinted glassmorphism. Background images visible. |

**Key rules:**
- All theme CSS is scoped to `body.fashion-home-active.nwsb-theme-*`
- `body.fashion-home-active` is only present when `#home` is the active screen
- So themes **never affect** `#home-nm` or any other screen
- Theme persists via `localStorage('nwsb_theme')` until explicitly changed
- The Black Edition cinematic intro (`#fashionHomeIntro`) only shows when user explicitly selects Black theme from Settings or taps Fashion Mode — never on page load

**JS:**
```js
setNwsbTheme('default')       // glassmorphism (default)
setNwsbTheme('black', true)   // solid black + shows intro once
setNwsbTheme('neo')           // neumorphism
setNwsbTheme('glass-black')   // dark blur glass
```

---

## 7. Subscription Tiers

### Tier Structure

```
FREE TRIAL — 7 days, full Frequency access, no card required
     ↓
RESONANCE    ₹299/month · ₹2,499/year
FREQUENCY    ₹699/month · ₹5,999/year
FREQUENCY X  ₹1,499/month · ₹11,999/year
```

No permanent free tier. After trial expires, app is locked until a plan is chosen.

### What Each Tier Includes

| Feature | Resonance | Frequency | Frequency X |
|---|---|---|---|
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
| ElevenLabs premium voice | ✗ | ✗ | ✓ |
| Custom words (5/mo) | ✗ | ✗ | ✓ |
| Word Drop 48h early | ✗ | ✗ | ✓ |
| Frequency X community | ✗ | ✗ | ✓ |
| Gold profile badge | ✗ | ✗ | ✓ |

### Payment
- **Gateway:** Razorpay
- **Key location:** `index.html` line ~23060 — replace `rzp_live_REPLACE_WITH_YOUR_KEY`
- **Server:** `worker.js` (Cloudflare Worker) — generates `order_id` for Razorpay
- **Post-payment:** `chkHandleSuccess()` — writes tier + subscription fields to Firestore

---

## 8. Deployment — Web

**Host:** Cloudflare Pages
**Domain:** nowssb.com
**Deploy:** Push to GitHub → Cloudflare Pages auto-deploys

Files deployed:
- `index.html` — main app
- `admin.html` — admin panel (accessed at `/admin.html`)
- `worker.js` — deployed separately as a Cloudflare Worker

---

## 9. Deployment — Android APK via Capacitor

The main app will be converted to a native Android APK using **Capacitor** — a tool that wraps the web app in a native Android WebView shell. No code rewriting needed.

### Step-by-Step Process

**Step 1 — Split index.html into src/ folder**
```
src/
├── index.html          ← shell HTML only
├── css/
│   ├── base.css
│   ├── screens.css
│   ├── components.css
│   └── themes.css
├── js/
│   ├── app.js          ← core init, auth, navigation
│   ├── player.js       ← word practice player
│   ├── social.js       ← people / social screens
│   ├── settings.js     ← settings panel
│   └── ...
└── assets/
```
This reduces the main HTML file from ~22,500 lines to a manageable structure and speeds up Capacitor builds.

**Step 2 — Initialize Capacitor**
```bash
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init NowssB com.nowssb.app --web-dir src
npx cap add android
```

**Step 3 — Configure capacitor.config.json**
```json
{
  "appId": "com.nowssb.app",
  "appName": "NowssB",
  "webDir": "src",
  "android": {
    "minSdkVersion": 22
  }
}
```

**Step 4 — Build**
```bash
npx cap sync
npx cap open android    ← opens Android Studio
```
In Android Studio: Build → Generate Signed APK/AAB → upload to Play Store.

**Step 5 — Play Store**
- Create app listing in Google Play Console
- Upload AAB (Android App Bundle)
- Set category: Health & Fitness
- Target audience: All ages (or 18+)

**Important Capacitor Notes:**
- Firebase works as-is (it uses HTTP, not native SDK)
- Microphone permission: add to `AndroidManifest.xml`
- Camera permission: add if profile photo upload is added
- Deep links: configure for payment return URLs

---

## 10. Admin APK & Push Notifications

The admin panel (`admin.html`) will also become a **separate Capacitor APK** — a private app on Sanjay's phone. It will receive **push notifications** from Firebase Cloud Messaging (FCM) whenever something happens in the main app.

### Architecture

```
User action in main app (purchase, word request, new signup)
    ↓
Firestore document updated
    ↓
Firebase Cloud Messaging (FCM) triggered
    ↓
Admin's phone receives push notification (even when app is closed)
    ↓
Tap notification → Admin APK opens to the relevant section
```

### How the Admin APK is Different from the Main APK

| | Main App | Admin App |
|---|---|---|
| Who uses it | All users | Sanjay only |
| Play Store | Public listing | NOT on public Play Store |
| Distribution | Play Store download | Sideload APK directly on Sanjay's phone |
| Notifications | User-facing (practice reminders) | Admin-facing (new orders, submissions) |
| Entry point | `index.html` | `admin.html` |

### Distribution: Sideloading (Recommended for Admin)

No Play Store needed for the admin app:
1. Build the admin APK in Android Studio
2. Copy APK file to Sanjay's phone
3. Enable "Install from unknown sources" on the phone
4. Install directly

OR use **Play Store Internal Testing track** — creates a private Play Store listing only Sanjay can see and download. Looks more professional.

### Setting Up FCM Notifications in Admin APK

**Step 1 — Add Capacitor Firebase Messaging plugin:**
```bash
npm install @capacitor-firebase/messaging
npx cap sync
```

**Step 2 — Add `google-services.json`** (download from Firebase Console → Project Settings → Android app) to `android/app/`

**Step 3 — Notification triggers** (in main app `index.html` or Cloudflare Worker):

Events that send admin notifications:
| Event | Notification |
|---|---|
| New user registered | "New user: [name] just joined" |
| Subscription purchased | "New subscription: [tier] — ₹[amount]" |
| Custom word request submitted | "Word request from [user]: [word name]" |
| CEO submits word in admin panel | Confirmation to admin |

**Step 4 — Register FCM token** in admin app on first launch, save to Firestore `admin/tokens` doc.

**Step 5 — Send notification** from Cloudflare Worker using FCM HTTP v1 API:
```js
// In worker.js — called when a Firestore trigger fires
await fetch('https://fcm.googleapis.com/v1/projects/nowssb-34f1b/messages:send', {
  method: 'POST',
  headers: { Authorization: 'Bearer ' + accessToken },
  body: JSON.stringify({
    message: {
      token: adminFcmToken,
      notification: { title: 'New Subscription', body: 'Frequency — ₹699' },
      data: { screen: 'users', uid: userId }
    }
  })
});
```

### Both Web + APK Coexist

The admin panel works as both:
- **Web:** `nowssb.com/admin.html` — open in any browser, full functionality
- **APK:** Native Android app on Sanjay's phone — same functionality + push notifications

The web version can't send push notifications to the phone. The APK can. Use whichever is convenient — they both read and write to the same Firestore.

---

## 11. What's Built vs Missing

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
| Razorpay payments | Checkout UI | Real API key + Worker `order_id` + `chkHandleSuccess()` |
| Groq AI | All function hooks | Real API key (`PASTE_YOUR_GROQ_KEY_HERE`) |
| Word Store | Product listings, cart | Actual payment processing |
| Chat | UI panel, message input | Firestore real-time listener |
| People Search | 8 hardcoded profiles | Real Firestore user query |
| Community Rating | Submit button | Star UI + Firestore write |
| Subscription gates | Tier UI only | Actual `GATE.check()` enforcement |

### Not Built Yet
- Sound Bath Mode (Sleep / Focus / Healing)
- Healing Body Map (SVG organ visualization)
- Voice Resonance Score (Web Audio API waveform comparison)
- AI Daily Word Prescription on home screen
- ElevenLabs audio per word (using Web Speech API currently)
- Firebase Cloud Messaging (no push notifications yet)
- Word Mastery Certificates (generation logic)
- `chkHandleSuccess()` post-payment Firestore write
- Sentence Alchemy auto-play after session
- Admin APK with FCM notifications

---

## 12. Development Roadmap

### Phase 1 — Make It Sellable (Next)
1. Wire Razorpay real key + Worker `order_id` + `chkHandleSuccess()`
2. Implement `GATE.check()` subscription enforcement on key features
3. Add `trialStartDate` / `trialEndDate` to `saveUser()` Firestore write
4. Fix Chat — wire Firestore real-time messages
5. Wire Groq API key — test AI pronunciation scoring

### Phase 2 — Premium Features
6. AI Daily Word Prescription on home screen (Groq)
7. Sentence Alchemy auto-play at session end (Groq)
8. ElevenLabs voice per word (replace Web Speech API)
9. Word Mastery Certificates (HTML canvas generation)
10. Voice Resonance Score (Web Audio API waveform)

### Phase 3 — App Build
11. Split `index.html` into `src/` folder
12. Capacitor project setup for main app
13. Android build → Play Store submission
14. Admin Capacitor project setup
15. FCM integration in admin APK
16. Sideload admin APK on Sanjay's phone

### Phase 4 — Growth
17. Firebase Cloud Messaging for user notifications (routine reminders)
18. Healing Body Map (SVG)
19. Sound Bath Mode
20. Shareable Word Mastery Certificates (canvas PNG → Instagram share)
21. Referral system (Firestore referral codes)
22. Leaderboard on home screen

---

## 13. Passwords & Keys

| Item | Value | Location |
|---|---|---|
| Admin panel password | `sanjay_nowssb_2026` | `admin.html` line 334 |
| Groq API key | **NEEDS TO BE ADDED** | `index.html` — search `PASTE_YOUR_GROQ_KEY_HERE` |
| Razorpay live key | **NEEDS TO BE ADDED** | `index.html` — search `rzp_live_REPLACE_WITH_YOUR_KEY` |
| ElevenLabs API key | **NEEDS TO BE ADDED** | `index.html` — search for ElevenLabs config |
| Firebase project | `nowssb-34f1b` | Already wired in both `index.html` and `admin.html` |

**Important:** The admin password is stored in plain text in `admin.html`. For the APK version, this should be replaced with Firebase Admin Auth (a separate Firebase user with admin role) so the password is never in the source code.

---

*Last updated: May 2026*
*Developer contact: Ribon (ribonswebsites)*
