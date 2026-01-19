# Firebase Setup Instructions for Email Verification

## 🔍 Current Status

Your app is currently running in **development mode** with Firebase **disabled**. This is why you're not receiving verification emails.

## ✅ To Enable Email Verification

### Option 1: Enable Firebase (Recommended for Production)

**Step 1: Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Follow the setup wizard

**Step 2: Add Your App to Firebase**

**For iOS:**
1. In Firebase Console, click the iOS icon (🍎)
2. Enter Bundle ID: `com.example.popmatch`
   - To verify: Check `ios/Runner.xcodeproj` → Build Settings → Product Bundle Identifier
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

**For Android (if needed):**
1. In Firebase Console, click the Android icon (🤖)
2. Enter Package name: `com.example.popmatch`
   - To verify: Check `android/app/build.gradle` → `applicationId`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

**Step 3: Enable Authentication**
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Email/Password**
3. Toggle **Enable** to **ON**
4. Click **Save**

**Step 4: Enable Firebase in Your Code**
1. Open `lib/services/firebase_config.dart`
2. Change line 6:
   ```dart
   static const bool _useFirebase = true; // Change from false to true
   ```

**Step 5: Rebuild the App**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Option 2: Keep Development Mode (For Testing)

If you want to continue testing without Firebase setup:
- Email verification won't actually send emails
- The app will simulate the flow (show verification screen)
- User can still proceed to login
- Good for development/testing without Firebase configuration

## 📧 Email Verification Configuration

Once Firebase is enabled, email verification works automatically:

1. **Automatic on Sign-Up**: When user signs up, Firebase automatically sends verification email
2. **Manual Resend**: User can tap "Resend Verification Email" button
3. **Email Template**: Customizable in Firebase Console → Authentication → Templates

### Email Template Customization

1. Go to Firebase Console → **Authentication** → **Templates**
2. Click on **"Email address verification"**
3. Customize:
   - Email subject
   - Email body
   - Action button text
   - Sender name

## 🔍 Verify Setup

After enabling Firebase, test:

1. **Sign up with a new email**
2. **Check your email inbox** (and spam folder)
3. **You should receive** a verification email from Firebase
4. **Click the verification link**
5. **Sign in** - should work normally

## ⚠️ Important Notes

- **Free Tier Limits**: Firebase free tier allows 10,000 emails/month
- **Email Delivery**: May take a few seconds to arrive
- **Spam Folder**: Check spam folder if email doesn't arrive
- **Email Format**: Must be a valid email format

## 🐛 Troubleshooting

### Email Not Received?
1. Check spam/junk folder
2. Verify Authentication is enabled in Firebase Console
3. Check Firebase Console → Authentication → Users (see if user was created)
4. Verify email address is correct
5. Check Firebase Console → Usage (ensure not over limits)

### Firebase Not Working?
1. Verify config files are in correct locations
2. Check bundle ID/package name matches Firebase Console
3. Run `flutter clean` and rebuild
4. Check console for Firebase initialization errors

---

**Current Status**: Firebase is **disabled** (`_useFirebase = false`)
**To Enable**: Set `_useFirebase = true` and add Firebase config files
