# Enable Firebase Email Verification - Step by Step Guide

## 🔍 Current Status

**Firebase is currently DISABLED** in your app. This is why you're not receiving verification emails.

**Location**: `lib/services/firebase_config.dart` line 6:
```dart
static const bool _useFirebase = false; // ← Currently disabled
```

## ✅ Quick Setup (5 Steps)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** (or use existing)
3. Enter project name: **"PopMatch"**
4. Follow the setup wizard (you can skip Google Analytics for now)

### Step 2: Add iOS App to Firebase

1. In Firebase Console, click the **iOS icon** (🍎)
2. **Bundle ID**: Enter `com.example.popmatch`
   - To verify your bundle ID: Check `ios/Runner.xcodeproj` → Build Settings → Product Bundle Identifier
3. **App nickname**: "PopMatch iOS" (optional)
4. **App Store ID**: Leave blank (optional)
5. Click **"Register app"**
6. **Download `GoogleService-Info.plist`**
7. **Place it in**: `ios/Runner/GoogleService-Info.plist`

### Step 3: Enable Email/Password Authentication

1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click **"Get started"** (if first time)
3. Go to **"Sign-in method"** tab
4. Click on **"Email/Password"**
5. Toggle **"Enable"** to **ON**
6. Click **"Save"**

**That's it!** Email verification is now enabled. Firebase will automatically:
- Send verification emails on sign-up
- Handle email verification links
- Track verification status

### Step 4: Enable Firebase in Your Code

1. Open `lib/services/firebase_config.dart`
2. Change line 6 from:
   ```dart
   static const bool _useFirebase = false;
   ```
   To:
   ```dart
   static const bool _useFirebase = true;
   ```

### Step 5: Rebuild the App

```bash
cd /Users/lucasperrusi/Projects/PopMatch
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d "iPhone 17 Pro" --debug
```

## 📧 How It Works

Once enabled:

1. **User signs up** → Firebase automatically sends verification email
2. **User receives email** → Clicks verification link
3. **Email verified** → User can sign in normally
4. **Resend email** → "Resend Verification Email" button works

## 🎨 Customize Email Template (Optional)

1. Firebase Console → **Authentication** → **Templates**
2. Click **"Email address verification"**
3. Customize:
   - Email subject
   - Email body text
   - Action button text
   - Sender name

## ✅ Verification Checklist

After setup, verify:

- [ ] `GoogleService-Info.plist` is in `ios/Runner/`
- [ ] Firebase Console → Authentication → Email/Password is **Enabled**
- [ ] `_useFirebase = true` in `firebase_config.dart`
- [ ] App rebuilt with `flutter clean && flutter pub get && cd ios && pod install`

## 🧪 Test Email Verification

1. **Sign up** with a new email address
2. **Check your email** (inbox and spam folder)
3. **You should receive** an email from Firebase
4. **Click the verification link**
5. **Sign in** - should work!

## ⚠️ Important Notes

- **Free Tier**: Firebase free tier includes 10,000 emails/month
- **Email Delivery**: Usually arrives within seconds
- **Spam Folder**: Check spam if email doesn't arrive
- **Development Mode**: Currently disabled - emails won't send until Firebase is enabled

## 🐛 Troubleshooting

### Email Not Received?
1. ✅ Check spam/junk folder
2. ✅ Verify Authentication → Email/Password is enabled in Firebase Console
3. ✅ Check Firebase Console → Authentication → Users (see if user was created)
4. ✅ Verify email address is correct
5. ✅ Check Firebase Console → Usage (ensure not over free tier limits)

### Firebase Not Initializing?
1. ✅ Verify `GoogleService-Info.plist` exists in `ios/Runner/`
2. ✅ Check bundle ID matches Firebase Console (`com.example.popmatch`)
3. ✅ Run `flutter clean` and rebuild
4. ✅ Check console for Firebase errors

### Still Not Working?
- Check Firebase Console → Authentication → Users
- Look for the user you signed up with
- Check if email is marked as "Verified" or "Unverified"
- Try resending verification email from the app

---

**Current**: Firebase disabled → No emails sent  
**After Setup**: Firebase enabled → Emails sent automatically ✅
