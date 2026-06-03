# Social backend deploy — turn on the social features

The social system (user search, follow requests, friends feed, "Friends Are Watching",
taste-match suggestions, and the For You **Friends** rail) is fully implemented in the app and in
`functions/index.js`, but it is **dormant until the Firebase backend is deployed and the app runs
with Firebase enabled**. With Firebase off (the default dev/local mode) every social call no-ops to
empty — that's why the Friends rail is blank.

Everything below is operational/user-side (needs your Firebase project + CLI). The code, Firestore
indexes (`firestore.indexes.json`), and rules (`firestore.rules`) are already in the repo and
deploy-ready. See also the `firebase-setup` skill.

## Prerequisites
- Firebase CLI: `npm i -g firebase-tools` → `firebase login`
- The project is `popmatch-48560` (see `.env` `FIREBASE_PROJECT_ID`). `firebase use popmatch-48560`.
- `flutterfire configure` has produced `firebase_options.dart` and the platform configs.

## 1. Enable Firebase Auth
In the Firebase console → Authentication → Sign-in method, enable the providers you use
(Email/Password, Google, Apple). The app's `FirebaseConfig.isEnabled` must resolve true (real
`firebase_options.dart` present and not in test mode) so `SocialService` issues real callable calls.

## 2. Deploy Firestore rules + indexes
```
firebase deploy --only firestore:rules,firestore:indexes
```
`firestore.indexes.json` already defines the composite indexes the feed needs
(`socialActivities`: actorUid ASC + createdAt DESC; `followEdges`: followerUid + status). Wait for
indexes to finish building (console shows "Building…") before testing the feed.

## 3. Deploy the Cloud Functions
```
cd functions && npm install && npm run lint && cd ..
firebase deploy --only functions
```
Social callables (region `us-central1`): `sendFollowRequest`, `respondToFollowRequest`,
`unfollowUser`, `searchUsers`, `recordSocialActivity`, `getFriendsFeed`, `getSuggestedUsers`.
(Email verification's `sendVerificationCode` + the Gmail/SMTP secrets are a separate concern — see
the `firebase-setup` skill.)

## 4. (Optional) Seed demo social data for testing
So you can see the social surfaces without a second real account:
1. Enable the seeder: set `DEV_SEED_ENABLED=true` for the functions (e.g. `functions/.env` or
   `firebase functions:secrets`/params), then redeploy functions.
2. In a **debug** build, Profile → **"Seed social data (dev)"** calls the `devSeedSocial` callable,
   which creates two demo friends, accepted follows for you, and sample liked activities.
3. Open For You / Search → the Friends feed + "Friends Are Watching" rail now populate.
4. **Turn it off for production:** set `DEV_SEED_ENABLED=false` (or remove `exports.devSeedSocial`)
   and redeploy. The debug-only button is already hidden in release builds (`kDebugMode`).

## Verify
- Search tab → "People": searching returns users; sending a follow request works.
- Like a few movies → `socialActivities` docs appear in Firestore.
- A followed friend's likes show in the friends feed, the For You Friends rail, and
  `FriendsWatchingScreen`.
- If the feed errors with "needs an index", wait for index builds to finish (step 2).
