# Instructions For Coding Agents

Read these docs before making code changes:

- `docs/README.md`
- `docs/product/requirements.md`
- `docs/product/user-scenarios.md`
- `docs/product/calendar-spec.md`
- `docs/product/product-spec.md`
- `docs/architecture/architecture.md`
- `docs/product/navigation-and-screens.md`
- `docs/engineering/flutter-coding-guidelines.md`
- `docs/architecture/api-server-migration.md`
- `docs/architecture/auth-plan.md`
- `docs/testing/testing.md`

If you only read one file after this one, read `docs/README.md`, then follow
its priority order for the task.

Project decisions:

- Flutter app for iOS and web first, Android later.
- Flutter frontend lives under `apps/frontend`.
- Go backend lives under `apps/api`.
- Riverpod for state management.
- Go API server for business logic.
- Firebase for authentication, Firestore, Storage, and notifications behind
  repositories and, over time, behind the API server.
- Authentication is deferred; when it starts, follow
  `docs/architecture/auth-plan.md`.
- The calendar is the product center.
- Future modules, such as todos, date records, conflict notes, anniversaries, and reviews, should link to calendar events through a generic linked-item model.
- User journeys and cross-screen behavior are defined in `docs/product/user-scenarios.md`; update it before implementing ambiguous flows.
- Calendar events should not own photos directly. Photos belong to linked records, and Calendar shows only linked thumbnails/previews.
- Calendar events support explicit start/end date-time ranges, including
  multi-day and overnight schedules.
- Couple members should have stable profile colors that distinguish who created
  each event.
- Calendar supports 내 일정, 상대 일정, and 우리 일정.
- Users can edit/delete 내 일정 and 우리 일정, but not 상대 일정.
- Users receive reminders for 내 일정/우리 일정 and can watch 상대 일정.
- MVP supports one active couple per user.
- MVP calendar events are visible to both couple members.
- MVP should implement the calendar core before implementing full todo, map, conflict, anniversary, or review modules.

Coding style:

- Prefer immutable models and pure functions where they fit naturally.
- Keep side effects out of widgets.
- Hide Firebase behind repositories/services.
- Keep changes small, focused, and consistent with existing code.
- Do not introduce a new state management package unless explicitly asked.
- Do not add feature-specific fields such as todo details, conflict body, or review rating directly to `CalendarEvent`; use linked items.
- Do not call Firebase directly from widgets.
- Do not add new direct Flutter-to-Firebase behavior when the same behavior is
  a backend business rule. Prefer adding it to the Go API server and exposing it
  through a Flutter repository.
- Do not add packages casually.

Working order:

1. Inspect existing code.
2. Identify the smallest feature boundary to change.
3. Update or create models first.
4. Add repository/service behavior.
5. Add Riverpod providers or controllers.
6. Add UI.
7. Add focused tests when practical.
8. Run verification commands.

Before finishing code work:

- For Flutter changes, run `cd apps/frontend && flutter analyze` when possible.
- For Flutter changes, run relevant tests from `apps/frontend` when possible.
- For Go API changes, run tests from `apps/api` when possible.
- Mention any commands that could not be run.
- Mention any product ambiguity that remains.
