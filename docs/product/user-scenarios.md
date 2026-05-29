# User Scenarios

This document is the scenario-level product contract for Couple Calendar.

Use this before implementing screens. A feature is not done only because a
screen exists; it is done when the user can complete the relevant scenario
without reaching a dead end.

## Core Principle

The app is a relationship timeline.

Users should be able to answer:

- What is planned?
- What happened on this day?
- Which memories, bucket list completions, reviews, conflicts, photos, and
  anniversaries are connected to this date?
- Can I move from a summary to the real detail without guessing where to go?

## Product Objects

### CalendarEvent

A calendar event is the time/date container.

It owns:

- title
- explicit start/end date-time range
- all-day state
- memo
- reminder settings
- ownership label: 내 일정, 상대 일정, or 우리 일정
- creator/user color or shared/couple visual treatment
- lightweight `LinkedItem` references

It does not own:

- photos
- review body/rating
- place search details beyond a preview
- conflict content
- bucket list category/item data

### LinkedItem

A linked item is a lightweight bridge from the calendar to another module.

It must contain enough display data for summaries:

- type
- target id/path
- title
- optional subtitle
- optional date
- optional thumbnail URL or photo attachment label
- optional preview text
- representative emoji derived from type

Every visible linked item chip or row must be tappable. If the real detail page
does not exist yet, it may open the owning module or a placeholder detail, but
it must not be inert.

### Module Records

Feature modules own their full content:

- `TodoCategory`, `TodoItem`, `TodoCompletion`
- `DateRecord`
- `ConflictRecord`
- `Review`
- `Anniversary`

The calendar only stores links/previews to those records.

## Navigation Rules

- Top-level tabs are Home, Calendar, Records, Settings.
- Records is the hub for Anniversaries, Bucket List, Date Records, Conflict
  Records, and Reviews.
- Calendar is the central timeline, but it must not be the only way to reach
  module records.
- Any summary row/chip/card shown on Home or Calendar must either open the
  related detail screen or move the user to the closest available owning module.
- If a flow creates something that appears on the calendar, the user must be
  able to navigate back from the source module to the calendar result.
- If a flow starts from Calendar and links another module, the linked module
  must reflect the result when the user opens that module later.
- Calendar events can span multiple days and should render as continuous
  ranges, not disconnected dots.
- Couple member colors should distinguish personal events throughout calendar
  surfaces.
- Our events should have a distinct shared/couple visual treatment.

## Scenario 1: Daily Check From Home

Goal: the user opens the app and quickly understands today and what is next.

Flow:

1. User opens Home.
2. App shows today's schedule count.
3. App shows the next anniversary or D-day.
4. App shows upcoming events sorted by actual date/time, not by event type.
5. User taps an upcoming event.
6. App opens that event detail.
7. User taps "캘린더에서 보기".
8. App switches to Calendar.

Acceptance criteria:

- Upcoming events include only today or future events.
- Sorting is date-first, then all-day/time/title within the same day.
- Empty state appears when there are no upcoming events.
- Tapping a listed event never does nothing.

## Scenario 2: Review A Calendar Day

Goal: the user selects a date and reviews everything connected to that day.

Flow:

1. User opens Calendar.
2. User selects a date.
3. App shows events for the selected date.
4. App shows anniversary markers for the selected date.
5. App shows linked item summary chips with representative emojis.
6. If linked records have photos, App shows small photo thumbnails/labels.
7. User taps an event.
8. App opens event detail.
9. User taps a linked item chip/photo summary.
10. App opens the linked record detail or owning module.

Acceptance criteria:

- Calendar day cells show enough event information to choose a date in linking
  flows.
- Selected-day linked summary is tappable.
- Linked photo summary is sourced from linked records, not from event-owned
  photos.
- Calendar event rows do not show a photo icon for event-owned photos.

## Scenario 3: Create A Plain Calendar Event

Goal: the user creates a shared schedule that is not necessarily a memory.

Flow:

1. User opens Calendar.
2. User selects a date.
3. User taps add event.
4. App opens event editor with selected date.
5. User enters title, optional memo, start/end date-time, all-day state, and
   reminder.
