# Product Spec

This is the current working product specification. Update it when product decisions change.

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
  conflict/place records.
- Calendar may display small thumbnails from linked records through
  `LinkedItem.thumbnailUrl`.

Calendar events can link to other modules through `LinkedItem`.

Each linked module should have a representative emoji so calendar summaries can
stay compact:

```text
todo: 🧭
date record: 📍
conflict: 💬
anniversary: 🎉
review: ⭐
place: 🗺️
```

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
2. User taps "버킷리스트 연결".
3. User selects a bucket category/item.
4. App creates a `TodoCompletion`.
5. App adds `LinkedItem(type: todo)` to the calendar event.

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
9. App adds `LinkedItem(type: todo)` to the calendar event.

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
10. App adds `LinkedItem(type: todo)` to the new calendar event.

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

- User can create date record with title, date, place name, address/description, memo, and photo labels.
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

- Base date comes from mock couple onboarding.
- App computes milestones such as 100 days, 200 days, 1 year, and yearly anniversaries.
- Generated occurrences appear in calendar/home/anniversary screens.

Generated occurrences should not be stored as ordinary calendar events by default.

## Deferred

- Real Firebase Auth.
- Real couple invite persistence.
- Firebase Storage photo upload.
- Map SDK integration.
- Conflict records.
- Reviews.
- Fine-grained permission model.
