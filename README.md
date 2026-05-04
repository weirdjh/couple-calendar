# Couple Calendar

Couple Calendar is a shared calendar app for couples.

The first version focuses on a flexible calendar core:

- Shared calendar events
- Simple event memos
- Photo attachments
- Event reminders
- A linked-content model for future todos, date records, conflict notes, anniversaries, reviews, and places

## Stack

- Flutter for iOS and web first, Android later
- Riverpod for state management
- Firebase for auth, data, photos, and notifications

## Docs

- Product requirements: `docs/requirements.md`
- Current product spec: `docs/product-spec.md`
- Architecture: `docs/architecture.md`
- Navigation and screens: `docs/navigation-and-screens.md`
- Flutter coding guidelines: `docs/flutter-coding-guidelines.md`
- Coding-agent instructions: `AGENTS.md`

## Development

After dependencies are configured:

```sh
flutter pub get
flutter analyze
flutter test
```

Run the app:

```sh
flutter run
```

Firebase project setup is not committed yet. Add platform-specific Firebase configuration before enabling real auth, Firestore, Storage, or notifications.
