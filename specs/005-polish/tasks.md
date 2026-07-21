---

description: "Task list for Specification 5: Polish"
---

# Tasks: Polish

**Input**: Design documents from `/specs/005-polish/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/widget-and-ci.md](./contracts/widget-and-ci.md), [quickstart.md](./quickstart.md)

**Tests**: Partial — the one new pure function (`FollowUpWidgetContent.select`) gets unit tests,
matching the constitution's test-first principle and Specifications 1-4's precedent for pure
logic. Dark mode/Dynamic Type/icon/launch screen and the widget's real on-device behavior are not
mechanically assertable via XCUITest (see research.md and quickstart.md) and are manual-only. CI
is verified by observing a real workflow run, not by a test inside the repository.

**Organization**: Tasks are grouped by user story. There is no Foundational phase — like
Specification 4, this spec's three user stories share no single blocking prerequisite: User Story
1 touches existing files in place, User Story 2 owns the App Group relocation and widget target
entirely within its own phase, and User Story 3 is a single standalone workflow file.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to the repository root, matching plan.md's Project Structure

---

## Phase 1: User Story 1 - A finished-feeling app, not a prototype (Priority: P1) 🎯 MVP

**Goal**: Every screen from Specifications 1-4 stays legible in dark mode and at large Dynamic Type
sizes; the app has a real icon and launch screen instead of system-default placeholders.

**Independent Test**: Switch the simulator to dark mode and to the largest three Dynamic Type
sizes, walk every screen from Specs 1-4, confirm nothing is illegible/clipped; check the Home
Screen and cold-launch for a real icon/launch screen — independent of the widget or CI existing.

### Implementation for User Story 1

- [ ] T001 [P] [US1] Audit `NextStep/Features/FollowUps/FollowUpRow.swift` and `TodayView.swift` for hard-coded colors (priority badges) and fixed-size text; replace with semantic system colors and default Dynamic-Type-respecting fonts
- [ ] T002 [P] [US1] Audit `NextStep/Features/Dashboard/FollowUpSummaryView.swift` and `DeveloperAnalyticsView.swift` for the same
- [ ] T003 [P] [US1] Audit `NextStep/Features/Contacts/ContactListView.swift`, `ContactDetailView.swift`, `ContactFormView.swift` for the same
- [ ] T004 [P] [US1] Audit `NextStep/Features/Interactions/InteractionFormView.swift`, `InteractionRow.swift` for the same
- [ ] T005 [P] [US1] Audit `NextStep/Features/FollowUps/FollowUpFormView.swift` for the same
- [ ] T006 [US1] Generate the app icon per research.md: a small SwiftUI view (colored rounded background + the `checklist` SF Symbol already used on the Today tab) rendered via `ImageRenderer` at each required size, assembled into `NextStep/Assets.xcassets/AppIcon.appiconset/` with a generated `Contents.json` — simple, flat, not overdesigned, matching the app's existing iconography
- [ ] T007 [US1] Add `NextStep/Assets.xcassets` to `project.yml`'s resources and set `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` so the generated icon is used (depends on T006)
- [ ] T008 [US1] Replace the blank system-generated launch screen with a deliberate one (a centered icon/name on a plain background) via `project.yml`'s `INFOPLIST_KEY_UILaunchScreen_*` settings, consistent visually with the new app icon (depends on T006)

**Checkpoint**: User Story 1 is functional and independently verifiable — dark mode, Dynamic Type,
icon, and launch screen are all addressed without needing the widget or CI to exist.

---

## Phase 2: User Story 2 - See tomorrow's follow-up without opening the app (Priority: P2)

**Goal**: A home-screen widget shows up to 3 overdue/due-today follow-ups, most-urgent-first,
refreshes promptly after in-app changes, and opens the Today screen when tapped.

**Independent Test**: Add the widget to a home screen with a mix of overdue/due-today/upcoming/
completed follow-ups, confirm correct content and ordering; confirm tap-to-open; confirm refresh
after completing a follow-up in-app.

### Tests for User Story 2

- [ ] T009 [P] [US2] Unit tests for `FollowUpWidgetContent.select` — top-3 cap, most-urgent-first ordering (overdue before due-today, oldest-overdue first), excludes upcoming/completed, empty-array on nothing due — in `NextStepTests/FollowUpWidgetContentTests.swift`

### Implementation for User Story 2

- [ ] T010 [US2] Add App Group `group.com.nextstep.app.NextStep` entitlements — `NextStep/NextStep.entitlements` for the main app target, configured in `project.yml`
- [ ] T011 [US2] Relocate the `ModelContainer` in `NextStep/App/NextStepApp.swift` to a `ModelConfiguration(url:)` inside the shared App Group container via `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`, for both the real and in-memory (test) configurations (depends on T010)
- [ ] T012 [P] [US2] Implement the pure `FollowUpWidgetContent.select(_:today:calendar:)` function per contracts/widget-and-ci.md in `NextStepWidget/FollowUpWidgetContent.swift`
- [ ] T013 [US2] Add the `NextStepWidget` Widget Extension target to `project.yml` (iOS 17+, same App Group entitlement as T010 via `NextStepWidget/NextStepWidget.entitlements`) (depends on T010)
- [ ] T014 [US2] Implement `FollowUpWidgetTimelineProvider` — opens a `ModelContext` against the shared App Group `ModelContainer`, fetches `FollowUp`s, calls `FollowUpWidgetContent.select(_:)`, returns a `.after(date)` timeline — in `NextStepWidget/FollowUpWidgetTimelineProvider.swift` (depends on T011, T012, T013)
- [ ] T015 [US2] Implement `FollowUpWidget` (widget configuration + SwiftUI view: up to 3 rows or a "Nothing due" empty state, `widgetURL` for tap-to-open) and `NextStepWidgetBundle` entry point in `NextStepWidget/FollowUpWidget.swift` and `NextStepWidgetBundle.swift` (depends on T014)
- [ ] T016 [US2] Wire tap-to-open routing: handle the widget's URL via `.onOpenURL` in `NextStep/App/NextStepApp.swift`, routing to the Today tab through `RootTabView`'s existing tab-selection state (depends on T015)
- [ ] T017 [US2] Call `WidgetCenter.shared.reloadAllTimelines()` from `saveFollowUp(_:for:)`, `completeFollowUp(_:)`, and `deleteFollowUp(_:)` in `NextStep/Core/Persistence/SwiftDataContactRepository.swift` (depends on T014)

**Checkpoint**: User Story 2 is functional — the widget shows correct, ordered content and stays
fresh; independently testable via T009 even before manual on-device verification.

---

## Phase 3: User Story 3 - Confidence that changes don't break the app (Priority: P3)

**Goal**: Every push and pull request automatically builds the app and runs `NextStepTests`, with
pass/fail visible on GitHub without any manual step.

**Independent Test**: Push a commit with a deliberately failing test, confirm the workflow reports
failure with the failing test identifiable; fix it, confirm success — independent of User Stories
1-2.

### Implementation for User Story 3

- [ ] T018 [US3] Create `.github/workflows/ci.yml` per contracts/widget-and-ci.md — triggers on `push` and `pull_request`, checks out the repo, selects an available Xcode, runs `xcodegen generate`, then `xcodebuild test -scheme NextStep -only-testing:NextStepTests` against a runner-available iOS Simulator destination

**Checkpoint**: User Story 3 is functional — verify by pushing a commit and observing the Actions
run and PR status directly on GitHub (see quickstart.md).

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Final verification spanning all three user stories.

- [ ] T019 Walk through every scenario in [quickstart.md](./quickstart.md) — dark mode, Dynamic Type, icon, launch screen, widget placement/ordering/tap-to-open/refresh, and CI's pass/fail visibility on a real push and PR — and fix any discrepancies found
- [ ] T020 [P] Add the Specification 5 entry to `AI_USAGE.md` per the constitution's Development Workflow

---

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1 (Phase 1)**: No dependencies on other phases in this spec — start immediately.
- **User Story 2 (Phase 2)**: No dependencies on User Story 1; independent. Internally, T010-T011
  (App Group + container relocation) block everything else in this phase — the widget cannot read
  any data until the store is in a location it can reach.
- **User Story 3 (Phase 3)**: Fully independent of both other stories — a single workflow file.
- **Polish (Phase 4)**: Depends on User Stories 1-3 all being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Fully independent — edits existing files in place, adds new asset/launch
  screen resources that nothing else in this spec depends on.
- **User Story 2 (P2)**: Fully independent of User Story 1 and 3. This is the spec's highest-risk
  phase — the App Group relocation (T010-T011) changes how the *existing* app's data is stored, so
  the full Specification 1-4 regression suite must pass after T011, not just this spec's own new
  test (T009).
- **User Story 3 (P3)**: Fully independent — touches no Swift source at all.

### Within Each User Story

- Model/protocol/infrastructure before view before wiring, matching Specifications 1-4's precedent.
- Story complete and checkpointed before moving to the next priority.
- **Regression discipline for User Story 2 specifically**: run the full `NextStepTests` +
  `NextStepUITests` suites immediately after T011 (the storage relocation), before proceeding to
  T012+ — a silent persistence regression here would be easy to miss until much later otherwise.

### Parallel Opportunities

- T001-T005 (User Story 1's per-screen audits) can all run in parallel — different files, no
  shared state.
- T009 and T012 (US2's test and pure function) can run in parallel with each other, and with all
  of Phase 1.
- T018 (US3's entire phase) can run in parallel with all of Phase 1 and Phase 2 — it touches no
  Swift source.
- T020 (AI_USAGE.md) can run in parallel with T019.

---

## Parallel Example: User Story 1

```bash
# All five per-screen audits together (different files):
Task: "Audit FollowUpRow.swift and TodayView.swift for dark mode/Dynamic Type"
Task: "Audit FollowUpSummaryView.swift and DeveloperAnalyticsView.swift for the same"
Task: "Audit ContactListView.swift, ContactDetailView.swift, ContactFormView.swift for the same"
Task: "Audit InteractionFormView.swift, InteractionRow.swift for the same"
Task: "Audit FollowUpFormView.swift for the same"

