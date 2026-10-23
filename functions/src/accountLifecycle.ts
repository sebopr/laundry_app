import { getAuth } from "firebase-admin/auth";
import {
  DocumentData,
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { sendEmail } from "./lib/email";

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

function db() {
  return getFirestore();
}

/**
 * Removes a user's residency from whatever building/household they're in:
 * reassigns household headship (or deletes the household if they were its
 * only member), cancels their own future bookings — freeing the slots and,
 * since these are plain doc deletes, triggering the existing
 * onBookingDeleted neighbour-notification for free — and clears the
 * resident fields off their user doc. Shared by leaveBuilding,
 * deleteAccount, removeResident (buildings.ts), and the stale-resident
 * cleanup below; never touches
 * managed_buildings, so it can't affect a building's admin.
 */
export async function cleanupResidency(firestore: Firestore, uid: string) {
  const userRef = firestore.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return;

  const userData = userSnap.data() as DocumentData;
  const linkedUuid = userData.linked_uuid as string | undefined;
  const householdId = userData.household_id as string | undefined;
  const isHead = userData.isHouseholdHead as boolean | undefined;

  if (householdId) {
    const householdRef = firestore.collection("households").doc(householdId);
    const householdSnap = await householdRef.get();
    if (householdSnap.exists) {
      const members =
        (householdSnap.data()?.members as string[] | undefined) ?? [];
      const remaining = members.filter((m) => m !== uid);

      if (remaining.length === 0) {
        await householdRef.delete();
      } else if (isHead) {
        const newHead = remaining[0];
        await householdRef.update({ members: remaining, head_uid: newHead });
        await firestore
          .collection("users")
          .doc(newHead)
          .update({ isHouseholdHead: true });
      } else {
        await householdRef.update({ members: FieldValue.arrayRemove(uid) });
      }
    }
  }

  const today = new Date().toISOString().slice(0, 10);
  const bookingsSnap = await firestore
    .collection("bookings")
    .where("user_id", "==", uid)
    .get();
  await Promise.all(
    bookingsSnap.docs
      .filter((doc) => {
        const date = doc.data().date as string | undefined;
        return date != null && date >= today;
      })
      .map((doc) => doc.ref.delete())
  );

  await userRef.update({
    linked_uuid: FieldValue.delete(),
    household_id: FieldValue.delete(),
    household_name: FieldValue.delete(),
    isHouseholdHead: FieldValue.delete(),
  });

  return { linkedUuid };
}

/** Lets a resident leave their building/household without deleting their account. */
export const leaveBuilding = onCall(
  { region: "europe-west6" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    await cleanupResidency(db(), uid);
    return { success: true };
  }
);

/**
 * Deletes the caller's account entirely: Firestore user doc, Firebase Auth
 * record, residency/household/booking cleanup, and any pending requests.
 * Refuses if the caller currently administers any building — they'd leave
 * it with no admin, which we never allow — so they have to transfer or
 * delete each building first.
 */
export const deleteAccount = onCall(
  { region: "europe-west6" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }

    const firestore = db();
    const userRef = firestore.collection("users").doc(uid);
    const userSnap = await userRef.get();
    const managedBuildings =
      (userSnap.data()?.managed_buildings as string[] | undefined) ?? [];
    if (managedBuildings.length > 0) {
      throw new HttpsError(
        "failed-precondition",
        "You manage one or more buildings. Transfer or delete them before deleting your account."
      );
    }

    await cleanupResidency(firestore, uid);

    const joinRequestsSnap = await firestore
      .collection("join_requests")
      .where("uid", "==", uid)
      .get();

    await Promise.all([
      ...joinRequestsSnap.docs.map((doc) => doc.ref.delete()),
      firestore.collection("email_verification_codes").doc(uid).delete(),
    ]);

    await userRef.delete();
    await getAuth().deleteUser(uid);

    logger.info(`Account ${uid} deleted.`);
    return { success: true };
  }
);

// ─── Stale resident cleanup ─────────────────────────────────────────────────

const STALE_WARNING_DAYS = 30;
const STALE_GRACE_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;

async function pushAndEmail(
  data: DocumentData,
  title: string,
  body: string
) {
  const token = data.fcmToken as string | undefined;
  const pushPromise = token
    ? getMessaging()
        .send({
          token,
          notification: { title, body },
          android: { priority: "high" as const },
          apns: { payload: { aps: { sound: "default" } } },
        })
        .catch((err) => logger.error("Failed to send push", err))
    : Promise.resolve();

  const email = data.email as string | undefined;
  const emailPromise = email
    ? sendEmail(RESEND_API_KEY.value(), [email], title, body).catch((err) =>
        logger.error("Failed to send email", err)
      )
    : Promise.resolve();

  await Promise.all([pushPromise, emailPromise]);
}

