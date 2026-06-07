# API Server Migration

## Decision

Use Go for the backend API server.

Chosen first stack:

- Go standard `net/http`
- `chi` router
- Domain services with repository interfaces
- Firebase Admin/Firestore repository later
- Docker Compose for local execution

The target architecture is:

```text
Flutter app -> Go API server -> Firebase Admin SDK -> Firestore/Auth/Storage
```

This replaces the current direct app-to-Firebase shape over time:

```text
Flutter app -> Firebase SDK -> Firestore/Auth/Storage
```

## Why This Direction

- The app is gaining cross-domain behavior: calendar events, date records,
  reviews, bucket list completions, anniversaries, reminders, and permissions.
- Those flows are easier to test and evolve when business rules live in API
  services instead of widgets, controllers, or Firestore security rules.
- The Flutter app already has repository interfaces, so each repository can be
  migrated from Firestore implementation to API implementation one domain at a
  time.
- Go keeps the backend compiled, lightweight, explicit, and easy to run in
  containers.

## Package Shape

```text
apps/api/
  cmd/server/
  internal/
    bootstrap/
      config.go
      container.go
    domain/
      calendar/
      daterecords/
      links/
    application/
      calendar/
      daterecords/
      links/
    adapters/
      httpapi/
      persistence/
        firestore/
        memory/
    platform/
      clock/
      idgen/
```

Layer rules:

- `domain/*` owns models, errors, and pure domain rules.
- `application/*` owns use cases and repository ports.
- `adapters/httpapi/*` owns HTTP routing, handlers, DTOs, mappers, and response
  translation.
- `adapters/persistence/*` owns Firestore and memory repository implementations.
- `bootstrap/*` wires config, repositories, services, and HTTP adapters.
- `platform/*` contains small generic technical dependencies such as clocks and
  id generation.

Feature HTTP adapters should keep this split:

```text
adapters/httpapi/
  router.go
  middleware.go
  httputil/
    response.go
    errors.go
  calendar/
    routes.go
    handlers.go
    dto.go
    mapper.go
  daterecords/
    routes.go
    handlers.go
    dto.go
    mapper.go
```

Do not put handlers, DTOs, mappers, and response helpers back into root
`router.go`.

## Migration Order

1. Keep Flutter repositories as the app boundary.
2. Add API repository implementations in Flutter, without deleting existing
   Firestore repositories.
3. Move calendar event rules first:
   - create/update/delete permission
   - multi-day range validation
   - reminder normalization
   - linked item attach/detach rules
4. Move date record linking next:
   - calendar event <-> date record bidirectional link
   - date record deletion cleanup
5. Move bucket list completion next:
   - bucket item completion records
   - completion <-> date record link
6. Move reviews next:
   - review <-> date record link
   - photo metadata
7. Move anniversaries after that:
   - recurrence calculation
   - lunar birthday conversion policy
8. Keep Firebase Security Rules as a defense layer, but move primary business
   decisions into API services.
9. Add authentication later. Follow `docs/architecture/auth-plan.md`; until
   then, keep local/dev identity deterministic so API and QA tests can exercise
   user/couple permissions.

## Current API Skeleton

The initial API server exists under `apps/api`.

Current local/dev identity is carried in an `X-Dev-User-Id` request header. All
`/v1/*` endpoints require that header before handlers run. Handlers should read
the user id from request context, not from query parameters or request bodies.
When real auth is added, replace the middleware implementation with
`Authorization` token verification while preserving the same context shape.

Implemented endpoints:

```text
GET    /healthz
GET    /v1/couples/{coupleID}/events?startAt=<RFC3339>&endAt=<RFC3339>
POST   /v1/couples/{coupleID}/events
PUT    /v1/couples/{coupleID}/events/{eventID}
DELETE /v1/couples/{coupleID}/events/{eventID}
GET    /v1/couples/{coupleID}/date-records
POST   /v1/couples/{coupleID}/date-records
PUT    /v1/couples/{coupleID}/date-records/{recordID}
DELETE /v1/couples/{coupleID}/date-records/{recordID}
PUT    /v1/couples/{coupleID}/date-records/{recordID}/calendar-event
DELETE /v1/couples/{coupleID}/date-records/{recordID}/calendar-event/{eventID}
POST   /v1/couples/{coupleID}/date-records/{recordID}/linked-items
POST   /v1/couples/{coupleID}/date-records/{recordID}/linked-items/remove
```

Calendar API now owns validation, reminder normalization, edit/delete
permissions, and watcher-only updates for partner-owned personal events.

Date record API now owns CRUD, place/photo metadata, linked item attach/detach,
and calendar event link/unlink persistence.

Cross-domain link use cases now live in `internal/application/links` and are
exposed under `/v1/couples/{coupleID}/links`. They own the multi-repository
flows that used to be orchestrated by Flutter services:

```text
POST   /v1/couples/{coupleID}/links/date-records/ensure-for-event
POST   /v1/couples/{coupleID}/links/date-records/from-event
DELETE /v1/couples/{coupleID}/links/date-records/{recordID}
POST   /v1/couples/{coupleID}/links/date-records/{recordID}/calendar-event
DELETE /v1/couples/{coupleID}/links/date-records/{recordID}/calendar-event/{eventID}
POST   /v1/couples/{coupleID}/links/todo-completions
DELETE /v1/couples/{coupleID}/links/todo-completions/{completionID}
POST   /v1/couples/{coupleID}/links/reviews/{reviewID}/date-record
DELETE /v1/couples/{coupleID}/links/reviews/{reviewID}/date-record/{recordID}
DELETE /v1/couples/{coupleID}/links/reviews/{reviewID}
POST   /v1/couples/{coupleID}/links/calendar-events/{eventID}/linked-items/remove
```

Keep single-domain CRUD in its own application package. Put only multi-domain
orchestration in `application/links`.

Cross-domain writes must run through the application transaction runner.
Firestore mode backs this runner with an atomic write batch. Memory mode uses an
immediate runner for fast service tests. The first protected flow is date-record
deletion cleanup; extend the same boundary to the remaining link/unlink flows.

The API server supports two repository modes:

- `EVENT_REPOSITORY=memory`
- `EVENT_REPOSITORY=firestore`

Local Docker Compose uses the Firestore repository against Firebase Emulator.

## Local Ports

```text
Flutter web          8080
Go API server        8088
Firebase Emulator UI 4000
Firestore emulator   8085
Auth emulator        9099
```

## Testing Direction

Use three test layers:

- Go service tests for domain rules.
- Go HTTP tests for API contracts.
- Flutter repository/controller tests against API fakes.

The important rule: business logic should be testable without Flutter widgets
and without a real database.

For QA automation, prioritize two-user couple scenarios over isolated CRUD.
Automated smoke tests should create or seed `qa-user-a` and `qa-user-b` in one
couple, plus `qa-user-c` as a non-member, then verify visibility, edit/delete
permissions, watch behavior, and calendar/date-record/bucket/review links. See
`docs/testing/testing.md` for the scenario checklist.