# User Story 3 entirely, in parallel with all of the above:
Task: "Create .github/workflows/ci.yml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: User Story 1.
2. **STOP and VALIDATE**: manually walk quickstart.md's User Story 1 scenarios (dark mode, Dynamic
   Type, icon, launch screen).
3. This is a demoable increment: the app looks and feels finished, even before the widget or CI
   exist.

### Incremental Delivery

1. Add User Story 1 → validate independently (manual) → the app looks finished.
2. Add User Story 2 → run the full regression suite immediately after T011 → validate independently
   (T009 automated + manual on-device placement) → the widget works.
3. Add User Story 3 → validate independently by pushing a real commit → CI is live.
4. Phase 4 Polish → full quickstart pass across all three stories, AI_USAGE.md entry.

---

## Notes

- [P] tasks touch different files with no unmet dependencies.
- [Story] label maps each task to its user story for traceability back to spec.md.
- Commit after each task or logical group, scoped to this specification only (constitution
  Development Workflow) — no unrelated refactors bundled in.
- The App Group storage relocation (T010-T011) is the one task in this entire spec-kit sequence
  (Specifications 1-5) that changes how *already-working* persistence behaves, rather than adding
  new behavior — treat it with the regression discipline noted above, not as routine additive work.
- Dark mode/Dynamic Type/icon/launch screen (User Story 1) and the widget's real on-device behavior
  (User Story 2) cannot be automated per research.md/quickstart.md — don't try to force them into
  XCUITest.
- CI (User Story 3) is verified by observing GitHub's own UI, not a local test command.
- Stop at each checkpoint to validate that story independently before moving on.
