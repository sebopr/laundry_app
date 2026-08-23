/**
 * One-off: completely wipes a single test account — Firebase Auth record,
 * Firestore user doc, household membership (with the same head-reassignment
 * logic as leaveBuilding/deleteAccount), every booking they ever made (past
 * and future — the production deleteAccount only cancels future ones and
 * leaves history alone, but for wiping a test account we want it all gone),
 * every join_requests doc they filed, and their email_verification_codes
 * doc if any.
 *
 * Unlike the production deleteAccount Cloud Function, this does NOT require
 * the caller to already be signed in as the account — it's meant to be run
 * from a dev machine against a uid you already know, e.g. to reset a test
 * account stuck in a bad state. If the account manages any buildings, the
 * script stops and prints them instead of touching anything, since deleting
 * a building would affect its other residents too — handle that separately.
 *
 * Usage (from functions/):
 *   npm run build
 *   node lib/scripts/deleteTestAccount.js --uid=<uid>            # dry run
 *   node lib/scripts/deleteTestAccount.js --uid=<uid> --apply    # deletes it
 *
 * Needs Application Default Credentials for the target Firebase project —
 * e.g. `gcloud auth application-default login`, or set
 * GOOGLE_APPLICATION_CREDENTIALS to a service account key.
 */

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

initializeApp();

function argValue(name: string): string | undefined {
  const prefix = `--${name}=`;
  const arg = process.argv.find((a) => a.startsWith(prefix));
  return arg?.slice(prefix.length);
}

async function main() {
  const uid = argValue("uid");
  const apply = process.argv.includes("--apply");

  if (!uid) {
    console.error("Usage: node lib/scripts/deleteTestAccount.js --uid=<uid> [--apply]");
    process.exit(1);
  }

  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    console.log(`No users/${uid} doc found. Checking Auth record only.`);
  }

  const userData = userSnap.data() ?? {};
  const managedBuildings = (userData.managed_buildings as string[] | undefined) ?? [];

  if (managedBuildings.length > 0) {
    console.log(
      `This account administers ${managedBuildings.length} building(s): ${managedBuildings.join(", ")}\n` +
        `Stopping — deleting it would leave those buildings without an admin and ` +
        `affect their other residents. Handle those separately first, then re-run.`
    );
    return;
  }

  const householdId = userData.household_id as string | undefined;
  const isHead = userData.isHouseholdHead as boolean | undefined;
  const linkedUuid = userData.linked_uuid as string | undefined;
  const email = userData.email as string | undefined;
  const displayName = userData.displayName as string | undefined;

  console.log(`Target: ${uid}${displayName ? ` (${displayName})` : ""}${email ? ` <${email}>` : ""}`);
  console.log(`  linked_uuid: ${linkedUuid ?? "(none)"}`);
  console.log(`  household_id: ${householdId ?? "(none)"}${isHead ? " (head)" : ""}`);

  const [bookingsSnap, joinRequestsSnap] = await Promise.all([
    db.collection("bookings").where("user_id", "==", uid).get(),
    db.collection("join_requests").where("uid", "==", uid).get(),
  ]);

  console.log(`  bookings to delete: ${bookingsSnap.size}`);
  console.log(`  join_requests to delete: ${joinRequestsSnap.size}`);

  let authExists = true;
  try {
    await getAuth().getUser(uid);
  } catch {
    authExists = false;
  }
  console.log(`  Firebase Auth record: ${authExists ? "exists" : "not found"}`);

  if (!apply) {
    console.log("\nDry run only — no changes made. Re-run with --apply to delete everything above.");
    return;
  }

  if (householdId) {
    const householdRef = db.collection("households").doc(householdId);
    const householdSnap = await householdRef.get();
    if (householdSnap.exists) {
      const members = (householdSnap.data()?.members as string[] | undefined) ?? [];
      const remaining = members.filter((m) => m !== uid);
      if (remaining.length === 0) {
        await householdRef.delete();
        console.log("Deleted household (no other members).");
      } else if (isHead) {
        const newHead = remaining[0];
        await householdRef.update({ members: remaining, head_uid: newHead });
        await db.collection("users").doc(newHead).update({ isHouseholdHead: true });
        console.log(`Reassigned household headship to ${newHead}.`);
      } else {
        await householdRef.update({ members: FieldValue.arrayRemove(uid) });
        console.log("Removed from household members.");
      }
    }
  }

  await Promise.all(bookingsSnap.docs.map((doc) => doc.ref.delete()));
  console.log(`Deleted ${bookingsSnap.size} booking(s).`);

  await Promise.all(joinRequestsSnap.docs.map((doc) => doc.ref.delete()));
  console.log(`Deleted ${joinRequestsSnap.size} join_requests doc(s).`);

  await db.collection("email_verification_codes").doc(uid).delete();

  if (userSnap.exists) {
    await userRef.delete();
    console.log("Deleted users doc.");
  }

  if (authExists) {
    await getAuth().deleteUser(uid);
    console.log("Deleted Firebase Auth record.");
  }

  console.log("\nDone — account fully wiped.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
