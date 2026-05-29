# Calendar Spec

This document defines calendar-specific product and UI behavior.

Use it together with `docs/product/user-scenarios.md`.

## Calendar Role

Calendar is the shared timeline. It shows when something is planned or when a
record happened, but it does not own every record's full content.

Calendar owns:

- schedule title
- start/end date and time
- all-day state
- memo
- reminders
- creator/editor identity
- display color derived from owner/user plus optional event category
- lightweight linked item previews

Calendar does not own:

- photos
- review body/rating
- conflict body
- bucket list data
- map provider details beyond linked preview text

## Event Time Model

Events must support multi-day schedules.

Do not model events as "start date + N hours" only. The editor should support:

- start date
- optional start time
- end date
- optional end time
- all-day toggle

Validation:

- `title` is required.
- `startAt` is required.
- `endAt` is required.
- `endAt` must be after `startAt`.
- For all-day events, store a normalized exclusive end date.
  - Example: May 5 through May 7 is stored as `startAt = 2026-05-05 00:00`
    and `endAt = 2026-05-08 00:00`.
- Timed events may also span multiple days.
- UI labels should display the user-facing inclusive range for all-day events.

Examples:

```text
Single timed event
2026-05-05 19:00 -> 2026-05-05 21:00

Multi-day all-day trip
2026-05-05 00:00 -> 2026-05-08 00:00
Displayed as: 2026.05.05 - 2026.05.07

Overnight timed event
2026-05-05 22:00 -> 2026-05-06 01:00
```

## Event Editor

The event editor should not use a duration-only control as the main model.

Recommended fields:

- title
- all-day switch
- start date
- start time when not all-day
- end date
- end time when not all-day
- memo
- reminder
- linked items

Helpful defaults:

- Calendar add button uses the selected calendar date.
- New timed event can default to 19:00-21:00 on the selected date.
- New all-day event can default to selected date through selected date.
- If a bucket item or module record starts the flow, show date picker first
  when the target date is not obvious.

Editor acceptance criteria:

- User can create a one-day event.
- User can create a multi-day all-day event.
- User can create an overnight timed event.
- User can edit an existing event's start/end dates.
- Invalid ranges show an inline error or save-time validation message.
- Event editor does not ask for photos.

## Month Calendar Rendering

The month grid must communicate multi-day event continuity.

### Single-Day Events

Single-day events can be rendered as:

- compact colored dot in dense/default mode
- title hint in selection/linking mode
- selected-day list item below the grid

### Multi-Day Events

Multi-day events should be rendered as horizontal bars/lines spanning the visible
days, not as unrelated dots on each day.

Rules:

- A multi-day event segment should stretch across consecutive days within the
  same calendar week row.
- If an event crosses a week boundary, render one segment per week row.
- Segment start should have a rounded leading edge when the event starts inside
  the visible week.
- Segment end should have a rounded trailing edge when the event ends inside the
  visible week.
- If the event continues from a previous week/month, use a flat or subtle
  continuation edge.
- If the event continues into the next week/month, use a flat or subtle
  continuation edge.
- Text may appear inside the first segment when there is enough space.
- In cramped mobile layouts, use a color bar plus selected-day detail below.

Ordering:

- Multi-day/all-day bars appear above single-day timed dots in the day cell.
- Within the same row, sort by start date, longer duration, then title.
- Timed single-day events sort by time.

Selection/linking mode:

- When choosing an existing event to link, date cells should show enough title
  information to identify events.
- The selected-date event list below the calendar is still required.

## Selected Day Panel

When a date is selected, the panel below the calendar should show:

- date label
- anniversaries/D-days
- linked item chips with representative emojis
- linked record photo thumbnails/labels when available
- event list sorted by all-day/time/title for that date

Tappable surfaces:

- Event row opens event detail.
- Linked chip opens linked detail or owning module.
- Linked photo thumbnail opens linked detail or owning module.

## User Identity And Colors

This is a couple app, so each member should be visually distinguishable.

Decision:

- Each couple member has a stable profile color.
- User A and User B colors are assigned during couple setup or first use.
- Calendar events have an ownership kind: my event, partner event, or our event.
- Personal events show the creator's profile color as the primary ownership
  signal.
- Our events should show both-user ownership, such as a blended/neutral couple
  color plus both initials, or a two-color treatment.
- Event category/color can exist later, but it must not erase who created the
  event.

Recommended MVP behavior:

- Demo user A color: teal.
- Demo user B color: coral or warm orange.
- My event uses the current user's color.
- Partner event uses the partner's color.
- Our event uses a distinct couple/shared treatment and should not look like it
  belongs to only one person.
