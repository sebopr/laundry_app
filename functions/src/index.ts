import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import {
  onDocumentCreated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

initializeApp();

export { sendVerificationCode, verifyEmailCode } from "./emailVerification";
export { appleSignInCallback } from "./appleSignIn";
export { onJoinRequestCreated, resolveJoinRequest } from "./joinRequests";
export {
  leaveBuilding,
  deleteAccount,
  checkStaleResidents,
} from "./accountLifecycle";

const db = getFirestore();
const messaging = getMessaging();

/**
 * Sends a push notification to the receiver whenever a new chat message is
 * written. The Flutter client's PushNotificationService stores each user's
 * current FCM token at users/{uid}.fcmToken; this is the counterpart that
 * actually delivers the push when the app isn't open to see it arrive live.
 */
export const onNewChatMessage = onDocumentCreated(
  "chat_rooms/{chatRoomId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const message = snapshot.data();
    const senderId = message.senderId as string | undefined;
    const senderEmail = message.senderEmail as string | undefined;
    const receiverId = message.receiverId as string | undefined;
    const text = message.message as string | undefined;

    if (!senderId || !senderEmail || !receiverId || !text) {
      logger.warn("Skipping: message missing expected fields", {
        senderId,
        senderEmail,
        receiverId,
        hasText: !!text,
      });
      return;
    }
    if (receiverId === senderId) {
      logger.info("Skipping: sender and receiver are the same user");
      return;
    }

    const [receiverDoc, senderDoc] = await Promise.all([
      db.collection("users").doc(receiverId).get(),
      db.collection("users").doc(senderId).get(),
    ]);

    const token = receiverDoc.data()?.fcmToken as string | undefined;
    if (!token) {
      logger.warn(`Skipping: no fcmToken stored for receiver ${receiverId}`, {
        receiverDocExists: receiverDoc.exists,
        receiverFields: Object.keys(receiverDoc.data() ?? {}),
      });
      return;
    }

    const senderName =
      (senderDoc.data()?.displayName as string | undefined) || senderEmail;

    try {
      const messageId = await messaging.send({
        token,
        notification: {
          title: senderName,
          body: text,
        },
        data: {
          senderId,
          senderEmail,
          senderName,
        },
        android: { priority: "high" },
        apns: {
          payload: {
            aps: { sound: "default" },
          },
        },
      });
      logger.info(`Push sent to ${receiverId}`, { messageId });
    } catch (err) {
      logger.error(`Failed to send chat push notification to ${receiverId}`, err);
    }
  }
);

const SLOT_LABELS: Record<string, string> = {
  morning: "Morning (08:00–12:00)",
  afternoon: "Afternoon (12:00–22:00)",
};

const MONTH_NAMES = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

/** Formats a "YYYY-MM-DD" booking date as "Today" / "Tomorrow" / "Aug 21". */
function formatBookingDate(dateStr: string): string {
  const [y, m, d] = dateStr.split("-").map(Number);
  if (!y || !m || !d) return dateStr;

  const bookingDate = Date.UTC(y, m - 1, d);
  const now = new Date();
  const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const diffDays = Math.round((bookingDate - today) / 86400000);

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Tomorrow";
  return `${MONTH_NAMES[m - 1]} ${d}`;
}

/**
 * Notifies every other resident of the same building when a machine slot is
 * booked or cancelled, so neighbours don't have to keep the app open to see
 * availability change.
 */
async function notifyBuildingOfBookingChange(
  booking: FirebaseFirestore.DocumentData,
  action: "booked" | "cancelled"
) {
  const linkedUuid = booking.linked_uuid as string | undefined;
  const bookerId = booking.user_id as string | undefined;
  const machine = booking.machine as number | undefined;
  const slot = booking.slot as string | undefined;
  const date = booking.date as string | undefined;

  if (!linkedUuid || !bookerId || machine == null || !slot || !date) {
    logger.warn(`Skipping booking ${action} notification: missing fields`, {
      linkedUuid,
      bookerId,
      machine,
      slot,
      date,
    });
    return;
  }

  const [bookerDoc, buildingUsersSnap] = await Promise.all([
    db.collection("users").doc(bookerId).get(),
    db.collection("users").where("linked_uuid", "==", linkedUuid).get(),
  ]);

  // Never fall back to the booker's email in a notification every other
  // resident sees — only their display name, or a neutral placeholder.
  const bookerName =
    (bookerDoc.data()?.displayName as string | undefined) || "A neighbour";
  const slotLabel = SLOT_LABELS[slot] ?? slot;
  const dateLabel = formatBookingDate(date);
  const title = action === "booked" ? "New booking" : "Booking cancelled";
  const verb = action === "booked" ? "booked" : "cancelled";
  const body =
    `${bookerName} ${verb} Machine ${machine} · ${dateLabel}, ${slotLabel}`;

  const tokens: string[] = [];
  buildingUsersSnap.forEach((doc) => {
    if (doc.id === bookerId) return; // don't notify the person who acted
    const token = doc.data().fcmToken as string | undefined;
    if (token) tokens.push(token);
  });

  if (tokens.length === 0) {
    logger.info(`No other residents with tokens for building ${linkedUuid}`);
    return;
  }

  try {
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        type: "booking",
        action,
        machine: String(machine),
        slot,
        date,
      },
      android: { priority: "high" },
      apns: {
        payload: {
          aps: { sound: "default" },
        },
      },
    });
    logger.info(`Booking ${action} notifications sent`, {
      success: response.successCount,
      failure: response.failureCount,
    });
  } catch (err) {
    logger.error(`Failed to send booking ${action} notifications`, err);
  }
}

export const onBookingCreated = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    await notifyBuildingOfBookingChange(snapshot.data(), "booked");
  }
);

export const onBookingDeleted = onDocumentDeleted(
  "bookings/{bookingId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    await notifyBuildingOfBookingChange(snapshot.data(), "cancelled");
  }
);
