/**
 * One-off cleanup for buildings that ended up with more than one admin
 * because of a since-fixed bug: an admin-resident scanning an EXISTING
 * building's QR code during onboarding used to add that building to their
 * own `managed_buildings` array instantly, alongside the real admin who
 * created it. That onboarding path now goes through the same join-request
 * approval flow as any other resident (see JoinRequestService), so no new
 * duplicates can form — this script only cleans up ones that already exist.
 *
 * For each building with more than one admin, the building's own
 * `created_by` field (set once, at creation, and never touched since) is
 * treated as the source of truth for who the real admin is. Every other
 * user who also has that building's uuid in their `managed_buildings` array
 * gets it removed — they keep their residency (linked_uuid, household,
 * etc.) untouched, they just stop being an admin of a building they didn't
 * create.
 *
 * Buildings where `created_by` isn't itself one of the admins found (e.g.
 * the creator removed themselves, or the field is missing) are left alone
 * and printed under "needs manual review" instead of guessed at.
 *
 * Usage (from functions/):
 *   npm run build
 *   node lib/scripts/fixDuplicateBuildingAdmins.js            # dry run, no writes
 *   node lib/scripts/fixDuplicateBuildingAdmins.js --apply    # actually fixes it
 *
 * Needs Application Default Credentials for the target Firebase project —
 * e.g. run `gcloud auth application-default login` first, or set
 * GOOGLE_APPLICATION_CREDENTIALS to a service account key with Firestore
 * access.
 */

import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

initializeApp();

async function main() {
  const apply = process.argv.includes("--apply");
  const db = getFirestore();

  const [buildingsSnap, usersSnap] = await Promise.all([
    db.collection("buildings").get(),
    db.collection("users").get(),
  ]);

  const createdByOf = new Map<string, string>();
  buildingsSnap.forEach((doc) => {
    const createdBy = doc.data().created_by as string | undefined;
    if (createdBy) createdByOf.set(doc.id, createdBy);
  });

  const adminsOf = new Map<string, string[]>();
  usersSnap.forEach((doc) => {
    const managed = doc.data().managed_buildings as string[] | undefined;
    if (!managed) return;
    for (const buildingUuid of managed) {
      const list = adminsOf.get(buildingUuid) ?? [];
      list.push(doc.id);
      adminsOf.set(buildingUuid, list);
    }
  });

  const duplicates = [...adminsOf.entries()].filter(
    ([, admins]) => admins.length > 1
  );

  if (duplicates.length === 0) {
    console.log("No buildings with more than one admin found. Nothing to do.");
    return;
  }

  console.log(
    `Found ${duplicates.length} building(s) with more than one admin.\n`
  );

  const needsManualReview: string[] = [];
  const fixes: { buildingUuid: string; keep: string; remove: string[] }[] = [];

  for (const [buildingUuid, admins] of duplicates) {
    const createdBy = createdByOf.get(buildingUuid);
    if (!createdBy || !admins.includes(createdBy)) {
      needsManualReview.push(buildingUuid);
      console.log(
        `⚠️  Building ${buildingUuid}: admins = [${admins.join(", ")}], ` +
          `created_by = ${createdBy ?? "(missing)"} — not among the admins found. ` +
          `Skipping; needs manual review.`
      );
      continue;
    }

    const remove = admins.filter((uid) => uid !== createdBy);
    fixes.push({ buildingUuid, keep: createdBy, remove });
    console.log(
      `Building ${buildingUuid}: keeping ${createdBy} (creator), ` +
        `removing admin rights from [${remove.join(", ")}]`
    );
  }

  console.log(
    `\n${fixes.length} building(s) will be fixed, ${needsManualReview.length} need manual review.`
  );

  if (!apply) {
    console.log("\nDry run only — no writes made. Re-run with --apply to fix.");
    return;
  }

  for (const { buildingUuid, remove } of fixes) {
    for (const uid of remove) {
      await db
        .collection("users")
        .doc(uid)
        .update({
          managed_buildings: FieldValue.arrayRemove(buildingUuid),
        });
      console.log(`Removed ${buildingUuid} from ${uid}'s managed_buildings.`);
    }
  }

  console.log("\nDone.");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
