const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineString, defineInt, defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
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
        "Email and code are required",
    );
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid email format",
    );
  }

  // Validate code format (should be 6 digits)
  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError(
        "invalid-argument",
        "Code must be 6 digits",
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
    const fromEmail = gmailUser.value() ||
      smtpUser.value() ||
      process.env.GMAIL_USER ||
      process.env.SMTP_USER ||
      "noreply@popmatch.app";
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
        error.message,
    );
  }
});

const db = getFirestore();

/**
 * Returns the current UTC time as an ISO-8601 string.
 * @return {string}
 */
function nowIso() {
  return new Date().toISOString();
}

/**
 * Loads a user's social privacy settings with defaults.
 * @param {string} uid
 * @return {Promise<Object>}
 */
async function getUserPrivacy(uid) {
  const snap = await db
      .collection("users")
      .doc(uid)
      .collection("privacy")
      .doc("settings")
      .get();
  const data = snap.data() || {};
  return {
    allowFollowers: data.allowFollowers !== false,
    shareLikes: data.shareLikes !== false,
    shareWatchlist: data.shareWatchlist !== false,
    shareWatchingActivity: data.shareWatchingActivity !== false,
    activityVisibility: data.activityVisibility || "followersOnly",
  };
}

exports.sendFollowRequest = onCall({region: "us-central1"}, async (request) => {
  const requesterUid = request.auth && request.auth.uid;
  const targetUid = request.data && request.data.targetUid;
  if (!requesterUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "targetUid is required.");
  }
  if (targetUid === requesterUid) {
    throw new HttpsError("invalid-argument", "You cannot follow yourself.");
  }

  const privacy = await getUserPrivacy(targetUid);
  if (!privacy.allowFollowers) {
    throw new HttpsError("permission-denied", "This user is not accepting followers.");
  }

  const docId = `${requesterUid}_${targetUid}`;
  await db.collection("followEdges").doc(docId).set({
    followerUid: requesterUid,
    followeeUid: targetUid,
    status: "pending",
    createdAt: nowIso(),
    updatedAt: nowIso(),
  }, {merge: true});

  await db.collection("users").doc(targetUid)
      .collection("incomingRequests")
      .doc(requesterUid)
      .set({
        followerUid: requesterUid,
        status: "pending",
        createdAt: nowIso(),
        updatedAt: nowIso(),
      }, {merge: true});

  return {ok: true};
});

exports.respondToFollowRequest = onCall({region: "us-central1"}, async (request) => {
  const followeeUid = request.auth && request.auth.uid;
  const requesterUid = request.data && request.data.requesterUid;
  const accept = request.data && request.data.accept === true;

  if (!followeeUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  if (!requesterUid || typeof requesterUid !== "string") {
    throw new HttpsError("invalid-argument", "requesterUid is required.");
  }

  const docId = `${requesterUid}_${followeeUid}`;
  await db.collection("followEdges").doc(docId).set({
    followerUid: requesterUid,
    followeeUid: followeeUid,
    status: accept ? "accepted" : "declined",
    updatedAt: nowIso(),
    acceptedAt: accept ? nowIso() : null,
  }, {merge: true});

  await db.collection("users").doc(followeeUid)
      .collection("incomingRequests")
      .doc(requesterUid)
      .delete();

  return {ok: true, status: accept ? "accepted" : "declined"};
});

exports.unfollowUser = onCall({region: "us-central1"}, async (request) => {
  const followerUid = request.auth && request.auth.uid;
  const targetUid = request.data && request.data.targetUid;
  if (!followerUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "targetUid is required.");
  }

  const docId = `${followerUid}_${targetUid}`;
  await db.collection("followEdges").doc(docId).delete();
  return {ok: true};
});

