# DDD and Repository Review

Last updated: 2026-05-17

This document is the handoff guide for continuing repository and service-layer
work in a fresh session.

## Current Verdict

The app is moving in the right direction, but it is not fully DDD-shaped yet.
The domain models are mostly Flutter/Firebase-free, and all current persistent
domains now have repository ports with mock implementations.

The biggest remaining gap is repository-backed transaction semantics. The first
application-service layer now exists for date-record linking and bucket
completion, but those services still call controllers internally. That is
acceptable for the prototype, but must be tightened before Firestore becomes the
real source of truth.

## Repository Coverage

Implemented repository ports:

- `CalendarEventRepository`
  - mock implementation exists
  - Firestore implementation exists
- `AuthRepository`
  - mock implementation exists
  - Firebase Auth implementation exists for current-user lookup
- `CoupleRepository`
  - mock implementation exists
  - local Firebase emulator implementation exists
  - Firestore implementation exists for current/create/join/reset flows
- `AnniversaryRepository`
  - mock implementation exists
  - Firestore implementation exists
- `TodoRepository`
  - mock implementation exists
  - Firestore implementation exists
- `DateRecordRepository`
  - mock implementation exists
  - Firestore implementation exists
- `ReviewRepository`
  - mock implementation exists
  - Firestore implementation exists
- `PhotoRepository`
  - mock placeholder implementation exists
  - Firebase Storage implementation is pending

Still presentation-level or incomplete:

- Auth/session still has only mock repository behavior.
- Couple creation/join still has only mock repository behavior.
- Notification/reminder delivery has no repository/service implementation yet.

## Findings

### P1: Cross-domain cleanup is not transaction-safe

`LinkedContentService`, `DateRecordService`, and `BucketCompletionService`
now perform writes through repositories and refresh controllers afterward.
This is closer to the target architecture, but still does not guarantee
consistency once Firestore is attached because multi-document writes are not yet
batched or transactional.

Risk:

- A completion can be removed from one record but remain linked elsewhere if
  one write fails.
- Cleanup only sees currently loaded controller state unless repositories expose
  query methods for linked content.

Required work:

- Use Firestore batch writes or transactions for multi-document changes.
- Add repository queries such as `findDateRecordsByLinkedItem` and
  `findEventsByLinkedItem`.

### P2: Auth and couple are only partly Firebase-backed

The current app session now goes through `AuthRepository` and
`CoupleRepository`. Firebase Auth current-user lookup works, and local emulator
mode can return `demo-couple` while ensuring the signed-in user has a membership
document for Firestore rules.

Risk:

- Production user profile and invite-code security rules are still incomplete.
  `FirestoreCoupleRepository` now uses `coupleInvites/{code}` for join lookup,
  but the invite flow still needs UX, expiration policy, and negative rules
  tests before release.

Required work:

- Decide how session loading should behave: one-shot fetch vs auth stream.
- Add tests for create/join/reset couple behavior.

### P2: Firestore implementations need production hardening

Bucket list, date records, and reviews now have Firestore implementations.
Photo uploads still have only a placeholder repository, and cross-domain writes
still need transaction/batch hardening.

Required work:

- `FirebaseStoragePhotoRepository`
- Firestore batch/transaction support for cross-domain writes

Use the collection shape in `docs/architecture/architecture.md`.

### P2: Repository method names should match behavior

Current one-shot repository reads use `fetch...`. Use `watch...` only when a
repository returns streams.

Required work:

- Keep new one-shot reads named `fetch...`.
- Add stream-based `watch...` methods later only where live sync is needed.

Recommended MVP choice:

- Use `fetch...` for now.
- Add real-time streams later where the UX clearly needs live sync.

### P2: Controllers are thinner, but still contain validation and UI messages

Controllers now delegate persistence, but validation and Korean user-facing
messages still live in controllers.

Risk:

- Domain rules are harder to test without Riverpod.

Required work:

- Extract pure validators for repeated rules.
- Keep controller responsibility to:
  - read session
  - call service/repository
  - update screen state

### P2: Linked previews are denormalized but not maintained globally

`LinkedItem` stores title, subtitle, preview, emoji, and thumbnail data. If the
source bucket item/review/date record changes, existing linked previews may
become stale.

Required work:

- Define whether stale previews are acceptable for MVP.
- If not acceptable, add service methods that update linked previews whenever
  the source record changes.

Recommended MVP choice:

- Allow stale historical previews for now.
- Add refresh/update behavior when editing source records becomes frequent.

### P3: Photos are still labels, not real uploaded assets

The `PhotoRepository` exists, but current UI still uses simple labels as photo
stand-ins.

Required work:

- Replace label input with file/image picker.
- Upload to Firebase Storage.
- Save `PhotoAttachment` metadata under the owning record.
- Keep Calendar rendering only thumbnails from linked records.

