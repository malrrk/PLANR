const {before, test} = require('node:test');
const assert = require('node:assert/strict');

const projectId = 'demo-planr';
const host = process.env.FIRESTORE_EMULATOR_HOST;
const documents = `http://${host}/v1/projects/${projectId}/databases/(default)/documents`;
const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
const token = `${encode({alg: 'none', typ: 'JWT'})}.${encode({
  iss: `https://securetoken.google.com/${projectId}`,
  aud: projectId,
  sub: 'viewer',
  user_id: 'viewer',
  iat: 1760000000,
  exp: 2000000000,
})}.`;

async function seed(path, fields) {
  const response = await fetch(`${documents}/${path}`, {
    method: 'PATCH',
    headers: {'Authorization': 'Bearer owner', 'Content-Type': 'application/json'},
    body: JSON.stringify({fields}),
  });
  assert.equal(response.status, 200);
}

async function read(path) {
  return fetch(`${documents}/${path}`, {
    headers: {'Authorization': `Bearer ${token}`},
  });
}

before(async () => {
  assert.ok(host, 'Run this test against the Firestore emulator.');
  await seed('users/legacy', {
    uid: {stringValue: 'legacy'},
    email: {stringValue: 'private@example.invalid'},
  });
  await seed('users/safe', {uid: {stringValue: 'safe'}});
  await seed('users/legacy/friends/other', {
    uid: {stringValue: 'other'},
    email: {stringValue: 'private@example.invalid'},
  });
  await seed('users/safe/friends/other', {uid: {stringValue: 'other'}});
});

test('a signed-in non-owner cannot read a legacy profile containing email', async () => {
  assert.equal((await read('users/legacy')).status, 403);
});

test('a signed-in user can read a profile without email', async () => {
  assert.equal((await read('users/safe')).status, 200);
});

test('a signed-in non-owner cannot read a legacy friendship containing email', async () => {
  assert.equal((await read('users/legacy/friends/other')).status, 403);
});

test('a signed-in user can read a friendship without email', async () => {
  assert.equal((await read('users/safe/friends/other')).status, 200);
});

test('a profile collection query cannot expose a legacy email', async () => {
  const response = await read('users');
  if (response.status === 200) {
    assert.doesNotMatch(await response.text(), /private@example\.invalid/);
  } else {
    assert.equal(response.status, 403);
  }
});

test('a friendship collection query cannot expose a legacy email', async () => {
  const response = await read('users/legacy/friends');
  if (response.status === 200) {
    assert.doesNotMatch(await response.text(), /private@example\.invalid/);
  } else {
    assert.equal(response.status, 403);
  }
});

test('a signed-in user cannot create a public profile containing email', async () => {
  const response = await fetch(`${documents}/users/viewer`, {
    method: 'PATCH',
    headers: {'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json'},
    body: JSON.stringify({fields: {
      uid: {stringValue: 'viewer'},
      displayName: {stringValue: 'Viewer'},
      username: {stringValue: 'viewer'},
      email: {stringValue: 'private@example.invalid'},
    }}),
  });
  assert.equal(response.status, 403);
});