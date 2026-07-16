---

description: "Task list for Specification 2: Interactions"
---

# Tasks: Interactions

**Input**: Design documents from `/specs/002-interactions/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/contact-repository-interactions.md](./contracts/contact-repository-interactions.md), [quickstart.md](./quickstart.md)

**Tests**: Included — spec.md's definition of done requires unit tests for timeline ordering and
repository behavior plus XCUITest coverage, matching the constitution's test-first principle and
Specification 1's precedent.

**Organization**: Tasks are grouped by user story (from spec.md). There is no Setup phase this
time — the Xcode project already exists from Specification 1.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to the repository root, matching plan.md's Project Structure

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: The `Interaction` model, its relationship to `NetworkingContact`, and the extended
repository — every user story depends on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T001 [P] Create the `Interaction` `@Model` and `InteractionType` enum (linkedInConnectionRequest, linkedInMessage, email, phoneOrVideoCall, inPersonMeeting, interview, referralRequest) in `NextStep/Core/Models/Interaction.swift` per [data-model.md](./data-model.md)
- [ ] T002 Add the `interactions` relationship (`@Relationship(deleteRule: .cascade, inverse: \Interaction.contact)`) to `NextStep/Core/Models/NetworkingContact.swift` (depends on T001)
- [ ] T003 Extend the `ContactRepository` protocol with `fetchInteractions(for:)`, `saveInteraction(_:for:)`, `deleteInteraction(_:)` in `NextStep/Core/Persistence/ContactRepository.swift` per [contracts/contact-repository-interactions.md](./contracts/contact-repository-interactions.md) (depends on T001, T002)
- [ ] T004 Implement the three methods in `NextStep/Core/Persistence/SwiftDataContactRepository.swift`, including recomputing `contact.lastInteractionDate` (max interaction date, or `nil` if none) on every save/delete (depends on T003)
- [ ] T005 [P] Implement the pure `InteractionTimeline.sorted(_:)` ordering function (date descending, `createdAt` descending tiebreak) in `NextStep/Features/Interactions/InteractionTimeline.swift`

**Checkpoint**: Foundation ready — model, relationship, repository, and ordering logic compile;
user story UI work can begin.

---

## Phase 2: User Story 1 - Log an interaction right after it happens (Priority: P1) 🎯 MVP

**Goal**: A user can log a new interaction (type + date required, notes/outcome/next-action
optional) against a contact, and the contact's last-interaction date updates.

**Independent Test**: Open a contact, log an interaction with just a type and date, confirm it
saves (verifiable via unit test/repository state) and the contact's last-interaction date updates
to match. Log one with all fields filled in. Cancel logging and confirm nothing was created.

### Tests for User Story 1

- [ ] T006 [P] [US1] Unit tests for `saveInteraction` (create path) and the resulting `lastInteractionDate` update in `NextStepTests/InteractionRepositoryTests.swift`
- [ ] T007 [P] [US1] XCUITest covering log-with-type-and-date-only, log-with-all-fields, and cancel-creates-nothing in `NextStepUITests/InteractionManagementFlowUITests.swift`

### Implementation for User Story 1

- [ ] T008 [P] [US1] Create `InteractionViewModel` in `NextStep/Features/Interactions/InteractionViewModel.swift` — load a contact's interactions and expose a create operation backed by `ContactRepository` (depends on Phase 1)
- [ ] T009 [US1] Create `InteractionFormView` (create mode) in `NextStep/Features/Interactions/InteractionFormView.swift`, mirroring `ContactFormView`'s structure (depends on T008)
- [ ] T010 [US1] Add a "Log Interaction" entry point to `NextStep/Features/Contacts/ContactDetailView.swift` that presents `InteractionFormView` as a sheet (depends on T009)

**Checkpoint**: User Story 1 is functional — interactions can be logged and the last-interaction
date updates, independently testable via the repository tests even before the timeline (US2)
renders them.

---

## Phase 3: User Story 2 - See a contact's interaction history at a glance (Priority: P2)

**Goal**: The contact detail screen shows a chronological (most-recent-first) timeline of that
contact's interactions.

**Independent Test**: Log several interactions with different dates for one contact; confirm the
timeline lists them most-recent-first, each showing type/date/outcome without opening it. Confirm
a contact with zero interactions shows guidance instead of an empty gap.

### Tests for User Story 2

- [ ] T011 [P] [US2] Unit tests for `InteractionTimeline.sorted(_:)` — descending date order and same-date tiebreak by `createdAt` — in `NextStepTests/InteractionTimelineOrderingTests.swift`
- [ ] T012 [P] [US2] XCUITest covering timeline ordering (most-recent-first) and the zero-interactions empty state, added to `NextStepUITests/InteractionManagementFlowUITests.swift`

### Implementation for User Story 2

- [ ] T013 [P] [US2] Create `InteractionRow` (type, date, outcome preview) in `NextStep/Features/Interactions/InteractionRow.swift`
- [ ] T014 [US2] Add the timeline section to `NextStep/Features/Contacts/ContactDetailView.swift`, sorted via `InteractionTimeline.sorted(_:)`, with empty-state guidance when there are no interactions (depends on T013, T010)

**Checkpoint**: User Stories 1 AND 2 both work — interactions can be logged and seen on the
timeline.

---

## Phase 4: User Story 3 - Correct or remove a logged interaction (Priority: P3)

**Goal**: A user can edit an existing interaction's fields or delete it (with confirmation), and
the contact's last-interaction date recalculates correctly, including cascade delete when the
whole contact is removed.

**Independent Test**: Edit an interaction and confirm the timeline reflects the change; cancel an
edit and confirm nothing changed; delete an interaction and confirm it's gone from the timeline
and the last-interaction date recalculates (including falling back to "none recorded" when the
last interaction is removed); delete a contact and confirm its interactions are gone too.

### Tests for User Story 3

- [ ] T015 [P] [US3] Unit tests for `saveInteraction` (update path), `deleteInteraction` (including `lastInteractionDate` falling back to the next most recent date, or `nil` when none remain), and cascade delete (deleting a contact removes its interactions) in `NextStepTests/InteractionRepositoryTests.swift`
- [ ] T016 [P] [US3] XCUITest covering edit-and-save, edit-and-cancel, and delete-with-confirmation for an interaction, added to `NextStepUITests/InteractionManagementFlowUITests.swift`

### Implementation for User Story 3

- [ ] T017 [US3] Extend `InteractionFormView` to accept an optional existing interaction, pre-fill its fields, and update in place on save instead of creating a new one, in `NextStep/Features/Interactions/InteractionFormView.swift` and `NextStep/Features/Interactions/InteractionViewModel.swift` (depends on T009)
- [ ] T018 [US3] Wire tapping a timeline row to open `InteractionFormView` in edit mode, in `NextStep/Features/Contacts/ContactDetailView.swift` (depends on T014, T017)
- [ ] T019 [US3] Add a delete action with confirmation on interaction rows/detail, removing via `ContactRepository.deleteInteraction`, in `NextStep/Features/Contacts/ContactDetailView.swift` (depends on T014, T004)

**Checkpoint**: All three user stories are independently functional — this is the full spec.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span all three user stories.

- [ ] T020 Add accessibility labels/hints to the new interaction controls (`InteractionFormView`, `InteractionRow`, the timeline's log/edit/delete actions)
- [ ] T021 Walk through every scenario in [quickstart.md](./quickstart.md) manually on a simulator (including the Specification 1 regression scenarios) and fix any discrepancies found
- [ ] T022 [P] Add the Specification 2 entry to `AI_USAGE.md` per the constitution's Development Workflow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies on other phases in this spec — start immediately.
  BLOCKS all user stories.
- **User Stories (Phase 2-4)**: All depend on Foundational completion. Recommended order follows
  priority: US1 → US2 → US3, since US2's timeline needs interactions to display (from US1) and
  US3's edit/delete needs interactions to act on (from US1/US2).
- **Polish (Phase 5)**: Depends on US1, US2, and US3 all being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Depends only on Foundational — this is the MVP slice (data exists and is
  verifiable via tests even without a visible timeline).
- **User Story 2 (P2)**: Needs US1's create flow to have interactions to display, but its own
  code (the timeline section, `InteractionRow`, ordering logic) is additive.
- **User Story 3 (P3)**: Needs an existing interaction (from US1) to edit/delete, and the
  timeline (from US2) to tap into, but its own code (edit mode, delete action) is additive.

### Within Each User Story

- Tests are written first and should fail before implementation begins.
- Model/protocol (Phase 1) before view model before views (as in Specification 1).
- Story complete and checkpointed before moving to the next priority.

### Parallel Opportunities

- T001 and T005 (the model and the pure ordering function) can run in parallel.
- T006 and T007 (US1 tests) can run in parallel.
- T011, T012, and T013 (US2 tests + `InteractionRow`) can run in parallel.
- T015 and T016 (US3 tests) can run in parallel.
- T022 (AI_USAGE.md) can run in parallel with T020-T021.

---

## Parallel Example: User Story 1

```bash
# Tests for User Story 1 together:
Task: "Unit tests for saveInteraction create path in NextStepTests/InteractionRepositoryTests.swift"
Task: "XCUITest for logging an interaction in NextStepUITests/InteractionManagementFlowUITests.swift"

