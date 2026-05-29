const projectId = 'demo-calendar';
const authBaseUrl = 'http://127.0.0.1:9099';
const firestoreBaseUrl =
  `http://127.0.0.1:8085/v1/projects/${projectId}/databases/(default)/documents`;

const coupleId = `couple-${Date.now()}`;
const eventId = `event-${Date.now()}`;
const inviteCode = `LOVE${Date.now()}`;

const owner = await signUp();
await createCouple({
  coupleId,
  inviteCode,
  userId: owner.localId,
  idToken: owner.idToken,
});
await createMember({
  coupleId,
  userId: owner.localId,
  role: 'owner',
  idToken: owner.idToken,
});
await createInvite({
  inviteCode,
  coupleId,
  userId: owner.localId,
  idToken: owner.idToken,
});

const eventPath = `couples/${coupleId}/events/${eventId}`;
await writeDocument({
  path: eventPath,
  idToken: owner.idToken,
  fields: {
    coupleId,
    title: '남산 데이트',
    startAt: new Date('2026-05-18T10:00:00.000Z'),
    endAt: new Date('2026-05-18T13:00:00.000Z'),
    rangeStartAt: new Date('2026-05-18T10:00:00.000Z'),
    rangeEndAt: new Date('2026-05-18T13:00:00.000Z'),
    isAllDay: false,
    memo: 'emulator smoke test',
    kind: 'date',
    colorValue: 16744576,
    ownership: 'shared',
    ownerUserId: owner.localId,
    watcherUserIds: [],
    photos: [],
    reminders: [],
    linkedItems: [],
    createdBy: owner.localId,
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
  },
});

const savedEvent = await readDocument({
  path: eventPath,
  idToken: owner.idToken,
});
assertEqual(savedEvent.fields.title.stringValue, '남산 데이트');

const outsider = await signUp();
await expectForbidden(
  readDocument({ path: eventPath, idToken: outsider.idToken }),
  'non-member event read',
);

await createMember({
  coupleId,
  userId: outsider.localId,
  role: 'member',
  idToken: outsider.idToken,
});
await patchDocument({
  path: `couples/${coupleId}`,
  idToken: outsider.idToken,
  fields: {
    memberIds: [owner.localId, outsider.localId],
    updatedAt: new Date(),
  },
  updateMask: ['memberIds', 'updatedAt'],
});
const outsiderRead = await readDocument({
  path: eventPath,
  idToken: outsider.idToken,
});
assertEqual(outsiderRead.fields.kind.stringValue, 'date');

console.log('Firebase emulator smoke test passed');

async function signUp() {
  const response = await fetch(
    `${authBaseUrl}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ returnSecureToken: true }),
    },
  );
  return parseJsonResponse(response, 'anonymous sign up');
}

async function createCouple({ coupleId, inviteCode, userId, idToken }) {
  await writeDocument({
    path: `couples/${coupleId}`,
    idToken,
    fields: {
      memberIds: [userId],
      inviteCode,
      partnerDisplayName: '상대방',
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  });
}

async function createInvite({ inviteCode, coupleId, userId, idToken }) {
  await writeDocument({
    path: `coupleInvites/${inviteCode}`,
    idToken,
    fields: {
      coupleId,
      createdBy: userId,
      createdAt: new Date(),
      expiresAt: null,
      disabledAt: null,
    },
  });
}

async function createMember({ coupleId, userId, role, idToken }) {
  await writeDocument({
    path: `couples/${coupleId}/members/${userId}`,
    idToken,
    fields: {
      userId,
      role,
      createdAt: new Date(),
    },
  });
}

async function writeDocument({ path, idToken, fields }) {
  const response = await fetch(`${firestoreBaseUrl}/${path}`, {
    method: 'PATCH',
    headers: authHeaders(idToken),
    body: JSON.stringify({ fields: encodeFields(fields) }),
  });
  return parseJsonResponse(response, `write ${path}`);
}

async function patchDocument({ path, idToken, fields, updateMask }) {
  const mask = updateMask
    .map((fieldPath) => `updateMask.fieldPaths=${encodeURIComponent(fieldPath)}`)
    .join('&');
  const response = await fetch(`${firestoreBaseUrl}/${path}?${mask}`, {
    method: 'PATCH',
    headers: authHeaders(idToken),
    body: JSON.stringify({ fields: encodeFields(fields) }),
  });
  return parseJsonResponse(response, `patch ${path}`);
}

async function readDocument({ path, idToken }) {
  const response = await fetch(`${firestoreBaseUrl}/${path}`, {
    method: 'GET',
    headers: authHeaders(idToken),
  });
  return parseJsonResponse(response, `read ${path}`);
}

function authHeaders(idToken) {
  return {
    authorization: `Bearer ${idToken}`,
    'content-type': 'application/json',
  };
}

async function expectForbidden(promise, label) {
  try {
    await promise;
  } catch (error) {
    if (String(error.message).includes('403')) {
      return;
    }
    throw error;
  }
  throw new Error(`${label} should have been rejected`);
}

async function parseJsonResponse(response, label) {
  const text = await response.text();
  const payload = text.length > 0 ? JSON.parse(text) : {};
  if (!response.ok) {
    throw new Error(`${label} failed with ${response.status}: ${text}`);
  }
  return payload;
}

function encodeFields(fields) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, encodeValue(value)]),
  );
}

function encodeValue(value) {
  if (value === null) {
    return { nullValue: null };
  }
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encodeValue) } };
  }
  if (typeof value === 'boolean') {
    return { booleanValue: value };
  }
  if (typeof value === 'number' && Number.isInteger(value)) {
    return { integerValue: String(value) };
  }
  if (typeof value === 'number') {
    return { doubleValue: value };
  }
  if (typeof value === 'object') {
    return { mapValue: { fields: encodeFields(value) } };
  }
  return { stringValue: String(value) };
}

function assertEqual(actual, expected) {
  if (actual !== expected) {
    throw new Error(`Expected ${expected}, got ${actual}`);
  }
}
