# Documentation Guide

This folder is the product and engineering source of truth for Couple Calendar.
Docs are grouped by responsibility so a new coding session can quickly find the
right contract instead of reading every note.

## Folder Map

- `docs/product/`: product behavior, user scenarios, screens, and feature specs.
- `docs/architecture/`: domain model, backend/API direction, repository/service
  boundaries, and future integrations.
- `docs/engineering/`: coding conventions and package/layer guidelines.
- `docs/testing/`: local test strategy, emulator notes, and verification commands.

## Priority Order

When docs disagree, use this priority order:

1. `docs/product/user-scenarios.md`
2. `docs/product/calendar-spec.md`
3. `docs/product/product-spec.md`
4. `docs/architecture/architecture.md`
5. `docs/product/navigation-and-screens.md`
6. `docs/product/requirements.md`
7. `docs/architecture/ddd-repository-review.md`
8. `docs/architecture/auth-plan.md`
9. `docs/engineering/go-api-package-guidelines.md`
10. `docs/testing/testing.md`
11. `docs/engineering/flutter-coding-guidelines.md`

Then update the stale document so the conflict does not remain.

## Read This First

Before implementing product behavior, read:

- `docs/product/user-scenarios.md`
- the feature-specific spec, currently `docs/product/calendar-spec.md`
- `docs/architecture/architecture.md` when data shape changes
- `docs/architecture/ddd-repository-review.md` when repository/service boundaries change
- `docs/architecture/auth-plan.md` when touching login, users, couples, sessions, or permissions
- `docs/engineering/go-api-package-guidelines.md` when changing Go API package/layer structure
- `docs/testing/testing.md` when API, repository, Firebase, or rules behavior changes
- `docs/engineering/flutter-coding-guidelines.md` when writing Flutter code

## Document Responsibilities

### Product Docs

`docs/product/user-scenarios.md`

Scenario-level product contract. Use it to answer what journey starts where,
what happens after save, what links appear on Calendar, how users navigate to
details, and how mistakes can be undone. This is the most important product
document for reducing implementation loops.

`docs/product/calendar-spec.md`

Calendar-specific behavior. Use it for start/end date-time ranges, multi-day
rendering, 내 일정/상대 일정/우리 일정, permissions, reminders, watched events,
user colors, Korean holidays, and shared-event visuals.

`docs/product/product-spec.md`

Current product decisions and high-level feature summary. Use it for accepted
decisions, current scope, deferred scope, and module status. Do not put long
step-by-step flows here; put those in `docs/product/user-scenarios.md`.

`docs/product/navigation-and-screens.md`

Screen responsibilities and routing direction. Use it to decide which screen
owns a workflow and which detail/edit routes should exist.

`docs/product/ux-improvement-plan.md`

Cross-screen UX audit and improvement-pass tracker. Use it to choose and record
the next UI/UX pass without duplicating feature behavior.

`docs/product/requirements.md`

Original and current requirements. Use it for product background, MVP
acceptance criteria, non-goals, and long-term requirement traceability.

### Architecture Docs

`docs/architecture/architecture.md`

Data, repository, and backend structure. Use it for model fields, feature
ownership, Firestore/storage shapes, and repository/service responsibilities.
When adding or changing model fields, update this document.

`docs/architecture/api-server-migration.md`

Plan for moving business rules from Flutter/Firebase-direct behavior into the
Go API server. Use it when deciding whether logic belongs in Flutter, API
application services, repositories, or Firebase adapters.

`docs/architecture/ddd-repository-review.md`

Repository and service-layer migration guide. Use it to see repository coverage,
which Firestore implementations remain, and which cross-domain flows should move
into application services.

`docs/architecture/auth-plan.md`

Deferred authentication plan. Use it when adding Naver login, user profiles,
couple membership, session/token handling, Firebase Auth custom-token bridging,
or permission rules.

### Engineering Docs

`docs/engineering/go-api-package-guidelines.md`

Go backend package and layer refactoring guide. Use it for domain/application/
adapter/platform boundaries, HTTP routing, handlers, DTOs, mappers, errors, and
testable functional rule logic.

`docs/engineering/flutter-coding-guidelines.md`

Implementation guidance for Flutter/Riverpod. Use it for state management,
model and repository patterns, testing expectations, and coding conventions.

### Testing Docs

`docs/testing/testing.md`

Test strategy and local verification. Use it for normal verification commands,
API smoke tests, Firebase emulator setup, repository contracts, and rules-test
boundaries.

## Adding New Docs

Avoid adding a new document unless it has a clear owner.

Good reasons:

- A feature area has enough detailed rules to deserve its own spec.
- A technical integration needs its own setup guide.
- A decision log is needed for tradeoffs that should not clutter product specs.

Bad reasons:

- Duplicating scenarios already covered in `docs/product/user-scenarios.md`.
- Copying the same model rules into multiple files.
- Writing temporary notes that should be tasks or comments.

## Update Checklist

When product behavior changes:

- Update `docs/product/user-scenarios.md`.
- Update a feature spec such as `docs/product/calendar-spec.md` if detailed rules changed.
- Update `docs/product/product-spec.md` if the product decision changed.
- Update `docs/architecture/architecture.md` if model/repository fields changed.
- Update `docs/product/navigation-and-screens.md` if screens/routes changed.
- Update `AGENTS.md` only for top-level instructions future coding agents must always know.

When backend or data behavior changes:

- Update `docs/architecture/architecture.md`.
- Update `docs/architecture/api-server-migration.md` if API ownership changed.
- Update `docs/architecture/ddd-repository-review.md` if repository/service boundaries changed.
- Update `docs/testing/testing.md` if verification commands or emulator setup changed.

When auth is implemented later:

- Start from `docs/architecture/auth-plan.md`.
- Update `docs/architecture/architecture.md` with final user/couple/session shapes.
- Update `docs/product/user-scenarios.md` for login, onboarding, invite, and permission flows.