# Foundational pieces together (Phase 1, before US1 starts):
Task: "Create Interaction model in NextStep/Core/Models/Interaction.swift"
Task: "Create InteractionTimeline.sorted(_:) in NextStep/Features/Interactions/InteractionTimeline.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (critical — blocks all stories).
2. Complete Phase 2: User Story 1.
3. **STOP and VALIDATE**: run T006/T007 and confirm interactions save and update
   `lastInteractionDate`, per quickstart.md's User Story 1 scenarios.
4. This is a demoable increment: interactions can be logged, even without a visible timeline yet.

### Incremental Delivery

1. Foundational → foundation ready.
2. Add User Story 1 → validate independently → interactions can be logged.
3. Add User Story 2 → validate independently → the timeline is visible.
4. Add User Story 3 → validate independently → full spec complete, including cascade delete.
5. Phase 5 Polish → accessibility, full quickstart pass (including Spec 1 regression), AI_USAGE.md entry.

---

## Notes

- [P] tasks touch different files with no unmet dependencies.
- [Story] label maps each task to its user story for traceability back to spec.md.
- Commit after each task or logical group, scoped to this specification only (constitution
  Development Workflow) — no unrelated refactors bundled in.
- Verify new tests fail before implementing the corresponding behavior.
- Run Specification 1's full test suite alongside this spec's new tests at each checkpoint — this
  spec modifies `NetworkingContact` and `ContactDetailView`, both load-bearing for Spec 1.
- Stop at each checkpoint to validate that story independently before moving on.
