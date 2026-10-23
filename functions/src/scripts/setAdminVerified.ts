/**
 * Marks a building admin as verified (or takes it back with --revoke).
 * Verified admins can manage any number of buildings and see residents'
 * contact details; self-declared ones are limited to one building and
 * names only (see buildings.ts).
 *
 * Sets `adminVerified` on the user and mirrors it as `admin_verified` on
 * every building they manage, which is what residents see.
 *
 * Usage (from functions/):
 *   npm run build
 *   node lib/scripts/setAdminVerified.js <uid>            # dry run, no writes
 *   node lib/scripts/setAdminVerified.js <uid> --apply
 *   node lib/scripts/setAdminVerified.js <uid> --revoke --apply
 *
 * Needs Application Default Credentials for the target Firebase project —
 * e.g. run `gcloud auth application-default login` first, or set
 * GOOGLE_APPLICATION_CREDENTIALS to a service account key with Firestore
 * access.
 */

import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();

async function main() {
  const uid = process.argv[2];
  const apply = process.argv.includes("--apply");
  const verified = !process.argv.includes("--revoke");
  if (!uid || uid.startsWith("--")) {
    console.error("Usage: node lib/scripts/setAdminVerified.js <uid> [--revoke] [--apply]");
    process.exit(1);
  }

  const db = getFirestore();
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    console.error(`No user ${uid}`);
    process.exit(1);
  }
  const user = userSnap.data()!;
  if (user.role !== "admin") {
    console.error(`User ${uid} is not an admin (role: ${user.role})`);
    process.exit(1);
  }

  const managed = (user.managed_buildings as string[] | undefined) ?? [];
  console.log(
    `${user.displayName ?? uid} <${user.email}>: adminVerified -> ${verified}, ` +
      `${managed.length} building(s)`
  );
  if (!apply) {
    console.log("Dry run. Re-run with --apply to write.");
    return;
  }

  const batch = db.batch();
  batch.update(userRef, { adminVerified: verified });
  for (const buildingId of managed) {
    batch.update(db.collection("buildings").doc(buildingId), {
      admin_verified: verified,
    });
  }
  await batch.commit();
  console.log("Done.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
