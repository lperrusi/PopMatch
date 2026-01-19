# Firebase Email Verification Setup Guide

## Current Status

**Firebase is currently DISABLED** in your app (`_useFirebase = false` in `firebase_config.dart`).

This means:
- ❌ Email verification emails are NOT being sent
- ✅ App works in development mode (local storage)
- ⚠️ To enable email verification, you need to configure Firebase

## Steps to Enable Email Verification

### Step 1: Create/Configure Firebase Project

1. **Go to Firebase Console**: [https://console.firebase.google.com/](https://console.firebase.google.com/)

2. **Create a new project** (or use existing):
   - Click "Add project"
   - Enter project name: "PopMatch" (or your preferred name)
   - Follow the setup wizard

3. **Add iOS App to Firebase**:
   - Click the iOS icon in Firebase Console
   - Enter iOS bundle ID: `com.example.popmatch` (check `ios/Runner.xcodeproj` to confirm)
   - Download `GoogleService-Info.plist`
   - Place it in: `ios/Runner/GoogleService-Info.plist`

4. **Add Android App to Firebase** (if needed):
   - Click the Android icon in Firebase Console
   - Enter Android package name: `com.example.popmatch` (check `android/app/build.gradle` to confirm)
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`

### Step 2: Enable Authentication

1. **In Firebase Console**, go to **Authentication** → **Sign-in method**

2. **Enable Email/Password**:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

3. **Configure Email Templates** (for verification emails):
   - Go to **Authentication** → **Templates**
   - Click on "Email address verification"
   - Customize the email template if desired
   - The default template works fine

### Step 3: Enable Email Verification

Firebase automatically sends verification emails when:
- A user signs up with email/password
- `sendEmailVerification()` is called

**No additional configuration needed** - it works automatically once Authentication is enabled!

### Step 4: Enable Firebase in Your App

1. **Update `lib/services/firebase_config.dart`**:
   ```dart
   static const bool _useFirebase = true; // Change from false to true
   ```

2. **Verify configuration files are in place**:
   - ✅ `ios/Runner/GoogleService-Info.plist` exists
   - ✅ `android/app/google-services.json` exists (if using Android)

3. **Rebuild the app**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

## Testing Email Verification

After enabling Firebase:

1. **Sign up with a new email** → Verification email should be sent automatically
2. **Check your email inbox** (and spam folder)
3. **Click the verification link** in the email
4. **Sign in** → Should work normally

## Troubleshooting

### Email Not Received?

1. **Check spam folder**
2. **Verify Firebase Authentication is enabled** in Firebase Console
3. **Check Firebase Console → Authentication → Users** - see if user was created
4. **Check Firebase Console → Usage and billing** - ensure you haven't hit email limits
5. **Verify email template** in Firebase Console → Authentication → Templates

### Firebase Not Initializing?

1. **Check configuration files exist**:
   - `ios/Runner/GoogleService-Info.plist`
   - `android/app/google-services.json`

2. **Verify bundle ID matches**:
   - iOS: Check `ios/Runner.xcodeproj` for bundle ID
   - Android: Check `android/app/build.gradle` for package name
   - Must match what you entered in Firebase Console

3. **Rebuild after adding config files**:
   ```bash
   flutter clean
   cd ios && pod install && cd ..
   flutter run
   ```

### Development vs Production

**Current Setup (Development Mode)**:
- Firebase disabled
- Uses local storage (SharedPreferences)
- Email verification doesn't send (by design)
- Good for testing without Firebase setup

**Production Setup**:
- Enable Firebase (`_useFirebase = true`)
- Add Firebase config files
- Email verification will work
- Requires Firebase project setup

## Quick Enable Checklist

- [ ] Firebase project created
- [ ] iOS app added to Firebase (if using iOS)
- [ ] Android app added to Firebase (if using Android)
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios/Runner/`
- [ ] `google-services.json` downloaded and placed in `android/app/` (if using Android)
- [ ] Authentication → Email/Password enabled in Firebase Console
- [ ] `_useFirebase = true` in `lib/services/firebase_config.dart`
- [ ] Rebuild app: `flutter clean && flutter pub get && cd ios && pod install && cd ..`

---

**Note**: Email verification requires a Firebase project. In development mode (Firebase disabled), the app simulates email sending but doesn't actually send emails. This is intentional for development without Firebase setup.