exports.searchUsers = onCall({region: "us-central1"}, async (request) => {
  const requesterUid = request.auth && request.auth.uid;
  const query = ((request.data && request.data.query) || "")
      .toString()
      .trim()
      .toLowerCase();
  if (!requesterUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  if (!query) return [];

  const snap = await db.collection("users").limit(50).get();
  const users = snap.docs
      .map((doc) => doc.data())
      .filter((u) => {
        const uid = (u.uid || "").toString();
        if (!uid || uid === requesterUid) return false;
        const name = (u.displayName || "").toString().toLowerCase();
        const email = (u.email || "").toString().toLowerCase();
        return name.includes(query) || email.includes(query);
      })
      .slice(0, 20)
      .map((u) => ({
        uid: u.uid || "",
        displayName: u.displayName || "",
        email: u.email || "",
        photoURL: u.photoURL || "",
      }));

  if (!users.length) return users;

  const statusByUid = {};
  const targetUids = users.map((u) => u.uid).filter(Boolean);
  const chunks = [];
  for (let i = 0; i < targetUids.length; i += 10) {
    chunks.push(targetUids.slice(i, i + 10));
  }

  for (const chunk of chunks) {
    const edgeSnap = await db.collection("followEdges")
        .where("followerUid", "==", requesterUid)
        .where("followeeUid", "in", chunk)
        .get();

    for (const doc of edgeSnap.docs) {
      const edge = doc.data() || {};
      const followeeUid = (edge.followeeUid || "").toString();
      const status = (edge.status || "pending").toString();
      if (followeeUid) {
        statusByUid[followeeUid] = status;
      }
    }
  }

  return users.map((u) => ({
    ...u,
    followStatus: statusByUid[u.uid] || "notFollowing",
  }));
});

exports.recordSocialActivity = onCall({region: "us-central1"}, async (request) => {
  const actorUid = request.auth && request.auth.uid;
  if (!actorUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const itemType = ((request.data && request.data.itemType) || "").toString();
  const itemId = ((request.data && request.data.itemId) || "").toString();
  const activityType = ((request.data && request.data.activityType) || "").toString();
  if (!itemType || !itemId || !activityType) {
    throw new HttpsError("invalid-argument", "itemType, itemId, activityType are required.");
  }

  const privacy = await getUserPrivacy(actorUid);
  const blockedByPrivacy = (activityType === "liked" && !privacy.shareLikes) ||
      (activityType === "watchlisted" && !privacy.shareWatchlist) ||
      (activityType === "watched" && !privacy.shareWatchingActivity);
  if (blockedByPrivacy || privacy.activityVisibility === "private") {
    return {ok: true, skipped: true};
  }

  const actorUser = await db.collection("users").doc(actorUid).get();
  const actorData = actorUser.data() || {};
  const actorDisplayName = actorData.displayName || "";

  const ref = db.collection("socialActivities").doc();
  const activity = {
    id: ref.id,
    actorUid,
    actorDisplayName,
    itemType,
    itemId,
    activityType,
    visibility: privacy.activityVisibility || "followersOnly",
    createdAt: nowIso(),
  };
  await ref.set(activity);

  return {ok: true, id: ref.id};
});

exports.getFriendsFeed = onCall({region: "us-central1"}, async (request) => {
  const viewerUid = request.auth && request.auth.uid;
  const limit = Math.min(
      Number((request.data && request.data.limit) || 40),
      100,
  );
  if (!viewerUid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  try {
    const followsSnap = await db.collection("followEdges")
        .where("followerUid", "==", viewerUid)
        .where("status", "==", "accepted")
        .get();
    const followed = followsSnap.docs.map((d) => d.data().followeeUid).filter(Boolean);
    if (!followed.length) return [];

    const out = [];
    const chunks = [];
    for (let i = 0; i < followed.length; i += 10) {
      chunks.push(followed.slice(i, i + 10));
    }
    for (const chunk of chunks) {
      const feedSnap = await db.collection("socialActivities")
          .where("actorUid", "in", chunk)
          .orderBy("createdAt", "desc")
          .limit(limit)
          .get();
      for (const doc of feedSnap.docs) {
        const data = doc.data();
        if (data.visibility === "private") continue;
        out.push(data);
      }
    }

    out.sort((a, b) => (b.createdAt || "").localeCompare(a.createdAt || ""));
    return out.slice(0, limit);
  } catch (err) {
    console.error("getFriendsFeed failed:", err);
    const msg = err && err.message ? String(err.message) : "";
    if (msg.includes("index") || msg.includes("FAILED_PRECONDITION") || msg.includes("requires an index")) {
      throw new HttpsError(
          "failed-precondition",
          "Firestore indexes are building or missing. Deploy firestore.indexes.json " +
          "and wait for indexes to finish building, then try again.",
      );
    }
    throw new HttpsError(
        "internal",
        "Could not load friends feed.",
    );
  }
});
