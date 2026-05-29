const apiBaseUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:8088';
const firestoreBaseUrl =
  process.env.FIRESTORE_EMULATOR_REST_URL ??
  'http://127.0.0.1:8085/v1/projects/demo-calendar/databases/(default)/documents';
const firestoreProjectId = process.env.FIRESTORE_PROJECT_ID ?? 'demo-calendar';
const userId = process.env.LOCAL_DEMO_USER_ID ?? 'demo-user-1';
const partnerId = process.env.LOCAL_DEMO_PARTNER_ID ?? 'local-partner';
const mode = process.argv[2] ?? 'seed';

if (!['seed', 'cleanup'].includes(mode)) {
  console.error('Usage: node tool/local_demo_data.mjs <seed|cleanup>');
  process.exit(1);
}

await waitForApi();

if (mode === 'cleanup') {
  await cleanup();
  console.log('Local demo data cleaned');
} else {
  await seed();
  console.log('Local demo data seeded');
}

async function seed() {
  await cleanup();

  const couple = await apiJson('/v1/couples', {
    method: 'POST',
    userId,
    body: { partnerName: '파트너' },
  });

  await apiJson('/v1/couples/join', {
    method: 'POST',
    userId: partnerId,
    body: { inviteCode: couple.inviteCode },
  });

  const picnic = await apiJson(`/v1/couples/${couple.id}/events`, {
    method: 'POST',
    userId,
    body: eventBody({
      title: '한강 피크닉',
      startAt: '2026-05-23T05:00:00.000Z',
      endAt: '2026-05-23T08:00:00.000Z',
      memo: '돗자리, 과일, 와인 챙기기',
      kind: 'schedule',
      ownership: 'shared',
      colorValue: 4291918692,
    }),
  });

  await apiJson(`/v1/couples/${couple.id}/events`, {
    method: 'POST',
    userId,
    body: eventBody({
      title: '출장',
      startAt: '2026-05-27T00:00:00.000Z',
      endAt: '2026-05-30T00:00:00.000Z',
      memo: '3일짜리 내 일정 샘플',
      kind: 'schedule',
      ownership: 'personal',
      colorValue: 4286611584,
    }),
  });

  await apiJson(`/v1/couples/${couple.id}/events`, {
    method: 'POST',
    userId: partnerId,
    body: eventBody({
      title: '파트너 저녁 약속',
      startAt: '2026-05-25T10:30:00.000Z',
      endAt: '2026-05-25T12:00:00.000Z',
      memo: '상대 일정 샘플',
      kind: 'schedule',
      ownership: 'personal',
      colorValue: 4283215696,
    }),
  });

  await apiJson(`/v1/couples/${couple.id}/events`, {
    method: 'POST',
    userId,
    body: eventBody({
      title: '주말 여행',
      startAt: '2026-06-06T00:00:00.000Z',
      endAt: '2026-06-08T00:00:00.000Z',
      memo: '여러 날 이어지는 우리 일정',
      kind: 'schedule',
      ownership: 'shared',
      colorValue: 4283268234,
    }),
  });

  const dateRecordResult = await apiJson(
    `/v1/couples/${couple.id}/links/date-records/ensure-for-event`,
    { method: 'POST', userId, body: { eventId: picnic.id } },
  );

  const category = await apiJson(`/v1/couples/${couple.id}/todos/categories`, {
    method: 'POST',
    userId,
    body: { draft: { title: '등산하기', emoji: '⛰️' } },
  });

  const item = await apiJson(`/v1/couples/${couple.id}/todos/items`, {
    method: 'POST',
    userId,
    body: {
      draft: {
        categoryId: category.id,
        title: '남산 가기',
        note: '야경 보는 코스로 다시 가보기',
      },
    },
  });

  await apiJson(`/v1/couples/${couple.id}/links/todo-completions`, {
    method: 'POST',
    userId,
    body: { itemId: item.id, eventId: picnic.id },
  });

  const review = await apiJson(`/v1/couples/${couple.id}/reviews`, {
    method: 'POST',
    userId,
    body: {
      draft: {
        type: 'movie',
        title: 'Before Sunrise',
        rating: 4.5,
        memo: '대화가 오래 남는 영화. 다음에는 Before Sunset 보기.',
        photos: [{ id: 'demo-review-photo-1', label: '포스터 느낌의 사진 메모' }],
      },
    },
  });

  await apiJson(
    `/v1/couples/${couple.id}/links/reviews/${review.id}/date-record`,
    {
      method: 'POST',
      userId,
      body: { recordId: dateRecordResult.recordId },
    },
  );

  await apiJson(`/v1/couples/${couple.id}/anniversaries`, {
    method: 'POST',
    userId,
    body: {
      draft: {
        title: '처음 만난 날',
        baseDate: '2024-02-14T00:00:00.000Z',
        repeatRule: 'hundredDaysAndYearly',
        calendarType: 'solar',
        isLeapMonth: false,
      },
    },
  });

  await apiJson(`/v1/couples/${couple.id}/anniversaries`, {
    method: 'POST',
    userId,
    body: {
      draft: {
        title: '어머니 생신',
        baseDate: '1966-03-23T00:00:00.000Z',
        repeatRule: 'yearly',
        calendarType: 'lunar',
        isLeapMonth: false,
      },
    },
  });
}

async function cleanup() {
  const response = await fetch(
    `${firestoreEmulatorOrigin()}/emulator/v1/projects/${firestoreProjectId}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`clear Firestore emulator failed with ${response.status}: ${text}`);
  }
}

async function apiJson(path, options = {}) {
  const requestUserId = options.userId ?? userId;
  const response = await fetch(`${apiBaseUrl}${path}`, {
    method: options.method ?? 'GET',
    headers: {
      'content-type': 'application/json',
      'x-dev-user-id': requestUserId,
    },
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${options.method ?? 'GET'} ${path} failed with ${response.status}: ${text}`);
  }
  return text.length === 0 ? null : JSON.parse(text);
}

async function waitForApi() {
  const deadline = Date.now() + 30_000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`${apiBaseUrl}/healthz`);
      if (response.ok) {
        return;
      }
    } catch (_) {
      // Keep polling until the API container is ready.
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`API did not become ready: ${apiBaseUrl}`);
}

function firestoreEmulatorOrigin() {
  return new URL(firestoreBaseUrl).origin;
}

function eventBody({
  title,
  startAt,
  endAt,
  memo,
  kind,
  ownership,
  colorValue,
}) {
  return {
    title,
    startAt,
    endAt,
    isAllDay: startAt.endsWith('T00:00:00.000Z') && endAt.endsWith('T00:00:00.000Z'),
    memo,
    kind,
    colorValue,
    ownership,
    watcherUserIds: [],
    linkedItems: [],
  };
}
