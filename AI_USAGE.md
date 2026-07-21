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
| 002 — Interactions | Spec, plan, tasks, and all implementation (Interaction model, repository extension, timeline UI, edit/delete) | User interacted with the running app between phases; asked for the tap-to-edit bug to be root-caused and fixed rather than worked around | None outright rejected; a mid-debugging architectural change (multi-sheet consolidation) turned out not to be the actual fix — see below | 15/15 unit tests, 16/16 UI tests |
| 003 — Follow-ups and Notifications | Spec, plan, tasks, and all implementation (FollowUp model, NotificationScheduling protocol + real/no-op implementations, Today screen, TabView restructure, notification routing) | User asked for a size/effort comparison against Specs 1-2 before starting, then asked for the whole spec (all 4 user stories + polish) to be built in one continuous pass | None outright rejected; two real bugs found and fixed during implementation — see below | 47/47 unit tests, 38/38 UI tests (full-project regression) |

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

### Specification 2: Interactions

**AI-assisted**: All artifacts — spec, plan, research, data model, task breakdown, and every
line of implementation (`Interaction` model, `NetworkingContact` cascade-delete relationship,
`ContactRepository` extension, `InteractionTimeline` ordering, `InteractionViewModel`,
`InteractionFormView`, the timeline UI on `ContactDetailView`) and both test suites.

**Manually reviewed**: The user interacted with the running app between phases and, when a
timeline-row tap-to-edit interaction stopped working, explicitly asked for the bug to be found
and fixed rather than routed around.

**Approaches tried and reworked**:

- Diagnosing the tap-to-edit bug went through two wrong turns before the real cause: first
  suspected multiple `.sheet()` modifiers stacked on one view (a real SwiftUI gotcha, and worth
  fixing regardless, but not the actual cause here), then suspected a `.swipeActions` /
  `Button` gesture conflict (also fixed by switching to `.onTapGesture` + `.contentShape`, also
  not the actual cause). The real bug: the UI test's helper still queried `app.buttons` for the
  row after its element type had changed to `.staticTexts` partway through the detour, so it was
  tapping an empty placeholder. Both architectural changes were kept since they're independently
  correct, but neither was the fix — the actual fix was a one-line query correction. Documented
  as a reminder to verify a hypothesis (e.g. via a debug counter proving whether a handler even
  fires) before restructuring code to match it.
- SwiftData's cascade-delete rule for `Interaction` was verified empirically with a dedicated
  test rather than trusted from documentation, continuing the precedent set in Specification 1.

**Validating tests**: `NextStepTests` gains `InteractionRepositoryTests` (save/fetch/update/
delete/cascade-delete, lastInteractionDate recompute) and `InteractionTimelineOrderingTests`
(date-descending sort with a stable tiebreak). `NextStepUITests` gains
`InteractionManagementFlowUITests` (log/view timeline/edit/delete, cascade delete). 15/15 unit
tests, 16/16 UI tests, all passing.

**Polish (completed retroactively)**: this spec's Polish phase (T020-T022) was originally skipped
and only closed out later, after Specification 3 shipped. Accessibility hints were added to match
the pattern already used elsewhere in the app: `contactDetail.deleteInteractionButton` now has
"Requires confirmation" (matching `contactDetail.deleteButton` and `today.deleteFollowUpButton`),
and `contactDetail.logInteractionButton` now has a descriptive hint (matching
`contactDetail.createFollowUpButton`). `InteractionFormView`'s fields already had identifiers and
implicit VoiceOver labels from their SwiftUI title parameters, at parity with `FollowUpFormView`.
`specs/002-interactions/quickstart.md`'s manual validation scenarios were cross-checked against
the existing automated test suite rather than walked by hand — no simulator tap-automation tool is
available in this environment (no `idb`, and `simctl` has no touch-injection command), so "manual
validation" here means: confirm each scenario has direct automated coverage, and explicitly flag
the one that doesn't. That gap is real: the relaunch-persistence test only covers a bare contact,
not one with interactions attached, so persistence of interaction data across a force-quit has
still not been verified by a human. Full regression suite re-run after these changes: 47/47 unit
tests, 38/38 UI tests passing (one UI test failed on the first run with the simulator's
"Lost connection to the application" error — this project's known environmental flakiness,
confirmed by re-running that single test in isolation, where it passed).

