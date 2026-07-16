# AI Usage

This project is developed with [Spec Kit](https://github.com/github/spec-kit) and
Claude Code, following spec-driven development: each feature is specified,
planned, broken into tasks, and implemented in its own reviewable increment.

## Tools used

- **Spec Kit** — specification, planning, and task-breakdown workflow
  (`/speckit-constitution`, `/speckit-specify`, `/speckit-plan`,
  `/speckit-tasks`, `/speckit-implement`).
- **Claude Code** — implementation, test writing, and refactoring within the
  scope of each approved spec.

## Log

Entries are added per specification as it's completed.

| Spec | AI-assisted parts | Manually reviewed | Rejected AI suggestions | Validating tests |
|------|--------------------|--------------------|---------------------------|-------------------|
| 001 — Core Data & Contact Management | Constitution, spec, plan, tasks, and all implementation (models, repository, views, view model) | User reviewed and interacted with the running app in the simulator throughout implementation, approved each phase before the next began | None outright rejected; several early approaches were revised after failing (see below) | 15/15 unit tests (Swift Testing + XCTest), 16/16 UI tests (XCUITest) |

### Specification 1: Core Data & Contact Management

**AI-assisted**: All artifacts — constitution, spec, plan, research, data model, task
breakdown, and every line of implementation (SwiftData models, `ContactRepository` protocol
and implementation, `ContactViewModel`, `ContactListView`, `ContactFormView`,
`ContactDetailView`) and both test suites.

**Manually reviewed**: The user drove the toolchain setup themselves (installed Xcode),
approved the workflow at each spec-kit phase transition (spec → plan → tasks → implement),
asked for a running-app checkpoint mid-implementation and interacted with it directly in the
iOS Simulator, and requested the shift to one-task-at-a-time execution with a status report
after each.

**Approaches tried and reworked** (not "rejected AI suggestions" from the user so much as
bugs caught and fixed during implementation — logged here per the constitution's
Development Workflow):

- A `SwiftDataContactRepositoryTests` helper that created a `ModelContainer` locally and
  returned only a repository built from its context crashed on first use. Root cause:
  `ModelContext` doesn't retain its owning `ModelContainer`, so the container was deallocated
  the moment the helper returned. This was initially misdiagnosed as a Swift Testing/SwiftData
  incompatibility (a same-scope XCTest prototype happened to work by accident) before the real
  cause was isolated. Fixed by holding the container as a stored property for the test
  struct's lifetime. See `specs/001-contact-management/research.md`.
- Several XCUITest queries needed correction after the real accessibility hierarchy was
  inspected (`app.debugDescription`) rather than assumed: `ContentUnavailableView`'s
  `accessibilityIdentifier` doesn't expose under the `.otherElements` type; a `Menu` placed
  in `.secondaryAction` collapses into the nav bar's "More" overflow button and loses its
  custom identifier there (only its label survives); an active `.searchable` search field
  hides other toolbar buttons entirely; a `confirmationDialog`'s button identifier matches two
  nested elements, requiring `.firstMatch`.
- The relaunch-persistence UI test is the one test that must use the real on-disk store
  (in-memory can't demonstrate cross-process persistence); an early run that failed before its
  cleanup step ran left a duplicate contact behind, so the test was made self-healing (it
  removes any leftover contact with its test name before creating a fresh one).

**Validating tests**: `NextStepTests` (15 tests: `ContactFilteringTests` — search/category
logic; `SwiftDataContactRepositoryTests` — save/fetch/update/delete/company-dedup) and
`NextStepUITests` (16 tests in `ContactManagementFlowUITests` — covers every acceptance
scenario in `spec.md` end-to-end for all three user stories plus relaunch persistence). All
pass. Manual spot-checks: empty state, dark-mode rendering.
