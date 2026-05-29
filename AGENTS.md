# Instructions For Coding Agents

This file is the entrypoint for new coding sessions. Keep it short and stable.
Detailed product, architecture, and testing rules live under `docs/`.

## Read First

Before making code changes, read `docs/README.md` and follow its priority order
for the task. Then read only the task-relevant specs.

Common starting points:

- Product behavior: `docs/product/user-scenarios.md`
- Calendar rules: `docs/product/calendar-spec.md`
- Screen ownership: `docs/product/navigation-and-screens.md`
- Data and architecture: `docs/architecture/architecture.md`
- API migration and Go layers: `docs/architecture/api-server-migration.md`
- Auth work: `docs/architecture/auth-plan.md`
- Flutter conventions: `docs/engineering/flutter-coding-guidelines.md`
- Go conventions: `docs/engineering/go-api-package-guidelines.md`
- Verification: `docs/testing/testing.md`

## Repository Shape

- Frontend: `apps/frontend`
- Backend API: `apps/api`
- Backend/Firebase config: `apps/api/config`
- Shared local runtime wiring: `infra/local`
- Docs: `docs`
- Local scripts: `tool`

## Working Principles

- Prefer immutable models and pure functions where they fit naturally.
- Keep side effects at repository, service, controller, or adapter boundaries.
- Keep widgets declarative and free of direct persistence/API calls.
- Prefer the Go API for business rules that affect multiple domains.
- Keep changes small, focused, and consistent with existing code.
- Do not introduce a new state management package unless explicitly asked.
- Do not add packages casually.
- Do not duplicate detailed product or architecture specs in this file; link to the owning doc instead.
- Update the relevant doc when behavior, architecture, commands, or workflows
  change.

## Working Order

1. Inspect existing code.
2. Read the task-relevant docs.
3. Identify the smallest feature boundary to change.
4. Update or create models and service/repository behavior.
5. Add providers, controllers, handlers, or adapters.
6. Add UI.
7. Add focused tests when practical.
8. Run verification commands.

## Before Finishing

- For Flutter changes, run `cd apps/frontend && flutter analyze` when possible.
- For Flutter changes, run relevant tests from `apps/frontend` when possible.
- For Go API changes, run tests from `apps/api` when possible.
- For local stack changes, validate `infra/local/docker-compose.yml`.
- Mention any commands that could not be run.
- Mention any product ambiguity that remains.