### Specification 3: Follow-ups and Notifications

**AI-assisted**: All artifacts — spec, plan, research, data model, task breakdown, and every
line of implementation: `FollowUp` model, `NotificationScheduling` protocol with real
(`UNNotificationScheduler`) and no-op (`NoOpNotificationScheduler`) implementations, the
repository extension, `FollowUpBucketing`, `TodayView`/`TodayViewModel`/`FollowUpRow`, the
`RootTabView` restructure, `NotificationRouter`/`NotificationDelegate` for notification-tap
routing, and all four user stories' UI wiring.

**Manually reviewed**: The user asked for a relative size/effort comparison against
Specifications 1-2 before starting (flagged as the largest architectural change so far, due to
the `TabView` restructure and first system-permission-flow), then explicitly asked for the
entire remaining spec — all four user stories plus polish — to be implemented in one continuous
pass with a single report at the end, a deliberate departure from the incremental
one-task-at-a-time cadence used for Specs 1-2.

**Approaches tried and reworked**:

- `saveFollowUp`/`completeFollowUp`/`deleteFollowUp` needed to be `async` (to call the also-async
  `NotificationScheduling`), which surfaced a real `SwiftData.ModelContext ... not Sendable,
  consider using a ModelActor` runtime warning: `SwiftDataContactRepository` was never
  statically pinned to the actor its `ModelContext` actually lives on. Fixed by marking
  `ContactRepository`, `SwiftDataContactRepository`, `NotificationScheduling`, and both scheduler
  implementations `@MainActor`, matching how they were already being used everywhere in
  practice.
- `.accessibilityIdentifier("today.screen")` on the `Group` wrapping `TodayView`'s content and
  `.accessibilityIdentifier("today.emptyState")` on the `ContentUnavailableView` inside it
  collided: because `Group` doesn't create its own accessibility element, the outer identifier
  silently overwrote the inner one on every leaf, so `today.emptyState` never actually existed
  in the accessibility tree and its test failed with no useful error. Fixed by removing the
  redundant outer identifier and checking the `NavigationBar` title instead for the one test
  that needed it.
- The most significant bug: after creating a follow-up from the Contacts tab and switching to
  Today, the screen still showed "No Follow-Ups Yet." Root cause — `TabView` keeps every tab's
  view alive rather than recreating it, so `TodayViewModel`'s `.task` (which only runs once per
  view identity) never re-ran when switching back to an already-initialized tab. Fixed by adding
  `.onAppear { viewModel?.loadFollowUps() }`, which does fire on every tab switch. This is a
  pattern worth remembering for any future tab added to this app.
- Because the app no longer opens directly to the contact list (it now opens to Today), every
  existing Specification 1-2 UI test needed a one-line fix to switch to the Contacts tab first;
  found by running the full regression suite rather than assuming the restructure was additive.

**Validating tests**: `NextStepTests` gains `FollowUpRepositoryTests` (save/fetch/reschedule/
complete/delete/cascade-delete, all cross-checked against `NoOpNotificationScheduler`'s recorded
calls), `FollowUpBucketingTests` (all four due-date buckets plus boundary dates), and
`NoOpNotificationSchedulerTests`. `NextStepUITests` gains `FollowUpManagementFlowUITests`
(create/prefill-from-interaction/see-on-Today/complete/reschedule/edit/delete/cascade/
authorization-request). Full project suite: 47/47 unit tests, 38/38 UI tests, all passing.

**Not automatable — flagged, not silently skipped**: the real notification-delivery path (does
a reminder actually arrive at its due date, does tapping it open the right contact) cannot be
driven by XCUITest, since it depends on the system-owned permission dialog. Unit and UI tests
instead verify the app's own scheduling/cancellation logic and graceful behavior via
`NoOpNotificationScheduler`. `specs/003-followups-notifications/quickstart.md` documents the
manual verification steps for a real device/simulator; these have not yet been run by a human.
