const apiBaseUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:8088';
const projectId = process.env.FIRESTORE_PROJECT_ID ?? 'demo-calendar';
const firestoreBaseUrl =
  process.env.FIRESTORE_EMULATOR_REST_URL ??
  `http://127.0.0.1:8085/v1/projects/${projectId}/databases/(default)/documents`;

const userId = `api-smoke-${Date.now()}`;
const created = {
  coupleId: undefined,
  inviteCode: undefined,
  eventId: undefined,
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
    body: { userId, partnerName: 'Smoke Partner' },
  });
  created.coupleId = couple.id;
  created.inviteCode = couple.inviteCode;

  const event = await apiJson(`/v1/couples/${couple.id}/events`, {
    method: 'POST',
    body: {
      userId,
      title: 'Smoke Date',
      startAt: '2026-05-22T10:00:00.000Z',
      endAt: '2026-05-22T12:00:00.000Z',
      isAllDay: false,
      memo: 'api smoke test',
      kind: 'schedule',
      colorValue: 4283268234,
      ownership: 'shared',
      linkedItems: [],
    },
  });
  created.eventId = event.id;

  const ensured = await apiJson(
    `/v1/couples/${couple.id}/links/date-records/ensure-for-event`,
    { method: 'POST', body: { userId, eventId: event.id } },
  );
  created.dateRecordId = ensured.recordId;
  assertEqual(ensured.record.linkedEventId, event.id, 'date record event link');

  const category = await apiJson(`/v1/couples/${couple.id}/todos/categories`, {
    method: 'POST',
    body: { userId, draft: { title: 'Smoke Bucket', emoji: '✅' } },
  });
  created.todoCategoryId = category.id;

  const item = await apiJson(`/v1/couples/${couple.id}/todos/items`, {
    method: 'POST',
    body: {
      userId,
      draft: {
        categoryId: category.id,
        title: 'Smoke Bucket Item',
        note: 'temporary',
      },
    },
  });
  created.todoItemId = item.id;

  const completion = await apiJson(
    `/v1/couples/${couple.id}/links/todo-completions`,
    { method: 'POST', body: { userId, itemId: item.id, eventId: event.id } },
  );
  created.todoCompletionId = completion.completion.id;
  assertEqual(completion.dateRecordId, ensured.recordId, 'todo completion record link');

  const review = await apiJson(`/v1/couples/${couple.id}/reviews`, {
    method: 'POST',
    body: {
      userId,
      draft: {
        type: 'movie',
        title: 'Smoke Review',
        rating: 4,
        memo: 'temporary',
        photos: [],
      },
    },
  });
  created.reviewId = review.id;

  const reviewLink = await apiJson(
    `/v1/couples/${couple.id}/links/reviews/${review.id}/date-record`,
    { method: 'POST', body: { userId, recordId: ensured.recordId } },
  );
  assertEqual(reviewLink.review.dateRecordId, ensured.recordId, 'review record link');

  await apiJson(`/v1/couples/${couple.id}/links/date-records/${ensured.recordId}?userId=${userId}`, {
    method: 'DELETE',
  });

  const reviews = await apiJson(`/v1/couples/${couple.id}/reviews?userId=${userId}`);
  assertEqual(reviews[0]?.dateRecordId ?? null, null, 'review record unlink on date delete');

  const todos = await apiJson(`/v1/couples/${couple.id}/todos?userId=${userId}`);
  assertEqual(todos.completions.length, 0, 'todo completion delete on date delete');

  const events = await apiJson(
    `/v1/couples/${couple.id}/events?userId=${userId}&startAt=2026-05-01T00:00:00.000Z&endAt=2026-06-01T00:00:00.000Z`,
  );
  assertEqual(events[0]?.kind, 'schedule', 'event kind reset on date delete');
  assertEqual(events[0]?.linkedItems?.length, 0, 'event links cleared on date delete');

  await apiJson(`/v1/couples/${couple.id}/links/reviews/${review.id}?userId=${userId}`, {
    method: 'DELETE',
  });

  console.log('API smoke test passed');
} finally {
  await cleanup();
}

async function apiJson(path, options = {}) {
  const requestUserId = options.userId ?? options.body?.userId ?? userId;
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

async function cleanup() {
  if (!created.coupleId) {
    return;
  }
  await ignoreFailure(
    apiJson(`/v1/couples/${created.coupleId}/events/${created.eventId}?userId=${userId}`, {
      method: 'DELETE',
    }),
  );
  await ignoreFailure(apiJson(`/v1/couples/current?userId=${userId}`, { method: 'DELETE' }));

  const paths = [
    `couples/${created.coupleId}/todoCategories/${created.todoCategoryId}`,
    `couples/${created.coupleId}/todoItems/${created.todoItemId}`,
    `couples/${created.coupleId}/todoCompletions/${created.todoCompletionId}`,
    `couples/${created.coupleId}/reviews/${created.reviewId}`,
    `couples/${created.coupleId}/dateRecords/${created.dateRecordId}`,
    `couples/${created.coupleId}/events/${created.eventId}`,
    `couples/${created.coupleId}/members/${userId}`,
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
