import {
  DocumentData,
  FieldValue,
  getFirestore,
} from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { cleanupResidency } from "./accountLifecycle";
import { sendEmail } from "./lib/email";

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
// Where reports about building admins are emailed. Set once on first
// deploy (the CLI prompts for it) and stored in functions/.env.<project>.
const REPORTS_EMAIL = defineString("REPORTS_EMAIL");

// Federal building register (GWR), served by swisstopo. Public, no key.
const GWR_LAYER =
  "https://api3.geo.admin.ch/rest/services/ech/MapServer/ch.bfs.gebaeude_wohnungs_register";

// Bump when the declaration wording in the app changes, so each stored
// acceptance says which text the admin actually agreed to.
const DECLARATION_VERSION = 1;

function db() {
  return getFirestore();
}

/**
 * Looks up a GWR entrance (`<EGID>_<EDID>`, the featureId the app's
 * address search returns) and gives back its building id and official
 * address. Done server-side so the EGID a building is stored under always
 * comes from the register itself, never from the client.
 */
async function lookupGwrBuilding(featureId: string) {
  if (!/^\d+_\d+$/.test(featureId)) {
    throw new HttpsError("invalid-argument", "Invalid address.");
  }
  const res = await fetch(`${GWR_LAYER}/${featureId}?returnGeometry=false`);
  if (res.status === 404) {
    throw new HttpsError("not-found", "Address not found in the register.");
  }
  if (!res.ok) {
    logger.error(`GWR lookup failed (${res.status}) for ${featureId}`);
    throw new HttpsError("unavailable", "Address register unavailable.");
  }
  const body = (await res.json()) as {
    feature?: { attributes?: Record<string, unknown> };
  };
  const attrs = body.feature?.attributes;
  if (!attrs?.egid) {
    throw new HttpsError("not-found", "Address not found in the register.");
  }
  return {
    egid: String(attrs.egid),
    address: `${attrs.strname_deinr}, ${attrs.dplz4} ${attrs.dplzname}`,
  };
}

/**
 * Loads the caller's user doc and checks they administer `buildingId`.
 * Every admin-only building call goes through this.
 */
async function requireBuildingAdmin(uid: string | undefined, buildingId: unknown) {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  if (typeof buildingId !== "string" || !buildingId) {
    throw new HttpsError("invalid-argument", "buildingId is required.");
  }
  const userSnap = await db().collection("users").doc(uid).get();
  const user = (userSnap.data() ?? {}) as DocumentData;
  const managed = (user.managed_buildings as string[] | undefined) ?? [];
  if (!managed.includes(buildingId)) {
    throw new HttpsError("permission-denied", "You do not manage this building.");
  }
  return user;
}

/**
 * Creates a building for the calling admin. Replaces the old client-side
 * create so the trust rules live in one place:
 *  - the admin must accept the declaration of authority (stored with the
 *    time and the text version they saw),
 *  - the address must be a real GWR building, and each EGID can only be
 *    registered once (`building_egids/{egid}` is the lock),
 *  - self-declared admins (no `adminVerified`) can manage one building.
 */
export const createBuilding = onCall(
  { region: "europe-west6" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    const featureId = request.data?.featureId as string | undefined;
    if (request.data?.declarationAccepted !== true) {
      throw new HttpsError(
        "failed-precondition",
        "The declaration of authority must be accepted."
      );
    }
    if (!featureId) {
      throw new HttpsError("invalid-argument", "featureId is required.");
    }

    const { egid, address } = await lookupGwrBuilding(featureId);

    const firestore = db();
    const userRef = firestore.collection("users").doc(uid);
    const egidRef = firestore.collection("building_egids").doc(egid);
    const buildingRef = firestore.collection("buildings").doc();

    await firestore.runTransaction(async (tx) => {
      const [userSnap, egidSnap] = await Promise.all([
        tx.get(userRef),
        tx.get(egidRef),
      ]);
      const user = (userSnap.data() ?? {}) as DocumentData;

      if (user.role !== "admin") {
        throw new HttpsError("permission-denied", "Only admins can create buildings.");
      }
      if (egidSnap.exists) {
        throw new HttpsError("already-exists", "This building is already registered.");
      }

      const verified = user.adminVerified === true;
      const managed = (user.managed_buildings as string[] | undefined) ?? [];
      if (!verified && managed.length >= 1) {
        throw new HttpsError(
          "resource-exhausted",
          "Unverified admins can manage one building."
        );
      }

      tx.set(buildingRef, {
        name: address,
        address,
        egid,
        created_by: uid,
        created_at: FieldValue.serverTimestamp(),
        machines: { "1": "active", "2": "active", "3": "active" },
        // Shown to residents so they can see, and report, who runs the
        // building. Kept in sync by the setAdminVerified script.
        admin_uid: uid,
        admin_name: (user.displayName as string | undefined) ?? "",
        admin_verified: verified,
      });
      tx.set(egidRef, { building_id: buildingRef.id });

      const updates: DocumentData = {
        managed_buildings: FieldValue.arrayUnion(buildingRef.id),
        adminDeclaration: {
          acceptedAt: FieldValue.serverTimestamp(),
          version: DECLARATION_VERSION,
        },
      };
      // A resident-admin's first building is also the one they live in.
      if (user.isResidentAdmin === true && !user.linked_uuid) {
        updates.linked_uuid = buildingRef.id;
      }
      tx.update(userRef, updates);
    });

    logger.info(`Building ${buildingRef.id} (EGID ${egid}) created by ${uid}`);
    return { buildingId: buildingRef.id, name: address };
  }
);