6. User chooses 내 일정 or 우리 일정.
7. User saves.
8. App returns to Calendar with the new event visible on the selected date.

Acceptance criteria:

- Event editor date defaults to the selected calendar date.
- User can change start and end date/time in the editor.
- Multi-day and overnight events are supported.
- Multi-day events render as continuous bars/lines in the month grid.
- Event creation does not ask for photos.
- Event can be edited and deleted from event detail.
- Reminder setting remains on the calendar event.
- User cannot create 상대 일정 directly; 상대 일정 appears when the partner
  creates a personal event.

## Scenario 4: Create Calendar Event From Bucket List Completion

Goal: the user creates an event from a bucket list completion and stores the
completion under the resulting date record.

Flow:

1. User opens Calendar.
2. User selects a date.
3. User taps add event.
4. App opens the event editor prefilled from the bucket item.
5. Event editor shows the bucket item as a pending preview.
6. User saves event.
7. App creates the event.
8. App creates or reuses a linked date record for the event.
9. App creates a `TodoCompletion` for the selected bucket item on the event
   date.
10. App attaches `LinkedItem(type: todo)` to the date record, not directly to
    the event.

Acceptance criteria:

- Pending links are visible before save.
- Saved links are real completions, not placeholder todo ids.
- The bucket list page shows the completion after save.
- The completion chip can navigate back to the calendar date.

## Scenario 5: Complete Bucket Item By Linking Existing Event

Goal: the user did something that already has a calendar event and wants to mark
a bucket item completed.

Flow:

1. User opens Records > Bucket List.
2. User creates or finds a category such as "등산 하기".
3. User creates or finds an item such as "남산 가기".
4. User taps "달성".
5. User chooses "기존 일정에 연결하기".
6. App opens a calendar picker.
7. Calendar date cells show event title hints.
8. User selects a date.
9. App lists that date's existing events with title, time, memo preview, linked
   count, and linked emojis.
10. User selects an event.
11. App creates a `TodoCompletion`.
12. App ensures the event has a linked date record.
13. App attaches a todo linked item to the date record, not directly to the
    event.

Acceptance criteria:

- User can choose the correct event without guessing from a blank calendar.
- The same `TodoItem` can be completed multiple times.
- Each completion can point to a different calendar event/date.
- Event detail shows the linked date record; the date record shows the linked
  bucket item.
- Bucket list completion chip can jump to the calendar date.

## Scenario 6: Complete Bucket Item By Creating New Event

Goal: the user completed a bucket item and wants to create the calendar event at
the same time.

Flow:

1. User opens Records > Bucket List.
2. User taps "달성" on an item.
3. User chooses "새 캘린더 일정 만들기".
4. App opens a calendar/date picker first.
5. User selects the target date.
6. User taps "새 일정 편집하기".
7. App opens event editor with the item title/memo prefilled.
8. Event editor shows the bucket item as a pending link.
9. User edits the schedule and saves.
10. App creates the event, creates or reuses a date record, creates a
    `TodoCompletion`, and links the completion to the date record.

Acceptance criteria:

- The flow does not jump straight to today's date.
- Date selection happens before event editing.
- The user can still change the date in the editor if needed.
- Completion date follows the saved event date.

## Scenario 7: Link Calendar Event To Bucket Item From Detail

Goal: the user opens an existing event and decides it completed a bucket item.

Flow:

1. User opens Calendar.
2. User opens an event detail.
3. User taps "데이트 기록에 버킷리스트 추가".
4. App opens bucket item picker grouped by category.
5. User selects an item.
6. App creates a `TodoCompletion` on the event date.
7. App attaches the linked item to the event's date record, not directly to the
   event.

Acceptance criteria:

- Date record detail updates after linking.
- Bucket list completion history updates.
- Duplicate links to the same completion are not created.

## Scenario 8: Unlink Or Correct Mistakes

Goal: the user can undo a wrong link.

Flow:

1. User opens event detail.
2. User sees linked items.
3. User taps unlink on a linked item.
4. App asks for confirmation.
5. App removes the link.
6. If the linked item is a todo completion, current MVP also removes the
   matching `TodoCompletion`.

