# Phase 0 Research: Experiments & Analytics

No `NEEDS CLARIFICATION` markers remained in the Technical Context. This documents the rationale
behind the concrete choices made there, plus a few non-obvious framework behaviors this spec
depends on getting right.

## Detecting a dismissed notification requires opting in, not just observing

- **Decision**: Register a `UNNotificationCategory` with the `.customDismissAction` option at app
  launch, and set `content.categoryIdentifier` to it on every scheduled follow-up reminder.
- **Rationale**: By default, `UNUserNotificationCenterDelegate` is **not** told when a user swipes
  away or otherwise clears a notification without opening the app — only explicit interactions
  (tap, custom actions) reach `userNotificationCenter(_:didReceive:withCompletionHandler:)`. The
  system only reports a dismissal (as `UNNotificationDismissActionIdentifier` in that same
  delegate method) if the notification's category was registered with `.customDismissAction`.
  Without this, FR-004 ("reminder dismissed" tracking) is silently unobservable — this would have
  been an easy gap to miss until manually testing dismissal on a device, so it's called out here
  rather than discovered during implementation.
- **Alternatives considered**: None — this is the only mechanism UserNotifications exposes for
  observing a dismissal. The alternative is not tracking dismissals at all, which directly
  contradicts FR-004.

## Distinguishing "create" from "reschedule" for the repository-level event

- **Decision**: Inside `SwiftDataContactRepository.saveFollowUp(_:for:)`, check
  `followUp.modelContext == nil` *before* calling `modelContext.insert(followUp)` to decide whether
  this call is a first-time creation (no event, matches Specification 3's existing precedent for
  new follow-ups) or an update to an already-persisted follow-up. Fire the `followUpRescheduled`
  analytics event only in the second case, and only when `dueDate` actually differs from the
  previously-persisted value.
- **Rationale**: `saveFollowUp` is already the single call site for both create and reschedule
  (this is also why it unconditionally cancels-then-reschedules the notification, per
  Specification 3's research). A SwiftData model's `modelContext` is `nil` until it has been
  inserted into a context, which makes it a reliable, already-available signal for "is this
  object new" without adding a separate `isNew` parameter that every call site would have to pass
  correctly.
- **Alternatives considered**: Adding an explicit `isReschedule: Bool` parameter to
  `saveFollowUp` — rejected, it duplicates information the object itself already encodes and adds
  a parameter every existing call site (`FollowUpViewModel`, `TodayViewModel`) would need to be
  audited to pass correctly. Comparing before/after `dueDate` alone without the `modelContext`
  check — insufficient on its own, since it wouldn't distinguish a genuine reschedule from the
  due-date-setting that happens during initial creation.

## Avoiding double-counting "contact opened" across sheet presentations

- **Decision**: Track `contactOpened` from `ContactDetailView` using a per-appearance guard
  (`@State private var hasTrackedOpen = false`, matching the existing
  `hasRequestedNotificationAuthorization` pattern already used in `TodayView`), set once inside
  `.onAppear` in this view specifically. Do not track it from `RootTabView`'s notification-tap
  routing separately — that routing pushes the same `ContactDetailView` onto the stack, so its
  `.onAppear` still fires once and no duplicate tracking call is needed at the routing layer.
- **Rationale**: SwiftUI re-invokes a view's `.onAppear` when a `.sheet` presented from it is
  dismissed (e.g. after editing the contact, logging an interaction, or creating a follow-up) —
  this is a real behavior, not a hypothetical: it's the same underlying mechanism behind
  Specification 3's TabView-staleness bug, where reappearing view state re-runs `.onAppear`
  unexpectedly. Without a guard, one visit to a contact that involves any sheet would be recorded
  as multiple `contactOpened` events, inflating the developer screen's counts and, if this data
  were ever used for real analysis, corrupting it.
- **Alternatives considered**: Tracking on `.task` instead of `.onAppear` — doesn't solve it,
  `.task` only avoids re-running on tab reselection (Specification 3's issue), not on sheet
  dismissal, which is the failure mode here. Tracking at the `NavigationStack`'s
  `navigationDestination` construction site — more correct in principle but not worth the added
  indirection for one guarded boolean.

## OSLog + SwiftData: one write satisfies both the logging and the inspection requirement

- **Decision**: `SwiftDataAnalyticsTracker.track(_:contact:followUp:)` does two things per call: an
  OSLog `Logger.log()` call (structured, matching the constitution's "OSLog rather than ad hoc
  print" requirement) and a synchronous `modelContext.insert(AnalyticsEvent(...))` so the developer
  screen (FR-010) can read events back through the same `ContactRepository`-adjacent persistence
  this app already uses everywhere else.
- **Rationale**: OSLog entries are not conveniently queryable back into a SwiftUI list from within
  the same running process without extra machinery (`OSLogStore` has real but non-trivial setup
  cost for a low-stakes debug screen); a SwiftData row is already the pattern this codebase uses
  for everything else that needs to be listed in the UI. Doing both from one call site keeps
  "record an event" a single, unmistakable operation rather than two things call sites could
  forget to keep in sync.
- **Alternatives considered**: OSLog only, reading it back via `OSLogStore(scope:
  .currentProcessIdentifier)` for the developer screen — technically possible on-device but adds
  meaningful complexity (log stores, predicates, subsystem/category filtering) for a feature whose
  own spec (Assumptions) explicitly doesn't require long retention or advanced querying.

## No "no-op" implementation needed for Analytics or Experiments

- **Decision**: Unlike `NotificationScheduling` (which has both `UNNotificationScheduler` and
  `NoOpNotificationScheduler`), `AnalyticsTracking` and `ExperimentProviding` each have exactly one
  implementation, used everywhere including under `-UITestResetState`.
- **Rationale**: The reason `NotificationScheduling` needed a fake was specifically that the real
  `UNUserNotificationCenter` permission dialog is a system-owned alert XCUITest cannot drive
  (Specification 3's research). Neither `AnalyticsTracking` (a local SwiftData write + OSLog call)
  nor `ExperimentProviding` (a local SwiftData find-or-create) touches any system permission
  surface or non-deterministic system UI, so there is nothing about them that's undrivable or
  flaky under automated tests — the real implementations are exactly what UI tests should exercise
  to prove FR-001 through FR-011 actually work end-to-end.
- **Alternatives considered**: A fake for symmetry with `NotificationScheduling` — rejected, adding
  a second implementation with no behavioral reason to exist beyond "the other protocol has one" is
  exactly the unnecessary architectural ceremony the constitution's Principle II rationale warns
  against.

## Reminder-copy experiment applies to the notification title, not the body

- **Decision**: The two reminder-copy variants apply to the notification's *title* line (currently
  the fixed string `"Follow up with {name}"` in `UNNotificationScheduler`), not its body — the body
  is either the user's own `suggestedAction` text or a fallback string, and the user's own authored
  text is not something this spec should be experimenting on.
- **Rationale**: FR-008 requires the notification to "reflect" the assigned variant, but doesn't
  specify which part of the copy; the title is the one piece of every reminder notification that is
  always app-authored copy (the body is conditionally user-authored), making it the only safe,
  consistent surface for a controlled two-variant experiment.
- **Alternatives considered**: Experimenting on the fallback body string only (used when there's no
  `suggestedAction`) — rejected, this would mean a large fraction of reminders (any with a
  suggested action, which is the common case) never actually exercise the experiment, undermining
  SC-003's "10 consecutive schedulings show the same variant" being a meaningful signal.
