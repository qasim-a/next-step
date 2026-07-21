# Implementation Plan: Polish

**Branch**: `005-polish` | **Date**: 2026-07-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-polish/spec.md`

## Summary

Three independent tracks: (1) an accessibility/appearance audit across every screen from
Specifications 1-4 (dark mode, Dynamic Type) plus a real app icon and launch screen, replacing the
current system-default placeholders; (2) a WidgetKit home-screen widget showing up to 3
overdue/due-today follow-ups, reading `FollowUp`/`NetworkingContact` data from a SwiftData store
relocated into an App Group shared container so both the main app and the new widget extension
target can read it; (3) a GitHub Actions workflow running `NextStepTests` on every push/PR.

## Technical Context

**Language/Version**: Swift 5.10 (Xcode 26.6)

**Primary Dependencies**: WidgetKit + SwiftUI (new — widget extension), unchanged SwiftData/
SwiftUI/UserNotifications/OSLog for the rest of the app

**Storage**: SwiftData, same models as Specifications 1-4 — but the `ModelContainer`'s on-disk
location moves from the app's default per-target sandbox directory to a shared App Group
container, since a widget extension cannot read the main app target's private sandbox. No schema
change; same models, same data, different file location.

**Testing**: No new unit-testable logic beyond one pure function (widget content selection —
top-3 overdue/due-today, most-urgent-first — mirrors `FollowUpBucketing`'s existing shape and is
tested the same way). Dark mode/Dynamic Type/app icon/launch screen are manual verification per
quickstart.md (not mechanically assertable via XCUITest — see research.md). CI itself is validated
by observing a real workflow run, not by a test inside the repository.

**Target Platform**: iOS 17.0+ (unchanged); WidgetKit on iOS 17+ supports the Home Screen and Lock
Screen — this spec targets the Home Screen only, per spec.md's scope

**Project Type**: Native iOS mobile app — adds one new target (a Widget Extension) to the existing
Xcode project; still a single repository, still local-first

**Performance Goals**: Widget timeline generation must not block or delay app launch when the main
app requests a reload; N/A for the polish audit or CI

**Constraints**: Fully on-device — the App Group container is still local storage shared between
two targets of the same app, not a network service; no new permission prompts (App Groups aren't a
user-facing permission)

**Scale/Scope**: Adds one Xcode target (`NextStepWidget`), one new small feature file (widget
timeline provider + view), an `Assets.xcassets` catalog (currently absent from the project), one
GitHub Actions workflow file, and a relocation of the existing `ModelContainer` setup — no new
`Features/` folder needed for the polish audit itself, since it touches existing files in place

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Native, Local-First iOS | PASS | Widget extension is native SwiftUI/WidgetKit; App Group container is on-device, shared between two targets of the same app — not a backend, not network |
| II. Feature-Based MVVM with Protocol Boundaries | PASS | Widget's content-selection logic is a pure function, mirroring `FollowUpBucketing`; no new protocol boundary needed since the widget reads through the same `ModelContainer`/models, not a new abstraction |
| III. Test-First Discipline | PASS | The one new pure function (widget content selection) is unit tested; appearance/CI items are manually verified per quickstart.md and documented as such, not silently skipped |
| IV. Spec-Driven, Incremental Delivery | PASS | Exactly one advanced feature (the widget) is selected, matching the constitution's "at most one or two" allowance; message assistant, business-card scanning, calendar integration, and App Intents remain out of scope |
| V. Networking-Scoped Privacy | PASS | No new system-permission surface — App Groups require no user-facing prompt; widget shows only data already present in the app |
| VI. Observable Experimentation | N/A | No experiment/analytics surface in this spec's scope |

No violations — Complexity Tracking table is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/005-polish/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
project.yml                                # MODIFIED: adds NextStepWidget target + App Group entitlements on both targets

NextStep/
├── NextStep.entitlements                  # NEW: App Group membership for the main app target
├── App/
│   └── NextStepApp.swift                  # MODIFIED: ModelContainer relocated to the App Group container URL
├── Assets.xcassets/                       # NEW: asset catalog (didn't exist before)
│   └── AppIcon.appiconset/                # NEW: generated icon at all required sizes
└── Resources/
    └── LaunchScreen (Info.plist-driven UILaunchScreen keys, or a minimal storyboard) # NEW

NextStepWidget/                            # NEW target
├── NextStepWidget.entitlements            # NEW: same App Group membership
├── NextStepWidgetBundle.swift             # WidgetKit entry point
├── FollowUpWidget.swift                   # Widget configuration + view
├── FollowUpWidgetTimelineProvider.swift   # TimelineProvider, reads the shared ModelContainer
└── FollowUpWidgetContent.swift            # Pure function: [FollowUp] -> up to 3, most-urgent-first (mirrors FollowUpBucketing)

NextStep/Core/Persistence/
└── SwiftDataContactRepository.swift       # MODIFIED: calls WidgetCenter.reloadAllTimelines() after any FollowUp mutation

.github/
└── workflows/
    └── ci.yml                             # NEW: build + NextStepTests on push/PR

NextStepTests/
└── FollowUpWidgetContentTests.swift       # NEW: top-3, most-urgent-first, empty state
```

**Structure Decision**: Adds one new Xcode target rather than folding widget code into the existing
`NextStep` target, since a Widget Extension is a genuinely separate binary/process on iOS — this
isn't a stylistic choice, WidgetKit requires it. The polish audit (dark mode, Dynamic Type) touches
existing files in place across `Features/*` rather than introducing new files, since it's fixing
what exists, not adding new UI. `SwiftDataContactRepository` gains one new side effect
(`WidgetCenter.reloadAllTimelines()`) alongside its existing notification-scheduling side effect,
following the same precedent Specification 3 established for keeping state-change side effects in
the repository rather than scattered across view models.

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
