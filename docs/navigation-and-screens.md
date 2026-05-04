# Navigation And Screens

This document captures the current screen direction. It is allowed to evolve, but future coding agents should update this file when navigation decisions change.

## Current Thinking

The app should not be only a calendar screen forever. The calendar is the center of the product, but other modules need their own places to create and review content.

Current first navigation:

```text
Home
Calendar
Records
Settings
```

Records is the hub for modules that are not pure calendar navigation:

```text
Anniversaries
Todos
Date records
Conflict records
Reviews
```

Todo, date records, conflict records, and reviews can start as placeholder screens, but each should eventually own its own data and link to calendar through `LinkedItem`.

## Home Screen

The home screen is likely needed because couples need a quick daily summary, not only a month grid.

Possible home content:

- Today and upcoming events.
- Next anniversary or D-day.
- Recently added photos or memories.
- Open todos for date ideas.
- Gentle prompts such as "review yesterday's date" later.
- Current signed-in user and couple connection state.

Do not make the home screen a marketing page. It should be an app dashboard.

Current behavior:

- Today count is based on events happening today.
- Upcoming events include only today or future events, sorted by UI event order.
- The calendar action switches to the calendar tab.
- Tapping an upcoming event opens the event detail.

## Calendar Screen

Calendar remains the central timeline.

Responsibilities:

- Show month/week/day calendar views over time.
- Show shared schedules.
- Show anniversary markers.
- Show generic linked item markers.
- Show representative linked item emojis in the selected date summary.
- Show small photo thumbnails in the selected date summary when linked records
  provide `LinkedItem.thumbnailUrl`.
- Let users create calendar events.
- Let users connect bucket list items while creating a calendar event.
- Let users open event details.
- Let users edit an existing event from event detail.

Calendar should not own full todo, conflict, review, or map workflows.
Calendar should also not own photos directly; photos belong to linked records.

## Todo Screen

Purpose:

- Work as a couple bucket list.
- Let users create categories, such as "등산 하기".
- Let users add detailed items under each category, such as "하남검단산 가기" or "남산 가기".
- Let the same item be completed multiple times.
- Link each completion record to a calendar date or event.

When a todo item is completed, the todo module owns the category, item, and completion data. The calendar gets a `LinkedItem`.

Current mock behavior:

- Users can add todo categories.
- Users can add detailed items inside a category.
- Users can add multiple completion records for the same item by selecting a date.
- Completing an item lets the user choose between opening the event editor for a new calendar event or linking to an existing event on the selected date.
- Existing event selection should show a calendar with event title hints in date cells, then event title, time, memo preview, linked item count, and linked item emojis for the selected date.
- If there is no existing event on the selected date, the app asks whether to create a new calendar event and then opens the event editor.
- New calendar event creation from a bucket item should show a calendar/date
  picker first, then open the event editor with the bucket item already shown as
  a pending link before save.
- The linked calendar event includes a `LinkedItem` with `type: todo`.
- Each `TodoCompletion` stores the linked calendar event id.
- Completion chips can jump back to the linked calendar date.
- Calendar event detail can also link an existing event to a bucket item.
- Calendar event detail can unlink a bucket item.

Recommended model:

```text
TodoCategory
TodoItem
TodoCompletion
```

## Records Screen

This is the grouped area for relationship records.

Current sections:

- Date records.
- Conflict records.
- Anniversaries and D-days.
- Todos.
- Reviews.

Conflict records are sensitive. Avoid placing detailed fight content directly on the home screen or calendar.

## Date Records Screen

Purpose:

- Record actual dates after they happened.
- Store date, title, memo, place snapshot, and photo metadata.
- Link the date record to a calendar event with `LinkedItem(type: dateRecord)`.

Current mock behavior:

- Users can create a date record with title, date, place name, address/description, memo, and photo labels.
- The place model is provider-neutral so Google Maps and Naver Maps can be added later.
- Saving a date record creates an all-day calendar event.
- The created calendar event includes a `LinkedItem` with `type: dateRecord`.
- The date record stores the linked calendar event id in `linkedEventId`.

## Review Screen

Purpose:

- Record consumed content such as movies, dramas, wine, restaurants, exhibitions, books, or similar experiences.
- Store category, title, rating, notes, date, photos, and optional place/provider metadata.
- Link a review to a calendar date or event.

Reviews should own ratings and review body. Calendar should only show linked previews.

## Settings Screen

Purpose:

- Signed-in user profile.
- Current couple information.
- Invite/join couple flow.
- Notification permissions.
- Firebase/account settings later.

## User Identity In UI

The app must eventually show:

- Which user is currently signed in.
- Which couple space is active.
- Who created each event.
- Potentially who last edited each event.

MVP can use demo ids, but the model already includes `createdBy`.

Recommended display:

- Event detail: "created by {displayName}".
- Event list: small avatar or initials when useful.
- Settings: current user and partner.

## Anniversaries And D-Days

The couple should be able to register important dates such as first meeting date or relationship start date.

After a base date is registered, the app should generate derived anniversary occurrences:

- 100 days
- 200 days
- 300 days
- 1 year
- 2 years
- yearly anniversaries after that

Recommended model:

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
```

Generated occurrences should usually be computed, not permanently written as many calendar events.

Recommended generated shape:

```text
AnniversaryOccurrence
anniversaryId
title
date
label
dayCount
yearCount
```

Calendar can display anniversary occurrences alongside events, but should distinguish them from editable user-created events.

Open question:

- Should generated anniversaries create notifications by default, or only if the user enables them?

## Suggested Routing

Initial routes:

```text
/
/home
/calendar
/calendar/events/:eventId
/records
/records/anniversaries
/settings
```

Later routes:

```text
/todos
/todos/:todoId
/records
/records/dates/:dateRecordId
/records/conflicts/:conflictId
/records/anniversaries/:anniversaryId
/reviews
/reviews/:reviewId
```

Use tab navigation for top-level app areas and push detail screens on top.
