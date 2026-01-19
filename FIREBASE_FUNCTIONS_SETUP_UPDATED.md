# Firebase Cloud Functions Setup - Updated for New Params API

## ⚠️ Important: Migration from functions.config()

The old `functions.config()` API is **deprecated** and will be removed in March 2026. This guide uses the new **`params`** API instead.

## ✅ What's Been Updated

- ✅ Cloud Function now uses `params` API (not deprecated `functions.config()`)
- ✅ Secrets stored in Cloud Secret Manager (secure)
- ✅ Environment variables support for local development

## 🚀 Quick Setup Steps

### Step 1: Install Dependencies

```bash
cd /Users/lucasperrusi/Projects/PopMatch/functions
npm install
```

### Step 2: Configure Email Service

You have two options:

#### Option A: Gmail (Easiest for Testing)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password**:
   - Go to: https://myaccount.google.com/security
   - Click "2-Step Verification" → "App passwords"
   - Generate password for "Mail"
   - Copy the 16-character password (e.g., `evom uxpw dogk adzh`)

3. **Set Environment Variables**:

   **For Gmail User (String)**:
   ```bash
   firebase functions:secrets:set GMAIL_USER
   # When prompted, enter: your-email@gmail.com
   ```

   **For Gmail App Password (Secret)**:
   ```bash
   firebase functions:secrets:set GMAIL_APP_PASSWORD
   # When prompted, enter your 16-character app password (e.g., evom uxpw dogk adzh)
   # Note: Remove spaces if prompted - just enter the 16 characters
   ```

#### Option B: SMTP (Production - SendGrid, Mailgun, etc.)

```bash
# Set SMTP configuration
firebase functions:secrets:set SMTP_HOST
# Enter: smtp.sendgrid.net (or your SMTP host)

firebase functions:secrets:set SMTP_USER
# Enter: apikey (or your SMTP username)

firebase functions:secrets:set SMTP_PASSWORD
# Enter: your-sendgrid-api-key (or your SMTP password)

firebase functions:secrets:set SMTP_PORT
# Enter: 587 (or your SMTP port)

firebase functions:secrets:set SMTP_SECURE
# Enter: false (or true for SSL)
```

### Step 3: Deploy Cloud Function

```bash
cd /Users/lucasperrusi/Projects/PopMatch
firebase deploy --only functions
```

**Important**: During deployment, Firebase will ask you to grant permissions to access the secrets. Answer **"yes"** to all prompts.

### Step 4: Grant Secret Access

After deploying, grant the function access to secrets:

```bash
firebase functions:secrets:access GMAIL_APP_PASSWORD
firebase functions:secrets:access SMTP_PASSWORD
```

Or set access during deployment (Firebase CLI will prompt you).

## 📱 Update Flutter App

```bash
cd /Users/lucasperrusi/Projects/PopMatch
flutter pub get
flutter run
```

## 🔍 Verify Secrets

Check if secrets are set:

```bash
firebase functions:secrets:list
```

## 🧪 Testing

1. Sign up with a new email
2. Check your email inbox for the 6-digit verification code
3. Enter the code in the app
4. Verify → Navigate to onboarding

## 📋 Setting Secrets via CLI

### Interactive Method (Recommended)

```bash
firebase functions:secrets:set SECRET_NAME
# Then paste the value when prompted
```

### Non-Interactive Method

```bash
echo "your-secret-value" | firebase functions:secrets:set SECRET_NAME
```

## 🔐 Secret Management

- **Secrets are stored in Cloud Secret Manager** (secure)
- **Only functions that explicitly bind to secrets can access them**
- **Secrets are versioned** - you can update them anytime

## 📚 Available Parameters

### String Parameters (Public)
- `GMAIL_USER` - Your Gmail email address
- `SMTP_HOST` - SMTP server hostname
- `SMTP_USER` - SMTP username
- `SMTP_PORT` - SMTP port (default: 587)
- `SMTP_SECURE` - Use SSL (default: false)

### Secret Parameters (Private)
- `GMAIL_APP_PASSWORD` - Gmail app password (16 characters)
- `SMTP_PASSWORD` - SMTP password/API key

## ⚠️ Troubleshooting

### Secret Not Found Error

If you get an error about secrets not being found:
1. Verify secret exists: `firebase functions:secrets:list`
2. Make sure secret is bound to function in `functions/index.js`
3. Redeploy: `firebase deploy --only functions`

### Email Not Sending

1. Check Cloud Function logs:
   ```bash
   firebase functions:log
   ```

2. Verify secrets are set correctly:
   ```bash
   firebase functions:secrets:list
   ```

3. Test Gmail app password format:
   - Should be 16 characters (no spaces)
   - Example: `evomuxpwdogkadzh`

### Permission Errors

If deployment fails with permission errors:
```bash
firebase login --reauth
```

## 🎯 Migration from Old Config

If you previously used `functions.config()`, you can migrate:

```bash
# Export old config
firebase functions:config:export

# This will show you what needs to be migrated to secrets/params
```

## 📖 Documentation

- [Firebase Functions Params](https://firebase.google.com/docs/functions/config-env)
- [Cloud Secret Manager](https://cloud.google.com/secret-manager)
- [Firebase Functions v2 Upgrade](https://firebase.google.com/docs/functions/2nd-gen-upgrade)

---

**That's it!** The Cloud Function now uses the modern `params` API and will continue working after March 2026. 🎉
