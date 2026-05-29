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

- Product requirements: `docs/product/requirements.md`
- Current product spec: `docs/product/product-spec.md`
- Architecture: `docs/architecture/architecture.md`
- Navigation and screens: `docs/product/navigation-and-screens.md`
- Auth plan: `docs/architecture/auth-plan.md`
- Testing guide: `docs/testing/testing.md`
- Flutter coding guidelines: `docs/engineering/flutter-coding-guidelines.md`
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

Firebase project setup is not committed yet. Add platform-specific Firebase
configuration before enabling real auth, Firestore, Storage, or notifications.
Authentication is deferred; see `docs/architecture/auth-plan.md`.

## Local Docker

Run the local API, Firebase emulator, and Flutter web app:

```sh
docker compose -f config/local/docker-compose.yml up -d --build
```

Seed local demo data for the web app:

```sh
docker compose -f config/local/docker-compose.yml run --rm demo-seed
```

Clean local demo data before shutting down:

```sh
docker compose -f config/local/docker-compose.yml run --rm demo-clean
docker compose -f config/local/docker-compose.yml down
```

The local web app uses `LOCAL_DEMO_USER_ID=demo-user-1`, so the seed script and
Flutter app point at the same couple data.

## Runtime Modes

Flutter chooses its data source with one flag:

```sh
--dart-define=APP_DATA_MODE=api
```

Modes:

- `api`: default. Flutter calls the Go API, and the API owns persistence and
  business rules.
- `mock`: UI/debug exception mode. Flutter uses in-memory mock repositories.
- `firebase`: legacy/direct mode. Flutter talks to Firebase SDK repositories
  without the Go API.

`USE_FIREBASE_EMULATOR` is only meaningful with `APP_DATA_MODE=firebase`; it
points the direct Firebase SDK repositories at the local emulator. It is not
needed in the default `api` mode because Flutter does not initialize Firebase
there.
