# Firebase Config

Firebase configuration is owned by the backend app. Local emulator files live
with the Go API because the default runtime is `Flutter -> Go API -> Firebase`.

## Local Emulator

Local emulator config lives in `apps/api/config/firebase/local`.

The shared local Docker Compose entrypoint lives in
`infra/local/docker-compose.yml` because it starts frontend, backend, and
Firebase together.

Run the repository integration tests with:

```bash
bash tool/run_firestore_emulator_tests.sh
```

The script starts Firebase Auth and Firestore emulators in Docker, runs the
Flutter tests, runs a Firebase emulator smoke test against `127.0.0.1`, then
shuts the container down.

Run the app and Firebase emulator together with:

```bash
docker compose -f infra/local/docker-compose.yml up --build
```

Then open `http://127.0.0.1:8080`. The Firebase Emulator UI is available at
`http://127.0.0.1:4000`.

Stop local services with:

```bash
docker compose -f infra/local/docker-compose.yml down
```

The local emulator exports data on shutdown to the Docker volume
`firebase-emulator-data`. This keeps local development data and emulator logs
out of the project root.

To start the emulator without importing or exporting local state, set:

```bash
FIREBASE_PERSISTENCE=false docker compose -f infra/local/docker-compose.yml up firebase-emulator
```

## Production

Production config should be added under `apps/api/config/firebase/production`
later.
Before production deployment, replace MVP membership rules with the final couple
invitation and role model.
