import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";

initializeApp();

const db = getFirestore();

export const acceptFriendRequest = onCall(async (request) => {
  const auth = request.auth;
  const data = request.data as {requestId?: string};

  if (!auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const requestId = data.requestId?.trim();

  if (!requestId) {
    throw new HttpsError("invalid-argument", "Missing requestId.");
  }

  const requestRef = db.collection("friend_requests").doc(requestId);
  const requestSnap = await requestRef.get();

  if (!requestSnap.exists) {
    throw new HttpsError("not-found", "Friend request not found.");
  }

  const friendRequest = requestSnap.data() as {
    fromUid?: string;
    toUid?: string;
    status?: string;
  };

  const fromUid = friendRequest.fromUid;
  const toUid = friendRequest.toUid;
  const status = friendRequest.status;

  if (!fromUid || !toUid) {
    throw new HttpsError("failed-precondition", "Invalid friend request.");
  }

  if (toUid !== auth.uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the receiving user can accept this request."
    );
  }

  if (status !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      "Friend request is no longer pending."
    );
  }

  const fromUserRef = db.collection("users").doc(fromUid);
  const toUserRef = db.collection("users").doc(toUid);

  const [fromUserSnap, toUserSnap] = await Promise.all([
    fromUserRef.get(),
    toUserRef.get(),
  ]);

  if (!fromUserSnap.exists || !toUserSnap.exists) {
    throw new HttpsError(
      "not-found",
      "One of the user profiles was not found."
    );
  }

  const fromUser = fromUserSnap.data() as Record<string, unknown>;
  const toUser = toUserSnap.data() as Record<string, unknown>;

  const batch = db.batch();

  batch.set(
    fromUserRef.collection("friends").doc(toUid),
    {
      uid: String(toUser.uid ?? toUid),
      displayName: String(toUser.displayName ?? "User"),
      username: String(toUser.username ?? "user"),
      usernameLower: String(
        toUser.usernameLower ??
          String(toUser.username ?? "user").toLowerCase()
      ),
      email: String(toUser.email ?? ""),
      photoUrl: toUser.photoUrl ?? null,
      bio: toUser.bio ?? null,
      createdAt: FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  batch.set(
    toUserRef.collection("friends").doc(fromUid),
    {
      uid: String(fromUser.uid ?? fromUid),
      displayName: String(fromUser.displayName ?? "User"),
      username: String(fromUser.username ?? "user"),
      usernameLower: String(
        fromUser.usernameLower ??
          String(fromUser.username ?? "user").toLowerCase()
      ),
      email: String(fromUser.email ?? ""),
      photoUrl: fromUser.photoUrl ?? null,
      bio: fromUser.bio ?? null,
      createdAt: FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  batch.update(requestRef, {
    status: "accepted",
    acceptedAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();

  return {
    success: true,
    fromUid,
    toUid,
  };
});
