# Navigation And Screens

This document captures the current screen direction. It is allowed to evolve, but future coding agents should update this file when navigation decisions change.

For user journeys and scenario-level acceptance criteria, see
`docs/product/user-scenarios.md`.

For month grid rendering, multi-day events, and couple member colors, see
`docs/product/calendar-spec.md`.

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
Reviews
```

Todo, date records, and reviews should own their own data and link to calendar
through `LinkedItem`.

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
- Show multi-day events as continuous bars/lines across the relevant day cells.
- Show anniversary markers.
- Show generic linked item markers.
- Show representative linked item emojis in the selected date summary.
- Show small photo thumbnails in the selected date summary when linked records
  provide `LinkedItem.thumbnailUrl`.
- Let users create calendar events.
- Let users connect bucket list items while creating a calendar event.
- Let users open event details.
- Let users edit an existing event from event detail.
- Show ownership labels: 내 일정, 상대 일정, 우리 일정.
- Disable edit/delete for 상대 일정.
- Let users watch/unwatch 상대 일정.

Calendar should not own full todo, conflict, review, or map workflows.
Calendar should also not own photos directly; photos belong to linked records.
Calendar should use the event creator's couple-member color as the primary
event color signal for personal events. Our events should use a distinct shared
visual treatment.

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
- Anniversaries and D-days.
- Todos.
- Reviews.

Conflict/fight records are out of the MVP and should not appear in app
navigation until explicitly reintroduced.

## Date Records Screen

Purpose:

- Record actual dates after they happened.
- Store date, title, memo, place snapshot, and photo metadata.
- Link the date record to a calendar event with `LinkedItem(type: dateRecord)`.

Current mock behavior:

- Users can create a date record with title, date, place name,
  address/description, memo, and photo attachments.
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
- User A/B profile colors.
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

The couple should be able to register important dates after creating or joining
a couple space. Onboarding should not force the first meeting date.

Each anniversary has a title, base date, calendar type, and repeat rule.
The UI should not force users to choose a semantic type such as birthday or
wedding anniversary.

MVP calendar types:

- solar
- Korean lunar

MVP repeat rules:

- every 100 days
- every year
- every 100 days and every year

The anniversary screen should show registered anniversary records and one next
occurrence per record. Generated occurrences should also appear in the calendar
for any visible month.

Recommended model:

```text
Anniversary
id
coupleId
title
baseDate
calendarType
isLeapMonth
repeatRule
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

Tapping an anniversary occurrence or its calendar shortcut should select that
date and move the user to the calendar tab.

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
