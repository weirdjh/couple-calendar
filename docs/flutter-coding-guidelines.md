# Flutter Coding Guidelines

These instructions are for future coding agents working on this Flutter project.

## Default Choices

- Use Flutter.
- Use Riverpod for state management.
- Use Firebase for auth, database, storage, and notifications.
- Prefer feature-first organization under `lib/features`.
- Keep implementation small and working before adding abstractions.
- Do not introduce Bloc, Provider, GetX, Redux, MobX, or another state library unless explicitly requested.
- Use Material 3 for the first UI system.
- Prefer simple Dart classes first. Add code generation only when the project already uses it or the owner approves it.

## Before Coding Checklist

Before changing code:

1. Read `AGENTS.md`.
2. Read `docs/requirements.md`.
3. Read `docs/architecture.md`.
4. Read this file.
5. Inspect the existing files for local patterns.
6. Make the smallest change that satisfies the requested behavior.

If the request conflicts with these docs, follow the user's latest request and update the docs if the product direction changed.

## Package Policy

Do not add dependencies casually.

Good reasons to add a package:

- It is a standard Flutter/Firebase integration package.
- It removes substantial platform-specific complexity.
- It is necessary for calendar UI, photo picking, notifications, routing, or immutable model generation.

Bad reasons:

- A small helper function would be enough.
- The package duplicates a capability already present.
- The package forces a new app architecture.

When adding a package, keep the choice conventional and document why in the final response.

Expected package families over time:

```text
flutter_riverpod
firebase_core
firebase_auth
cloud_firestore
firebase_storage
firebase_messaging
image_picker
flutter_local_notifications
go_router
```

Calendar UI packages should be evaluated when implementation begins. Do not lock one in until the first calendar screen is being built.

## Functional Style Preference

The product owner prefers functional programming. In Flutter, apply that taste pragmatically:

- Prefer immutable data models.
- Prefer pure functions for mapping, filtering, validation, date calculations, and data conversion.
- Keep side effects in repositories, data sources, controllers, or services.
- Avoid side effects in widgets' `build` methods.
- Avoid hidden global mutable state.
- Return new values instead of mutating existing model objects.
- Use `copyWith` on models when updating state.

Do not force heavy functional abstractions if they make normal Flutter code harder to read.

Recommended model style:

```dart
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.memo = '',
    this.photos = const [],
    this.reminders = const [],
    this.linkedItems = const [],
  });

  final String id;
  final String coupleId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String memo;
  final List<EventPhoto> photos;
  final List<Reminder> reminders;
  final List<LinkedItem> linkedItems;

  CalendarEvent copyWith(...) {
    // Return a new CalendarEvent.
  }
}
```

If the project later adopts `freezed`, use it consistently for immutable models and unions. Do not mix many model styles in the same feature.

## Riverpod Rules

- Wrap the app with `ProviderScope`.
- Use providers for dependencies such as repositories and services.
- Use `Notifier`, `AsyncNotifier`, `StateNotifier`, or simple `Provider` depending on complexity.
- Prefer `AsyncValue` for loading/error/data UI.
- Keep providers close to the feature that owns them.
- Do not call Firebase directly from widgets.
- Do not put large business logic inside widgets.
- Prefer `ConsumerWidget` or `ConsumerStatefulWidget` when widgets need providers.
- Keep provider names boring and searchable.

Recommended flow:

```text
Screen or widget
  reads provider
  calls controller action
Controller or notifier
  validates and coordinates state
Repository
  talks to Firebase or local APIs
Model
  represents immutable app data
```

Avoid these patterns:

- Calling `FirebaseFirestore.instance` inside a widget.
- Starting network requests from `build`.
- Mutating a list inside provider state and expecting the UI to update.
- Sharing form controllers globally without a reason.

## Firebase Rules

- Keep Firebase calls behind repository interfaces/classes.
- Convert Firestore documents to domain models at the data layer boundary.
- Store timestamps consistently.
- Never hardcode real user ids, couple ids, API keys, or Firebase project ids in feature code.
- Keep Firebase initialization in app/bootstrap code, not in feature widgets.
- Write code so a fake repository can be used in tests.
- Keep Firestore field names stable and centralized near serialization code.
- Use server timestamps for `createdAt` and `updatedAt` when saving.
- Handle permission errors with user-visible messages.