Acceptance criteria:

- Every linked item visible in event detail has an unlink affordance.
- Destructive unlinking asks for confirmation.
- Future decision: support "remove link only" without deleting the module
  record.

## Scenario 9: Create A Date Record With Photos And Place

Goal: the user records an actual date memory after it happened.

Flow:

1. User opens Records > Date Records.
2. User enters title, date, place name/address, memo, and photos.
3. User saves.
4. App creates a `DateRecord`.
5. App asks whether to link to an existing event or create a new event when
   there is no obvious target event.
6. If linking existing, App shows the common existing-event calendar picker.
7. If creating new, App opens event editor with pending date-record link.
8. App attaches `LinkedItem(type: dateRecord)` to the event.
9. The linked item includes a thumbnail/photo attachment preview if photos
   exist.
10. Calendar selected-day summary shows the date record chip and photo summary.
11. User taps the chip/photo summary.
12. App opens the date record detail or Date Records screen.

Acceptance criteria:

- Photos stay on `DateRecord`, not `CalendarEvent`.
- Calendar displays only linked previews/thumbnails.
- Date record can be reached from Calendar.
- Date record creation follows the common link-existing-or-create-new-event
  pattern.

## Scenario 10: Anniversaries And D-Days

Goal: the user sees important couple and family milestones without manually
creating every calendar event.

Flow:

1. User creates or joins a couple space.
2. User opens Records > Anniversaries and adds a record such as first meeting
   date, wedding anniversary, or a parent's birthday.
3. User selects whether the base date should repeat as solar or Korean lunar.
   For Korean lunar anniversaries, the selected year/month/day is stored as the
   lunar base date and converted to solar dates only for calendar display.
4. User selects a repeat rule: every 100 days, every year, or both.
5. App computes future occurrences from the base date.
6. Home shows the nearest upcoming milestone across all anniversary records.
7. The anniversary screen shows each registered record and one next occurrence.
8. Calendar shows anniversary markers for generated dates in any visible month.
9. User taps a next occurrence shortcut and the app opens the calendar date.

Acceptance criteria:

- Generated anniversaries are computed, not stored as ordinary editable events
  by default.
- Anniversary markers are visually distinct from user-created events.
- Onboarding does not require a first meeting date.
- Tapping an anniversary shortcut opens the matching calendar date.

## Scenario 11: Conflict Records

Goal: the couple can record conflicts without exposing sensitive details on the
calendar.

Flow:

1. User opens Records > Conflict Records.
2. User creates a conflict record with date, topic, body, and resolution state.
3. User links it to an existing calendar event or creates a new event through
   the common calendar linking flow.
4. Calendar shows only a discreet linked item summary.
5. User must intentionally open the conflict record to see details.

Acceptance criteria:

- Conflict body is not shown directly on Home or Calendar.
- Calendar preview should use a neutral label/emoji.
- Opening details should be an intentional tap.
- Conflict record creation follows the common link-existing-or-create-new-event
  pattern.

Current status:

- Placeholder only.

## Scenario 12: Reviews

Goal: the couple records consumed content such as movies, dramas, wine,
restaurants, exhibitions, or books.

Flow:

1. User opens Records > Reviews.
2. User creates a review with category, title, rating, date, notes, optional
   photos, and optional place/provider metadata.
3. User links it to an existing calendar event or creates a new event through
   the common calendar linking flow.
4. Calendar shows a review chip with rating/preview when possible.
5. If the review has photos, Calendar shows small linked photo thumbnails.
6. User taps the review chip/photo summary.
7. App opens review detail.

Acceptance criteria:

- Review owns rating, body, category, and photos.
- Calendar owns only `LinkedItem(type: review)`.
- Reviews can link to existing events or create a new event through the common
  calendar picker/editor flow.

Current status:

- Placeholder only.

## Scenario 13: Event Ownership, Permissions, And Watch

Goal: the user understands whether an event is mine, my partner's, or ours, and
what actions are allowed.

Flow:

