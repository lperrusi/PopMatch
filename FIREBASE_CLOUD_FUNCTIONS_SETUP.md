# Firebase Cloud Functions Setup for Email Verification

## Overview

This guide will help you set up Firebase Cloud Functions to send verification code emails to users.

## Prerequisites

1. ✅ Firebase project created (you already have "PopMatch")
2. ✅ Node.js installed (v18 or higher)
3. ✅ Firebase CLI installed (`npm install -g firebase-tools`)

## Step 1: Install Firebase CLI (if not installed)

```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for authentication.

## Step 3: Initialize Firebase Functions

```bash
cd /Users/lucasperrusi/Projects/PopMatch
firebase init functions
```

**When prompted:**
- **Select "PopMatch"** (or your Firebase project name)
- **Language**: JavaScript
- **ESLint**: Yes (recommended)
- **Install dependencies**: Yes

This will create the `functions/` directory with the necessary files.

## Step 4: Install Dependencies

```bash
cd functions
npm install
```

This installs:
- `firebase-functions` - Firebase Functions SDK
- `firebase-admin` - Firebase Admin SDK
- `nodemailer` - Email sending library

## Step 5: Configure Email Service

You have two options for sending emails:

### Option A: Gmail (Easiest for Testing)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Under "2-Step Verification", click "App passwords"
   - Generate a new app password for "Mail"
   - Copy the 16-character password

3. **Set Environment Variables**:
   ```bash
   cd functions
   firebase functions:config:set gmail.user="your-email@gmail.com"
   firebase functions:config:set gmail.app_password="your-16-char-app-password"
   ```

### Option B: SMTP (Any Email Service)

1. Get SMTP credentials from your email provider (SendGrid, Mailgun, etc.)

2. **Set Environment Variables**:
   ```bash
   cd functions
   firebase functions:config:set smtp.host="smtp.gmail.com"
   firebase functions:config:set smtp.port="587"
   firebase functions:config:set smtp.user="your-email@gmail.com"
   firebase functions:config:set smtp.password="your-password"
   firebase functions:config:set smtp.secure="false"
   ```

## Step 6: Deploy Cloud Function

```bash
cd /Users/lucasperrusi/Projects/PopMatch
firebase deploy --only functions
```

This will deploy the `sendVerificationCode` function to Firebase.

## Step 7: Install cloud_functions Package in Flutter

```bash
cd /Users/lucasperrusi/Projects/PopMatch
flutter pub get
```

The `cloud_functions` package has already been added to `pubspec.yaml`.

## Step 8: Test the Function

1. **Run your Flutter app**:
   ```bash
   flutter run
   ```

2. **Sign up with a new email**
   - The app will call the Cloud Function
   - Check your email for the verification code

3. **Check Cloud Function logs** (if email doesn't send):
   ```bash
   firebase functions:log
   ```

## Troubleshooting

### Email Not Sending

1. **Check Cloud Function logs**:
   ```bash
   firebase functions:log
   ```

2. **Verify environment variables**:
   ```bash
   firebase functions:config:get
   ```

3. **Test the function locally** (requires emulator):
   ```bash
   firebase emulators:start
   ```

### Cloud Function Not Found Error

- Make sure the function is deployed: `firebase deploy --only functions`
- Check the function name matches: `sendVerificationCode`
- Verify you're using the correct Firebase project

### Gmail App Password Not Working

- Make sure 2-Factor Authentication is enabled
- Use the 16-character App Password, not your regular password
- Try generating a new App Password

## Project Structure

```
PopMatch/
├── functions/
│   ├── index.js          # Cloud Function code
│   ├── package.json      # Node.js dependencies
│   └── .gitignore
├── firebase.json         # Firebase configuration
├── .firebaserc          # Firebase project settings (created by firebase init)
└── lib/
    └── services/
        └── auth_service.dart  # Updated to call Cloud Function
```

## Next Steps

After setup is complete:

1. ✅ Cloud Function deployed
2. ✅ Email service configured
3. ✅ Flutter app updated to call Cloud Function
4. ✅ Users will receive verification codes via email

## Security Notes

- ⚠️ **Never commit** `.firebaserc` or environment variables to git
- ⚠️ Store sensitive credentials in Firebase Functions config (not in code)
- ✅ The `functions/.gitignore` already excludes `node_modules/` and `.env`

## Cost Considerations

- Firebase Functions: **Free tier**: 2 million invocations/month
- Gmail: **Free** for personal use
- SMTP services: Varies by provider (SendGrid offers free tier)

---

**Your Cloud Function is ready!** After deployment, users will receive beautiful HTML emails with their 6-digit verification codes. 🎉
