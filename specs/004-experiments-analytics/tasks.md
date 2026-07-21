---

description: "Task list for Specification 4: Experiments & Analytics"
---

# Tasks: Experiments & Analytics

**Input**: Design documents from `/specs/004-experiments-analytics/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/analytics-and-experiments.md](./contracts/analytics-and-experiments.md), [quickstart.md](./quickstart.md)

**Tests**: Included — spec.md's definition of done requires unit tests for the summary
calculation, deterministic variant assignment, and event recording, plus XCUITest coverage,
matching the constitution's test-first principle and Specifications 1-3's precedent.

**Organization**: Tasks are grouped by user story. There is no Foundational phase this time —
unlike Specifications 1-3, this spec's three user stories share no single blocking model or
protocol (see plan.md's Project Structure): User Story 1 only needs existing `FollowUp` data,
User Story 2 owns `ExperimentAssignment`/`ExperimentProviding`, and User Story 3 owns
`AnalyticsEvent`/`AnalyticsTracking`. Each story's phase is self-contained.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to the repository root, matching plan.md's Project Structure

---

## Phase 1: User Story 1 - See how I'm doing on follow-ups (Priority: P1) 🎯 MVP

**Goal**: A follow-up performance summary (completion rate, counts by status), reachable from the
Today tab, reflecting the current state of the user's follow-ups.

**Independent Test**: Complete, reschedule, and leave overdue a mix of follow-ups across several
contacts, then open the summary and confirm the numbers match — independent of whether any
analytics events or experiments exist, since this story reads `FollowUp` data directly.

### Tests for User Story 1

- [ ] T001 [P] [US1] Unit tests for `FollowUpInsights.summarize(_:)` — completion rate math, status counts, empty-state case, and that a deleted follow-up drops out of both numerator and denominator — in `NextStepTests/FollowUpInsightsTests.swift`
- [ ] T002 [P] [US1] XCUITest covering the summary's numbers matching a mix of completed/overdue/upcoming follow-ups, the empty state with none created, and the numbers updating immediately after completing a follow-up, in `NextStepUITests/ExperimentsAnalyticsFlowUITests.swift`

### Implementation for User Story 1

- [ ] T003 [US1] Implement the pure `FollowUpInsights.summarize(_:) -> FollowUpSummary` function (completion rate, counts by completed/overdue/upcoming, excluding deleted follow-ups by construction since they're simply absent from the input array) in `NextStep/Features/Dashboard/FollowUpInsights.swift`
- [ ] T004 [US1] Create `FollowUpSummaryView`, rendering the summary via `ContactRepository.fetchAllFollowUps()` + `FollowUpInsights`, with empty-state guidance when there are no follow-ups, in `NextStep/Features/Dashboard/FollowUpSummaryView.swift` (depends on T003)
- [ ] T005 [US1] Add an "Insights" toolbar entry point to `NextStep/Features/FollowUps/TodayView.swift` presenting `FollowUpSummaryView` (depends on T004)

**Checkpoint**: User Story 1 is functional and independently testable — the summary reflects real
follow-up data without needing User Story 2 or 3 to exist.

---

## Phase 2: User Story 2 - Consistent reminder wording per person (Priority: P2)

**Goal**: Each on-device installation is assigned one of two reminder-notification-title variants,
once, and every subsequent scheduled reminder for that installation uses the same variant.

**Independent Test**: Trigger reminder scheduling multiple times across separate app launches for
the same installation and confirm the notification title's wording variant never changes; confirm
via unit tests that a fresh `ExperimentAssignment` lookup persists its first result.

### Tests for User Story 2

- [ ] T006 [P] [US2] Unit tests for `SwiftDataExperimentProvider` — first access assigns and persists a variant, subsequent accesses return the same persisted variant unchanged — in `NextStepTests/SwiftDataExperimentProviderTests.swift`

### Implementation for User Story 2

- [ ] T007 [P] [US2] Create the `ExperimentAssignment` `@Model` and `ReminderCopyVariant` enum (control, variant) in `NextStep/Core/Models/ExperimentAssignment.swift` per [data-model.md](./data-model.md)
- [ ] T008 [US2] Create the `ExperimentProviding` protocol and its environment key in `NextStep/Core/Experiments/ExperimentProviding.swift` per [contracts/analytics-and-experiments.md](./contracts/analytics-and-experiments.md) (depends on T007)
- [ ] T009 [US2] Implement `SwiftDataExperimentProvider` — find-or-create the `ExperimentAssignment` row for `experimentKey == "reminderCopy"`, assigning a variant only if no row exists yet — in `NextStep/Core/Experiments/SwiftDataExperimentProvider.swift` (depends on T008)
- [ ] T010 [US2] Wire `SwiftDataExperimentProvider` into `NextStep/App/NextStepApp.swift`'s environment injection, alongside the existing `contactRepository`/`notificationScheduling` pattern (depends on T009)
- [ ] T011 [US2] Update `NextStep/Core/Notifications/UNNotificationScheduler.swift` to take an injected `ExperimentProviding` and use `reminderCopyVariant` to choose the notification's title template (control: "Follow up with {name}"; variant: alternate wording) — the body remains unchanged (user's `suggestedAction` or the existing fallback), per research.md (depends on T009)

**Checkpoint**: User Story 2 is functional — reminder titles consistently reflect one assigned
variant per installation; independently testable via unit tests without User Story 1 or 3.

---

## Phase 3: User Story 3 - Inspect what's being tracked (Priority: P3)

**Goal**: A developer screen, reachable from the Contacts tab's existing overflow menu, lists
recorded analytics events (most-recent-first) and the current reminder-copy variant assignment.

**Independent Test**: Perform actions covering each of the five tracked event types, then open the
developer screen and confirm each appears with its type and timestamp, alongside the current
variant (from User Story 2, if already assigned).

### Tests for User Story 3

- [ ] T012 [P] [US3] Unit tests for `SwiftDataAnalyticsTracker` — `track(_:contact:followUp:)` persists an `AnalyticsEvent` with the correct type/timestamp/`contextLabel`, and `fetchRecentEvents()` returns them most-recent-first — in `NextStepTests/SwiftDataAnalyticsTrackerTests.swift`
- [ ] T013 [P] [US3] XCUITest covering the developer screen's event list ordering, its empty state with nothing tracked yet, and the displayed experiment variant, added to `NextStepUITests/ExperimentsAnalyticsFlowUITests.swift`

### Implementation for User Story 3

- [ ] T014 [P] [US3] Create the `AnalyticsEvent` `@Model` and `AnalyticsEventType` enum (reminderDisplayed, contactOpened, followUpCompleted, reminderDismissed, followUpRescheduled) in `NextStep/Core/Models/AnalyticsEvent.swift` per [data-model.md](./data-model.md)
- [ ] T015 [US3] Create the `AnalyticsTracking` protocol and its environment key in `NextStep/Core/Analytics/AnalyticsTracking.swift` per [contracts/analytics-and-experiments.md](./contracts/analytics-and-experiments.md) (depends on T014)
- [ ] T016 [US3] Implement `SwiftDataAnalyticsTracker` — OSLog structured log entry + `AnalyticsEvent` persistence per call, non-throwing, `fetchRecentEvents()` sorted most-recent-first — in `NextStep/Core/Analytics/SwiftDataAnalyticsTracker.swift` (depends on T015)
- [ ] T017 [US3] Wire `SwiftDataAnalyticsTracker` into `NextStep/App/NextStepApp.swift`'s environment injection (depends on T016)
- [ ] T018 [US3] Register a `UNNotificationCategory` with `.customDismissAction` at launch and set it as scheduled reminders' `categoryIdentifier`, in `NextStep/App/NextStepApp.swift` and `NextStep/Core/Notifications/UNNotificationScheduler.swift` — required for dismissal to be observable at all, per research.md (depends on T011)
- [ ] T019 [US3] Track `reminderDisplayed` (on foreground presentation / delivered-notification handling) and `reminderDismissed` (on `UNNotificationDismissActionIdentifier`) in `NextStep/Core/Notifications/NotificationDelegate.swift` (depends on T017, T018)
- [ ] T020 [P] [US3] Track `contactOpened` in `NextStep/Features/Contacts/ContactDetailView.swift`, guarded (`@State private var hasTrackedOpen`) to fire once per appearance, not on every sheet dismissal — per research.md (depends on T017)
- [ ] T021 [US3] Track `followUpCompleted` in `completeFollowUp(_:)`, and `followUpRescheduled` in `saveFollowUp(_:for:)` only when updating an already-persisted follow-up (`modelContext != nil` before insert) whose `dueDate` changed — per research.md's create-vs-reschedule detection — in `NextStep/Core/Persistence/SwiftDataContactRepository.swift` (depends on T017)
- [ ] T022 [US3] Create `DeveloperAnalyticsView` (event list most-recent-first via `fetchRecentEvents()`, empty state, current `reminderCopyVariant` display) in `NextStep/Features/Dashboard/DeveloperAnalyticsView.swift` (depends on T017, T009)
- [ ] T023 [US3] Add a "Developer Info" entry point to the existing overflow menu in `NextStep/Features/Contacts/ContactListView.swift`, presenting `DeveloperAnalyticsView` (depends on T022)

**Checkpoint**: All three user stories are independently functional — this is the full spec.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span all three user stories.

- [ ] T024 Add accessibility labels/hints to the new summary and developer-screen controls (`FollowUpSummaryView`, `DeveloperAnalyticsView`, the new "Insights" and "Developer Info" entry points)
- [ ] T025 Walk through every scenario in [quickstart.md](./quickstart.md) — including the manual-only reminder-copy variant scenario on a real device/simulator and the full Specification 1-3 regression suite — and fix any discrepancies found
- [ ] T026 [P] Add the Specification 4 entry to `AI_USAGE.md` per the constitution's Development Workflow

---

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1 (Phase 1)**: No dependencies on other phases in this spec — start immediately.
- **User Story 2 (Phase 2)**: No dependencies on User Story 1; independent.
- **User Story 3 (Phase 3)**: T018 depends on T011 (Phase 2) because it modifies the same
  `UNNotificationScheduler.scheduleReminder` method T011 already touched — this is the one real
  ordering constraint across stories in this spec. Everything else in Phase 3 is independent of
  Phase 1/2.
- **Polish (Phase 4)**: Depends on User Stories 1-3 all being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Fully independent — reads existing `FollowUp` state only, no new model
  or protocol shared with the other stories.
- **User Story 2 (P2)**: Fully independent of User Story 1; User Story 3's T018 has a soft
  ordering dependency on this story's T011 (same file, same method) but no functional dependency —
  User Story 3's own event tracking would work even if User Story 2 didn't exist.
- **User Story 3 (P3)**: Independent of User Story 1. Has the one file-level ordering note on
  User Story 2 above; otherwise additive.

### Within Each User Story

- Tests are written first and should fail before implementation begins.
- Model/protocol before view model before views (as in Specifications 1-3).
- Story complete and checkpointed before moving to the next priority.

### Parallel Opportunities

- T001 and T002 (US1 tests) can run in parallel.
- T007 (US2 model) has no dependencies and can start immediately, in parallel with all of Phase 1.
- T012, T013, and T014 (US3 tests + model) can run in parallel with each other, and T014 can run
  in parallel with all of Phase 1/2.
- T020 (contactOpened tracking) can run in parallel with T018-T019 (notification-dismissal
  plumbing) once T017 is done — different files.
- T026 (AI_USAGE.md) can run in parallel with T024-T025.

---

## Parallel Example: User Story 1

```bash
# Tests for User Story 1 together:
Task: "Unit tests for FollowUpInsights.summarize in NextStepTests/FollowUpInsightsTests.swift"
Task: "XCUITest for the follow-up summary in NextStepUITests/ExperimentsAnalyticsFlowUITests.swift"

