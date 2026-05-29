# Product Spec

This is the current working product specification. Update it when product decisions change.

For scenario-level behavior, navigation expectations, and cross-screen
acceptance criteria, see `docs/product/user-scenarios.md`.

For calendar-specific event time, multi-day rendering, and user color rules,
see `docs/product/calendar-spec.md`.

## Product

Couple Calendar is a shared relationship calendar for couples.

The app should combine:

- Shared schedules.
- Couple bucket lists.
- Date records.
- Anniversaries and D-days.
- Conflict records.
- Reviews for consumed content.
- Photos and reminders.

## Current Navigation

Top-level tabs:

```text
Home
Calendar
Records
Settings
```

Records contains:

```text
Anniversaries
Bucket list
Date records
Conflict records
Reviews
```

## Calendar

The calendar is the central timeline.

Current behavior:

- Month view.
- Event creation.
- Event editing from event detail.
- Multi-day and overnight event support through explicit start/end date-time.
- Event detail.
- Memo and reminders.
- Linked items.
- Anniversary markers.
- Linked item emoji summary on the selected date panel.
- Linked item photo thumbnail summary on the selected date panel when linked
  records have photos.
- Linked item removal from event detail.
- New event creation can attach bucket list links before saving. Todo links
  selected during creation are converted into `TodoCompletion` records after
  the event is saved, then attached back to the event as real linked items.

Decision:

- Calendar events should not own photos directly.
- Photos should live in linked records such as date records, reviews, or later
  place records.
- Calendar may display small thumbnails from linked records through
  `LinkedItem.thumbnailUrl`.
- Multi-day events should render as continuous bars/lines across day cells, not
  as disconnected dots.
- Calendar supports 내 일정, 상대 일정, and 우리 일정.
- Couple member profile colors distinguish personal ownership.
- Our events use a distinct shared/couple visual treatment.
- Event category color is secondary to creator/user color.

Calendar events can link to other modules through `LinkedItem`.

Each linked module should have a representative emoji so calendar summaries can
stay compact:

```text
todo: 🧭
date record: 📍
anniversary: 🎉
review: ⭐
place: 🗺️
```

## Accepted Product Decisions

- Linked item taps should eventually open real detail pages. Until detail pages
  exist, they should open the owning module or a clear placeholder.
- Date records and reviews should support the same calendar
  linking pattern as bucket list completions: link to an existing event or
  create a new event.
- Conflict/fight records are out of the MVP and should not appear in the app
  navigation until explicitly reintroduced.
- `TodoItem` is a reusable goal. `TodoCompletion` is the actual dated
  achievement.
- `TodoCompletion` should stay lightweight. Long memories, photos, and places
  should live in date records or other linked records attached to the same
  calendar event.
- Home is a summary/dashboard, not a creation-heavy command center.
- Generated anniversaries should stay computed by default. Users may later add
  a generated anniversary as a normal event or enable reminders explicitly.
- Calendar event creator/user color is the primary color signal. Category color
  can be added later as a secondary accent.
- Users can edit/delete 내 일정 and 우리 일정.
- Users cannot edit/delete 상대 일정.
- Users receive reminders for 내 일정 and 우리 일정.
- Users can watch 상대 일정 to receive reminders/updates for that event.
- Repeating events are deferred until after the first release.
- Month view plus selected-day panel is enough for the first release.

## Bucket List

The old Todo concept is now a couple bucket list.

Model:

```text
TodoCategory
TodoItem
TodoCompletion
```

Example:

```text
등산 하기
- 하남검단산 가기
- 남산 가기
```

Important rule:

- A `TodoItem` can be completed multiple times.
- Each completion can link to a different calendar event/date.
- The completion, not the item itself, represents a specific achieved date.

## Bucket List And Calendar Linking

All three linking scenarios should be supported.

### 1. Existing Calendar Event To Bucket Item

Flow:

1. User opens a calendar event detail.
2. User taps "데이트 기록에 버킷리스트 추가".
3. User selects a bucket category/item.
4. App creates a `TodoCompletion`.
5. App ensures the event has a linked date record.
6. App adds `LinkedItem(type: todo)` to the date record, not directly to the
   calendar event.

### 2. Bucket Item To Existing Calendar Event

Flow:

1. User opens bucket list.
2. User taps "달성" on an item.
3. User selects "기존 일정에 연결하기".
4. App shows a calendar picker with small event titles inside date cells.
5. User selects a date.
6. App shows existing events for that date with title, time, memo preview, linked item count, and linked item emojis.
7. User selects an event.
8. App creates a `TodoCompletion`.
9. App ensures the selected event has a linked date record.
10. App adds `LinkedItem(type: todo)` to the date record, not directly to the
    calendar event.

### 3. Bucket Item To New Calendar Event

Flow:

1. User opens bucket list.
2. User taps "달성" on an item.
3. User selects "새 캘린더 일정 만들기".
4. App opens a calendar picker first so the user can choose the target date.
5. User chooses a date and opens the event editor.
6. App opens the event editor prefilled with the bucket item title and memo.
7. Event editor shows the bucket item as a pending linked item before save.
8. User edits and saves the event.
9. App creates a `TodoCompletion`.
10. App creates or reuses the new event's date record.
11. App adds `LinkedItem(type: todo)` to the date record, not directly to the
    calendar event.

If the user tries to link to an existing event on a date with no events, the app asks whether to create a new event and then opens the event editor.

## Unlinking

Current MVP behavior:

- Calendar event detail lets the user remove a linked item.
- Removing a todo linked item also removes the matching `TodoCompletion` when it exists.

Future refinement:

- Separate "remove calendar link" from "delete completion record" if users need to keep an unlinked completion history.
- Decide whether removing a linked item inside the edit sheet should also remove
  the related module record, or whether destructive unlinking should stay only
  in event detail.

## Date Records

Date records are actual date memories.

Current behavior:

- User can create date record with title, date, place name,
  address/description, memo, and photo attachments.
- Saving a date record creates an all-day calendar event.
- The event links back with `LinkedItem(type: dateRecord)`.

Map provider details should stay provider-neutral:

```text
PlaceSnapshot
- manual
- googleMaps
- naverMaps
```

## Anniversaries

Anniversaries are generated from a base date.

Current behavior:

- Anniversaries are registered inside the couple space after onboarding.
- Users can freely add anniversary records with a title, base date, calendar type, and repeat rule.
- Anniversary records are owned by the anniversary module and saved through the anniversary repository. With Firebase enabled, records are stored under `couples/{coupleId}/anniversaries`.
- Calendar type supports solar and Korean lunar dates. Lunar dates should be converted to solar dates before being shown on the calendar.
- Supported MVP repeat rules are `100 days`, `yearly`, and `100 days + yearly`.
- Typical records include first meeting date, wedding anniversary, and parents' birthdays.
- The anniversary screen shows registered records and one next occurrence per record.
- Generated occurrences appear in calendar, home, and anniversary screens.
- Opening an occurrence from the anniversary screen should move the user to the calendar date.

Generated occurrences should not be stored as ordinary calendar events by default.

## Deferred

- Real Firebase Auth.
- Real couple invite persistence.
- Firebase Storage photo upload.
- Map SDK integration.
- Conflict records.
- Reviews.
- Fine-grained permission model.
