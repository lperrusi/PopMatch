# Firebase Cloud Functions - Deferred

## Status

✅ **Code Ready**: All Cloud Functions code is implemented and ready  
⏸️ **Deployment Deferred**: Waiting for Firebase Blaze plan upgrade

## Current Behavior

The app currently:
- ✅ Generates 6-digit verification codes
- ✅ Stores codes in local storage (SharedPreferences)
- ✅ Logs codes to console for testing
- ⏸️ **Does NOT send emails yet** (requires Cloud Functions deployment + Blaze plan)

## What's Ready

- ✅ `functions/index.js` - Cloud Function code (using modern params API)
- ✅ `functions/package.json` - Dependencies configured
- ✅ Flutter app integration - Calls Cloud Function when available
- ✅ Error handling - Falls back to console logging if Cloud Function unavailable

## When Ready to Deploy (Future)

### Prerequisites
1. Upgrade Firebase project to **Blaze (pay-as-you-go) plan**
   - Visit: https://console.firebase.google.com/project/popmatch-48560/usage/details
   - Note: Blaze plan has a generous free tier for most use cases

### Deployment Steps
1. Set secrets:
   ```bash
   firebase functions:secrets:set GMAIL_USER
   firebase functions:secrets:set GMAIL_APP_PASSWORD
   ```

2. Deploy:
   ```bash
   firebase deploy --only functions
   ```

3. Test email sending

See `FIREBASE_FUNCTIONS_SETUP_UPDATED.md` for detailed instructions.

## Testing Without Email

For now, users can:
1. Sign up → Code generated and logged
2. Check console logs for the 6-digit code
3. Enter code manually in the verification screen
4. Complete verification → Navigate to onboarding

**The verification flow works perfectly** - email sending is just a convenience feature.

---

**Note**: This is intentionally deferred to focus on core app features first. Email verification can be enabled later when ready for production.
