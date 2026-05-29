# Firebase Config

Firebase configuration is grouped by environment so local emulator files do not
sit in the project root.

## Local Emulator

Local emulator config lives in `config/firebase/local`.

The local Docker Compose entrypoint lives in `config/local/docker-compose.yml`
so app-local runtime wiring is separate from Firebase config files.

Run the repository integration tests with:

```bash
bash tool/run_firestore_emulator_tests.sh
```

The script starts Firebase Auth and Firestore emulators in Docker, runs the
Flutter tests, runs a Firebase emulator smoke test against `127.0.0.1`, then
shuts the container down.

Run the app and Firebase emulator together with:

```bash
docker compose -f config/local/docker-compose.yml up --build
```

Then open `http://127.0.0.1:8080`. The Firebase Emulator UI is available at
`http://127.0.0.1:4000`.

Stop local services with:

```bash
docker compose -f config/local/docker-compose.yml down
```

The local emulator exports data on shutdown to
`config/local/firebase-data`, which is ignored by git. This keeps local
development data and emulator logs out of the project root.

To start the emulator without importing or exporting local state, set:

```bash
FIREBASE_PERSISTENCE=false docker compose -f config/local/docker-compose.yml up firebase-emulator
```

## Production

Production config should be added under `config/firebase/production` later.
Before production deployment, replace MVP membership rules with the final couple
invitation and role model.
