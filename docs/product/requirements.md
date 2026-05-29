# Couple Calendar Requirements

## Product Summary

Couple Calendar is a calendar-based app for couples to share schedules, record memories, and connect relationship-related content to specific dates.

The product should start as an iOS-first Flutter app with web support. Android should be supported later from the same Flutter codebase.

The first useful version should answer one question well: "What happened, what is planned, and what memories or relationship records are connected to this day?"

## Target Users

- A couple that wants one shared place for plans and memories.
- Users who want emotional and personal context, not just productivity scheduling.
- Users who may add records quickly on mobile and later review them on mobile or web.

## Product Terms

- `Couple`: the private shared space for two users. MVP assumes exactly two members.
- `CalendarEvent`: a schedule or date-based record shown directly on the calendar.
- `LinkedItem`: a lightweight reference from a calendar event or date to another feature's record.
- `DateRecord`: a future module for actual date memories, places, photos, and notes.
- `ConflictRecord`: a future module for fight/conflict records.
- `Review`: a future module for consumed content such as movies, dramas, wine, restaurants, books, or exhibitions.

## Original Long-Term Requirements

The app is basically a calendar-based application used together by a couple.

Through the calendar, it should support:

1. Sharing schedules with each other.
2. Recording dates, including location registration through Google Maps or Naver Maps.
3. Managing a todo list in a separate app area, then linking completed date-related todos back to the calendar so users can see which todos were completed on a date.
4. Recording conflicts or fights in a separate app area, then linking those records to the calendar.
5. Recording D-days and anniversaries.
6. Recording consumed content such as movies, dramas, wine, exhibitions, restaurants, and similar experiences with reviews and star ratings.
7. Uploading photos.

## First MVP Scope

The first build should focus on a flexible calendar core instead of trying to implement every module at once.

Included:

- Basic sign-in flow.
- Couple creation or invite-based couple joining.
- Shared calendar event list.
- Monthly calendar view.
- Event creation, editing, and deletion.
- Event title, explicit start date/time, explicit end date/time, all-day
  option, and creator/user color display.
- Multi-day and overnight events.
- Event ownership: 내 일정, 상대 일정, 우리 일정.
- Ownership-based edit/delete permissions.
- Watch support for partner personal events.
- Simple memo on each event.
- Reminder setting on each event.
- A flexible linked-content model so future modules can attach their records to calendar events.
- Simple event detail screen that shows memo, reminders, and linked items.
- Photo upload on linked records such as date records and reviews. Calendar
  displays only lightweight linked thumbnails/previews.
- Basic distinction between the signed-in user, partner, and event creator once auth is connected.

Deferred:

- Full todo module.
- Full date-record module with maps.
- Full conflict journal module.
- Full anniversary/D-day module.
- Full content review module.
- Recurring events.
- Shared editing permissions beyond "both couple members can edit."
- Offline-first conflict resolution.
- Full home dashboard.
- Advanced search, feeds, analytics, or social features.

## Product Principles

- The calendar is the center, but it should not become a giant object that directly owns every feature.
- Other features should be independently modeled and linked to calendar events.
- The app should feel personal, calm, and useful for everyday relationship memory keeping.
- Avoid building a generic productivity calendar. The experience should support couples: shared plans, memories, emotional context, and reviewable history.
- Every record that can matter on a date should eventually be linkable to that date.
- Prefer a small working core over incomplete versions of many modules.
- Sensitive records, especially conflict records, should be visible only when the user intentionally opens them.

## Key User Flows

### Create Or Join A Couple

1. User signs in.
2. User creates a couple space or enters an invite code.
3. Both users can see the same shared calendar after joining.
4. MVP should support one active couple per user.

### Create A Calendar Event

1. User opens the calendar.
2. User selects a date.
3. User taps add.
4. User enters title, start/end date and time, memo, and reminder.
5. User chooses 내 일정 or 우리 일정.
6. Event appears on both users' shared calendar with ownership styling.

### Review A Day

