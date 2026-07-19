# Contract: ContactRepository follow-up methods

Extends the `ContactRepository` contract from Specifications 1-2 with `FollowUp` CRUD. Same
internal `Features/*` ↔ `SwiftData` boundary as before — no external/network API.

## Protocol shape (additions)

```swift
protocol ContactRepository {
    // ... Specification 1-2 methods unchanged ...

    func fetchFollowUps(for contact: NetworkingContact) throws -> [FollowUp]
    func saveFollowUp(_ followUp: FollowUp, for contact: NetworkingContact) throws
    func completeFollowUp(_ followUp: FollowUp) throws
    func deleteFollowUp(_ followUp: FollowUp) throws
}
```

## Behavioral contract

- `fetchFollowUps(for:)` returns every `FollowUp` belonging to the given contact, in an
  unspecified order — bucketing/ordering for the Today screen is `FollowUpBucketing`'s
  responsibility, not the repository's (same precedent as `fetchInteractions`).
- `saveFollowUp(_:for:)` inserts a new follow-up (setting its `contact` relationship) if it isn't
  already tracked, or persists in-place edits (priority, suggested action, due date) if it is.
  Whenever the due date changes on an existing, incomplete follow-up, it cancels any existing
  scheduled reminder and schedules a new one via the injected `NotificationScheduling`. For a
  brand-new incomplete follow-up, it schedules a reminder. Callers are responsible for field
  validation before calling this — the repository does not re-validate.
- `completeFollowUp(_:)` sets `isCompleted = true` and `completedAt = .now`, persists the change,
  and cancels any scheduled reminder for that follow-up.
- `deleteFollowUp(_:)` removes the follow-up permanently and cancels any scheduled reminder for
  it, matching FR-011.
- Deleting a contact via the existing `delete(_ contact:)` method cascades to delete all of that
  contact's follow-ups via the SwiftData relationship's `.cascade` delete rule (same pattern
  Specification 2 verified empirically for interactions) — the repository additionally cancels any
  scheduled reminders for those follow-ups before the cascade delete completes, since SwiftData's
  cascade rule has no way to know about the separate notification system.

## NotificationScheduling contract

```swift
protocol NotificationScheduling {
    func requestAuthorizationIfNeeded() async -> Bool
    func scheduleReminder(for followUp: FollowUp) async
    func cancelReminder(for followUp: FollowUp) async
}
```

- `requestAuthorizationIfNeeded()` asks the system for notification permission if the app hasn't
  already determined the user's choice; returns whether reminders can currently be scheduled.
  Never assumed true (FR-014).
- `scheduleReminder(for:)` is a no-op if authorization has not been granted — callers do not need
  to check authorization status themselves before calling it (FR-017: the rest of the app keeps
  working regardless).
- `cancelReminder(for:)` is always safe to call, including for a follow-up with no scheduled
  reminder (e.g. because permission was never granted).
- `UNNotificationScheduler` implements this against the real `UNUserNotificationCenter`.
  `NoOpNotificationScheduler` implements it by recording calls in memory and never actually
  scheduling anything — used whenever the app is running under `-UITestResetState` or
  `XCTestConfigurationFilePath` (see research.md), and directly by unit tests.

## Error handling

- `ContactRepository`'s throwing methods surface underlying SwiftData/`ModelContext` errors
  unchanged, consistent with Specifications 1-2's contracts.
- `NotificationScheduling` methods do not throw — scheduling failures (e.g. denied permission)
  are represented by silently not scheduling, not by errors, since a missed reminder must never
  block or fail the underlying follow-up operation (FR-017).

## Consumers

- `FollowUpViewModel` (Features/FollowUps) is the production consumer of both protocols.
- `FollowUpRepositoryTests` exercises `SwiftDataContactRepository`'s follow-up methods against an
  in-memory `ModelContainer` with a `NoOpNotificationScheduler` injected, including a dedicated
  test confirming cascade delete removes follow-ups and cancels their reminders.
- `NoOpNotificationSchedulerTests` verifies the fake correctly records schedule/cancel calls so
  other tests can assert against it.
- `FollowUpManagementFlowUITests` exercises the app end-to-end with the app's own
  `NoOpNotificationScheduler` active (via `-UITestResetState`), never touching the real system
  permission dialog.
