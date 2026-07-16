# Quickstart: Interactions

Validation guide for this spec once implementation is complete. See [data-model.md](./data-model.md)
for field details and
[contracts/contact-repository-interactions.md](./contracts/contact-repository-interactions.md)
for the persistence boundary being exercised.

## Prerequisites

- Xcode with an iOS 17+ simulator installed (same toolchain as Specification 1).
- Repository checked out on branch `002-interactions`, with Specification 1 already merged.

## Build & run

```bash
open NextStep.xcodeproj
# Select the "NextStep" scheme and an iOS 17+ simulator, then Run (Cmd+R)
```

## Run automated tests

```bash
# Unit tests: InteractionTimelineOrderingTests + InteractionRepositoryTests
# (plus Specification 1's SwiftDataContactRepositoryTests + ContactFilteringTests, unchanged)
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepTests

# UI tests: InteractionManagementFlowUITests
# (plus Specification 1's ContactManagementFlowUITests, unchanged)
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepUITests
```

Expected: all tests pass, including Specification 1's full suite (regression check).

## Manual validation scenarios

These mirror spec.md's acceptance scenarios.

1. **Log an interaction (User Story 1)**
   - Open a contact, log an interaction with just a type and date → it appears on the timeline
     and the contact's last-interaction date updates to match.
   - Log another interaction filling in notes, outcome, and a next-action note → all details save
     and are visible.
   - Start logging an interaction, then cancel → no interaction is created, timeline unchanged.

2. **See the timeline (User Story 2)**
   - With several interactions logged at different dates, open the contact → timeline shows them
     most-recent-first.
   - Without opening an entry, confirm its type, date, and outcome (if any) are visible.
   - Open a contact with zero interactions → see guidance to log the first one, not an empty gap.

3. **Edit and delete (User Story 3)**
   - Edit an interaction's type/date/notes/outcome/next-action and save → timeline reflects the
     change immediately.
   - Edit an interaction but cancel → original values unchanged.
   - Delete an interaction (confirm the prompt) → it disappears from the timeline.
   - Delete a contact's most recent interaction → the contact's last-interaction date falls back
     to the next most recent interaction's date.
   - Delete a contact's only interaction → last-interaction date reverts to "none recorded" and
     the timeline shows its empty-guidance state again.

4. **Cascade delete (FR-012)**
   - Log a few interactions for a contact, then delete that contact from its detail screen →
     confirm (via re-adding a contact with the same name, or via the unit test) that no orphaned
     interactions remain.

5. **Persistence**
   - Force-quit the app after logging/editing/deleting interactions, relaunch → all interactions
     and the recomputed last-interaction dates are exactly as left.

## Out of scope for this validation pass

Follow-ups, reminders, notifications, and scheduling a next action as an actual reminder are not
part of this spec — the next-action field is descriptive text only (see spec.md Assumptions).
