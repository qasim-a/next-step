---

description: "Task list for Specification 1: Core Data & Contact Management"
---

# Tasks: Core Data & Contact Management

**Input**: Design documents from `/specs/001-contact-management/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/contact-repository.md](./contracts/contact-repository.md), [quickstart.md](./quickstart.md)

**Tests**: Included — spec.md's definition of done requires unit tests for filtering/repository
behavior, and the constitution (Principle III) requires XCTest/XCUITest coverage of the full
create/search/edit/delete flow, empty states, and relaunch/persistence.

**Organization**: Tasks are grouped by user story (from spec.md) to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to the repository root, matching plan.md's Project Structure

---

## Phase 1: Setup

**Purpose**: Bring the Xcode project itself into existence — nothing in this spec exists yet.

- [ ] T001 Create the `NextStep` Xcode project at repository root: SwiftUI app target `NextStep` (iOS 17.0 deployment target), plus `NextStepTests` (Swift Testing) and `NextStepUITests` (XCTest/XCUITest) targets, per plan.md's Project Structure
- [ ] T002 [P] Create the empty folder groups `NextStep/App/`, `NextStep/Core/Models/`, `NextStep/Core/Persistence/`, `NextStep/Core/DesignSystem/`, and `NextStep/Features/Contacts/` matching plan.md (no `Core/Notifications`, `Core/Analytics`, or `Core/Experiments` yet — those belong to later specs)

**Checkpoint**: Project builds and runs (empty screen) on an iOS 17+ simulator.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared models and persistence boundary every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T003 [P] Create `NetworkingContact` SwiftData `@Model` (with `RelationshipCategory` enum: recruiter, referral, alumnus, hiringManager, peer) in `NextStep/Core/Models/NetworkingContact.swift` per [data-model.md](./data-model.md)
- [ ] T004 [P] Create `Company` SwiftData `@Model` in `NextStep/Core/Models/Company.swift` per [data-model.md](./data-model.md)
- [ ] T005 Define the `ContactRepository` protocol in `NextStep/Core/Persistence/ContactRepository.swift` per [contracts/contact-repository.md](./contracts/contact-repository.md) (depends on T003, T004)
- [ ] T006 Implement `SwiftDataContactRepository` (conforms to `ContactRepository`, owns the `ModelContext`) in `NextStep/Core/Persistence/SwiftDataContactRepository.swift` (depends on T005)
- [ ] T007 Wire `NextStepApp.swift` in `NextStep/App/NextStepApp.swift`: configure the SwiftData `ModelContainer` for `NetworkingContact`/`Company` and make a `ContactRepository` available to the view hierarchy (depends on T006)

**Checkpoint**: Foundation ready — models, repository, and app wiring compile; user story UI work can begin.

---

## Phase 3: User Story 1 - Capture a new contact right after meeting someone (Priority: P1) 🎯 MVP

**Goal**: A user can create a contact (name required, everything else optional) and see it appear
in the contact list.

**Independent Test**: Launch the app, add a contact with only a name → it appears in the list.
Add another contact filling in every field → all fields save. Try saving with an empty name → save
is blocked. Cancel creation → no contact is created.

### Tests for User Story 1

- [ ] T008 [P] [US1] Unit tests for `SwiftDataContactRepository` save/fetch round-trip against an in-memory `ModelContainer` in `NextStepTests/SwiftDataContactRepositoryTests.swift`
- [ ] T009 [P] [US1] XCUITest covering create-with-name-only, create-with-all-fields, blocked-empty-name, and cancel-discards-nothing in `NextStepUITests/ContactManagementFlowUITests.swift`

### Implementation for User Story 1

- [ ] T010 [P] [US1] Create `ContactViewModel` in `NextStep/Features/Contacts/ContactViewModel.swift` exposing create/save operations backed by `ContactRepository` (depends on Phase 2)
- [ ] T011 [US1] Create `ContactFormView` (create/edit) in `NextStep/Features/Contacts/ContactFormView.swift` with name-required validation, presented as a sheet (depends on T010)
- [ ] T012 [US1] Create `ContactListView` in `NextStep/Features/Contacts/ContactListView.swift` listing contacts from `ContactViewModel`, with empty-state guidance for zero contacts (SC-006) and an action that presents `ContactFormView` as a sheet (depends on T010)
- [ ] T013 [US1] Set `ContactListView` as the app's root view in `NextStep/App/NextStepApp.swift` (depends on T012)

**Checkpoint**: User Story 1 is fully functional and independently testable — contacts can be
created and appear in the list.

---

## Phase 4: User Story 2 - Find a contact again quickly (Priority: P2)

**Goal**: A user can search by name/company and filter by relationship category, combined or
separately.

**Independent Test**: Seed several contacts across companies/categories. Search by partial name →
only matches show. Search by partial company → only matches show. Filter by category → only that
category shows. Combine search + filter → results satisfy both. No matches → clear empty-results
state. Clear search/filter → full list returns.

### Tests for User Story 2

- [ ] T014 [P] [US2] Unit tests for the `ContactFiltering` function — search by name, by company, category filter, combined search+filter, no-match case — in `NextStepTests/ContactFilteringTests.swift`
- [ ] T015 [P] [US2] XCUITest covering search-matches, category-filter, combined filter, empty-results state, and clearing search/filter, added to `NextStepUITests/ContactManagementFlowUITests.swift`

### Implementation for User Story 2

- [ ] T016 [P] [US2] Implement the pure `ContactFiltering` function (search text over name/company + category filter) in `NextStep/Features/Contacts/ContactFiltering.swift`
- [ ] T017 [US2] Add a search field and relationship-category filter control to `NextStep/Features/Contacts/ContactListView.swift`, driven by `ContactFiltering` (depends on T016, T012)
- [ ] T018 [US2] Add the empty-results state (no matches) to `NextStep/Features/Contacts/ContactListView.swift`, distinct from the zero-contacts empty state from US1 (depends on T017)

**Checkpoint**: User Stories 1 AND 2 both work independently.

---

## Phase 5: User Story 3 - Review and update a contact over time (Priority: P3)

**Goal**: A user can open a contact's full detail view, edit and save (or cancel) changes, and
delete a contact with confirmation.

**Independent Test**: Open an existing contact → see all stored fields. Edit a field and save →
change reflected in detail view and list. Edit but cancel → original value unchanged. Delete with
confirmation → contact gone from list and search. Force-quit and relaunch → all data intact.

### Tests for User Story 3

- [ ] T019 [P] [US3] Unit tests for `SwiftDataContactRepository` update and delete behavior, added to `NextStepTests/SwiftDataContactRepositoryTests.swift`
- [ ] T020 [P] [US3] XCUITest covering view-detail, edit-and-save, edit-and-cancel, delete-with-confirmation, and relaunch persistence, added to `NextStepUITests/ContactManagementFlowUITests.swift`

### Implementation for User Story 3

- [ ] T021 [P] [US3] Create `ContactDetailView` in `NextStep/Features/Contacts/ContactDetailView.swift` showing all stored fields, structured so interaction-history and opportunity sections can be added later without rework (FR-018) (depends on Phase 2)
- [ ] T022 [US3] Wire `ContactListView` row selection to navigate to `ContactDetailView` in `NextStep/Features/Contacts/ContactListView.swift` (depends on T021, T012)
- [ ] T023 [US3] Add an edit entry point on `ContactDetailView` that reuses `ContactFormView` pre-filled with the contact's current values, honoring save/cancel semantics from FR-012/FR-013, in `NextStep/Features/Contacts/ContactDetailView.swift` and `NextStep/Features/Contacts/ContactFormView.swift` (depends on T021, T011)
- [ ] T024 [US3] Add a delete action with confirmation on `ContactDetailView`, removing the contact via `ContactRepository.delete` in `NextStep/Features/Contacts/ContactDetailView.swift` (depends on T021, T006)

**Checkpoint**: All three user stories are independently functional — this is the full spec.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that span all three user stories.

- [ ] T025 Add accessibility labels to the interactive controls in `NextStep/Features/Contacts/ContactListView.swift`, `NextStep/Features/Contacts/ContactFormView.swift`, and `NextStep/Features/Contacts/ContactDetailView.swift`
- [ ] T026 Enforce the notes max-length and relationship-strength (1–5) bounds from data-model.md's validation rules in `NextStep/Features/Contacts/ContactFormView.swift`
- [ ] T027 Walk through every scenario in [quickstart.md](./quickstart.md) manually on a simulator and fix any discrepancies found
- [ ] T028 [P] Add the Specification 1 entry to `AI_USAGE.md` (AI-assisted parts, manually reviewed code, rejected suggestions, validating tests) per the constitution's Development Workflow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion. BLOCKS all user stories.
- **User Stories (Phase 3-5)**: All depend on Foundational completion; independently testable
  once it's done. Recommended order follows priority: US1 → US2 → US3.
- **Polish (Phase 6)**: Depends on US1, US2, and US3 all being complete.

### User Story Dependencies

- **User Story 1 (P1)**: No dependency on other stories — this is the MVP slice.
- **User Story 2 (P2)**: Builds on `ContactListView` from US1 (adds search/filter to it) but is
  independently testable — US1's create flow just needs to exist first to have contacts to find.
- **User Story 3 (P3)**: Builds on `ContactListView`/`ContactFormView` from US1 but is
  independently testable — needs an existing contact to open/edit/delete.

### Within Each User Story

- Tests are written first and should fail before implementation begins.
- Models/protocol (Phase 2) before view models before views (this spec's models are shared, so
  they live entirely in Phase 2).
- View model before the views that consume it.
- Story complete and checkpointed before moving to the next priority.

### Parallel Opportunities

- T003 and T004 (the two models) can run in parallel.
- T008 and T009 (US1 tests) can run in parallel.
- T014, T015, and T016 (US2 tests + `ContactFiltering` implementation) can run in parallel.
- T019, T020, and T021 (US3 tests + `ContactDetailView` creation) can run in parallel.
- T028 (AI_USAGE.md) can run in parallel with T025-T027.

---

## Parallel Example: User Story 1

```bash
# Tests for User Story 1 together:
Task: "Unit tests for SwiftDataContactRepository save/fetch in NextStepTests/SwiftDataContactRepositoryTests.swift"
Task: "XCUITest for create-contact flow in NextStepUITests/ContactManagementFlowUITests.swift"

# Foundational models together (Phase 2, before US1 starts):
Task: "Create NetworkingContact model in NextStep/Core/Models/NetworkingContact.swift"
Task: "Create Company model in NextStep/Core/Models/Company.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (critical — blocks all stories).
3. Complete Phase 3: User Story 1.
4. **STOP and VALIDATE**: run T008/T009 and manually create a contact per quickstart.md's User
   Story 1 scenarios.
5. This is a demoable MVP: contacts can be captured and listed, even without search or editing.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. Add User Story 1 → validate independently → demo-able MVP.
3. Add User Story 2 → validate independently → search/filter now works.
4. Add User Story 3 → validate independently → full spec complete.
5. Phase 6 Polish → accessibility, validation bounds, full quickstart pass, AI_USAGE.md entry.

---

## Notes

- [P] tasks touch different files with no unmet dependencies.
- [Story] label maps each task to its user story for traceability back to spec.md.
- Commit after each task or logical group, scoped to this specification only (constitution
  Development Workflow) — no unrelated refactors bundled in.
- Verify new tests fail before implementing the corresponding behavior.
- Stop at each checkpoint to validate that story independently before moving on.
