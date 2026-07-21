# Contract: Widget content and CI workflow

Two independent contracts. Neither is an in-process Swift protocol like `ContactRepository` or
`AnalyticsTracking` — the widget's is a pure function contract (its own process, its own target),
and CI's is a workflow-file contract (what the pipeline must do, not a Swift API).

## FollowUpWidgetContent (pure function)

```swift
enum FollowUpWidgetContent {
    static func select(
        _ followUps: [FollowUp],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> [FollowUp]
}
```

### Behavioral contract

- Returns at most 3 follow-ups, filtered to only those overdue or due today (never upcoming, never
  completed) — same boundary rule as `FollowUpBucketing` (Specification 3).
- Ordering: overdue first (oldest `dueDate` first, i.e. most-overdue leads), then due-today
  (earliest time-of-day first), matching FR-005's "most-urgent-first."
- Returns an empty array when there is nothing overdue or due today — the widget view is
  responsible for rendering FR-006's "nothing due" state when given an empty array, this function
  itself has no concept of a UI state.
- Pure and synchronous — no I/O, no `ModelContext` access; the `TimelineProvider` is responsible
  for fetching `[FollowUp]` from the shared store and passing it in, mirroring how `TodayView`
  fetches before calling `FollowUpBucketing.bucket(_:)`.

## Widget timeline refresh

- `FollowUpWidgetTimelineProvider` (WidgetKit's `TimelineProvider`) opens a `ModelContext` against
  the same App Group-located `ModelContainer` the main app uses (see data-model.md), fetches
  `FollowUp`s, calls `FollowUpWidgetContent.select(_:)`, and returns a `Timeline` with a
  `.after(date)` refresh policy (system-scheduled, not a tight custom interval — see research.md).
- `SwiftDataContactRepository.saveFollowUp(_:for:)`, `.completeFollowUp(_:)`, and
  `.deleteFollowUp(_:)` each call `WidgetCenter.shared.reloadAllTimelines()` after their existing
  persistence/notification-scheduling work, so the widget reflects an in-app change promptly
  without waiting for the system's own passive budget.
- Tapping the widget opens the app via a `widgetURL`/`Link` targeting a URL the app's own
  `onOpenURL` handling routes straight to the Today tab (mirroring `RootTabView`'s existing
  notification-tap routing pattern from Specification 3, reusing the same "land on a specific tab"
  mechanism rather than inventing a second one).

## CI workflow (`.github/workflows/ci.yml`)

- **Trigger**: `push` (any branch) and `pull_request`.
- **Job**: checks out the repository, selects an available Xcode via `xcode-select`, runs
  `xcodegen generate` (the project is not committed as a static `.xcodeproj` — see
  `AI_USAGE.md`/existing developer workflow), then
  `xcodebuild test -scheme NextStep -only-testing:NextStepTests -destination 'platform=iOS Simulator,name=<runner-available device>'`.
- **Reporting**: relies on GitHub Actions' own built-in check-run/PR-status reporting — no custom
  reporting step is added, satisfying FR-012 ("visible... without requiring the maintainer to
  manually re-run anything") for free.
- **Out of scope for this job**: `NextStepUITests` — see research.md's "CI targets the unit suite"
  decision. Not wired into this workflow at all in this spec, not even as an allowed-to-fail step,
  to keep the first version of CI simple.

## Consumers

- `FollowUpWidget` (the `Widget`/`WidgetBundle` view) is the sole consumer of
  `FollowUpWidgetContent.select(_:)`'s output for rendering.
- `FollowUpWidgetContentTests` exercises the pure function directly, the same way
  `FollowUpBucketingTests` and `FollowUpInsightsTests` test their respective pure functions.
- GitHub's own PR UI and commit-status API are the "consumers" of the CI workflow's result — no
  in-repo code consumes it.
