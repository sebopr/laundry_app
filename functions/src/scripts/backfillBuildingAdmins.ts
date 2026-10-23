/**
 * One-off backfill for buildings created before createBuilding (buildings.ts)
 * existed: adds the `admin_uid`, `admin_name` and `admin_verified` fields
 * residents now see in Settings. The admin is the building's `created_by`
 * (see fixDuplicateBuildingAdmins for why that's the source of truth).
 *
 * Buildings that already have `admin_uid` are skipped. Buildings without
 * `created_by`, or whose creator no longer exists, are printed under
 * "needs manual review".
 *
 * Existing buildings get no EGID; their admins keep them as they are.
 *
 * Usage (from functions/):
 *   npm run build
 *   node lib/scripts/backfillBuildingAdmins.js            # dry run, no writes
 *   node lib/scripts/backfillBuildingAdmins.js --apply
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
  const apply = process.argv.includes("--apply");
  const db = getFirestore();

  const buildingsSnap = await db.collection("buildings").get();
  const review: string[] = [];
  let updated = 0;

  for (const doc of buildingsSnap.docs) {
    const data = doc.data();
    if (data.admin_uid) continue;

    const createdBy = data.created_by as string | undefined;
    const adminSnap = createdBy
      ? await db.collection("users").doc(createdBy).get()
      : null;
    if (!adminSnap?.exists) {
      review.push(`${doc.id} (${data.name ?? "unnamed"})`);
      continue;
    }

    const admin = adminSnap.data()!;
    const fields = {
      admin_uid: createdBy,
      admin_name: (admin.displayName as string | undefined) ?? "",
      admin_verified: admin.adminVerified === true,
    };
    console.log(`${doc.id} (${data.name ?? "unnamed"}) ->`, fields);
    if (apply) await doc.ref.update(fields);
    updated++;
  }

  console.log(`\n${updated} building(s) ${apply ? "updated" : "to update"}.`);
  if (review.length) {
    console.log("Needs manual review:");
    review.forEach((r) => console.log(`  ${r}`));
  }
  if (!apply) console.log("Dry run. Re-run with --apply to write.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
