# Phase 0 Research: Follow-ups and Notifications

No `NEEDS CLARIFICATION` markers remained in the Technical Context. This documents the rationale
behind the concrete choices made there.

## Testing notification behavior without the real permission dialog

- **Decision**: Define `NotificationScheduling` as a protocol with two implementations —
  `UNNotificationScheduler` (wraps the real `UNUserNotificationCenter`) and
  `NoOpNotificationScheduler` (records calls in memory, grants no real permission, sends nothing).
  The app selects which one to inject the same way it already selects an in-memory vs. real
  `ModelContainer`: based on `-UITestResetState` / `XCTestConfigurationFilePath` (the same
  test-detection switch already in `NextStepApp.swift` from Specification 1).
- **Rationale**: `UNUserNotificationCenter`'s permission prompt is a system-owned UI (effectively
  a SpringBoard alert), not app UI — XCUITest cannot reliably drive it, and even if it could,
  granting real notification permission in a CI-run simulator is exactly the kind of
  environment-dependent, flaky precondition this project's `-UITestResetState` pattern exists to
  avoid (see Specification 1's ModelContainer-lifetime research entry, and Specification 2's
  simulator-flakiness discussion). Testing against a fake keeps scheduling logic (schedule on
  create, reschedule on due-date change, cancel on complete/delete) fully deterministic and fast.
- **Alternatives considered**: Driving the real permission alert via `addUIInterruptionMonitor` —
  technically possible but historically flaky across Xcode/iOS versions, and still wouldn't let
  unit tests (which don't run the app) verify scheduling logic. Skipping notification testing
  entirely — rejected, it's directly required by this spec's definition of done and by the
  constitution's test-first principle.

## Where cascade-delete and reschedule/cancel logic lives

- **Decision**: Mirror Specification 2's precedent — `SwiftDataContactRepository` calls the
  injected `NotificationScheduling` instance directly from its `FollowUp` save/delete methods
  (schedule on save if incomplete, cancel on delete or on completion, reschedule by canceling +
  rescheduling when the due date changes), the same way it recomputes
  `lastInteractionDate` on every interaction write.
- **Rationale**: Keeping this in the repository means the reschedule/cancel invariant holds
  regardless of which view model calls it, consistent with the reasoning already established for
  `lastInteractionDate` in Specification 2's research.
- **Alternatives considered**: Doing it in `FollowUpViewModel` — would need every future call site
  (and there's already more than one: create, complete, reschedule, delete) to remember to keep
  notifications in sync; rejected for the same reason the `lastInteractionDate` recompute isn't in
  the view model.

## Due-date bucketing as a pure function

- **Decision**: A `FollowUpBucketing` pure function (mirroring `ContactFiltering` and
  `InteractionTimeline` from Specifications 1-2) that takes `[FollowUp]` and today's date, and
  returns the four buckets (Overdue, Due Today, Upcoming, Recently Completed).
- **Rationale**: Keeps the due-date rules — which are the crux of this spec's stated "central
  value" — independently unit-testable without a `ModelContext`, and keeps `TodayView` a thin
  rendering layer over already-computed buckets.
- **Alternatives considered**: Computed properties on `FollowUp` (e.g. `isOverdue`) — reasonable
  as a supporting detail, but the *recently completed window* and *bucket assignment* need "today"
  as an input to be testable (tests can't wait for real time to pass), so a pure function taking
  today's date as a parameter is still needed regardless; decided to keep all bucketing logic in
  one place rather than splitting it across model computed properties and a grouping function.

## Root navigation: TabView placement

- **Decision**: `NextStepApp.swift`'s `WindowGroup` now hosts a `TabView` with `TodayView` first
  and `ContactListView` (unchanged from Specification 1) second, rather than `ContactListView`
  being the root.
- **Rationale**: This is exactly the architectural change spec.md calls for (FR-013) — Today
  becomes the landing screen, matching the product's stated intent that follow-ups are the app's
  central value, not merely an additional feature.
- **Alternatives considered**: Keeping Contacts as the default tab with Today second — rejected,
  contradicts FR-013 and the product brief's explicit framing of the Today screen's priority.

## Notification tap → contact routing

- **Decision**: `NextStepApp` observes notification interactions via a
  `UNUserNotificationCenterDelegate` set at launch, extracts the follow-up's contact identifier
  from the notification's `userInfo`, and stores it in a small piece of app-level state that
  `ContactListView`'s `navigationDestination` can react to (pushing straight to that contact).
- **Rationale**: This keeps the routing decision at the app root (where the `TabView` and
  navigation stacks live) rather than threading a callback through several view layers.
- **Alternatives considered**: Handling the tap entirely inside `TodayView` — doesn't work,
  because a tapped notification can arrive while the app is backgrounded on any tab, not
  necessarily Today, so the routing needs to happen above both tabs.
