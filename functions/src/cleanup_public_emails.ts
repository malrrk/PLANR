import {initializeApp} from "firebase-admin/app";
import {
  FieldPath,
  FieldValue,
  Firestore,
  getFirestore,
  Query,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";

export const cleanupPublicEmails = async (
  firestore: Firestore,
  options: {apply?: boolean} = {}
): Promise<{scanned: number; changed: number}> => {
  const sources: Query[] = [
    firestore.collection("usernames"),
    firestore.collection("users"),
    firestore.collectionGroup("friends"),
  ];
  let scanned = 0;
  let changed = 0;

  for (const source of sources) {
    let last: QueryDocumentSnapshot | undefined;
    let hasNextPage = true;
    while (hasNextPage) {
      let query = source.orderBy(FieldPath.documentId()).limit(250);
      if (last) query = query.startAfter(last);
      const page = await query.get();
      if (page.empty) break;

      const batch = firestore.batch();
      let batchSize = 0;
      for (const doc of page.docs) {
        const parts = doc.ref.path.split("/");
        const isPublicRecord = (parts.length === 2 &&
          (parts[0] === "users" || parts[0] === "usernames")) ||
          (parts.length === 4 && parts[0] === "users" &&
            parts[2] === "friends");
        if (!isPublicRecord) continue;
        scanned++;
        if (Object.prototype.hasOwnProperty.call(doc.data(), "email")) {
          changed++;
          if (options.apply) {
            batch.update(doc.ref, {email: FieldValue.delete()});
            batchSize++;
          }
        }
      }
      if (batchSize > 0) await batch.commit();
      last = page.docs[page.docs.length - 1];
      hasNextPage = page.size === 250;
    }
  }

  return {scanned, changed};
};

if (require.main === module) {
  const projectArgument = process.argv.slice(2)
    .find((arg) => arg.startsWith("--project="));
  const projectId = projectArgument?.slice("--project=".length);
  const apply = process.argv.includes("--apply");
  const invalidArguments = process.argv.slice(2).some(
    (arg) => arg !== projectArgument && arg !== "--apply"
  );

  if (!projectId || invalidArguments) {
    console.error(
      "Usage: node cleanup_public_emails.js --project=PROJECT_ID [--apply]"
    );
    process.exitCode = 1;
  } else {
    initializeApp({projectId});
    cleanupPublicEmails(getFirestore(), {apply})
      .then((result) => console.log(
        JSON.stringify({projectId, apply, ...result})
      ))
      .catch((error) => {
        console.error(error);
        process.exitCode = 1;
      });
  }
}
