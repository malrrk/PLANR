const {before, test} = require('node:test');
const assert = require('node:assert/strict');
const {createRequire} = require('node:module');

const projectId = 'demo-planr';
const backendRequire = createRequire(require.resolve('../functions/package.json'));
const {getFirestore} = backendRequire('firebase-admin/firestore');

process.env.GCLOUD_PROJECT = projectId;
const {acceptFriendRequest} = require('../functions/lib/index.js');
const firestore = getFirestore();

before(async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run this test against the Firestore emulator.');
});

test('friend acceptance does not retain emails in friendship documents', async () => {
  await firestore.doc('users/requester').set({
    uid: 'requester', displayName: 'Requester', username: 'requester', email: 'requester@example.invalid',
  });
  await firestore.doc('users/receiver').set({
    uid: 'receiver', displayName: 'Receiver', username: 'receiver', email: 'receiver@example.invalid',
  });
  await firestore.doc('friend_requests/requester_receiver').set({
    fromUid: 'requester', toUid: 'receiver', status: 'pending',
  });
  await firestore.doc('users/requester/friends/receiver').set({
    uid: 'receiver', email: 'old@example.invalid',
  });

  await acceptFriendRequest.run({
    auth: {uid: 'receiver'},
    data: {requestId: 'requester_receiver'},
  });

  for (const path of ['users/requester/friends/receiver', 'users/receiver/friends/requester']) {
    const data = (await firestore.doc(path).get()).data();
    assert.ok(data);
    assert.equal(Object.hasOwn(data, 'email'), false);
  }
});

test('cleanup defaults to dry-run and removes public emails only when applied', async () => {
  const {cleanupPublicEmails} = require('../functions/lib/cleanup_public_emails.js');
  const records = [
    'usernames/cleanup_user',
    'users/cleanup_user',
    'users/cleanup_user/friends/cleanup_friend',
  ];
  for (const path of records) {
    await firestore.doc(path).set({email: 'private@example.invalid', displayName: 'Keep me'});
  }
  await firestore.doc('release_security/public_data').set({emailsRemoved: false});

  await cleanupPublicEmails(firestore);
  for (const path of records) {
    assert.equal((await firestore.doc(path).get()).get('email'), 'private@example.invalid');
  }

  await cleanupPublicEmails(firestore, {apply: true});
  await cleanupPublicEmails(firestore, {apply: true});
  for (const path of records) {
    const data = (await firestore.doc(path).get()).data();
    assert.equal(Object.hasOwn(data, 'email'), false);
    assert.equal(data.displayName, 'Keep me');
  }
  assert.equal((await firestore.doc('release_security/public_data').get()).get('emailsRemoved'), false);
});