- Event row leading stripe/avatar uses ownership color/treatment.
- Calendar dots/bars use ownership color/treatment by default.
- Event detail shows ownership label and creator name/color.
- Settings shows current user, partner, and their colors.

Future behavior:

- Users can change their own profile color.
- Partner color remains visible but may be selected by the partner.
- If an event is imported or ownership is unknown, use neutral color plus
  fallback label.

Accessibility:

- Do not rely on color alone. Pair colors with initials, labels, or tooltips
  where space allows.
- Chosen colors must pass contrast expectations for text/icons when used as
  foreground/background.

## Relationship Between User Color And Event Color

Avoid two competing meanings for color.

Recommended rule:

- Ownership color is primary.
- Event category color is secondary and optional.
- If both exist, use ownership color/treatment for the calendar bar/stripe and
  category color as a small tag or accent inside detail/list views.

MVP simplification:

- Use ownership color/treatment as the event color.
- Keep existing event `colorValue` only as display fallback until user profile
  colors are fully wired.

## Event Ownership And Permissions

Calendar events should support three user-facing ownership labels:

```text
내 일정
상대 일정
우리 일정
```

Recommended model:

```text
CalendarEvent
- ownership: personal | shared
- createdBy
- ownerUserId
- watcherUserIds
```

Derived labels from the current user's perspective:

- `ownership == personal && ownerUserId == currentUser.id`: 내 일정
- `ownership == personal && ownerUserId != currentUser.id`: 상대 일정
- `ownership == shared`: 우리 일정

Editing/deletion rules:

- User can edit/delete 내 일정.
- User can edit/delete 우리 일정.
- User cannot edit/delete 상대 일정.
- Partner-owned personal events should show read-only detail plus watch controls.

Creation rules:

- Event editor should let the user choose ownership: 내 일정 or 우리 일정.
- "상대 일정" is not directly created by the current user. It appears when the
  partner creates their own personal event.
- Module-created events may default to 우리 일정 when the record is shared couple
  content, unless the flow explicitly asks for personal ownership.

Detail UI rules:

- Show ownership label near title/date.
- Show creator.
- Hide or disable edit/delete for 상대 일정.
- Show watch toggle for 상대 일정.

## Reminder And Watch Rules

Reminder delivery depends on ownership.

Decision:

- 내 일정: the owner receives reminders.
- 우리 일정: both couple members receive reminders by default.
- 상대 일정: the non-owner does not receive reminders by default, but can watch
  the event.

Watch behavior:

- Watching a partner event means the current user wants updates/reminders for
  that event.
- `watcherUserIds` stores users who watch an event they do not own.
- A watched 상대 일정 should visually indicate that it is watched.
- User can unwatch later.

Reminder recipients:

```text
personal event: ownerUserId + watcherUserIds
shared event: all couple memberIds
```

MVP implementation may store reminders on the event and derive recipients at
notification scheduling time. Later, store per-user notification preferences if
needed.

## Linked Records With Photos

Calendar events do not own photos.

If a linked record has photos:

- linked item may include `thumbnailUrl` or photo attachment preview
- selected-day panel shows small thumbnails/labels
- tapping the thumbnail opens the owning record/module

Examples:

- DateRecord photo appears on Calendar through `LinkedItem.thumbnailUrl`.
- Review photo appears on Calendar through `LinkedItem.thumbnailUrl`.
- TodoCompletion does not own photos directly.

## Common Calendar Linking Flow

Use this shared pattern for bucket list, date records, reviews, and conflicts:

1. User starts from a module record.
2. If target date is not obvious, show calendar/date picker first.
3. User can choose an existing event or create a new event.
4. Existing event picker shows event title hints in date cells.
5. New event editor shows pending linked item before save.
6. After save/link, Calendar shows the linked item summary.
7. Source module shows the linked calendar result.

Do not implement a separate one-off linking flow per module unless a scenario
requires a real difference.

## Open Calendar Questions

These are the main product questions still worth deciding before deeper
implementation:

- Should multi-day event bars show only title, or title plus time when timed?
- Should recurring events be supported before real launch?
- Should fully private hidden events exist later, or are personal events always
  visible to the partner as read-only/watchable?
- Should anniversary occurrences support custom reminder defaults?
- Should calendar support week/day views, or is month plus selected-day panel
  enough for the first release?

Current recommendation:

- MVP supports 내 일정, 상대 일정, and 우리 일정.
- Users can edit/delete 내 일정 and 우리 일정, but not 상대 일정.
- 상대 일정 can be watched to receive reminders/updates.
- Repeating events can wait until after the first release.
- Month view plus selected-day panel is enough for the first release.
