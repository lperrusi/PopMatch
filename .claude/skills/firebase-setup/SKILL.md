---
name: firebase-setup
description: Use when the user asks how to set up Firebase for the first time, configure Firebase Auth (email/password, Google, Apple sign-in), enable Firestore, or deploy the Cloud Functions. Trigger phrases: "set up Firebase", "Firebase project", "Google sign-in", "Apple sign-in", "enable email verification", "Firebase Auth", "Firestore", "deploy functions".
allowed-tools: [Bash, Read]
---

## Prerequisites

- Node.js v18+
- Firebase CLI: `npm install -g firebase-tools`
- Flutter SDK 3.2.3+

---

## 1. Create Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com/)
2. Create a project named **PopMatch** (project ID: `popmatch-48560`)
3. Download config files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

---

## 2. Enable Authentication

In Firebase Console → Authentication → Sign-in method:

| Provider | Steps |
|---|---|
| **Email/Password** | Enable; enable "Email link" if using magic link |
| **Google** | Enable; download updated `GoogleService-Info.plist` |
| **Apple** | Enable; requires Apple Developer account + Services ID + key |

---

## 3. Enable Firestore

Firebase Console → Firestore Database → Create database → Start in **test mode** (tighten rules before production).

---

## 4. Configure iOS for Google & Apple Sign-In

```bash
cd ios && pod install && cd ..
```

For **Google Sign-In**, add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` to the iOS URL schemes in `ios/Runner/Info.plist`.

For **Apple Sign-In**, ensure the `Sign In with Apple` capability is enabled in Xcode → Signing & Capabilities.

---

## 5. Deploy Cloud Functions (email verification)

> **Requires Firebase Blaze (pay-as-you-go) plan.** The Spark (free) plan does not allow deploying Cloud Functions. Blaze has a generous free tier for typical usage.
>
> **API note:** `functions/index.js` uses the `params` API (not the deprecated `functions.config()` which is removed March 2026). Do not revert to `functions.config()`.

```bash
# Log in
firebase login

# Install function dependencies
cd functions && npm install && cd ..

# Store email credentials in Cloud Secret Manager (params API)
# GMAIL_USER, SMTP_HOST, SMTP_USER, SMTP_PORT are params — set in functions/.env.popmatch-48560
# Only the passwords are secrets:
firebase functions:secrets:set GMAIL_APP_PASSWORD  # 16-char Gmail App Password (not account password)
firebase functions:secrets:set SMTP_PASSWORD       # only if using custom SMTP instead of Gmail

# Deploy
firebase deploy --only functions
```

The deployed function is `sendVerificationCode`. It sends a 6-digit HTML email matching the app theme; codes expire after 15 minutes.

> Until deployed, the code is logged to the Flutter console — you can still test the full flow manually.

---

## 5b. Social features — deploy functions + Firestore indexes

Social (`SocialProvider` → `SocialService` → Cloud Functions in `functions/index.js`) is
Firebase-backed and needs the same Blaze plan + deploy as email verification, **plus**
composite indexes for the friends-feed query.

```bash
# Deploy the social callable functions (sendFollowRequest, respondToFollowRequest,
# unfollowUser, searchUsers, recordSocialActivity, getFriendsFeed, getSuggestedUsers)
firebase deploy --only functions

# Deploy Firestore indexes (getFriendsFeed runs a compound query that needs one)
firebase deploy --only firestore:indexes
```

`getFriendsFeed` queries `socialActivities` by followed users ordered by time — this requires
a composite index. The function already error-handles the missing-index case
(`functions/index.js:503-508`); when you hit it, the Firebase Console logs a link that
auto-creates the exact index, or add it to `firestore.indexes.json` and redeploy.

Feature flags `SOCIAL_UI_ENABLED` / `FRIENDS_FEED_ENABLED` (`lib/services/feature_flags.dart`,
default true) gate the social UI; set them false at build time to ship without social.

## 6. Verify setup

```bash
flutter pub get
flutter run
```

Sign up → check email for verification code. If no email:
```bash
firebase functions:log          # check function execution
firebase functions:secrets:access GMAIL_APP_PASSWORD   # verify secret is set
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Firebase init errors | `flutter clean && flutter pub get` |
| `sendVerificationCode` not found | `firebase deploy --only functions` |
| Gmail app password rejected | Ensure 2FA is on; use App Password not account password |
| Google sign-in fails on iOS | Verify `REVERSED_CLIENT_ID` is in `Info.plist` URL schemes |
| Apple sign-in fails | Check Apple Developer Services ID and associated domains |
| Friends feed empty / index error in logs | Deploy the composite index: `firebase deploy --only firestore:indexes`, or use the auto-create link in the Console error |
