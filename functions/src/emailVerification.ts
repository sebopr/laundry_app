import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

const CODE_TTL_MINUTES = 10;
const RESEND_COOLDOWN_SECONDS = 60;
const MAX_ATTEMPTS = 5;

function db() {
  return getFirestore();
}

function generateCode(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function sendCodeEmail(apiKey: string, email: string, code: string) {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Lavaplan <noreply@inboxly.ch>",
      to: [email],
      subject: `${code} is your Lavaplan verification code`,
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 420px; margin: 0 auto;">
          <h2 style="color: #12A3A8;">Confirm your email</h2>
          <p>Enter this code in the app to finish setting up your Lavaplan account:</p>
          <div style="font-size: 32px; font-weight: 700; letter-spacing: 8px; background: #F3F7F7; padding: 16px 20px; border-radius: 12px; text-align: center; margin: 20px 0;">
            ${code}
          </div>
          <p style="color: #6B6B80; font-size: 13px;">This code expires in ${CODE_TTL_MINUTES} minutes. If you didn't request this, you can safely ignore this email.</p>
        </div>
      `,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Resend API error (${res.status}): ${body}`);
  }
}

/**
 * Generates a 6-digit code, stores it, and emails it to the caller's own
 * address. Requires the caller to already be signed in (the account exists
 * in Firebase Auth, just unverified).
 */
export const sendVerificationCode = onCall(
  { secrets: [RESEND_API_KEY], region: "europe-west6" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }

    const userRecord = await getAuth().getUser(uid);
    const email = userRecord.email;
    if (!email) {
      throw new HttpsError("failed-precondition", "This account has no email address.");
    }
    if (userRecord.emailVerified) {
      throw new HttpsError("failed-precondition", "Email is already verified.");
    }

    const docRef = db().collection("email_verification_codes").doc(uid);
    const existing = await docRef.get();
    const lastSentAt = existing.data()?.createdAt as Timestamp | undefined;
    if (lastSentAt) {
      const secondsSince = (Date.now() - lastSentAt.toMillis()) / 1000;
      if (secondsSince < RESEND_COOLDOWN_SECONDS) {
        throw new HttpsError(
          "resource-exhausted",
          `Please wait ${Math.ceil(RESEND_COOLDOWN_SECONDS - secondsSince)}s before requesting another code.`
        );
      }
    }

    const code = generateCode();
    await docRef.set({
      code,
      email,
      attempts: 0,
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromMillis(Date.now() + CODE_TTL_MINUTES * 60 * 1000),
    });

    try {
      await sendCodeEmail(RESEND_API_KEY.value(), email, code);
    } catch (err) {
      logger.error(`Failed to send verification code to ${email}`, err);
      throw new HttpsError("internal", "Could not send the email. Try again shortly.");
    }

    logger.info(`Verification code sent to ${uid}`);
    return { success: true };
  }
);

/**
 * Checks a submitted code against the one on file and, if it matches, flips
 * emailVerified on the Firebase Auth account via the Admin SDK — the same
 * flag the link-based flow used to set automatically.
 */
export const verifyEmailCode = onCall(
  { region: "europe-west6" },
  async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const submitted = (request.data?.code as string | undefined)?.trim();
  if (!submitted || submitted.length !== 6) {
    throw new HttpsError("invalid-argument", "Enter the 6-digit code.");
  }

  const docRef = db().collection("email_verification_codes").doc(uid);
  const snap = await docRef.get();
  if (!snap.exists) {
    throw new HttpsError(
      "failed-precondition",
      "No code requested yet. Request a new one."
    );
  }

  const data = snap.data()!;
  const attempts = (data.attempts as number | undefined) ?? 0;
  const expiresAt = data.expiresAt as Timestamp;

  if (attempts >= MAX_ATTEMPTS) {
    await docRef.delete();
    throw new HttpsError(
      "resource-exhausted",
      "Too many incorrect attempts. Request a new code."
    );
  }
  if (Date.now() > expiresAt.toMillis()) {
    await docRef.delete();
    throw new HttpsError("deadline-exceeded", "That code expired. Request a new one.");
  }
  if (submitted !== data.code) {
    await docRef.update({ attempts: attempts + 1 });
    const remaining = MAX_ATTEMPTS - (attempts + 1);
    throw new HttpsError(
      "invalid-argument",
      `Incorrect code. ${remaining} attempt${remaining === 1 ? "" : "s"} left.`
    );
  }

  await getAuth().updateUser(uid, { emailVerified: true });
  await docRef.delete();
  logger.info(`Email verified via code for ${uid}`);
  return { success: true };
});
