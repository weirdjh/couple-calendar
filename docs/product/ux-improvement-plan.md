# UX Improvement Plan

This document tracks cross-screen UX problems and improvement passes. Detailed
feature behavior still belongs in the owning product specs.

## Principles

- Prefer visible content over explanatory copy.
- Use familiar icons for repeated actions and keep labels short.
- Show linked content by title, emoji, photo, or rating instead of generic
  "linked" status text.
- Keep creation and editing separate from browsing screens.
- Review complete user journeys, not isolated screens.
- Verify mobile-sized web first, then wider web layouts.

## Completed Passes

### Calendar Core Pass 1

- Replaced the solid selected-day fill with a lighter selection treatment.
- Increased calendar cell height so the month grid uses more of the viewport.
- Simplified selected-day event rows into title, time, memo, and compact state
  icons.
- Shortened selected-day actions to `데이트` and `일정`.
- Removed the `일정 상세` app-bar title.
- Replaced large event-detail cards and chips with lightweight sections.
- Hid empty memo and reminder sections.
- Show linked content as content rows; show only relevant add actions.

## Next Passes

### P1: Home

- Make the representative photo the visual focus.
- Make pinned anniversary/event summaries open their source.
- Reduce empty explanatory areas and strengthen upcoming-event scanning.
- Clarify the distinction between pinned content and upcoming content.

### P1: Records Hub

- Make Date records, Bucket list, Reviews, and Anniversaries visually
  distinguishable without descriptions.
- Show useful counts or recent state only when actionable.
- Remove placeholder or unavailable modules from primary navigation.

### P1: Date Record Journey

- Review `Calendar -> Date record -> Bucket/Review -> Calendar` as one journey.
- Make linked bucket items and reviews identifiable by title and representative
  icon.
- Keep unlinking and destructive actions inside edit or overflow actions.

### P2: Creation And Editing

- Standardize editor headers, save actions, field spacing, and validation.
- Prefer pickers and selection sheets over free-form identifiers.
- Verify cancel/back behavior never loses work without warning.

### P2: Onboarding And Settings

- Reduce onboarding copy and make create/join choices easier to scan.
- Replace development-facing identifiers with user-facing identity.
- Reserve production auth and couple-invite UX for the authentication phase.

## Verification Notes

- `flutter analyze` must pass after each UI pass.
- Critical mobile flows should have focused widget tests.
- The local Flutter web container must isolate `.dart_tool` and `build` from
  the host so browser builds do not break host-side tests.
