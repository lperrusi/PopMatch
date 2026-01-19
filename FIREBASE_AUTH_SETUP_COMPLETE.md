# Complete Firebase Authentication Setup Guide

## 🎯 What You're Setting Up

1. ✅ **Email/Password Authentication** (for email verification)
2. ✅ **Google Sign-In**
3. ✅ **Apple Sign-In**

## Step-by-Step Instructions

### Step 1: Add Your iOS App to Firebase

1. **On the Firebase Console page you're on**, click the **"+ Add app"** button (top right, next to the project name)

2. **Click the iOS icon** (🍎)

3. **Fill in the iOS app registration form**:
   - **iOS bundle ID**: `com.example.popmatch`
     - To verify: Check your Xcode project → Build Settings → Product Bundle Identifier
   - **App nickname** (optional): "PopMatch iOS"
   - **App Store ID** (optional): Leave blank for now
   
4. **Click "Register app"**

5. **Download `GoogleService-Info.plist`**:
   - You'll see a download button
   - Click to download the file

6. **Add the file to your project**:
   - Open Finder
   - Navigate to: `/Users/lucasperrusi/Projects/PopMatch/ios/Runner/`
   - Drag and drop `GoogleService-Info.plist` into that folder
   - **OR** use terminal:
     ```bash
     # Move the downloaded file to the correct location
     mv ~/Downloads/GoogleService-Info.plist /Users/lucasperrusi/Projects/PopMatch/ios/Runner/
     ```

7. **Click "Next"** in Firebase Console (you can skip the remaining steps for now)

### Step 2: Enable Authentication Methods

1. **In Firebase Console**, click **"Build"** in the left sidebar (under Product categories)

2. **Click "Authentication"**

3. **Click "Get started"** (if this is your first time)

4. **Go to the "Sign-in method" tab**

#### Enable Email/Password:

1. **Click on "Email/Password"**
2. **Toggle "Enable" to ON** (the first toggle at the top)
3. **Click "Save"**

✅ Email verification is now enabled! Firebase will automatically send verification emails.

#### Enable Google Sign-In:

1. **Click on "Google"**
2. **Toggle "Enable" to ON**
3. **Project support email**: Select your email (or the project default)
4. **Click "Save"**

✅ Google Sign-In is now enabled!

**Note**: For production, you'll need to configure OAuth consent screen in Google Cloud Console, but for testing, this is enough.

#### Enable Apple Sign-In:

1. **Click on "Apple"**
2. **Toggle "Enable" to ON**
3. **OAuth code flow configuration**:
   - **Services ID**: Leave blank for now (needed for production)
   - **Apple team ID**: Leave blank for now (needed for production)
   - For development/testing, you can enable it without these
4. **Click "Save"**

✅ Apple Sign-In is now enabled!

**Note**: For full Apple Sign-In in production, you'll need to:
- Configure Services ID in Apple Developer Console
- Add your Apple Team ID
- But for basic testing, enabling it here is enough

### Step 3: Enable Firebase in Your Code

1. **Open** `lib/services/firebase_config.dart`

2. **Change line 6** from:
   ```dart
   static const bool _useFirebase = false;
   ```
   To:
   ```dart
   static const bool _useFirebase = true;
   ```

### Step 4: Rebuild Your App

```bash
cd /Users/lucasperrusi/Projects/PopMatch
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d "iPhone 17 Pro" --debug
```

## ✅ What's Now Enabled

After completing these steps:

1. **Email/Password Authentication** ✅
   - Users can sign up with email/password
   - Verification emails are sent automatically
   - Users can verify their email

2. **Google Sign-In** ✅
   - Users can sign in with Google
   - Works on both iOS and Android

3. **Apple Sign-In** ✅
   - Users can sign in with Apple
   - Works on iOS (and web if configured)

## 🧪 Testing

### Test Email Verification:
1. Sign up with a new email
2. Check your email inbox (and spam folder)
3. You should receive a verification email from Firebase
4. Click the verification link
5. Sign in - should work!

### Test Google Sign-In:
1. Tap "Sign in with Google" button
2. Select your Google account
3. Should sign in successfully

### Test Apple Sign-In:
1. Tap "Sign in with Apple" button
2. Use Face ID/Touch ID or Apple ID password
3. Should sign in successfully

## 📋 Quick Checklist

- [ ] iOS app added to Firebase
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios/Runner/`
- [ ] Authentication → Email/Password → **Enabled**
- [ ] Authentication → Google → **Enabled**
- [ ] Authentication → Apple → **Enabled**
- [ ] `_useFirebase = true` in `firebase_config.dart`
- [ ] App rebuilt with `flutter clean && flutter pub get && cd ios && pod install`

## 🔧 Additional Configuration (Optional)

### Customize Email Templates:
1. Firebase Console → **Authentication** → **Templates**
2. Click **"Email address verification"**
3. Customize the email subject and body
4. Click **"Save"**

### Google Sign-In OAuth (For Production):
- Configure OAuth consent screen in [Google Cloud Console](https://console.cloud.google.com/)
- Add authorized domains
- Configure OAuth client IDs

### Apple Sign-In (For Production):
- Configure Services ID in [Apple Developer Console](https://developer.apple.com/)
- Add your Apple Team ID
- Configure redirect URLs

---

**You're all set!** Once you complete these steps and rebuild the app, all three authentication methods will work, and email verification will send real emails.