1. User selects a calendar date.
2. App shows schedules and linked records for that date.
3. User can open event details, photos, completed todos, date records, conflict notes, anniversaries, or reviews when those modules exist.

### See Upcoming Relationship Milestones

1. User creates or joins a couple space first.
2. User registers anniversaries such as first meeting date, wedding anniversary, or parents' birthdays.
3. User selects solar or Korean lunar repeat mode. For Korean lunar anniversaries, the selected year/month/day is stored as the lunar base date and converted to solar dates for calendar display.
4. User selects a repeat rule such as every 100 days, every year, or both.
5. App computes future anniversary occurrences from each base date.
6. Calendar shows those dates as anniversary markers.
7. User can open a generated occurrence on the calendar from the anniversary screen.

### Attach Future Content To A Date

1. User creates content in another module, such as a todo, fight record, or movie review.
2. User links it to a date or event.
3. Calendar displays a small reference to that content.

### Receive A Reminder

1. User adds a reminder to an event.
2. App schedules a notification for that user's device.
3. User receives the reminder at the chosen time when platform permissions allow it.
4. Later versions should synchronize reminder delivery across both users and devices.

## MVP Acceptance Criteria

The MVP is acceptable when:

- A user can sign in.
- A user can create or join a couple.
- A couple member can create, edit, delete, and view shared calendar events.
- Events are fetched by visible calendar range.
- Events can span multiple days.
- Multi-day events are visible as continuous ranges on the month calendar.
- Creator/user colors distinguish 내 일정 and 상대 일정.
- 우리 일정 has a distinct shared visual treatment.
- Current user can edit/delete 내 일정 and 우리 일정.
- Current user cannot edit/delete 상대 일정.
- Current user can watch 상대 일정.
- An event can contain a memo.
- An event can contain at least one reminder setting.
- Linked records such as date records can contain photos and expose a
  lightweight thumbnail/preview on the calendar.
- Both couple members can see the same shared events after refresh.
- The data model can represent future linked items without changing the `CalendarEvent` shape drastically.

## Extension Requirements

Future modules must follow this rule:

- The module owns its own data.
- The calendar owns only a lightweight link or preview.
- The calendar can render unknown linked item types in a generic way.

Example:

```text
Review record owns title, category, rating, body, photos, and provider metadata.
CalendarEvent owns only a LinkedItem pointing to that review.
```

This prevents the calendar model from becoming a large mixed schema containing every product feature.

## Scenario Contract

Feature implementation should follow `docs/product/user-scenarios.md`.
Calendar-specific implementation should also follow `docs/product/calendar-spec.md`.

Before implementing a screen or interaction, identify the scenario, source
screen, target screen after save, link ownership, and correction/unlink path.
If the scenario is missing or ambiguous, update that document first.

## Non-Goals For Early Versions

- Do not implement complex social networking.
- Do not support more than one couple per user unless explicitly needed.
- Do not build a public marketing website inside the Flutter app.
- Do not optimize for SEO in the app UI.
- Do not build admin tooling until real operational needs appear.

## Assumptions

- MVP supports one couple per user.
- Most records are shared with both couple members by default.
- Both members can create, edit, and delete shared calendar events in MVP.
- Firebase is acceptable as the first backend even if a custom backend is introduced later.
- iOS quality matters first; web should be usable but does not need every native capability on day one.

## Open Questions

These are intentionally unresolved. Do not block MVP implementation unless a feature depends on the answer.

- Sign-in providers: email/password, Apple, Google, Kakao, or Naver?
- Should event deletion be undoable from the UI?
- Should watched partner events notify about all changes, or reminders only?
- Should conflict records appear as visible calendar markers, or only inside a protected/private view?
- Should reminders notify one user, both users, or whoever created the reminder?
- What photo limits should exist per linked record type?
- Should date records be separate from calendar events, or should a calendar event become a date record after the date passes?
- Which map provider should be implemented first for Korea-focused use: Naver Maps or Google Maps?
- What should the first home screen show: upcoming events, anniversaries, recent records, or a compact mix?
