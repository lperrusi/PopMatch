# Firebase Cloud Functions - Quick Setup Guide

## ✅ What's Been Done

1. ✅ Cloud Function code created (`functions/index.js`)
2. ✅ Flutter code updated to call Cloud Function
3. ✅ `cloud_functions` package added to `pubspec.yaml`
4. ✅ Firebase configuration files created

## 🚀 Quick Start (5 Steps)

### Step 1: Install Firebase CLI (if not installed)

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Install Cloud Functions Dependencies

```bash
cd /Users/lucasperrusi/Projects/PopMatch/functions
npm install
```

### Step 4: Configure Email Service (Gmail Example)

**Option A: Using Gmail (Easiest)**

1. Enable 2-Factor Authentication on your Gmail account
2. Generate App Password:
   - Go to: https://myaccount.google.com/security
   - Click "2-Step Verification" → "App passwords"
   - Generate password for "Mail"
   - Copy the 16-character password

3. Set environment variables:
   ```bash
   cd /Users/lucasperrusi/Projects/PopMatch/functions
   firebase functions:config:set gmail.user="your-email@gmail.com"
   firebase functions:config:set gmail.app_password="your-16-char-app-password"
   ```

**Option B: Using SendGrid or Mailgun (Recommended for Production)**

```bash
firebase functions:config:set smtp.host="smtp.sendgrid.net"
firebase functions:config:set smtp.port="587"
firebase functions:config:set smtp.user="apikey"
firebase functions:config:set smtp.password="your-sendgrid-api-key"
firebase functions:config:set smtp.secure="false"
```

### Step 5: Deploy Cloud Function

```bash
cd /Users/lucasperrusi/Projects/PopMatch
firebase deploy --only functions
```

## 📱 Update Flutter App

After deploying, update Flutter dependencies:

```bash
cd /Users/lucasperrusi/Projects/PopMatch
flutter pub get
flutter run
```

## 🧪 Testing

1. Sign up with a new email
2. Check your email inbox for the verification code
3. Enter the 6-digit code in the app
4. Verify → Navigate to onboarding

## 📋 Files Created

- ✅ `functions/index.js` - Cloud Function code
- ✅ `functions/package.json` - Node.js dependencies
- ✅ `firebase.json` - Firebase configuration
- ✅ `.firebaserc` - Firebase project settings

## 🔍 Verify Setup

Check if function is deployed:
```bash
firebase functions:list
```

View function logs:
```bash
firebase functions:log
```

## ⚠️ Important Notes

1. **Email Configuration Required**: The Cloud Function will work, but emails won't send until you configure the email service (Gmail/SMTP)

2. **Development Mode**: If email service is not configured, the code will be logged to console (you can still test manually)

3. **Security**: Never commit `.firebaserc` or environment variables to git

## 🎯 Next Steps

1. ✅ Complete Steps 1-5 above
2. ✅ Test sign-up flow
3. ✅ Check email for verification code
4. ✅ Verify code in app
5. ✅ Navigate to onboarding

---

**That's it!** Once deployed, users will receive beautiful HTML emails with their 6-digit verification codes. 🎉