Recommended serialization boundary:

```text
Firestore document
  -> data mapper
  -> domain model
  -> provider/controller
  -> widget
```

## Calendar Rules

- The calendar feature is the core of the app.
- Calendar events may reference other content, but should not directly own todo, conflict, review, map, or anniversary business logic.
- Use `LinkedItem` for generic references to other modules.
- Query events by visible date range.
- Avoid loading every event for a couple at app startup.
- Keep date math centralized in utility functions to avoid timezone bugs.
- Keep event sorting deterministic: all-day events first, then start time, then title.
- Treat date-only concepts separately from timestamp-based events.
- Do not add todo/review/conflict fields directly to `CalendarEvent`.

## UI Rules

- Build the real app screen first, not a landing page.
- Prefer calm, useful, app-like UI over marketing-style hero sections.
- Use Material 3 unless a stronger design system is introduced.
- Keep widgets small and named after product concepts.
- Use icons for common actions.
- Ensure text fits on small iPhone screens and web widths.
- Do not use visible instructional copy to explain obvious UI controls.
- Prefer bottom sheets or full-screen dialogs for mobile event creation.
- Ensure the calendar day cell remains readable when there are multiple event markers.
- Use empty, loading, error, and permission-denied states deliberately.

## Forms

- Keep form state local when the form is simple and not shared.
- Move form state to a Riverpod controller when it has async saves, uploads, validation, or cross-screen behavior.
- Validate before saving.
- Show clear loading and error states.
- Prevent duplicate submits while saving.
- Keep validation functions pure when possible.
- Do not lose unsaved form state when adding photos unless the user intentionally cancels.

## Photos

- Use Firebase Storage for image files.
- Store only image metadata in Firestore.
- Compress or resize photos before upload when practical.
- Keep upload progress state separate from the saved event state.
- Do not block the whole calendar UI while one photo uploads.
- Represent photo upload failures per photo when possible.
- Avoid assuming file APIs work the same on iOS and web.

## Reminders

- Treat reminder scheduling as a side effect.
- Keep reminder data in the event model, but schedule notifications through a reminder service.
- Early MVP may use local notifications.
- Do not assume web push behaves the same as iOS notifications.
- Store reminder intent even if platform scheduling fails, then show a recoverable error.
- Ask for notification permission at the point of need.

## Error Handling

- Use explicit error states in providers.
- Show short user-facing messages for auth, permission, upload, and save failures.
- Log technical details only where a logging mechanism exists.
- Do not swallow exceptions silently.
- Do not expose raw Firebase exception text directly if it is confusing or sensitive.

## Testing

Add focused tests around:

- Date range calculations.
- Event filtering and sorting.
- Model serialization.
- Repository behavior with fakes.
- Provider/controller behavior for create/edit/delete flows.

For UI changes, at least run `flutter analyze` and relevant tests before finishing.

Test with fake repositories first. Avoid requiring a real Firebase project for basic unit tests.

## Change Discipline

- Keep edits scoped to the requested feature.
- Do not rewrite generated platform folders unless required.
- Do not reformat unrelated files.
- Do not add packages casually; explain why a package is needed.
- Prefer readable boring code over clever abstractions.
- Leave short comments only when they clarify non-obvious behavior.
- Do not implement deferred modules unless the request explicitly asks for them.
- Update docs when changing architecture or product assumptions.

## Naming

- Use product names in code: `CalendarEvent`, `LinkedItem`, `Couple`, `Reminder`, `EventPhoto`.
- Use `Repository` for persistent data access.
- Use `Service` for side effects or platform integrations.
- Use `Controller` or `Notifier` for screen actions and state transitions.
- Use `Screen` for full pages and `Widget` names for reusable pieces.

## When Requirements Are Ambiguous

Prefer these defaults unless the user says otherwise:

- Couple size: exactly two users.
- Calendar events: shared with both users.
- Event permissions: both users can edit and delete.
- Reminder delivery: schedule on the current device first.
- Conflict records: do not show detailed content directly on the calendar.
- Maps: keep provider-neutral domain models.
- Web: must be usable, but mobile UX has priority.

If ambiguity affects data shape or would be expensive to reverse later, stop and ask the user.
