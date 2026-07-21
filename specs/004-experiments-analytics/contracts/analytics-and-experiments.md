# Contract: AnalyticsTracking and ExperimentProviding

Two new protocol boundaries, both named directly by the constitution (Principle II). Same internal
`Features/*` ↔ `SwiftData` boundary as `ContactRepository`/`NotificationScheduling` — no
external/network API, no third-party analytics SDK.

## AnalyticsTracking

```swift
@MainActor
protocol AnalyticsTracking {
    func track(_ type: AnalyticsEventType, contact: NetworkingContact?, followUp: FollowUp?)
    func fetchRecentEvents() throws -> [AnalyticsEvent]
}
```

### Behavioral contract

- `track(_:contact:followUp:)` is synchronous and non-throwing — recording an event MUST NOT be
  able to fail or block the caller (FR-015). Internally it emits one OSLog structured log entry
  and inserts one `AnalyticsEvent` row, capturing `contact?.name` (or `followUp?.contact?.name`) as
  the row's `contextLabel` snapshot at call time.
- Callers pass whichever of `contact`/`followUp` is relevant to the event type; both may be `nil`
  for an event with no natural subject (none of the five current event types need this, but the
  signature allows it rather than special-casing).
- `fetchRecentEvents()` returns events most-recent-first (FR-010's ordering requirement is the
  developer screen's job to display, but sorting at the source keeps the view a thin renderer,
  consistent with this codebase's `FollowUpBucketing`/`InteractionTimeline` precedent). May throw
  the same underlying `ModelContext` errors as `ContactRepository`'s fetch methods.
- `SwiftDataAnalyticsTracker` is the only production implementation (see research.md — no fake is
  needed, unlike `NotificationScheduling`).

### Call sites (which event, from where)

| Event | Call site |
|---|---|
| `reminderDisplayed` | `NotificationDelegate`, when a reminder notification is presented while the app is foregrounded, and when a delivered notification's tap is handled |
| `contactOpened` | `ContactDetailView.onAppear`, guarded to fire once per appearance (see research.md) |
| `followUpCompleted` | `SwiftDataContactRepository.completeFollowUp(_:)` |
| `reminderDismissed` | `NotificationDelegate`, on receiving `UNNotificationDismissActionIdentifier` (requires the `.customDismissAction` category — see research.md) |
| `followUpRescheduled` | `SwiftDataContactRepository.saveFollowUp(_:for:)`, only when updating an already-persisted follow-up whose `dueDate` changed (see research.md's create-vs-reschedule detection) |

## ExperimentProviding

```swift
@MainActor
protocol ExperimentProviding {
    var reminderCopyVariant: ReminderCopyVariant { get }
}
```

### Behavioral contract

- `reminderCopyVariant` is a synchronous, non-throwing computed property. On first access ever
  (no `ExperimentAssignment` row yet exists for `experimentKey == "reminderCopy"`), the real
  implementation assigns a variant, persists it, and returns it. On every subsequent access, it
  reads and returns the already-persisted row's `variant` unchanged (FR-007).
- Variant selection on first assignment may use any source of randomness — determinism is a
  property of *persisting the outcome*, not of the selection mechanism itself (see spec.md User
  Story 2's framing: "not random-per-launch," i.e. it must not be re-rolled each time, not that the
  initial pick must be non-random).
- `SwiftDataExperimentProvider` is the only production implementation (see research.md).
- `UNNotificationScheduler.scheduleReminder(for:)` reads `reminderCopyVariant` to choose the
  notification title template (FR-008) — see research.md for why the title, not the body, is the
  experimented-on surface.

## Error handling

- `AnalyticsTracking.track(_:contact:followUp:)` and `ExperimentProviding.reminderCopyVariant`
  never throw — any underlying persistence failure is swallowed internally (logged via OSLog at a
  fault level, not surfaced to the caller), consistent with FR-015's "never block or fail the
  action it accompanies."
- `AnalyticsTracking.fetchRecentEvents()` throws underlying `ModelContext` errors unchanged,
  consistent with `ContactRepository`'s existing fetch methods — this is a read used only by the
  developer screen, where surfacing a fetch failure is acceptable.

## Consumers

- `FollowUpSummaryView`/`FollowUpInsightsViewModel` (Features/Dashboard) — reads `FollowUp` data
  directly via `ContactRepository.fetchAllFollowUps()`, **not** `AnalyticsTracking` (see spec.md
  Assumptions: the summary and the event log are deliberately two different data sources).
- `DeveloperAnalyticsView`/`DeveloperAnalyticsViewModel` (Features/Dashboard) — the sole production
  consumer of `AnalyticsTracking.fetchRecentEvents()` and `ExperimentProviding.reminderCopyVariant`
  for display purposes.
- `ContactDetailView`, `SwiftDataContactRepository`, `NotificationDelegate` — production callers of
  `AnalyticsTracking.track(_:contact:followUp:)` per the call-site table above.
- `UNNotificationScheduler` — the sole production caller of `ExperimentProviding.reminderCopyVariant`.
- `SwiftDataAnalyticsTrackerTests`, `SwiftDataExperimentProviderTests` exercise both real
  implementations against an in-memory `ModelContainer`.
- `ExperimentsAnalyticsFlowUITests` exercises the app end-to-end with the real implementations
  active (no fakes needed under `-UITestResetState` — see research.md).
