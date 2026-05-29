# Testing Guide

This project keeps two test layers.

## Fast Local Tests

Run these after normal Flutter changes:

```bash
cd apps/frontend
flutter analyze
flutter test
```

The default test suite uses mock repositories and pure application/domain code.
It should stay fast and deterministic.

Run these after normal Go API changes:

```bash
docker compose -f infra/local/docker-compose.yml run --rm api go test ./...
```

Cross-domain use cases in `apps/api/internal/application/links` must have Go
service tests. These tests should use memory repositories and should verify the
state of every affected domain after the use case runs.

## Firebase Emulator Integration Tests

Run these when Firestore repository behavior, Firebase rules, or backend-shaped
data changes:

```bash
bash tool/run_firestore_emulator_tests.sh
```

The script starts Firebase Auth and Firestore emulators in Docker, then runs:

```bash
(cd apps/frontend && flutter test)
docker compose -f infra/local/docker-compose.yml exec -T firebase-emulator \
  node /workspace/tool/firebase_emulator_smoke_test.mjs
```

The Flutter test suite verifies repository contracts against mock repositories
and application services. The Firebase smoke test signs in with Firebase Auth
emulator, creates a couple member document, and verifies Firestore rules plus
document writes/reads against the emulator:

- member-scoped writes are allowed
- calendar event documents can be written/read by couple members
- non-members cannot read couple documents
- a newly added member can read the same couple document

This catches rules, Auth emulator, Firestore emulator, and backend-shaped data
regressions. Direct FlutterFire repository integration tests should be added
later with a stable device/integration-test runner; browser unit tests currently
hang during Firebase setup in this local environment.

Local Firebase config lives under `apps/api/config/firebase/local`, and the
shared local app compose file lives at `infra/local/docker-compose.yml`. Keep
root-level Firebase files out of the repo; production config should later live
under `apps/api/config/firebase/production`.

Local app runs export Firebase Emulator state to the Docker volume
`firebase-emulator-data` on shutdown and import it on the next startup. This
keeps local emulator state out of the project tree.
Use a full `docker compose -f infra/local/docker-compose.yml down` when you
want the export to happen cleanly.

The integration test script disables emulator persistence with
`FIREBASE_PERSISTENCE=false` so smoke-test data does not leak into your local
app state.

## Firebase Rules

The current Firestore rules are still MVP-level, but they are not wide open:

- a user must be authenticated
- a user can create their own `members/{userId}` document
- couple-owned documents require an existing membership document

Before production release, replace this with invitation-based couple membership
rules and add negative permission tests.

## API Smoke Test

Run this after API contract, repository, or cross-domain use case changes:

```bash
docker compose -f infra/local/docker-compose.yml up -d --build api
node tool/api_smoke_test.mjs
node tool/api_two_user_qa_smoke_test.mjs
```

The smoke test covers the current backend-owned happy path:

- couple creation
- calendar event creation
- event -> date record ensure
- bucket category/item creation
- bucket completion -> date record link
- review -> date record link
- date record deletion cleanup
- review/date/todo/event cleanup assertions

The script uses the Go API for behavior and the Firestore emulator REST API for
best-effort cleanup of throwaway documents. It assumes local ports from
`infra/local/docker-compose.yml`.

`tool/api_two_user_qa_smoke_test.mjs` adds the couple-specific permission path:

- create `qa-user-a`
- join `qa-user-b` into the same couple
- verify partner visibility
- verify partner cannot edit/delete A's personal event
- verify partner can watch A's personal event
- verify partner can edit/delete our shared event
- verify non-member cannot create date-record links
- verify partner can link a shared calendar event to a date record
- verify bucket-list completion links through that date record
- verify review link/unlink updates both review and date record state
- verify bucket-list completion unlink removes completion and date-record link
- verify date-record/calendar unlink clears the calendar-side date-record link
- verify non-member access is rejected for calendar, date records, bucket list,
  reviews, and anniversaries

## Two-User QA Automation

The most valuable QA automation for this app is not single-user CRUD. It should
exercise a couple with two users because most product rules depend on ownership,
shared visibility, and cross-domain links.

Use this default QA cast:

- `qa-user-a`: current user.
- `qa-user-b`: partner in the same couple.
- `qa-user-c`: non-member used for negative permission checks.

Recommended automated scenario:

1. Seed or create one couple containing `qa-user-a` and `qa-user-b`.
2. Sign in or impersonate `qa-user-a`.
3. Create 내 일정, 우리 일정, a date record, a bucket-list category/item, and a review.
4. Link bucket-list completion -> date record -> calendar event.
5. Verify Calendar shows the linked summary, bucket-list emoji, and date border.
6. Sign in or impersonate `qa-user-b`.
7. Verify `qa-user-b` can see the couple calendar and our-event data.
8. Verify `qa-user-b` cannot edit/delete `qa-user-a`'s 내 일정.
9. Verify `qa-user-b` can edit/delete 우리 일정.
10. Verify `qa-user-b` can watch `qa-user-a`'s event for reminders.
11. Sign in or impersonate `qa-user-c`.
12. Verify `qa-user-c` cannot read the couple calendar or linked records.
13. Clean up all QA data through API delete endpoints.

Until real Naver login exists, this should run against deterministic local QA
identities through the Go API and Firebase emulator. When auth is implemented,
keep the same scenario and replace only the login/bootstrap step.

Implementation should happen in layers:

- API service tests for permission and cross-domain state transitions.
- API smoke script that creates two users and runs the full happy path plus
  negative permission checks.
- Flutter widget/controller tests for role-based UI states.
- Optional browser-driven E2E later, once routes and stable test selectors exist.
