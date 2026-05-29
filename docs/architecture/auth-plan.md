# Authentication Plan

Authentication is intentionally deferred. The current app should keep using the
existing local/dev flow while product and API boundaries stabilize.

## Decision

Do not implement Naver login or Firebase Auth in the current milestone.

When auth starts, use Naver login as the user-facing provider and let the Go API
own application identity, couple membership, sessions, and permission checks.
Firebase may still be used behind the API for data, storage, messaging, or
optional custom-token bridging.

## Recommended Target Flow

1. Flutter starts Naver OAuth login.
2. Flutter receives a Naver access token or authorization result.
3. Flutter sends that credential to the Go API.
4. Go API verifies it with Naver.
5. Go API upserts the app user.
6. Go API creates or refreshes an API session/token.
7. Flutter calls API endpoints with `Authorization`.
8. API services enforce user, couple, and event permissions.

If direct Firebase SDK access is needed later, the API can mint a Firebase custom
token after verifying Naver identity. Keep that as an integration option, not as
the first dependency.

## Data To Store

User:

- app user id
- provider name, initially `naver`
- provider user id
- email, nickname, profile image when available
- created time, updated time, last login time
- optional deleted/deactivated time

Couple membership:

- couple id
- user id
- role or membership status
- joined time
- active/inactive status

Session/token:

- user id
- issued time
- expiry time
- refresh or revocation metadata if we choose server-side sessions

## Permission Direction

- 내 일정: editable/deletable by creator.
- 우리 일정: editable/deletable by both active couple members.
- 상대 일정: visible to the other member, not editable/deletable by them.
- 상대 일정 watch: user may opt into reminder/watch behavior without owning the event.
- Linked records, reviews, bucket-list completions, and anniversaries should use
  the same couple membership boundary.

## QA Automation Direction

Before real Naver login exists, QA automation should use deterministic test
users created by the API or emulator seed data:

- `qa-user-a`: primary user.
- `qa-user-b`: partner user in the same couple.
- optional `qa-user-c`: non-member used for negative permission tests.

These identities should exercise the same couple and permission rules that real
auth will later use. Local/dev requests identify those users with `X-Dev-User-Id`.
When Naver login is added, keep the same scenario tests and replace only the
middleware login/bootstrap step with `Authorization` token verification.

## Implementation Tasks

1. Add user and couple domain models.
2. Add user/couple repository ports in the API.
3. Add local QA identity seeding for two couple members and one non-member.
4. Add Naver auth adapter for token verification.
5. Add auth application service for login/upsert/session creation.
6. Add HTTP endpoints for login, current user, logout, and session refresh if needed.
7. Add API middleware that resolves the authenticated user.
8. Move permission checks into application services.
9. Update Flutter API client to attach the API token.
10. Add onboarding screens for couple creation/invite after login.
11. Add API tests for auth and permission boundaries.

## Non-Goals For Now

- No Naver login UI in the current milestone.
- No Firebase Auth custom-token flow yet.
- No production session revocation model yet.
- No social-provider abstraction beyond keeping the provider fields extensible.
