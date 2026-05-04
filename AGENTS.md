# Instructions For Coding Agents

Read these docs before making code changes:

- `docs/requirements.md`
- `docs/product-spec.md`
- `docs/architecture.md`
- `docs/navigation-and-screens.md`
- `docs/flutter-coding-guidelines.md`

If you only read one file after this one, read `docs/flutter-coding-guidelines.md`.

Project decisions:

- Flutter app for iOS and web first, Android later.
- Riverpod for state management.
- Firebase for authentication, Firestore, Storage, and notifications.
- The calendar is the product center.
- Future modules, such as todos, date records, conflict notes, anniversaries, and reviews, should link to calendar events through a generic linked-item model.
- MVP supports one active couple per user.
- MVP calendar events are shared with both couple members.
- MVP should implement the calendar core before implementing full todo, map, conflict, anniversary, or review modules.

Coding style:

- Prefer immutable models and pure functions where they fit naturally.
- Keep side effects out of widgets.
- Hide Firebase behind repositories/services.
- Keep changes small, focused, and consistent with existing code.
- Do not introduce a new state management package unless explicitly asked.
- Do not add feature-specific fields such as todo details, conflict body, or review rating directly to `CalendarEvent`; use linked items.
- Do not call Firebase directly from widgets.
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

- Run `flutter analyze` when possible.
- Run relevant tests when possible.
- Mention any commands that could not be run.
- Mention any product ambiguity that remains.
