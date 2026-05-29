# Go API Package Guidelines

This document is the guide for preserving and evolving the `apps/api` package
structure. The goal is to make the Go server easier to test, easier to extend,
and harder to accidentally turn into a mixed-responsibility backend.

## Problem To Fix

The API initially worked, but package boundaries were too loose. This document
describes the structure that should be preserved as the server grows.

Problems this structure is meant to prevent:

- Root HTTP router files owning too many responsibilities:
  routing, middleware setup, handlers, request DTOs, response writing, error
  translation, and domain input mapping.
- HTTP adapters, application use cases, domain models, and persistence adapters
  becoming siblings under `internal`, making layer relationships invisible.
- Domain/application code hiding side effects instead of receiving dependencies
  such as clock and ID generation explicitly.
- Firestore or memory persistence for multiple domains accumulating in one
  shared package.

## Target Principles

Use these principles for the refactor:

- One file should have one reason to change.
- Package paths should reveal the layer.
- HTTP should be an adapter, not the application.
- Domain/application code should be testable without HTTP, Firebase, Docker, or
  Flutter.
- Side effects should sit at edges: HTTP, database, clock, id generation, auth,
  storage, notification delivery.
- Prefer pure functions for validation, normalization, mapping, filtering, and
  permission decisions.
- Do not introduce broad abstractions before there are at least two real users,
  but do keep ports/interfaces at domain boundaries.

## Target Package Shape

Refactor toward this shape:

```text
apps/api/
  cmd/server/
    main.go

  internal/
    bootstrap/
      config.go
      container.go

    domain/
      calendar/
        model.go
        errors.go
        permissions.go
        validation.go
      daterecords/
        model.go
        errors.go
        validation.go
      links/
        model.go

    application/
      calendar/
        ports.go
        service.go
        service_test.go
      daterecords/
        ports.go
        service.go
        service_test.go
      links/
        service.go
        date_records.go
        todos.go
        reviews.go
        helpers.go
        service_test.go

    adapters/
      httpapi/
        router.go
        middleware.go
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
      persistence/
        firestore/
          calendar/
            repository.go
            mapper.go
          daterecords/
            repository.go
            mapper.go
        memory/
          calendar/
            repository.go
          daterecords/
            repository.go

    platform/
      clock/
        clock.go
      idgen/
        idgen.go
```

Notes:

- `domain/*` contains entities, value objects, errors, and pure domain rules.
- `application/*` contains use cases and repository ports.
- `adapters/httpapi/*` contains HTTP-only concerns.
- `adapters/persistence/*` contains database implementations.
- `platform/*` contains small generic technical interfaces and implementations.
- `bootstrap/*` wires config, dependencies, and adapters together.

## Responsibility Rules

### Router

`adapters/httpapi/router.go` should only:

- create the root `chi.Router`
- attach global middleware
- mount feature route groups

It should not:

- decode request bodies
- call services directly
- define DTO structs
- know domain input structs
- translate domain errors

### Feature Routes

Each feature route file should only mount endpoints:

```go
func MountRoutes(r chi.Router, handlers Handlers) {
    r.Route("/v1/couples/{coupleID}/events", func(r chi.Router) {
        r.Get("/", handlers.List)
        r.Post("/", handlers.Create)
    })
}
```

### Handlers

Handlers should:

- read path/query/body input
- call mapper functions to build application input
- call exactly one application service method per endpoint unless the endpoint
  is explicitly an orchestration use case
- write JSON or errors through shared response helpers

Handlers should not:

- contain business rules
- mutate domain models manually beyond DTO mapping
- contain Firestore-specific behavior

### DTO And Mapper

DTOs are HTTP contracts. They belong in `adapters/httpapi/<feature>/dto.go`.

Mapping functions belong in `mapper.go` and should be pure:

```go
func toCreateInput(coupleID string, req createRequest) application.CreateInput
```

DTOs should not leak into application services. Domain/application models should
not be shaped only to satisfy JSON.

### Error Translation

Keep domain errors in domain packages. Translate them once in
`adapters/httpapi/errors.go`.

