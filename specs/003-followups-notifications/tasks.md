---

description: "Task list for Specification 3: Follow-ups and Notifications"
---

# Tasks: Follow-ups and Notifications

**Input**: Design documents from `/specs/003-followups-notifications/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/contact-repository-followups.md](./contracts/contact-repository-followups.md), [quickstart.md](./quickstart.md)

**Tests**: Included — spec.md's definition of done requires unit tests for due-date bucketing and
repository/notification-scheduling behavior, plus XCUITest coverage, matching the constitution's
test-first principle and Specifications 1-2's precedent.

**Organization**: Tasks are grouped by user story. There is no Setup phase — the Xcode project
already exists.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- File paths are relative to the repository root, matching plan.md's Project Structure

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: The `FollowUp` model, notification-scheduling boundary, and repository extension —
every user story depends on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T001 [P] Create the `FollowUp` `@Model` and `FollowUpPriority` enum (low, medium, high) in `NextStep/Core/Models/FollowUp.swift` per [data-model.md](./data-model.md)
- [ ] T002 Add the `followUps` relationship (`@Relationship(deleteRule: .cascade, inverse: \FollowUp.contact)`) to `NextStep/Core/Models/NetworkingContact.swift` (depends on T001)
- [ ] T003 [P] Create the `NotificationScheduling` protocol and its environment key in `NextStep/Core/Notifications/NotificationScheduling.swift` per [contracts/contact-repository-followups.md](./contracts/contact-repository-followups.md)
- [ ] T004 [P] Implement `UNNotificationScheduler` (real, backed by `UNUserNotificationCenter`) in `NextStep/Core/Notifications/UNNotificationScheduler.swift` (depends on T003)
- [ ] T005 [P] Implement `NoOpNotificationScheduler` (records calls in memory, schedules nothing real) in `NextStep/Core/Notifications/NoOpNotificationScheduler.swift` (depends on T003)
- [ ] T006 Extend the `ContactRepository` protocol with `fetchFollowUps(for:)`, `fetchAllFollowUps()`, `saveFollowUp(_:for:)`, `completeFollowUp(_:)`, `deleteFollowUp(_:)` in `NextStep/Core/Persistence/ContactRepository.swift` (depends on T001, T002)
- [ ] T007 Implement the above in `NextStep/Core/Persistence/SwiftDataContactRepository.swift`, taking an injected `NotificationScheduling` and calling schedule/cancel per the contract (create schedules, due-date change reschedules, complete/delete cancels, contact deletion cancels reminders for all its follow-ups before the cascade) (depends on T004, T005, T006)
- [ ] T008 [P] Implement the pure `FollowUpBucketing` function (Overdue/Due Today/Upcoming/Recently Completed) in `NextStep/Features/FollowUps/FollowUpBucketing.swift`
- [ ] T009 Wire scheduler selection into `NextStep/App/NextStepApp.swift` — `NoOpNotificationScheduler` under `-UITestResetState`/`XCTestConfigurationFilePath` (same test-detection switch as the in-memory `ModelContainer`), `UNNotificationScheduler` otherwise — and inject it into the repository (depends on T007)

**Checkpoint**: Foundation ready — model, notification boundary, repository, and bucketing logic
compile; user story UI work can begin.

---

## Phase 2: User Story 1 - Capture a follow-up for a contact (Priority: P1) 🎯 MVP

**Goal**: A user can create a follow-up (due date required, priority/suggested action optional)
against a contact, optionally pre-filled from an interaction's next-action text.

**Independent Test**: Create a follow-up with just a due date and confirm it saves (verifiable via
repository/unit tests even before the Today screen exists to display it). Create one from an
interaction's next-action text and confirm the suggested action starts pre-filled but editable.
Cancel creation and confirm nothing is created.

### Tests for User Story 1

- [ ] T010 [P] [US1] Unit tests for `saveFollowUp` (create path) confirming persistence and that `NoOpNotificationScheduler` records a schedule call, in `NextStepTests/FollowUpRepositoryTests.swift`
- [ ] T011 [P] [US1] XCUITest covering create-with-due-date-only, create-with-all-fields, create-from-interaction-prefill, and cancel-creates-nothing, in `NextStepUITests/FollowUpManagementFlowUITests.swift`

### Implementation for User Story 1

- [ ] T012 [P] [US1] Create `FollowUpViewModel` in `NextStep/Features/FollowUps/FollowUpViewModel.swift` — load a contact's follow-ups and expose a create operation backed by `ContactRepository` (depends on Phase 1)
- [ ] T013 [US1] Create `FollowUpFormView` (create mode, with an optional pre-fill parameter) in `NextStep/Features/FollowUps/FollowUpFormView.swift`, mirroring `ContactFormView`/`InteractionFormView`'s structure (depends on T012)
- [ ] T014 [US1] Add a "Create Follow-Up" entry point to `NextStep/Features/Contacts/ContactDetailView.swift` (contact-level, no pre-fill) presenting `FollowUpFormView` as a sheet (depends on T013)
- [ ] T015 [US1] Add a "Create Follow-Up" action on each interaction row in `ContactDetailView.swift`, pre-filling `FollowUpFormView` from that interaction's next-action text (depends on T013)

**Checkpoint**: User Story 1 is functional and independently testable — follow-ups can be created,
verifiable via T010/T011 even before Story 2 makes them visible anywhere in the UI.

---

## Phase 3: User Story 2 - See what needs attention today (Priority: P2)

**Goal**: A new Today tab, first in the app's tab bar, shows follow-ups grouped into Overdue, Due
Today, Upcoming, and Recently Completed.

**Independent Test**: Create follow-ups due in the past, today, and the future for different
contacts; confirm the Today screen buckets them correctly without navigating into individual
contacts. Confirm the app launches directly to Today. Confirm the empty state appears with zero
follow-ups.

### Tests for User Story 2

- [ ] T016 [P] [US2] Unit tests for `FollowUpBucketing` — overdue/due-today/upcoming/recently-completed assignment and boundary dates (e.g. exactly midnight, exactly the edge of the recent-completion window) — in `NextStepTests/FollowUpBucketingTests.swift`
- [ ] T017 [P] [US2] XCUITest covering all four Today-screen sections, the empty state, and that the app opens to Today on launch, added to `NextStepUITests/FollowUpManagementFlowUITests.swift`

### Implementation for User Story 2

- [ ] T018 [P] [US2] Create `FollowUpRow` (contact name, due date/status, priority, suggested action preview) in `NextStep/Features/FollowUps/FollowUpRow.swift`
- [ ] T019 [US2] Create `TodayView` with the four sections and empty-state guidance, using `FollowUpBucketing` and `ContactRepository.fetchAllFollowUps()`, in `NextStep/Features/FollowUps/TodayView.swift` (depends on T018)
- [ ] T020 [US2] Restructure `NextStep/App/NextStepApp.swift`'s root into a `TabView`: Today (`TodayView`) first, Contacts (`ContactListView`, unchanged) second, Today selected by default (depends on T019)

**Checkpoint**: User Stories 1 AND 2 both work — follow-ups can be created and seen grouped by due
date on the new Today tab.

---

## Phase 4: User Story 3 - Act on a follow-up (Priority: P3)

**Goal**: A user can mark a follow-up complete, reschedule it, edit its details, or delete it —
including deleting a contact removing its follow-ups.

**Independent Test**: Complete a follow-up and confirm it moves to Recently Completed; reschedule
one and confirm it moves to the section matching its new due date; edit one and confirm the
changes stick; delete one and confirm it's gone everywhere; delete a contact with follow-ups and
confirm they're gone too.

### Tests for User Story 3

- [ ] T021 [P] [US3] Unit tests for `completeFollowUp`, rescheduling via `saveFollowUp` (due-date change triggers cancel+reschedule), `deleteFollowUp`, and cascade delete (deleting a contact removes its follow-ups and cancels their reminders), in `NextStepTests/FollowUpRepositoryTests.swift`
- [ ] T022 [P] [US3] XCUITest covering complete, reschedule, edit, delete-with-confirmation, and delete-contact-removes-its-follow-ups, added to `NextStepUITests/FollowUpManagementFlowUITests.swift`

### Implementation for User Story 3

- [ ] T023 [US3] Extend `FollowUpViewModel` and `FollowUpFormView` to support editing an existing follow-up (pre-filled, updates in place on save — editing the due date is how rescheduling happens), in `NextStep/Features/FollowUps/FollowUpViewModel.swift` and `FollowUpFormView.swift` (depends on T012, T013)
- [ ] T024 [US3] Add a complete action to `FollowUpRow`/`TodayView` (depends on T019)
- [ ] T025 [US3] Wire tapping a follow-up row to open `FollowUpFormView` in edit mode, in `TodayView.swift` (depends on T023, T019)
- [ ] T026 [US3] Add a delete action with confirmation to `FollowUpRow`/`TodayView`, removing via `ContactRepository.deleteFollowUp` (depends on T019, T007)

**Checkpoint**: User Stories 1, 2, AND 3 all work — the full follow-up lifecycle is usable without
notifications yet.

---

## Phase 5: User Story 4 - Get reminded without having the app open (Priority: P4)

**Goal**: Notification permission is requested explicitly; incomplete follow-ups get local
reminders that stay in sync as they're rescheduled, completed, or deleted; tapping a reminder
opens the relevant contact; everything else keeps working if permission is denied.

**Independent Test**: With the no-op scheduler (automated tests) confirm the app requests
authorization gracefully and never breaks regardless of the outcome. Manually (real
device/simulator, per quickstart.md) confirm an actual reminder arrives, updates on reschedule,
cancels on completion/deletion, and tapping it opens the right contact.

### Tests for User Story 4

- [ ] T027 [P] [US4] Unit tests for `NoOpNotificationScheduler` confirming it correctly records schedule/cancel calls (used to verify T007's repository behavior), in `NextStepTests/NoOpNotificationSchedulerTests.swift`
- [ ] T028 [P] [US4] XCUITest confirming the app requests notification authorization at the right moment and continues working normally regardless of outcome, under the no-op scheduler, added to `NextStepUITests/FollowUpManagementFlowUITests.swift`

### Implementation for User Story 4

- [ ] T029 [US4] Call `requestAuthorizationIfNeeded()` at the first relevant moment (e.g. when the Today tab first appears, or when the first follow-up is created) in `NextStep/Features/FollowUps/TodayView.swift` or `FollowUpViewModel.swift` (depends on T004, T005, T009)
- [ ] T030 [US4] Implement notification-tap → contact routing via a `UNUserNotificationCenterDelegate` set at launch, storing the target contact for the navigation stack to react to, in `NextStep/App/NextStepApp.swift` (depends on T020)

**Checkpoint**: All four user stories are independently functional — this is the full spec.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span all four user stories.

- [ ] T031 Add accessibility labels/hints to the new follow-up and Today-screen controls (`FollowUpFormView`, `FollowUpRow`, `TodayView`'s complete/delete actions)
- [ ] T032 Walk through every scenario in [quickstart.md](./quickstart.md) manually — including the notification scenario on a real device/simulator (outside the automated suite) and the full Specification 1-2 regression suite — and fix any discrepancies found
- [ ] T033 [P] Add the Specification 3 entry to `AI_USAGE.md` per the constitution's Development Workflow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies on other phases in this spec — start immediately.
  BLOCKS all user stories.
- **User Stories (Phase 2-5)**: All depend on Foundational completion. Recommended order follows
  priority: US1 → US2 → US3 → US4, since US2's Today screen needs US1's follow-ups to display,
  US3's act-on-a-follow-up needs one to exist (US1) and be visible to tap (US2), and US4's
  reminders only matter once follow-ups can be created, seen, and change state (US1-3).
- **Polish (Phase 6)**: Depends on US1-4 all being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Depends only on Foundational — the MVP slice (data exists and is
  verifiable via tests even without the Today screen).
- **User Story 2 (P2)**: Needs US1's create flow to have follow-ups to display, and introduces
  the `TabView` restructure — everything after this phase runs inside the new tab structure.
- **User Story 3 (P3)**: Needs an existing follow-up (US1) visible somewhere to act on (US2), but
  its own code (complete/reschedule/edit/delete) is additive.
- **User Story 4 (P4)**: Needs follow-ups to exist and change state (US1-3) for reminders to have
  anything to schedule, reschedule, or cancel; purely additive on top.

### Within Each User Story

- Tests are written first and should fail before implementation begins.
- Model/protocol (Phase 1) before view model before views (as in Specifications 1-2).
- Story complete and checkpointed before moving to the next priority.

### Parallel Opportunities

- T001, T003 (model + notification protocol) can run in parallel; T004/T005 (the two scheduler
  implementations) can run in parallel once T003 exists.
- T010 and T011 (US1 tests) can run in parallel.
- T016, T017, and T018 (US2 tests + `FollowUpRow`) can run in parallel.
- T021 and T022 (US3 tests) can run in parallel.
- T027 and T028 (US4 tests) can run in parallel.
- T033 (AI_USAGE.md) can run in parallel with T031-T032.

---

## Parallel Example: User Story 1

```bash
# Tests for User Story 1 together:
Task: "Unit tests for saveFollowUp create path in NextStepTests/FollowUpRepositoryTests.swift"
Task: "XCUITest for create-follow-up flow in NextStepUITests/FollowUpManagementFlowUITests.swift"

