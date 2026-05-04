# Architecture

## Stack

- Flutter for iOS and web first, Android later.
- Riverpod for state management.
- Firebase for authentication, data, file storage, and notifications.

Recommended Firebase services:

- Firebase Auth for sign-in.
- Cloud Firestore for shared app data.
- Firebase Storage for photos.
- Firebase Cloud Messaging for push notifications.
- Firebase Functions or another backend worker later for server-side notification scheduling and cross-platform jobs.

## Architecture Goals

- Keep the calendar flexible enough to show many record types without owning all their schemas.
- Keep Firebase replaceable behind repositories where reasonable.
- Keep widgets mostly declarative and side-effect free.
- Keep feature boundaries clear so future modules can be added without rewriting the calendar.
- Make the MVP small enough to ship while preserving room for Android, maps, reviews, and richer reminders.

## High-Level Shape

The app should be feature-first, with shared infrastructure separated from product features.

Recommended structure:

```text
lib/
  app/
    app.dart
    theme.dart
    router.dart
  core/
    errors/
    firebase/
    routing/
    time/
    widgets/
  features/
    auth/
    couple/
    calendar/
    photos/
    reminders/
    linked_items/
```

Each feature can contain:

```text
data/
  repositories/
  sources/
domain/
  models/
  services/
presentation/
  controllers/
  screens/
  widgets/
```

For small features, do not create empty folders just to satisfy this shape. Add structure when the feature needs it.

## Dependency Direction

Dependencies should point toward stable product concepts:

```text
presentation -> domain
presentation -> repositories/services
data -> domain
```

Pragmatic interpretation for this project:

- Screens and widgets may depend on domain models and Riverpod providers.
- Controllers/notifiers coordinate UI state and call repositories or services.
- Repositories hide Firebase details and return domain models.
- Domain models should not import Flutter UI packages or Firebase SDKs.
- Domain models should not depend on repository or data-source classes.
- Data mappers may depend on domain models, but domain models should stay platform-neutral.
- Shared UI components can live under `core/widgets` only when used by more than one feature.

## Core Data Model

### UserProfile

```text
id
displayName
photoUrl
createdAt
updatedAt
```

MVP user profile should be minimal. Avoid adding profile fields until a real screen needs them.

### Couple

```text
id
memberIds
inviteCode
createdAt
updatedAt
```

MVP assumes exactly two members. If later supporting multiple relationship spaces, introduce a user-to-couple membership collection instead of overloading this model.

### CalendarEvent

```text
id
coupleId
title
startAt
endAt
isAllDay
memo
color
photos
reminders
linkedItems
createdBy
lastEditedBy
createdAt
updatedAt
deletedAt
```

Use soft delete when practical so accidental deletion can be recovered later.

Calendar event rules:

- `title` is required.
- `startAt` is required.
- `endAt` should be required after normalization.
- For all-day events, store a predictable normalized range rather than relying on a missing time.
- For instant records, set `endAt` to the same value as `startAt` or use a short normalized duration consistently.
- `memo` can be empty.
- `photos`, `reminders`, and `linkedItems` default to empty lists.
- Calendar queries should exclude records with `deletedAt`.
- `createdBy` should reference a user id.
- `lastEditedBy` should be added when edit flows are implemented.

### EventPhoto

```text
id
storagePath
downloadUrl
uploadedBy
createdAt
```

Keep image dimensions and content type later if needed:

```text
width
height
contentType
sizeBytes
```

### Reminder

```text
id
eventId
remindAt
offsetMinutes
enabled
createdAt
updatedAt
```

`offsetMinutes` is useful for UI choices such as 10 minutes before, 1 hour before, or 1 day before. `remindAt` is useful for actual scheduling. Store both when possible.

### LinkedItem

```text
type
id
title
date
preview
```

Possible `type` values:

```text
todo
date_record
conflict
anniversary
review
place
```

The calendar should render linked items generically. Feature-specific screens can provide richer UI later.

Recommended expanded shape:

```text
type
targetId
targetPath
title
subtitle
date
thumbnailUrl
preview
createdAt
```

- `type` tells the calendar which icon or fallback label to use.
- `targetId` identifies the linked record.
- `targetPath` can point to the Firestore document path or app route.
- `title`, `subtitle`, `thumbnailUrl`, and `preview` are denormalized display fields.
- If the original record changes, the owning feature is responsible for updating the preview when necessary.

Use a generic fallback UI for unknown `type` values.

## Future Feature Ownership

Feature records should be owned by their feature collection:

- Todo owns todo status, due date, completion, and checklist details.
- Date records own place details, photos, and date-specific memory notes.
- Conflict records own conflict content, resolution state, and sensitive metadata.
- Anniversary records own recurrence rules and D-day calculations.
- Reviews own category, rating, body, provider metadata, and review photos.

Calendar events should only store `linkedItems` that reference these records.

## Firestore Shape

Start with a couple-centered data shape:

```text
users/{userId}
couples/{coupleId}
couples/{coupleId}/events/{eventId}
couples/{coupleId}/todos/{todoId}
couples/{coupleId}/dateRecords/{dateRecordId}
couples/{coupleId}/conflicts/{conflictId}
couples/{coupleId}/reviews/{reviewId}
couples/{coupleId}/anniversaries/{anniversaryId}
```