# User Story 2's model can start in parallel with all of User Story 1:
Task: "Create ExperimentAssignment model in NextStep/Core/Models/ExperimentAssignment.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: User Story 1.
2. **STOP and VALIDATE**: run T001/T002 and confirm the summary's numbers are correct, per
   quickstart.md's User Story 1 scenarios.
3. This is a demoable increment: the completion-rate summary works, even without any experiment or
   analytics-event plumbing existing yet.

### Incremental Delivery

1. Add User Story 1 → validate independently → the follow-up summary is usable.
2. Add User Story 2 → validate independently (automated) + manually (real device, per
   quickstart.md) → reminder titles are deterministically assigned per installation.
3. Add User Story 3 → validate independently → the developer screen shows tracked events and the
   current variant.
4. Phase 4 Polish → accessibility, full quickstart pass (including Spec 1-3 regression),
   AI_USAGE.md entry.

---

## Notes

- [P] tasks touch different files with no unmet dependencies.
- [Story] label maps each task to its user story for traceability back to spec.md.
- Commit after each task or logical group, scoped to this specification only (constitution
  Development Workflow) — no unrelated refactors bundled in.
- Verify new tests fail before implementing the corresponding behavior.
- Run Specifications 1-3's full regression suite alongside this spec's new tests at each
  checkpoint — this spec modifies `ContactDetailView`, `ContactListView`, `TodayView`,
  `UNNotificationScheduler`, `SwiftDataContactRepository`, and `NextStepApp.swift`, all
  load-bearing for everything built so far.
- The reminder-copy variant's real-notification scenario (T025's manual pass) cannot be fully
  automated per research.md, mirroring Specification 3's notification-delivery constraint — don't
  try to force it into the XCUITest suite.
- Stop at each checkpoint to validate that story independently before moving on.