# Foundational pieces together (Phase 1, before US1 starts):
Task: "Create FollowUp model in NextStep/Core/Models/FollowUp.swift"
Task: "Create NotificationScheduling protocol in NextStep/Core/Notifications/NotificationScheduling.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (critical — blocks all stories).
2. Complete Phase 2: User Story 1.
3. **STOP and VALIDATE**: run T010/T011 and confirm follow-ups save correctly, per
   quickstart.md's User Story 1 scenarios.
4. This is a demoable increment: follow-ups can be captured, even without the Today screen yet.

### Incremental Delivery

1. Foundational → foundation ready.
2. Add User Story 1 → validate independently → follow-ups can be captured.
3. Add User Story 2 → validate independently → the Today screen and tab bar exist.
4. Add User Story 3 → validate independently → the full lifecycle (act on a follow-up) works.
5. Add User Story 4 → validate independently (automated) + manually (real device, per
   quickstart.md) → reminders work end-to-end.
6. Phase 6 Polish → accessibility, full quickstart pass (including Spec 1-2 regression),
   AI_USAGE.md entry.

---

## Notes

- [P] tasks touch different files with no unmet dependencies.
- [Story] label maps each task to its user story for traceability back to spec.md.
- Commit after each task or logical group, scoped to this specification only (constitution
  Development Workflow) — no unrelated refactors bundled in.
- Verify new tests fail before implementing the corresponding behavior.
- Run Specifications 1-2's full regression suite alongside this spec's new tests at each
  checkpoint — this spec modifies `NetworkingContact` and the app's root navigation structure,
  both load-bearing for everything built so far.
- The real notification-delivery scenario (T032's manual pass) cannot be automated per
  research.md — don't try to force it into the XCUITest suite.
- Stop at each checkpoint to validate that story independently before moving on.
