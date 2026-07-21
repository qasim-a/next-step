# Quickstart: Polish

Validation guide for this spec once implementation is complete. See [data-model.md](./data-model.md)
for the storage relocation and [contracts/widget-and-ci.md](./contracts/widget-and-ci.md) for the
widget content and CI contracts.

## Prerequisites

- Xcode with an iOS 17+ simulator installed (same toolchain as Specifications 1-4).
- Repository checked out on branch `005-polish`, with Specifications 1-4 already merged.
- A GitHub remote configured (for User Story 3's CI verification) — `AI_USAGE.md`/project history
  confirms this repository already pushes to `https://github.com/qasim-a/next-step.git`.

## Build & run

```bash
xcodegen generate
open NextStep.xcodeproj
# Select the "NextStep" scheme and an iOS 17+ simulator, then Run (Cmd+R).
# To preview the widget: select the "NextStepWidget" scheme, choose "FollowUpWidget" as the
# widget to preview when prompted, and Run — Xcode shows it in the widget gallery/preview canvas.
```

## Run automated tests

```bash
# Unit tests: FollowUpWidgetContentTests
# (plus Specifications 1-4's suites, unchanged)
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepTests

# No new UI tests in this spec (see spec.md Assumptions and research.md's CI decision) —
# Specifications 1-4's existing NextStepUITests suites should still pass unchanged, since this
# spec only relocates ModelContainer storage and touches existing views' color/type usage:
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:NextStepUITests
```

Expected: all tests pass, including Specifications 1-4's full suites (regression check) — the
`ModelContainer` relocation (data-model.md) is exactly the kind of change that could silently break
existing persistence-dependent tests if done wrong, so this regression pass matters more than usual
for this spec.

## Manual validation scenarios

These mirror spec.md's acceptance scenarios. Automated coverage is noted per scenario; most of
User Story 1 and all of the widget's real-device behavior in User Story 2 requires a human, since
neither dark mode/Dynamic Type rendering nor a real home-screen widget placement can be driven by
XCUITest.

1. **App-wide polish (User Story 1)** — manual-only
   - Switch the simulator/device to dark mode (Settings → Developer, or Control Center) → walk
     through every screen from Specifications 1-4 (Contacts list/detail/form, interaction
     timeline/form, Today screen, follow-up form, Insights, Developer Info) → confirm all text
     stays legible and no custom-colored element (priority badges) becomes unreadable.
   - Switch to each of the three largest Dynamic Type accessibility sizes (Settings →
     Accessibility → Display & Text Size → Larger Text) → repeat the same screen walkthrough →
     confirm no clipped/truncated/overlapping text and every button stays tappable.
   - Check the Home Screen and app switcher → confirm a custom icon appears, not the gray
     placeholder.
   - Force-quit and relaunch → confirm a deliberate launch screen appears briefly, not blank white.

2. **Home-screen widget (User Story 2)** — partially automated
   - Content-selection logic (top-3, most-urgent-first, empty state):
     `FollowUpWidgetContentTests` (automated).
   - Add the widget to a home screen with a mix of overdue/due-today/upcoming/completed follow-ups
     → confirm it shows the correct up-to-3, most-urgent-first. **Not yet run by a human.**
   - With no overdue or due-today follow-ups → confirm the "nothing due" state appears, not a
     blank layout. **Not yet run by a human.**
   - Tap the widget → confirm the app opens directly to the Today screen. **Not yet run by a
     human.**
   - Complete a follow-up shown on the widget from within the app, return to the home screen →
     confirm the widget updates (may take a moment; per SC-003, must not stay stale indefinitely).
     **Not yet run by a human.**

3. **CI (User Story 3)** — verify directly on GitHub, not via a local command
   - Push a commit with a deliberately failing test → confirm the GitHub Actions run reports
     failure and the failing test is identifiable from the run's log.
   - Fix the test, push again → confirm the run reports success.
   - Open a pull request → confirm the check status is visible on the PR before merging.

## Out of scope for this validation pass

Lock Screen widgets, in-widget interactivity (App Intents), any second experiment/advanced
feature beyond the one widget, and `NextStepUITests` running in CI are not part of this spec (see
spec.md Assumptions).
