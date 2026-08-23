import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { sendEmail } from "./lib/email";

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

function db() {
  return getFirestore();
}

/**
 * Notifies every admin of the target building whenever a resident requests
 * to join the building or create a new household within it. Requests are
 * written directly by the client (users/{uid} is the only doc they can
 * already write to a similar degree) but only take effect once an admin
 * calls resolveJoinRequest below — that's the part that actually grants
 * access, and it runs with the Admin SDK so it isn't gated by what the
 * client's own Firestore rules allow it to write.
 */
export const onJoinRequestCreated = onDocumentCreated(
  { document: "join_requests/{requestId}", secrets: [RESEND_API_KEY] },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    if (data.status !== "pending") return;

    const linkedUuid = data.linked_uuid as string | undefined;
    const type = data.type as string | undefined;
    if (!linkedUuid || !type) {
      logger.warn("Skipping join request notification: missing fields", {
        linkedUuid,
        type,
      });
      return;
    }

    const [buildingDoc, adminsSnap] = await Promise.all([
      db().collection("buildings").doc(linkedUuid).get(),
      db()
        .collection("users")
        .where("managed_buildings", "array-contains", linkedUuid)
        .get(),
    ]);

    if (adminsSnap.empty) {
      logger.warn(`No admins found for building ${linkedUuid}`);
      return;
    }

    const buildingName =
      (buildingDoc.data()?.name as string | undefined) ?? "your building";
    const requesterName =
      (data.displayName as string | undefined) ||
      (data.email as string | undefined) ||
      "A new resident";

    const title =
      type === "household" ? "New household request" : "New resident request";
    const body =
      type === "household"
        ? `${requesterName} wants to create the household "${data.household_name}" in ${buildingName}.`
        : `${requesterName} wants to join ${buildingName}.`;

    const tokens: string[] = [];
    const emails: string[] = [];
    adminsSnap.forEach((doc) => {
      const adminData = doc.data();
      const token = adminData.fcmToken as string | undefined;
      if (token) tokens.push(token);
      const email = adminData.email as string | undefined;
      if (email) emails.push(email);
    });

    const pushPromise = tokens.length
      ? getMessaging()
          .sendEachForMulticast({
            tokens,
            notification: { title, body },
            data: {
              type: "join_request",
              requestId: event.params.requestId,
              requestType: type,
            },
            android: { priority: "high" },
            apns: { payload: { aps: { sound: "default" } } },
          })
          .then((response) => {
            logger.info("Join request push sent to admins", {
              success: response.successCount,
              failure: response.failureCount,
            });
          })
          .catch((err) => logger.error("Failed to send admin push", err))
      : Promise.resolve();

    const emailPromise = emails.length
      ? sendEmail(
          RESEND_API_KEY.value(),
          emails,
          title,
          `${body} Open Lavaplan to accept or decline this request.`
        )
          .then(() => logger.info(`Join request email sent to ${emails.length} admin(s)`))
          .catch((err) => logger.error("Failed to send admin email", err))
      : Promise.resolve();

    await Promise.all([pushPromise, emailPromise]);
  }
);

/**
 * Approves or rejects a pending join request. Runs as the caller (an admin
 * of the target building), but performs the actual grant with the Admin SDK
 * so it doesn't depend on the admin's own client having write access to
 * another resident's user doc or to the households collection.
 */
export const resolveJoinRequest = onCall(
  { region: "europe-west6" },
  async (request) => {
    const adminUid = request.auth?.uid;
    if (!adminUid) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }

    const requestId = request.data?.requestId as string | undefined;
    const approve = request.data?.approve as boolean | undefined;
    if (!requestId || typeof approve !== "boolean") {
      throw new HttpsError(
        "invalid-argument",
        "requestId and approve are required."
      );
    }

    const reqRef = db().collection("join_requests").doc(requestId);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "Request not found.");
    }

    const reqData = reqSnap.data()!;
    if (reqData.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "This request has already been resolved."
      );
    }

    const linkedUuid = reqData.linked_uuid as string;
    const adminDoc = await db().collection("users").doc(adminUid).get();
    const managedBuildings =
      (adminDoc.data()?.managed_buildings as string[] | undefined) ?? [];
    if (!managedBuildings.includes(linkedUuid)) {
      throw new HttpsError(
        "permission-denied",
        "You do not manage this building."
      );
    }

    const requesterUid = reqData.uid as string;
    const type = reqData.type as string;

    if (approve) {
      if (type === "household") {
        const householdName = reqData.household_name as string;
        const householdRef = db().collection("households").doc();
        await householdRef.set({
          name: householdName,
          linked_uuid: linkedUuid,
          head_uid: requesterUid,
          members: [requesterUid],
          createdAt: Timestamp.now(),
        });
        await db().collection("users").doc(requesterUid).update({
          household_id: householdRef.id,
          household_name: householdName,
          isHouseholdHead: true,
        });
      } else {
        await db().collection("users").doc(requesterUid).update({
          linked_uuid: linkedUuid,
        });
      }
    }

    await reqRef.update({
      status: approve ? "approved" : "rejected",
      reviewedAt: Timestamp.now(),
      reviewedBy: adminUid,
    });

    const requesterDoc = await db().collection("users").doc(requesterUid).get();
    const token = requesterDoc.data()?.fcmToken as string | undefined;
    if (token) {
      const title = approve ? "Request approved" : "Request declined";
      const body =
        type === "household"
          ? approve
            ? "Your new household has been approved."
            : "Your household request was declined."
          : approve
            ? "You've been added to the building."
            : "Your request to join the building was declined.";

      try {
        await getMessaging().send({
          token,
          notification: { title, body },
          data: {
            type: "join_request_resolved",
            status: approve ? "approved" : "rejected",
          },
          android: { priority: "high" },
          apns: { payload: { aps: { sound: "default" } } },
        });
      } catch (err) {
        logger.error(`Failed to notify requester ${requesterUid}`, err);
      }
    }

    logger.info(
      `Join request ${requestId} ${approve ? "approved" : "rejected"} by ${adminUid}`
    );
    return { success: true };
  }
);
