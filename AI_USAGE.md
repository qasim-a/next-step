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
| 004 — Experiments & Analytics | Spec, plan, tasks, and all implementation (AnalyticsTracking + ExperimentProviding protocols and real implementations, AnalyticsEvent/ExperimentAssignment models, follow-up summary, developer screen, five event-tracking call sites) | User asked whether Specs 4-5 were worth doing and whether the app was demo-ready before starting Spec 4; requested this spec's four phases be built in one continuous pass, same cadence as Spec 3 | None outright rejected; one planned design (date-diffing for reschedule detection) was simplified after proving unworkable, and two real bugs were found and fixed during implementation — see below | 60/60 unit tests, 44/44 UI tests (full-project regression) |

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

### Specification 4: Experiments & Analytics

**AI-assisted**: All artifacts — spec, plan, research, data model, task breakdown, and every
line of implementation: `AnalyticsTracking` and `ExperimentProviding` protocols (both named
directly by the constitution), their real implementations (`SwiftDataAnalyticsTracker`,
`SwiftDataExperimentProvider`), the `AnalyticsEvent`/`ExperimentAssignment` SwiftData models, the
follow-up completion-rate summary, the hidden developer screen, and the five event-tracking call
sites wired into `ContactDetailView`, `SwiftDataContactRepository`, and `NotificationDelegate`.

**Manually reviewed**: Before starting, the user asked two framing questions — whether
Specifications 4-5 were worth building at all, and whether the app in its current state was
demo-ready — which were answered candidly (Spec 4 optional, Spec 5 more valuable if shipping for
real use) before the user chose to proceed with Spec 4. The user then asked for all four phases
built in one continuous pass, the same cadence used for Specification 3.

**Approaches tried and reworked**:

- The plan (`research.md`) originally called for the repository to fire `followUpRescheduled` only
  when a follow-up's `dueDate` actually changed, by comparing it against its previously-persisted
  value. This turned out to be unworkable as planned: `FollowUp` is a SwiftData reference type, and
  the one call site that reschedules (`TodayViewModel.rescheduleFollowUp`) mutates `dueDate`
  directly before calling the repository, so the "old" value is already gone by the time the
  repository method runs — there's no public SwiftData API to read a model's last-persisted value
  back out mid-edit. Simplified to firing the event whenever `saveFollowUp` is called on an
  already-persisted follow-up (detected via `modelContext != nil`), which is an accurate proxy in
  this app specifically because there is no other UI path to updating an existing follow-up besides
  that reschedule form. Documented in `research.md` as a revision, not silently changed.
- A second, unrelated instance of Specification 3's `Group`-identifier-collision bug: the
  developer screen's "Events" `Section` had `.accessibilityIdentifier("developerAnalytics.eventList")`
  applied to the whole section, which silently overwrote the inner `developerAnalytics.emptyState`
  and `developerAnalytics.event` identifiers on its leaf content — `Section`, like `Group`, doesn't
  create its own accessibility element. Found the same way as Specification 3's instance: a UI test
  failed with no useful error, root-caused by exporting the actual accessibility hierarchy from the
  test run's `.xcresult` bundle rather than guessing. Fixed by removing the section-level identifier
  entirely, keeping only the leaf-level ones.
- A real (not test-only) UI test bug, not an app bug: a test helper for reaching the developer
  screen assumed tapping the Contacts tab always lands on the contact list. It doesn't — the
  Contacts tab's `NavigationPath` persists across tab switches (the same `TabView`-keeps-every-tab-
  alive behavior documented in Specification 3), so a test that had already pushed a contact detail
  screen earlier landed back on that screen instead. Fixed the test helper to pop back via
  `BackButton` first if present, rather than assuming a fresh list.
- Tracking a dismissed notification ("swiped away without opening the app") turned out to require
  opting in: `UNUserNotificationCenterDelegate` is not told about a dismissal by default — only a
  notification category registered with `.customDismissAction` reports it. Caught during planning
  (`research.md`) rather than during implementation, since it's the kind of gap that's easy to miss
  until testing dismissal by hand on a device.

**Validating tests**: `NextStepTests` gains `FollowUpInsightsTests` (completion-rate math, status
counts, empty state, deleted-follow-up exclusion), `SwiftDataExperimentProviderTests`
(first-access assignment persists and is stable across re-reads, including from a fresh provider
instance over the same store), and `SwiftDataAnalyticsTrackerTests` (event persistence with
correct fields, most-recent-first ordering, and that an event stays meaningful after its
referenced contact is deleted). `NextStepUITests` gains `ExperimentsAnalyticsFlowUITests`
(summary numbers/empty state/live updates, developer-screen event list/empty state/variant
display). Full project suite: 60/60 unit tests, 44/44 UI tests, all passing.

**Not automatable — flagged, not silently skipped**: the reminder-copy variant's effect on a real,
delivered notification (does the title actually show the assigned wording, does it stay consistent
across real scheduling over time) cannot be driven by XCUITest, for the same system-permission-
dialog reason as Specification 3's notification-delivery path.
`specs/004-experiments-analytics/quickstart.md` documents the manual verification steps; these
have not yet been run by a human.