async function sendStaleWarning(
  userRef: FirebaseFirestore.DocumentReference,
  data: DocumentData
) {
  await userRef.update({ staleWarningAt: Timestamp.now() });
  await pushAndEmail(
    data,
    "Still living there?",
    `We haven't seen you in Lavaplan in a while. If you've moved out, no action needed. Otherwise, just open the app in the next ${STALE_GRACE_DAYS} days to keep your building access.`
  );
}

async function removeStaleResident(
  firestore: Firestore,
  uid: string,
  data: DocumentData
) {
  const linkedUuid = data.linked_uuid as string;
  await cleanupResidency(firestore, uid);

  const [buildingDoc, adminsSnap] = await Promise.all([
    firestore.collection("buildings").doc(linkedUuid).get(),
    firestore
      .collection("users")
      .where("managed_buildings", "array-contains", linkedUuid)
      .get(),
  ]);

  const buildingName =
    (buildingDoc.data()?.name as string | undefined) ?? "the building";
  const residentName =
    (data.displayName as string | undefined) ||
    (data.email as string | undefined) ||
    "A resident";

  await pushAndEmail(
    data,
    "Removed due to inactivity",
    `You were removed from ${buildingName} after ${STALE_WARNING_DAYS}+ days of inactivity. Scan its QR code again if you still live there.`
  );

  const adminTokens: string[] = [];
  const adminEmails: string[] = [];
  adminsSnap.forEach((doc) => {
    const admin = doc.data();
    if (admin.fcmToken) adminTokens.push(admin.fcmToken as string);
    if (admin.email) adminEmails.push(admin.email as string);
  });

  const adminTitle = "Resident auto-removed";
  const adminBody = `${residentName} was automatically removed from ${buildingName} after ${STALE_WARNING_DAYS}+ days of inactivity.`;

  const pushPromise = adminTokens.length
    ? getMessaging()
        .sendEachForMulticast({
          tokens: adminTokens,
          notification: { title: adminTitle, body: adminBody },
          android: { priority: "high" },
          apns: { payload: { aps: { sound: "default" } } },
        })
        .catch((err) => logger.error("Failed to notify admins", err))
    : Promise.resolve();

  const emailPromise = adminEmails.length
    ? sendEmail(RESEND_API_KEY.value(), adminEmails, adminTitle, adminBody).catch(
        (err) => logger.error("Failed to email admins", err)
      )
    : Promise.resolve();

  await Promise.all([pushPromise, emailPromise]);
  logger.info(`Auto-removed stale resident ${uid} from building ${linkedUuid}`);
}

/**
 * Daily sweep for residents who've stopped opening the app. At 30 days
 * inactive we warn them; if they still haven't opened the app 7 days after
 * that, we remove their residency the same way leaveBuilding would, and let
 * both them and the building's admin(s) know it happened. lastActive is
 * stamped client-side (see PushNotificationService.registerToken) whenever
 * an authenticated session starts.
 */
export const checkStaleResidents = onSchedule(
  { schedule: "every 24 hours", region: "europe-west6", secrets: [RESEND_API_KEY] },
  async () => {
    const firestore = db();
    const now = Date.now();

    const residentsSnap = await firestore
      .collection("users")
      .where("linked_uuid", "!=", null)
      .get();

    for (const doc of residentsSnap.docs) {
      const data = doc.data();
      const lastActive = data.lastActive as Timestamp | undefined;
      if (!lastActive) continue; // no baseline yet — avoid guessing

      const daysSinceActive = (now - lastActive.toMillis()) / DAY_MS;
      const staleWarningAt = data.staleWarningAt as Timestamp | undefined;

      if (!staleWarningAt) {
        if (daysSinceActive >= STALE_WARNING_DAYS) {
          await sendStaleWarning(doc.ref, data);
        }
        continue;
      }

      // A warning is outstanding — did they open the app since it was sent?
      if (lastActive.toMillis() > staleWarningAt.toMillis()) {
        await doc.ref.update({ staleWarningAt: FieldValue.delete() });
        continue;
      }

      const daysSinceWarning = (now - staleWarningAt.toMillis()) / DAY_MS;
      if (daysSinceWarning >= STALE_GRACE_DAYS) {
        await removeStaleResident(firestore, doc.id, data);
      }
    }
  }
);