1. User opens Calendar.
2. App shows events with ownership labels/visuals: 내 일정, 상대 일정, 우리 일정.
3. User opens 내 일정 detail.
4. App allows edit/delete.
5. User opens 우리 일정 detail.
6. App allows edit/delete.
7. User opens 상대 일정 detail.
8. App disables edit/delete and offers watch/unwatch.
9. User watches 상대 일정.
10. App marks it as watched and includes the user in reminder/update delivery.

Acceptance criteria:

- 내 일정 and 상대 일정 use the relevant member's profile color.
- 우리 일정 uses a distinct shared/couple visual treatment.
- Current user can edit/delete 내 일정 and 우리 일정.
- Current user cannot edit/delete 상대 일정.
- 상대 일정 can be watched/unwatched.
- Watch status affects reminder/update recipients.
- Color is not the only ownership signal; use labels, names, or initials where
  space allows.

## Scenario 14: User And Couple Identity

Goal: the user understands which couple space and which user is active.

Flow:

1. User opens Settings.
2. App shows current signed-in user.
3. App shows active couple space and partner status.
4. App shows user A and user B profile colors.
5. Event detail shows ownership label and creator.
6. Later, event detail can show last editor.

Acceptance criteria:

- MVP may use demo user/couple, but UI should reserve space for real identity.
- Real Firebase Auth should replace demo identity without changing feature
  flows.
- Settings can change or preview the current user's profile color later.

## Scenario 15: Notifications

Goal: the user receives reminders for schedule-based events.

Flow:

1. User creates or edits a calendar event.
2. User selects reminder timing.
3. App stores reminder setting on the calendar event.
4. App derives reminder recipients from ownership/watch status.
5. Native app later schedules local/push notification.

Acceptance criteria:

- Reminder belongs to `CalendarEvent`.
- Reminder UI is available in event create/edit.
- 내 일정 reminders notify the owner.
- 우리 일정 reminders notify both members.
- 상대 일정 reminders notify the non-owner only if watched.
- Platform notification permission handling can be implemented later.

## Cross-Screen Contracts

These rules apply to every scenario.

### No Dead Summaries

Anything that looks like a summary of real content must be tappable:

- Home upcoming event rows.
- Calendar selected-day linked chips.
- Calendar linked photo thumbnails.
- Event detail linked item rows.
- Bucket list completion chips.

### Date Selection Comes Before Date-Bound Creation

If a user creates a date-bound record from another module and the target date is
not obvious, show a calendar/date picker first.

Examples:

- Bucket item completion to new event.
- Review to new event.
- Conflict record to new event.

### Existing Event Linking Needs Context

When linking to an existing event, do not show a blank date picker alone.

The picker must show:

- calendar with event title hints in date cells
- selected date label
- event title
- time/all-day
- memo preview when available
- linked item count
- linked item emojis
- option to create a new event on the selected date

### Link Ownership

The module owns the full record. Calendar owns the lightweight link.

Examples:

- Bucket list owns `TodoCompletion`.
- Date Records owns photos/place/memo.
- Reviews owns rating/body/photos.
- Conflict Records owns sensitive body/resolution.

### Unlinking

Every linked item should have a correction path.

MVP:

- Event detail can unlink.
- Todo unlink deletes the matching completion.

Future:

- Offer "unlink only" versus "delete record" for modules where preserving
  history matters.

### After Save

Every create/edit flow must define what happens after save:

- Event create/edit: return to calendar or event detail with updated data.
- Bucket completion: show completion and allow jump to calendar date.
- Date record: show record list and link visible on calendar date.
- Review/conflict: show record detail/list and link visible on calendar date.

## Implementation Checklist For Future Models

Before coding a feature, answer these:

- What scenario does this implement?
- What is the source screen?
- What is the target screen after save?
- Does the user need to choose a date first?
- Can the user link to an existing event?
- Can the user create a new event from this flow?
- Where is the full data owned?
- What `LinkedItem` preview appears on Calendar?
- What happens when the linked chip is tapped?
- How can the user undo a mistaken link?
- What empty states are needed?
- What should be hidden from Home/Calendar because it is sensitive?

If any answer is missing, update this document before implementation.
