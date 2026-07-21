# Quickstart: Experiments & Analytics

Validation guide for this spec once implementation is complete. See [data-model.md](./data-model.md)
for field details and
[contracts/analytics-and-experiments.md](./contracts/analytics-and-experiments.md) for the
protocol boundaries being exercised.

## Prerequisites

- Xcode with an iOS 17+ simulator installed (same toolchain as Specifications 1-3).
- Repository checked out on branch `004-experiments-analytics`, with Specifications 1-3 already
  merged.

## Build & run

```bash
open NextStep.xcodeproj
# Select the "NextStep" scheme and an iOS 17+ simulator, then Run (Cmd+R)
```

## Run automated tests

```bash
# Unit tests: FollowUpInsightsTests + SwiftDataAnalyticsTrackerTests + SwiftDataExperimentProviderTests
# (plus Specifications 1-3's suites, unchanged)
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepTests

# UI tests: ExperimentsAnalyticsFlowUITests
# (plus Specifications 1-3's suites, unchanged)
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepUITests
```

Expected: all tests pass, including Specifications 1-3's full suites (regression check).

## Manual validation scenarios

These mirror spec.md's acceptance scenarios. Each is marked with how it's currently verified.

1. **Follow-up performance summary (User Story 1)** — automated
   - With no follow-ups ever created, open the summary → see guidance that there's nothing to
     summarize yet, not a zero-filled or broken view.
     (`test_summaryWithNoFollowUps_showsEmptyState`)
   - Create a handful of follow-ups, complete some, leave others overdue/upcoming, open the
     summary → completion rate and status counts match what was actually done.
     (`FollowUpInsightsTests.completionRateExcludesUpcomingFromTheDenominator`,
     `test_summaryReflectsCompletedAndOverdueFollowUps`)
   - Complete a follow-up from the Today screen, then open the summary → numbers already reflect
     the change without relaunching the app. (`test_summaryUpdatesImmediatelyAfterCompletingAFollowUp`)
   - Delete a follow-up (completed or not) → it drops out of both the numerator and denominator of
     the completion rate, not counted as a completion or a miss.
     (`FollowUpInsightsTests.deletedFollowUpIsSimplyAbsentFromTheInput`)

2. **Deterministic reminder-copy variant (User Story 2)** — partially automated; the persistence
   mechanism is unit-tested, but its effect on a real, delivered notification is manual-only (needs
   a real device or a simulator with notification permission granted; cannot be driven by XCUITest,
   same constraint as Specification 3's real notification-delivery path).
   - Persistence and stability of the assignment across launches:
     `SwiftDataExperimentProviderTests` (automated).
   - Fresh install, create a follow-up due today, grant notification permission → note which
     variant's wording appears in the delivered notification's title. **Not yet run by a human.**
   - Create additional follow-ups due today over the next few app launches → the title wording
     stays the same variant every time. **Not yet run by a human.**
   - Fresh install on a second simulator/device → it may (not must) land on the other variant,
     confirming assignment isn't hard-coded. **Not yet run by a human.**

3. **Developer screen (User Story 3)** — automated, except the two notification-dependent event
   types
   - Contact-opened and follow-up-completed/rescheduled events appear, most-recent-first:
     `test_developerScreenListsTrackedEvents_mostRecentFirst`. Reminder-displayed/dismissed events
     require a real delivered notification — same manual-only constraint as Scenario 2.
   - Fresh install, before any tracked action → developer screen shows an empty-state message, not
     a blank or broken list. (`test_developerScreenWithNoEventsYet_showsEmptyState`)
   - The developer screen displays the currently assigned variant regardless of whether any events
     have been recorded yet — opening the screen itself triggers first-time assignment if none
     exists. (`test_developerScreenShowsAssignedExperimentVariant`)

4. **Privacy (SC-004)** — manual-only
   - With network conditioning/monitoring active (e.g. Instruments' Network template, or Xcode's
     Network Link Conditioner), perform every action in Scenarios 1-3 → confirm zero outbound
     network requests are made by the app at any point. **Not yet run by a human** — there is no
     automated way to assert "no network request was ever made" from within XCUITest.

## Out of scope for this validation pass

Message generation, business-card scanning, calendar integration, App Intents, widgets, and any
second experiment beyond reminder copy are not part of this spec (see spec.md Assumptions and the
constitution's Principle IV).
