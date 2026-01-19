const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineString, defineInt, defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const nodemailer = require("nodemailer");

initializeApp();

// Define environment parameters (using new params API instead of deprecated config)
// These are set using: firebase functions:secrets:set SECRET_NAME
// Or using .env files for local development

// Gmail configuration
const gmailUser = defineString("GMAIL_USER", {default: ""});
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");

// SMTP configuration
const smtpHost = defineString("SMTP_HOST", {default: ""});
const smtpUser = defineString("SMTP_USER", {default: ""});
const smtpPassword = defineSecret("SMTP_PASSWORD");
const smtpPort = defineInt("SMTP_PORT", {default: 587});
const smtpSecure = defineString("SMTP_SECURE", {default: "false"});

// Configure email transporter using environment variables
// For production, use Gmail, SendGrid, Mailgun, or another email service
// Note: Secret values can only be accessed at runtime (inside the function handler)
const createEmailTransporter = () => {
  // Option 1: Gmail (requires App Password - see setup instructions)
  // Access secret values using .value() at runtime
  const gmailUserValue = gmailUser.value() || process.env.GMAIL_USER;
  const gmailPasswordValue = gmailAppPassword.value() || process.env.GMAIL_APP_PASSWORD;
  
  if (gmailUserValue && gmailPasswordValue) {
    return nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: gmailUserValue,
        pass: gmailPasswordValue,
      },
    });
  }

  // Option 2: SMTP (for any email service)
  const smtpHostValue = smtpHost.value() || process.env.SMTP_HOST;
  const smtpUserValue = smtpUser.value() || process.env.SMTP_USER;
  const smtpPasswordValue = smtpPassword.value() || process.env.SMTP_PASSWORD;
  const smtpPortValue = smtpPort.value() || parseInt(process.env.SMTP_PORT || "587");
  const smtpSecureValue = smtpSecure.value() === "true" || process.env.SMTP_SECURE === "true";
  
  if (smtpHostValue && smtpUserValue && smtpPasswordValue) {
    return nodemailer.createTransport({
      host: smtpHostValue,
      port: smtpPortValue,
      secure: smtpSecureValue,
      auth: {
        user: smtpUserValue,
        pass: smtpPasswordValue,
      },
    });
  }

  // Fallback: Log email (for development/testing)
  console.warn("⚠️ Email configuration not found. Emails will be logged only.");
  console.warn("⚠️ To enable email sending, configure Gmail or SMTP settings.");
  return null;
};

/**
 * Cloud Function to send verification code via email
 * 
 * Called from Flutter app with:
 * {
 *   email: "user@example.com",
 *   code: "123456"
 * }
 */
exports.sendVerificationCode = onCall({
  region: "us-central1", // Change to your preferred region
  maxInstances: 10,
  secrets: [gmailAppPassword, smtpPassword], // Reference secrets
}, async (request) => {
  const {email, code} = request.data;

  // Validate input
  if (!email || !code) {
    throw new HttpsError(
      "invalid-argument",
      "Email and code are required"
    );
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid email format"
    );
  }

  // Validate code format (should be 6 digits)
  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError(
      "invalid-argument",
      "Code must be 6 digits"
    );
  }

  try {
    const transporter = createEmailTransporter();

    if (!transporter) {
      // Log email for development/testing
      console.log(`📧 [DEV] Verification code for ${email}: ${code}`);
      return {
        success: true,
        message: "Verification code generated (email logging only - configure email service for production)",
      };
    }

    // Email content
    const fromEmail = gmailUser.value() || smtpUser.value() || process.env.GMAIL_USER || process.env.SMTP_USER || "noreply@popmatch.app";
    const mailOptions = {
      from: process.env.EMAIL_FROM || `"PopMatch" <${fromEmail}>`,
      to: email,
      subject: "Verify Your PopMatch Account",
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
              line-height: 1.6;
              color: #333;
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
            }
            .container {
              background-color: #1a1a1a;
              color: #f7f3e8;
              padding: 30px;
              border-radius: 12px;
              border: 2px solid #f6c344;
            }
            h1 {
              color: #f6c344;
              text-align: center;
              margin-bottom: 30px;
            }
            .code-box {
              background-color: #2e1403;
              border: 2px solid #f6c344;
              border-radius: 8px;
              padding: 20px;
              text-align: center;
              margin: 30px 0;
            }
            .code {
              font-size: 36px;
              font-weight: bold;
              color: #f6c344;
              letter-spacing: 8px;
              font-family: monospace;
            }
            .instructions {
              margin: 20px 0;
              color: #f7f3e8;
            }
            .footer {
              margin-top: 30px;
              padding-top: 20px;
              border-top: 1px solid #f6c344;
              color: #f7f3e8;
              font-size: 14px;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>🎬 Verify Your PopMatch Account</h1>
            <p class="instructions">
              Welcome to PopMatch! To complete your registration, please enter the verification code below:
            </p>
            <div class="code-box">
              <div class="code">${code}</div>
            </div>
            <p class="instructions">
              Enter this code in the PopMatch app to verify your email address and start discovering movies!
            </p>
            <p class="instructions" style="font-size: 14px; color: #f7f3e8; opacity: 0.8;">
              This code will expire in 15 minutes. If you didn't request this code, you can safely ignore this email.
            </p>
            <div class="footer">
              <p>Thank you for joining PopMatch! 🍿</p>
              <p style="font-size: 12px; opacity: 0.7;">
                If you have any questions, please contact our support team.
              </p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `
Verify Your PopMatch Account

Welcome to PopMatch! To complete your registration, please enter the following verification code in the app:

${code}

This code will expire in 15 minutes.

If you didn't request this code, you can safely ignore this email.

Thank you for joining PopMatch! 🍿
      `.trim(),
    };

    // Send email
    await transporter.sendMail(mailOptions);

    console.log(`✅ Verification code email sent to ${email}`);

    return {
      success: true,
      message: "Verification code email sent successfully",
    };
  } catch (error) {
    console.error(`❌ Error sending verification code email:`, error);
    throw new HttpsError(
      "internal",
      "Failed to send verification code email",
      error.message
    );
  }
});
