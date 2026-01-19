# Onboarding Debug Guide

## What to Look For in Debug Console

When testing the onboarding flow, watch for these debug messages:

### 1. **During Onboarding Completion:**
```
🎯 Completing onboarding for user: [email]
📝 Updating preferences: {selectedGenres: [...], selectedPlatforms: [...], onboardingCompleted: true}
✅ Updated user preferences. onboardingCompleted: true
✅ Saved user data to SharedPreferences
✅ User data saved successfully. Email: [email], onboardingCompleted: true
✅ Onboarding completion verified. onboardingCompleted: true
📋 Full preferences: {...}
```

### 2. **During Sign-In (Second Login):**
```
✅ Loaded existing user data for [email]
📋 User preferences: {...}
🎯 onboardingCompleted: true/false
```

**If you see:**
- `✅ Loaded existing user data` with `onboardingCompleted: true` → Should skip onboarding ✅
- `⚠️ Creating new user` → User data not found, will show onboarding ❌
- `⚠️ Found user data but email/ID mismatch` → Matching issue ❌

### 3. **During Login Check:**
```
🔍 Login check - onboardingCompleted: true/false, preferences: {...}
✅ Onboarding completed, navigating to HomeScreen
⚠️ Onboarding not completed, navigating to OnboardingScreen
```

## Expected Flow

### First Login:
1. Sign in → Should see: `⚠️ Creating new user` (first time)
2. Complete onboarding → Should see all the ✅ messages above
3. Navigate to Home

### Second Login:
1. Sign in → Should see: `✅ Loaded existing user data` with `onboardingCompleted: true`
2. Should see: `✅ Onboarding completed, navigating to HomeScreen`
3. Should **NOT** see onboarding screen

## Troubleshooting

### If onboarding still shows on second login:

1. **Check if data is saved:**
   - Look for `✅ User data saved successfully` after completing onboarding
   - If missing, data wasn't saved

2. **Check if data is loaded:**
   - Look for `✅ Loaded existing user data` during sign-in
   - If you see `⚠️ Creating new user`, data wasn't found

3. **Check email matching:**
   - Look for `⚠️ Found user data but email/ID mismatch`
   - Emails must match exactly (case-insensitive)

4. **Check preferences:**
   - Look for `🎯 onboardingCompleted: true` in the loaded user data
   - If it shows `false`, the flag wasn't saved correctly

## Common Issues

### Issue 1: User data not saved
**Symptom:** No `✅ User data saved successfully` message
**Fix:** Check if `authProvider.userData` is not null before calling `updatePreferences`

### Issue 2: User data not loaded
**Symptom:** See `⚠️ Creating new user` on second login
**Fix:** Check if email matches exactly (case-insensitive)

### Issue 3: Preferences not preserved
**Symptom:** User data loaded but `onboardingCompleted: false`
**Fix:** Check if `updatePreferences` is merging correctly (should use spread operator)

---

**Next Steps:** Run the app and check the console output to identify where the issue is occurring.
