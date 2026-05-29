const apiBaseUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:8088';
const projectId = process.env.FIRESTORE_PROJECT_ID ?? 'demo-calendar';
const firestoreBaseUrl =
  process.env.FIRESTORE_EMULATOR_REST_URL ??
  `http://127.0.0.1:8085/v1/projects/${projectId}/databases/(default)/documents`;

const runId = Date.now();
const userA = `qa-user-a-${runId}`;
const userB = `qa-user-b-${runId}`;
const userC = `qa-user-c-${runId}`;
const created = {
  coupleId: undefined,
  inviteCode: undefined,
  personalEventId: undefined,
  sharedEventId: undefined,
  dateRecordId: undefined,
  reviewId: undefined,
  todoCategoryId: undefined,
  todoItemId: undefined,
  todoCompletionId: undefined,
};

try {
  await apiJson('/healthz');

  const couple = await apiJson('/v1/couples', {
    method: 'POST',
    body: { userId: userA, partnerName: 'QA Partner' },
  });
  created.coupleId = couple.id;
  created.inviteCode = couple.inviteCode;

  const joined = await apiJson('/v1/couples/join', {
    method: 'POST',
    body: { userId: userB, inviteCode: couple.inviteCode },
  });
  assertEqual(joined.id, couple.id, 'partner joined same couple');

  const personalEvent = await apiJson(`/v1/couples/${couple.id}/events`, {
    method: 'POST',
    body: eventBody({
      userId: userA,
      title: 'QA A Personal Event',
      ownership: 'personal',
      startAt: '2026-05-23T10:00:00.000Z',
      endAt: '2026-05-23T12:00:00.000Z',
    }),
  });
  created.personalEventId = personalEvent.id;
  assertEqual(personalEvent.ownerUserId, userA, 'personal event owner');

  const sharedEvent = await apiJson(`/v1/couples/${couple.id}/events`, {
    method: 'POST',
    body: eventBody({
      userId: userA,
      title: 'QA Shared Event',
      ownership: 'shared',
      startAt: '2026-05-24T10:00:00.000Z',
      endAt: '2026-05-24T12:00:00.000Z',
    }),
  });
  created.sharedEventId = sharedEvent.id;

  const events = await apiJson(
    `/v1/couples/${couple.id}/events?startAt=2026-05-01T00:00:00.000Z&endAt=2026-06-01T00:00:00.000Z`,
    { userId: userB },
  );
  assertEqual(events.length >= 2, true, 'couple calendar visibility');

  await expectApiError(
    `/v1/couples/${couple.id}/events/${personalEvent.id}`,
    {
      method: 'PUT',
      body: updateBody(personalEvent, {
        userId: userB,
        title: 'QA B Should Not Rename This',
      }),
    },
    403,
    'partner cannot edit personal event',
  );

  const watched = await apiJson(`/v1/couples/${couple.id}/events/${personalEvent.id}`, {
    method: 'PUT',
    body: updateBody(personalEvent, {
      userId: userB,
      watcherUserIds: [userB],
    }),
  });
  assertEqual(watched.watcherUserIds.includes(userB), true, 'partner can watch personal event');

  await expectApiError(
    `/v1/couples/${couple.id}/events/${personalEvent.id}`,
    { method: 'DELETE', userId: userB },
    403,
    'partner cannot delete personal event',
  );

  const updatedShared = await apiJson(`/v1/couples/${couple.id}/events/${sharedEvent.id}`, {
    method: 'PUT',
    body: updateBody(sharedEvent, {
      userId: userB,
      title: 'QA Shared Event Updated By B',
    }),
  });
  assertEqual(updatedShared.title, 'QA Shared Event Updated By B', 'partner can edit shared event');

  await expectApiError(
    `/v1/couples/${couple.id}/links/date-records/ensure-for-event`,
    { method: 'POST', userId: userC, body: { eventId: sharedEvent.id } },
    403,
    'non-member cannot create date record link',
  );

  const ensured = await apiJson(
    `/v1/couples/${couple.id}/links/date-records/ensure-for-event`,
    { method: 'POST', userId: userB, body: { eventId: sharedEvent.id } },
  );
  created.dateRecordId = ensured.recordId;
  assertEqual(ensured.record.linkedEventId, sharedEvent.id, 'partner can link shared event to date record');

  const dateEvent = await findEvent(couple.id, sharedEvent.id, userA);
  assertEqual(dateEvent.kind, 'date', 'date record link changes event kind to date');
  assertEqual(
    hasLinkedItem(dateEvent.linkedItems, 'dateRecord', ensured.recordId),
    true,
    'calendar event shows linked date record',
  );

  const category = await apiJson(`/v1/couples/${couple.id}/todos/categories`, {
    method: 'POST',
    userId: userA,
    body: { draft: { title: 'QA Bucket', emoji: '⛰️' } },
  });
  created.todoCategoryId = category.id;

  const item = await apiJson(`/v1/couples/${couple.id}/todos/items`, {
    method: 'POST',
    userId: userA,
    body: {
      draft: {
        categoryId: category.id,
        title: 'QA Bucket Item',
        note: 'two-user qa',
      },
    },
  });
  created.todoItemId = item.id;

  const completion = await apiJson(
    `/v1/couples/${couple.id}/links/todo-completions`,
    { method: 'POST', userId: userB, body: { itemId: item.id, eventId: sharedEvent.id } },
  );
  created.todoCompletionId = completion.completion.id;
  assertEqual(completion.dateRecordId, ensured.recordId, 'bucket completion links through date record');

  const recordWithTodo = await findDateRecord(couple.id, ensured.recordId, userA);
  assertEqual(
    hasLinkedItem(recordWithTodo.linkedItems, 'todo', completion.completion.id),
    true,
    'date record shows linked bucket completion',
  );

  const review = await apiJson(`/v1/couples/${couple.id}/reviews`, {
    method: 'POST',
    userId: userA,
    body: {
      draft: {
        type: 'movie',
        title: 'QA Review',
        rating: 4.5,
        memo: 'two-user qa',
        photos: [],
      },
    },
  });
  created.reviewId = review.id;

  const reviewLink = await apiJson(
    `/v1/couples/${couple.id}/links/reviews/${review.id}/date-record`,
    { method: 'POST', userId: userB, body: { recordId: ensured.recordId } },
  );
  assertEqual(reviewLink.review.dateRecordId, ensured.recordId, 'partner can link review to date record');
  assertEqual(
    hasLinkedItem(reviewLink.record.linkedItems, 'review', review.id),
    true,
    'date record shows linked review',
  );

  const reviewUnlink = await apiJson(
    `/v1/couples/${couple.id}/links/reviews/${review.id}/date-record/${ensured.recordId}`,
    { method: 'DELETE', userId: userA },
  );
  assertEqual(reviewUnlink.review.dateRecordId ?? null, null, 'owner can unlink review from date record');
  assertEqual(
    hasLinkedItem(reviewUnlink.record.linkedItems, 'review', review.id),
    false,
    'date record removes unlinked review',
  );

  await apiJson(`/v1/couples/${couple.id}/links/todo-completions/${completion.completion.id}`, {
    method: 'DELETE',
    userId: userB,
  });
  created.todoCompletionId = undefined;

  const todosAfterUnlink = await apiJson(`/v1/couples/${couple.id}/todos`, { userId: userA });
  assertEqual(todosAfterUnlink.completions.length, 0, 'bucket completion unlink removes completion');

  const recordWithoutTodo = await findDateRecord(couple.id, ensured.recordId, userA);
  assertEqual(
    hasLinkedItem(recordWithoutTodo.linkedItems, 'todo', completion.completion.id),
    false,
    'date record removes unlinked bucket completion',
  );

  const dateUnlink = await apiJson(
    `/v1/couples/${couple.id}/links/date-records/${ensured.recordId}/calendar-event/${sharedEvent.id}`,
    { method: 'DELETE', userId: userB },
  );
  assertEqual(dateUnlink.record.linkedEventId ?? null, null, 'partner can unlink date record from shared event');

  const eventAfterUnlink = await findEvent(couple.id, sharedEvent.id, userA);
  assertEqual(
    hasLinkedItem(eventAfterUnlink.linkedItems, 'dateRecord', ensured.recordId),
    false,
    'calendar event removes unlinked date record',
  );

  await apiJson(`/v1/couples/${couple.id}/events/${sharedEvent.id}`, {
    method: 'DELETE',
    userId: userB,
  });
  created.sharedEventId = undefined;

  await expectApiError(
    `/v1/couples/${couple.id}/events?startAt=2026-05-01T00:00:00.000Z&endAt=2026-06-01T00:00:00.000Z&userId=${userC}`,
    { method: 'GET', userId: userC },
    403,
    'non-member cannot read couple calendar',
  );
  await expectApiError(
    `/v1/couples/${couple.id}/date-records?userId=${userC}`,
    { method: 'GET', userId: userC },
    403,
    'non-member cannot read date records',
  );
  await expectApiError(
    `/v1/couples/${couple.id}/todos?userId=${userC}`,
    { method: 'GET', userId: userC },
    403,
    'non-member cannot read bucket list',
  );
  await expectApiError(
    `/v1/couples/${couple.id}/reviews?userId=${userC}`,
    { method: 'GET', userId: userC },
    403,
    'non-member cannot read reviews',
  );
  await expectApiError(
    `/v1/couples/${couple.id}/anniversaries?userId=${userC}`,
    { method: 'GET', userId: userC },
    403,
    'non-member cannot read anniversaries',
  );

  console.log('Two-user QA smoke test passed');
} finally {
  await cleanup();
}

