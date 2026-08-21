import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

initializeApp();

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
