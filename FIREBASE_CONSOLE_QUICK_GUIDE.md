# Firebase Console Quick Setup Guide

## 🎯 You're Here: Firebase Project Overview Page

Follow these steps in order:

---

## Step 1: Add iOS App (Do This First!)

1. **Click the "+ Add app" button** (top right, next to "PopMatch")

2. **Click the iOS icon** (🍎)

3. **Fill in the form**:
   ```
   iOS bundle ID: com.example.popmatch
   App nickname: PopMatch iOS (optional)
   App Store ID: (leave blank)
   ```

4. **Click "Register app"**

5. **Download `GoogleService-Info.plist`**
   - Click the download button
   - Save the file

6. **Add file to your project**:
   - Open Finder
   - Navigate to: `/Users/lucasperrusi/Projects/PopMatch/ios/Runner/`
   - Drag `GoogleService-Info.plist` into that folder
   - ✅ Make sure it's in `ios/Runner/` (not a subfolder)

7. **Click "Next"** in Firebase Console (skip remaining steps)

---

## Step 2: Enable Authentication

1. **In the left sidebar**, click **"Build"** (under Product categories)

2. **Click "Authentication"**

3. **Click "Get started"** (if you see this button)

4. **Click the "Sign-in method" tab** (at the top)

### Enable Email/Password:

1. **Click on "Email/Password"** (first option in the list)
2. **Toggle the first "Enable" switch to ON** (at the top)
3. **Click "Save"** (bottom right)

✅ **Email verification is now enabled!** Firebase will automatically send verification emails.

### Enable Google Sign-In:

1. **Click on "Google"** (in the sign-in providers list)
2. **Toggle "Enable" to ON**
3. **Project support email**: Select your email from the dropdown
4. **Click "Save"**

✅ **Google Sign-In is now enabled!**

### Enable Apple Sign-In:

1. **Click on "Apple"** (in the sign-in providers list)
2. **Toggle "Enable" to ON**
3. **Click "Save"**

✅ **Apple Sign-In is now enabled!**

**Note**: For production, you'll need to add Services ID and Team ID, but for testing this is enough.

---

## Step 3: Verify Setup

After completing the above, you should see:

- ✅ **Email/Password**: Enabled (green)
- ✅ **Google**: Enabled (green)
- ✅ **Apple**: Enabled (green)

---

## Step 4: Enable Firebase in Code

After you complete the Firebase Console setup, I'll enable Firebase in your code. But first, make sure:

- [ ] `GoogleService-Info.plist` is in `ios/Runner/` folder
- [ ] Email/Password is enabled in Firebase Console
- [ ] Google Sign-In is enabled in Firebase Console
- [ ] Apple Sign-In is enabled in Firebase Console

---

## 📋 Quick Checklist

**In Firebase Console:**
- [ ] iOS app added (Bundle ID: `com.example.popmatch`)
- [ ] `GoogleService-Info.plist` downloaded
- [ ] File placed in `ios/Runner/` folder
- [ ] Authentication → Email/Password → **Enabled**
- [ ] Authentication → Google → **Enabled**
- [ ] Authentication → Apple → **Enabled**

**Next Steps (I'll do this after you confirm):**
- [ ] Enable Firebase in code (`_useFirebase = true`)
- [ ] Rebuild app

---

**Once you've completed Steps 1-2 in Firebase Console, let me know and I'll enable Firebase in your code!**