function eventBody({
  userId,
  title,
  ownership,
  startAt,
  endAt,
  watcherUserIds = [],
}) {
  return {
    userId,
    title,
    startAt,
    endAt,
    isAllDay: false,
    memo: 'two-user qa smoke test',
    kind: 'schedule',
    colorValue: 4283268234,
    ownership,
    watcherUserIds,
    linkedItems: [],
  };
}

function updateBody(event, overrides = {}) {
  return {
    userId: overrides.userId,
    title: overrides.title ?? event.title,
    startAt: event.startAt,
    endAt: event.endAt,
    isAllDay: event.isAllDay,
    memo: event.memo,
    kind: event.kind,
    colorValue: event.colorValue,
    ownership: event.ownership,
    watcherUserIds: overrides.watcherUserIds ?? event.watcherUserIds ?? [],
    linkedItems: event.linkedItems ?? [],
  };
}

async function apiJson(path, options = {}) {
  const requestUserId = options.userId ?? options.body?.userId ?? userA;
  const response = await fetch(`${apiBaseUrl}${path}`, {
    method: options.method ?? 'GET',
    headers: { 'content-type': 'application/json', 'x-dev-user-id': requestUserId },
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${options.method ?? 'GET'} ${path} failed with ${response.status}: ${text}`);
  }
  return text.length === 0 ? null : JSON.parse(text);
}

async function expectApiError(path, options, expectedStatus, label) {
  const requestUserId = options.userId ?? options.body?.userId ?? userA;
  const response = await fetch(`${apiBaseUrl}${path}`, {
    method: options.method ?? 'GET',
    headers: { 'content-type': 'application/json', 'x-dev-user-id': requestUserId },
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  if (response.status !== expectedStatus) {
    throw new Error(`${label}: expected ${expectedStatus}, got ${response.status}: ${await response.text()}`);
  }
}

async function findEvent(coupleId, eventId, userId) {
  const events = await apiJson(
    `/v1/couples/${coupleId}/events?startAt=2026-05-01T00:00:00.000Z&endAt=2026-06-01T00:00:00.000Z`,
    { userId },
  );
  const event = events.find((candidate) => candidate.id === eventId);
  if (!event) {
    throw new Error(`event ${eventId} not found`);
  }
  return event;
}

async function findDateRecord(coupleId, recordId, userId) {
  const records = await apiJson(`/v1/couples/${coupleId}/date-records`, { userId });
  const record = records.find((candidate) => candidate.id === recordId);
  if (!record) {
    throw new Error(`date record ${recordId} not found`);
  }
  return record;
}

function hasLinkedItem(items, type, targetId) {
  return (items ?? []).some((item) => item.type === type && item.targetId === targetId);
}

async function cleanup() {
  if (!created.coupleId) {
    return;
  }
  await ignoreFailure(
    apiJson(`/v1/couples/${created.coupleId}/events/${created.personalEventId}?userId=${userA}`, {
      method: 'DELETE',
    }),
  );
  await ignoreFailure(
    apiJson(`/v1/couples/${created.coupleId}/events/${created.sharedEventId}?userId=${userA}`, {
      method: 'DELETE',
    }),
  );
  await ignoreFailure(
    apiJson(`/v1/couples/${created.coupleId}/links/reviews/${created.reviewId}?userId=${userA}`, {
      method: 'DELETE',
    }),
  );
  await ignoreFailure(
    apiJson(`/v1/couples/${created.coupleId}/links/todo-completions/${created.todoCompletionId}?userId=${userA}`, {
      method: 'DELETE',
    }),
  );
  await ignoreFailure(
    apiJson(`/v1/couples/${created.coupleId}/links/date-records/${created.dateRecordId}?userId=${userA}`, {
      method: 'DELETE',
    }),
  );
  await ignoreFailure(apiJson('/v1/couples/current', { method: 'DELETE', userId: userA }));
  await ignoreFailure(apiJson('/v1/couples/current', { method: 'DELETE', userId: userB }));

  const paths = [
    `couples/${created.coupleId}/todoCategories/${created.todoCategoryId}`,
    `couples/${created.coupleId}/todoItems/${created.todoItemId}`,
    `couples/${created.coupleId}/todoCompletions/${created.todoCompletionId}`,
    `couples/${created.coupleId}/reviews/${created.reviewId}`,
    `couples/${created.coupleId}/dateRecords/${created.dateRecordId}`,
    `couples/${created.coupleId}/events/${created.personalEventId}`,
    `couples/${created.coupleId}/events/${created.sharedEventId}`,
    `couples/${created.coupleId}/members/${userA}`,
    `couples/${created.coupleId}/members/${userB}`,
    `coupleInvites/${created.inviteCode}`,
    `couples/${created.coupleId}`,
  ];
  for (const path of paths.filter((path) => !path.includes('undefined'))) {
    await ignoreFailure(deleteFirestoreDocument(path));
  }
}

async function deleteFirestoreDocument(path) {
  const response = await fetch(`${firestoreBaseUrl}/${path}`, { method: 'DELETE' });
  if (!response.ok && response.status !== 404) {
    throw new Error(`delete ${path} failed with ${response.status}: ${await response.text()}`);
  }
}

async function ignoreFailure(promise) {
  try {
    await promise;
  } catch (_) {
    // Cleanup is best-effort; the assertion failure should stay focused on the
    // behavior under test.
  }
}

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${expected}, got ${actual}`);
  }
}
