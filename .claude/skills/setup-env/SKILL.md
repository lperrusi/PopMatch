---
name: setup-env
description: Use when the user asks how to set up the development environment, configure API keys, set up .env, or pass keys at build time. Trigger phrases: "set up env", "configure API keys", "TMDB key", ".env setup", "dart-define".
allowed-tools: [Bash, Read, Write]
---

## Steps

1. Copy the template:
   ```bash
   cp .env.example .env
   ```

2. Fill in `.env`:
   - `TMDB_API_KEY` — required (get from themoviedb.org)
   - `OMDB_API_KEY` — optional (supplemental ratings)
   - `FIREBASE_PROJECT_ID` — optional (defaults to `popmatch-48560`)
   - Feature flags: `SOCIAL_UI_ENABLED`, `FRIENDS_FEED_ENABLED`, `TMDB_USE_SAMPLE_FALLBACK`

## Key consumption

- **Build time** (preferred):
  ```bash
  flutter run --dart-define-from-file=.env
  # or per-key:
  flutter run --dart-define=OMDB_API_KEY=your_key
  ```
- **Runtime fallback**: `OMDbService.instance.loadApiKey()` reads from SharedPreferences; `FirebaseConfig.initialize()` uses `FIREBASE_PROJECT_ID`.

## Firebase Cloud Functions (email verification)

The `sendVerificationCode` function (`functions/index.js`) must be deployed separately and **requires Firebase Blaze plan**. Until deployed, the 6-digit code is logged to the Flutter console for manual testing.

See the `/firebase-setup` skill for full deployment steps. Quick reference:
```bash
cd functions && npm install && cd ..
# Set secrets via params API (not deprecated functions.config()):
# GMAIL_USER and SMTP_* are params — set them in functions/.env.popmatch-48560
# Only these two need secrets:
firebase functions:secrets:set GMAIL_APP_PASSWORD  # 16-char Gmail App Password
firebase functions:secrets:set SMTP_PASSWORD       # if using custom SMTP instead
firebase deploy --only functions
firebase functions:log   # if emails aren't arriving
```
