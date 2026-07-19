# Quickstart: Follow-ups and Notifications

Validation guide for this spec once implementation is complete. See [data-model.md](./data-model.md)
for field details and
[contracts/contact-repository-followups.md](./contracts/contact-repository-followups.md) for the
persistence and notification-scheduling boundaries being exercised.

## Prerequisites

- Xcode with an iOS 17+ simulator installed (same toolchain as Specifications 1-2).
- Repository checked out on branch `003-followups-notifications`, with Specifications 1-2 merged.

## Build & run

```bash
open NextStep.xcodeproj
# Select the "NextStep" scheme and an iOS 17+ simulator, then Run (Cmd+R)
```

## Run automated tests

```bash
# Unit tests: FollowUpBucketingTests + FollowUpRepositoryTests + NoOpNotificationSchedulerTests
# (plus all Specification 1-2 unit tests, unchanged)
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepTests

# UI tests: FollowUpManagementFlowUITests
# (plus all Specification 1-2 UI tests, unchanged)
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepUITests
```

Expected: all tests pass, including the full Specification 1-2 regression suite. UI tests never
trigger the real notification permission dialog (the app runs against `NoOpNotificationScheduler`
under `-UITestResetState`).

## Manual validation scenarios

These mirror spec.md's acceptance scenarios. Scenario 4 (notifications) needs a real device or
simulator run outside the automated test harness, since it's the one part the no-op scheduler
deliberately doesn't exercise.

1. **Capture a follow-up (User Story 1)**
   - Open a contact, create a follow-up with just a due date → it saves.
   - Create another filling in priority and a suggested action → both save.
   - Create one from an interaction's next-action text → suggested action starts pre-filled, still
     editable.
   - Cancel creating a follow-up → nothing is created.

2. **See what needs attention today (User Story 2)**
   - Launch the app → it opens directly to the Today tab.
   - With follow-ups due in the past, today, and the future, confirm they land in Overdue, Due
     Today, and Upcoming respectively.
   - Complete one → confirm it appears in Recently Completed.
   - With zero follow-ups, confirm the Today screen shows guidance, not a blank screen.

3. **Act on a follow-up (User Story 3)**
   - Mark an incomplete follow-up complete → it moves to Recently Completed with a completion
     date.
   - Reschedule an incomplete follow-up → it moves to the section matching its new due date.
   - Edit a follow-up's priority/suggested action → changes reflect immediately.
   - Delete a follow-up (confirm the prompt) → it disappears everywhere.
   - Delete a contact with follow-ups → its follow-ups disappear from Today too.

4. **Get reminded (User Story 4 — manual, real device/simulator only)**
   - On first relevant action, confirm the system notification permission prompt appears.
   - Grant permission, create a follow-up due a few minutes out, background the app, and confirm
     a reminder arrives at that time.
   - Reschedule that follow-up → confirm the reminder time updates (no duplicate reminder).
   - Complete or delete it → confirm no reminder arrives.
   - Tap a delivered reminder → confirm the app opens directly to that follow-up's contact.
   - Separately, deny permission and confirm every other part of this spec (create, Today screen,
     complete, reschedule, edit, delete) still works normally.

## Out of scope for this validation pass

Insights and Settings tabs, experiments/analytics, and automatically generated follow-ups are not
part of this spec (see spec.md Assumptions) — do not expect to see them yet.