### P3: Some model copy behavior is still limited

`DateRecord.copyWith` now supports clearing `linkedEventId`. Other nullable
fields, such as `place`, may need explicit clear flags later.

Required work:

- Add clear flags when edit screens need to clear nullable fields.
- Avoid using `null` both as "keep old value" and "clear value".

## Target Layering

Preferred dependency direction:

```text
Screen/Widget
  -> Controller/Notifier
  -> Application Service
  -> Repository Port
  -> Mock or Firestore Repository
  -> Domain Model
```

Rules:

- Widgets should not call repositories directly.
- Controllers should not import other feature controllers for business logic.
- Cross-domain workflows should live in application services.
- Repositories should return domain models, not Firestore documents.
- Domain models should stay free of Flutter widgets and Firebase SDKs.

## Application Services To Add

### `BucketCompletionService`

Owns bucket item completion flows.

Responsibilities:

- Complete a bucket item for a selected date/event/date record.
- Create a date record when needed.
- Link completion to date record.
- Remove completion and all dependent links.

Current status:

- Implemented as `lib/features/todos/application/bucket_completion_service.dart`.
- Has a service test in `test/bucket_completion_service_test.dart`.
- Writes through repositories and refreshes controllers afterward.

### `DateRecordService`

Owns date-record-to-calendar behavior.

Responsibilities:

- Create date record with linked calendar date event.
- Link an existing date record to an existing event.
- Unlink a date record from a calendar event.
- Keep calendar `LinkedItem(type: dateRecord)` preview in sync when needed.

Current status:

- Implemented as `lib/features/date_records/application/date_record_service.dart`.
- Handles creating a date record from an event and ensuring an event has a date
  record.
- Writes through repositories and refreshes controllers afterward.

### `ReviewService`

Owns review-to-date-record behavior.

Responsibilities:

- Create review.
- Link review to a date record.
- Remove review and unlink from date record.
- Later, create review from a date flow.

### `LinkedContentService`

Keep this as the generic cleanup/orchestration layer, but move it away from
controller state reads.

Required direction:

- Continue using repositories for writes.
- Use batch/transaction writes.
- Return deterministic success/failure results.

## Firestore Collection Plan

Use couple-scoped collections:

```text
couples/{coupleId}/events/{eventId}
couples/{coupleId}/anniversaries/{anniversaryId}
couples/{coupleId}/todoCategories/{categoryId}
couples/{coupleId}/todoItems/{itemId}
couples/{coupleId}/todoCompletions/{completionId}
couples/{coupleId}/dateRecords/{dateRecordId}
couples/{coupleId}/reviews/{reviewId}
```

Use Storage paths:

```text
couples/{coupleId}/dateRecords/{dateRecordId}/photos/{photoId}.jpg
couples/{coupleId}/reviews/{reviewId}/photos/{photoId}.jpg
```

Recommended rule:

- Keep bucket categories/items/completions as separate flat collections.
- Flat collections make it easier to query completions by event/date later.

## Test Plan

Add tests in this order:

1. Pure domain tests
   - date range math
   - anniversary occurrence calculation
   - linked item preview builders
2. Repository contract tests
   - mock todo repository CRUD
   - mock date record repository CRUD/link/unlink
   - mock review repository CRUD
3. Controller tests
   - controllers call repositories and update state
   - validation failures do not write
4. Application service tests
   - completing bucket item creates the expected links
   - removing completion cleans date records and calendar events
   - date record creation creates/links calendar event
5. Widget tests for critical flows
   - bucket item completion flow
   - calendar date summary flow
   - date record create/edit flow

## Functional Style Guidance

Keep this project pragmatic, not dogmatic:

- Prefer immutable models and `copyWith`.
- Prefer `map`, `where`, and `fold` for list transformations when readable.
- Keep side effects at repository/service/controller boundaries.
- Put pure calculations in domain services.
- Do not force complex functional abstractions into Flutter UI code.

Good:

```dart
final updated = records
    .map((record) => record.id == targetId ? nextRecord : record)
    .toList();
```

Avoid:

```dart
records[index] = nextRecord;
state.records.add(record);
```

## Next Implementation Steps

Recommended next session order:

1. Add `FirebaseAuthRepository` and `FirestoreCoupleRepository`.
2. Add repository contract tests for Todo, DateRecord, Review.
3. Add Firestore batch/transaction support for cross-domain service writes.
4. Add real photo picking/upload using `PhotoRepository`.
5. Add Firebase Auth/Couple production flow tests after real auth is connected.

Definition of done for the repository migration:

- Every persistent domain has a repository port.
- Every repository port has a mock implementation.
- Firebase-specific code is only in data repositories or infrastructure.
- Cross-domain writes go through application services.
- Critical services have tests with fake/mock repositories.
- Screens do not directly coordinate multi-domain business logic.