This keeps shared data scoped by couple and makes security rules easier to reason about.

Expected event query:

```text
couples/{coupleId}/events
  where deletedAt == null
  where startAt < visibleRangeEnd
  where endAt >= visibleRangeStart
  orderBy startAt
```

Firestore may require composite indexes for calendar range queries. If the exact query becomes awkward because of optional `endAt`, add a normalized `rangeStartAt` and `rangeEndAt`.

## Repository Contracts

Start with clear repository responsibilities even if the first implementation is simple.

```text
AuthRepository
  authStateChanges()
  signIn(...)
  signOut()

CoupleRepository
  watchCurrentCouple(userId)
  createCouple(userId)
  joinCouple(inviteCode, userId)

CalendarEventRepository
  watchEvents(coupleId, visibleRange)
  createEvent(coupleId, input)
  updateEvent(coupleId, event)
  deleteEvent(coupleId, eventId)

PhotoRepository
  uploadEventPhoto(coupleId, eventId, file)
  deleteEventPhoto(coupleId, eventId, photoId)

ReminderService
  scheduleReminder(event, reminder)
  cancelReminder(reminderId)
```

Repositories may be concrete classes at first. Add interfaces or abstract classes when tests or alternate implementations need them.

## Storage Shape

```text
couples/{coupleId}/events/{eventId}/photos/{photoId}.jpg
couples/{coupleId}/reviews/{reviewId}/photos/{photoId}.jpg
```

Do not store large image bytes in Firestore. Store metadata and download URLs only.

## Time Rules

- Store timestamps in UTC in Firebase.
- Convert to local time only at the UI boundary.
- Date-only values, such as anniversaries, should be modeled explicitly instead of pretending midnight is always safe.
- Calendar queries should fetch a visible date range, not all events forever.
- Use an explicit visible range object for month/week/day screens.
- Normalize all-day events so they sort predictably.

## State Management

Riverpod owns screen-facing state:

- Auth session.
- Current user profile.
- Current couple.
- Selected calendar date.
- Visible calendar range.
- Events in visible range.
- Event editor form state.
- Photo upload state.
- Reminder state.

Widgets should read state and dispatch actions. They should not call Firestore directly.

Suggested provider groups:

```text
authStateProvider
currentUserProvider
currentCoupleProvider
visibleCalendarRangeProvider
selectedDateProvider
calendarEventsProvider
eventEditorControllerProvider
photoUploadControllerProvider
reminderServiceProvider
```

Provider names can change, but keep the responsibilities separate.

## Navigation

Use a simple routing setup initially:

```text
/
/home
/sign-in
/couple
/calendar
/calendar/events/:eventId
/settings
```

Add nested routes only when the app has multiple mature feature areas.

See `docs/navigation-and-screens.md` for current product navigation direction.

## Anniversaries

Anniversaries and D-days should be their own feature rather than regular calendar events.

Recommended stored model:

```text
Anniversary
id
coupleId
title
baseDate
kind
createdBy
createdAt
updatedAt
deletedAt
```

The calendar should compute and display generated occurrences such as 100 days, 200 days, 1 year, and yearly anniversaries. These generated occurrences should not be stored as ordinary `CalendarEvent` records unless the user explicitly creates a related event.

## Notifications

Early MVP:

- Use local notifications for reminders on the current device.
- Ask for notification permission only when the user creates or enables a reminder.
- Store reminder settings even if notification permission is denied.

Later:

- Use FCM plus backend scheduling for reliable cross-device reminders.
- Web notifications should be handled separately because browser permission and delivery behavior differs from mobile.

## Maps

Do not couple the domain model directly to Google Maps or Naver Maps SDK objects.

Use a neutral place model:

```text
provider
providerPlaceId
name
address
latitude
longitude
url
```

This allows Google Maps and Naver Maps to coexist.

## Privacy And Safety

- Couple data is private to the two linked users.
- Firestore security rules must ensure only couple members can read or write couple data.
- Uploaded photos must be scoped under the couple id.
- Conflict records may be emotionally sensitive; do not surface them too aggressively in calendar UI.

Minimum security rule intent:

- A signed-in user can read their own `users/{userId}` document.
- A signed-in user can read or write a `couples/{coupleId}` document only if their uid is in `memberIds`.
- A signed-in user can read or write subcollection records only under couples where they are a member.
- Storage access follows the same couple membership rule.

## Platform Notes

- iOS is the first quality target.
- Web should support the same core calendar and data views, but native features such as photo picking and notifications may need platform-specific implementations.
- Android should not require a major rewrite if feature code avoids iOS-only assumptions.

## Implementation Order

Recommended order for future coding work:

1. Add dependencies and app bootstrap.
2. Create immutable domain models.
3. Add mock repositories and local calendar UI.
4. Implement event create/edit/detail flow with mock data.
5. Connect Firebase Auth.
6. Connect couple creation/joining.
7. Connect Firestore event persistence.
8. Add Firebase Storage photo upload.
9. Add local notification reminders.
10. Add tests around date range logic, model serialization, and calendar providers.
