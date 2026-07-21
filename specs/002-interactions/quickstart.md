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

These mirror spec.md's acceptance scenarios. Each is marked with how it's currently verified:
automated (unit and/or UI test), or manual-only (needs a human tapping through the simulator —
see the note at the end of this section).

1. **Log an interaction (User Story 1)** — automated
   - Open a contact, log an interaction with just a type and date → it appears on the timeline
     and the contact's last-interaction date updates to match.
     (`InteractionRepositoryTests.savingAnInteractionUpdatesContactLastInteractionDate`,
     `InteractionManagementFlowUITests.test_loggingInteractionWithAllFields_dismissesFormAndReturnsToDetail`)
   - Log another interaction filling in notes, outcome, and a next-action note → all details save
     and are visible. (same UI test, all fields populated)
   - Start logging an interaction, then cancel → no interaction is created, timeline unchanged.
     (`test_cancelingLogInteraction_dismissesFormWithoutSaving`)

2. **See the timeline (User Story 2)** — automated
   - With several interactions logged at different dates, open the contact → timeline shows them
     most-recent-first. (`InteractionTimelineOrderingTests`,
     `test_loggingTwoInteractions_showsMostRecentlyLoggedFirst`)
   - Without opening an entry, confirm its type, date, and outcome (if any) are visible.
     (`InteractionRow` is rendered directly in the timeline list, exercised by the same test)
   - Open a contact with zero interactions → see guidance to log the first one, not an empty gap.
     (`test_contactWithNoInteractions_showsTimelineEmptyState`)

3. **Edit and delete (User Story 3)** — automated
   - Edit an interaction's type/date/notes/outcome/next-action and save → timeline reflects the
     change immediately. (`test_editingInteraction_updatesTimeline`)
   - Edit an interaction but cancel → original values unchanged.
     (`test_cancelingInteractionEdit_leavesInteractionUnchanged`)
   - Delete an interaction (confirm the prompt) → it disappears from the timeline.
     (`test_deletingInteraction_withConfirmation_removesFromTimeline`)
   - Delete a contact's most recent interaction → the contact's last-interaction date falls back
     to the next most recent interaction's date.
     (`InteractionRepositoryTests.deletingTheMostRecentInteractionFallsBackToNextMostRecentDate`)
   - Delete a contact's only interaction → last-interaction date reverts to "none recorded" and
     the timeline shows its empty-guidance state again.
     (`deletingTheOnlyInteractionRevertsLastInteractionDateToNil`)

4. **Cascade delete (FR-012)** — automated
   - Log a few interactions for a contact, then delete that contact from its detail screen →
     confirm no orphaned interactions remain.
     (`InteractionRepositoryTests.deletingAContactCascadesToDeleteItsInteractions`)

5. **Persistence** — manual-only, not yet run by a human
   - Force-quit the app after logging/editing/deleting interactions, relaunch → all interactions
     and the recomputed last-interaction dates are exactly as left. The existing relaunch UI test
     (`ContactManagementFlowUITests.test_relaunchingApp_persistsContactAcrossLaunch`) only exercises
     a bare contact, not one with interactions attached, so this specific case has no automated
     coverage yet.

**Note on "manual" verification**: scenarios above are marked automated where an existing unit or
UI test exercises the same behavior end-to-end against the real SwiftData store or a live
simulator session. Scenario 5 is the one gap — it genuinely requires a human relaunching the app
on a simulator or device and eyeballing the result.

## Out of scope for this validation pass

Follow-ups, reminders, notifications, and scheduling a next action as an actual reminder are not
part of this spec — the next-action field is descriptive text only (see spec.md Assumptions).