Do not spread `errors.Is(...)` switch statements across handlers.

### Application Services

Application services should:

- receive explicit input structs
- depend on ports/interfaces
- return domain models or result structs
- own transaction-level use cases when a flow crosses multiple domains

Application services should not:

- import HTTP packages
- import Firestore packages
- read environment variables
- write logs for normal control flow

### Domain

Domain packages should prefer:

- immutable-ish value updates
- small pure functions
- explicit permission predicates
- validation functions returning domain errors

Examples:

```go
func CanEditEvent(event Event, userID string) bool
func NormalizeEvent(input EventDraft, now time.Time, id string) (Event, error)
func IsWatchOnlyUpdate(before Event, after Event, userID string) bool
```

Avoid hidden global state.

## Functional Style In Go

Go is not a functional language, but keep this style:

- Prefer functions that transform input to output without side effects.
- Keep mutation local and obvious.
- Pass dependencies explicitly.
- Keep repository methods boring: load, save, list, soft-delete.
- Keep business decisions out of repositories.
- Avoid package-level mutable variables.
- Prefer table-driven tests for pure rule functions.

Good:

```go
func ValidateDateRange(startAt, endAt time.Time) error
func LinkedItemsWithout(items []LinkedItem, target LinkedItemRef) []LinkedItem
```

Avoid:

```go
func (h Handler) Update(w http.ResponseWriter, r *http.Request) {
    // decode, validate, authorize, normalize, persist, map response,
    // and coordinate another domain all inline
}
```

## Cross-Domain Use Cases

Do not let HTTP handlers manually coordinate multiple repositories.

When a user flow crosses domains, add or extend an application use case package:

```text
internal/application/links/
  date_records.go
  todos.go
  reviews.go
  helpers.go
```

Current examples that belong in `application/links`:

- date record <-> calendar event bidirectional link
- deleting a date record and removing calendar/review/todo linked references
- bucket completion -> date record -> calendar summary
- review <-> date record link/unlink/delete cleanup

Single-domain CRUD should stay in its own domain application package. HTTP
handlers should call one `application/links` method when they expose an
orchestration endpoint.

Keep `application/links` split by user-flow family. Do not grow one giant
service file again:

- `date_records.go`: event/date-record creation, link, unlink, delete cleanup
- `todos.go`: bucket completion link and completion removal
- `reviews.go`: review/date-record link, unlink, delete cleanup
- `helpers.go`: pure linked-item mapping/filtering helpers

## Refactor Order For Similar Future Work

When another large structural move is needed, do it in small, compile-safe
steps:

1. Create the new folder skeleton.
2. Move domain models/errors first.
3. Move application services and ports next.
4. Move persistence adapters next.
5. Split HTTP code:
   - `router.go`
   - `middleware.go`
   - `response.go`
   - `errors.go`
   - `calendar/{routes,handlers,dto,mapper}.go`
   - `daterecords/{routes,handlers,dto,mapper}.go`
6. Keep bootstrap wiring last.
7. Keep behavior unchanged and run tests after each large move.

Important: this should be a structural refactor. Do not add review/todo API
behavior in the same session.

## Acceptance Criteria

The refactor is done when:

- No single HTTP file contains router setup, DTOs, handlers, and response
  helpers together.
- `internal/domain`, `internal/application`, and `internal/adapters` exist and
  package paths make the layer obvious.
- Domain/application packages do not import HTTP or Firestore.
- HTTP handlers are thin and mostly decode/map/call/respond.
- Persistence repositories remain replaceable with memory repositories.
- Existing API endpoints keep the same request/response shape.
- Existing tests pass:

```sh
docker compose -f infra/local/docker-compose.yml run --rm api go test ./...
(cd apps/frontend && flutter analyze)
(cd apps/frontend && flutter test)
```

Run the existing local smoke checks after rebuilding the API container.

## Naming Decision

Use plural domain package names only when the product concept is naturally
plural in the app. Current recommendation:

- `calendar`
- `daterecords`
- `reviews`
- `todos`
- `anniversaries`

Do not mix singular and plural randomly.