/**
 * Residents of a building, for its admin's residents list. Contact details
 * are only included for verified admins — self-declared admins see names
 * and households only.
 */
export const getBuildingResidents = onCall(
  { region: "europe-west6" },
  async (request) => {
    const buildingId = request.data?.buildingId;
    const admin = await requireBuildingAdmin(request.auth?.uid, buildingId);
    const canSeeContacts = admin.adminVerified === true;

    const snap = await db()
      .collection("users")
      .where("linked_uuid", "==", buildingId)
      .get();

    const residents = snap.docs.map((doc) => {
      const d = doc.data();
      return {
        uid: doc.id,
        displayName: (d.displayName as string | undefined) ?? "",
        household_id: (d.household_id as string | undefined) ?? null,
        household_name: (d.household_name as string | undefined) ?? null,
        isHouseholdHead: d.isHouseholdHead === true,
        ...(canSeeContacts ? { email: (d.email as string | undefined) ?? "" } : {}),
      };
    });

    return { residents, canSeeContacts };
  }
);

/**
 * Removes a resident from a building the caller administers. Uses the same
 * cleanup as leaveBuilding, so households and future bookings are handled
 * too.
 */
export const removeResident = onCall(
  { region: "europe-west6" },
  async (request) => {
    const adminUid = request.auth?.uid;
    const buildingId = request.data?.buildingId;
    await requireBuildingAdmin(adminUid, buildingId);

    const residentUid = request.data?.uid as string | undefined;
    if (!residentUid) {
      throw new HttpsError("invalid-argument", "uid is required.");
    }
    if (residentUid === adminUid) {
      throw new HttpsError("invalid-argument", "Use leave building instead.");
    }

    const firestore = db();
    const residentSnap = await firestore.collection("users").doc(residentUid).get();
    if (residentSnap.data()?.linked_uuid !== buildingId) {
      throw new HttpsError("not-found", "Not a resident of this building.");
    }

    await cleanupResidency(firestore, residentUid);
    return { success: true };
  }
);

function escapeHtml(text: string) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Lets a resident report that their building's admin doesn't act for the
 * owner or property management. One report per resident per building
 * (`admin_reports/{buildingId}_{uid}`); reports are reviewed by hand.
 */
export const reportBuildingAdmin = onCall(
  { region: "europe-west6", secrets: [RESEND_API_KEY] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }
    const reason = String(request.data?.reason ?? "").trim().slice(0, 500);

    const firestore = db();
    const userSnap = await firestore.collection("users").doc(uid).get();
    const buildingId = userSnap.data()?.linked_uuid as string | undefined;
    if (!buildingId) {
      throw new HttpsError("failed-precondition", "You are not in a building.");
    }

    const buildingSnap = await firestore.collection("buildings").doc(buildingId).get();
    const building = buildingSnap.data() ?? {};
    const adminUid =
      (building.admin_uid as string | undefined) ??
      (building.created_by as string | undefined);
    if (adminUid === uid) {
      throw new HttpsError("invalid-argument", "You are this building's admin.");
    }

    const reportRef = firestore
      .collection("admin_reports")
      .doc(`${buildingId}_${uid}`);
    if ((await reportRef.get()).exists) {
      return { success: true };
    }

    await reportRef.set({
      building_id: buildingId,
      building_name: (building.name as string | undefined) ?? "",
      admin_uid: adminUid ?? null,
      reporter_uid: uid,
      reason,
      status: "open",
      createdAt: FieldValue.serverTimestamp(),
    });

    const to = REPORTS_EMAIL.value();
    if (to) {
      try {
        await sendEmail(
          RESEND_API_KEY.value(),
          [to],
          "Building admin reported",
          `A resident of ${escapeHtml(String(building.name ?? buildingId))} ` +
            `reported its admin (${escapeHtml(adminUid ?? "unknown")}).` +
            (reason ? `<br><br>Reason: ${escapeHtml(reason)}` : "") +
            `<br><br>Report: admin_reports/${escapeHtml(reportRef.id)}`
        );
      } catch (err) {
        logger.error("Failed to email admin report", err);
      }
    }

    logger.info(`Admin of building ${buildingId} reported by ${uid}`);
    return { success: true };
  }
);
