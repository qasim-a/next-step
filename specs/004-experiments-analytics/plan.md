# Implementation Plan: Experiments & Analytics

**Branch**: `004-experiments-analytics` | **Date**: 2026-07-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-experiments-analytics/spec.md`

## Summary

Add two new `Core` protocol boundaries named directly by the constitution — `AnalyticsTracking`
and `ExperimentProviding` — backed by two new SwiftData models (`AnalyticsEvent`,
`ExperimentAssignment`). The real `AnalyticsTracking` implementation both emits an OSLog structured
log entry and persists an `AnalyticsEvent` row so a hidden developer screen can list them; the real
`ExperimentProviding` implementation assigns one of two reminder-notification-copy variants the
first time it's asked, persists that choice, and returns it unchanged thereafter. A new
`Features/Dashboard` folder hosts two small, low-ceremony views: a follow-up completion summary
reachable from the Today tab (real end-user value), and the hidden developer screen reachable from
the Contacts tab's existing overflow menu (debug/inspection value only).

## Technical Context

**Language/Version**: Swift 5.10 (Xcode 26.6)

**Primary Dependencies**: SwiftUI, SwiftData, OSLog (new — structured logging only, no
third-party analytics SDK)

**Storage**: SwiftData, same store as Specifications 1-3; adds `AnalyticsEvent` (append-only,
no relationships requiring cascade delete — see data-model.md for why it stores plain UUIDs/labels
instead of model references) and `ExperimentAssignment` (a single row per experiment key)

**Testing**: Swift Testing for the follow-up summary calculation (pure function, mirrors
`FollowUpBucketing`), the deterministic variant-assignment logic, and repository-level event
recording; XCTest/XCUITest for the summary view and the developer screen's list/empty states

**Target Platform**: iOS 17.0+ (unchanged)

**Project Type**: Native iOS mobile app — continuation of the existing single Xcode app target

**Performance Goals**: Recording an event or reading the assigned variant never blocks the UI
action it accompanies (FR-015) — both are synchronous, in-memory-cheap SwiftData writes/reads, no
async round trip required

**Constraints**: Fully on-device; OSLog is local structured logging, not a remote sink — no
network calls are introduced by this spec (SC-004)

**Scale/Scope**: Adds 2 models, a `Core/Analytics` module (`AnalyticsTracking` protocol + real
implementation), a `Core/Experiments` module (`ExperimentProviding` protocol + real
implementation), a new `Features/Dashboard` folder (summary view + developer screen), and touches
existing call sites in `ContactDetailView`, `TodayView`, `RootTabView`/notification handling, and
`UNNotificationScheduler` to invoke tracking/experiment reads at the five specified moments

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Native, Local-First iOS | PASS | OSLog is on-device; `AnalyticsEvent`/`ExperimentAssignment` are SwiftData, same store; no network calls |
| II. Feature-Based MVVM with Protocol Boundaries | PASS | Adds the two protocols the constitution names explicitly (`AnalyticsTracking`, `ExperimentProviding`) plus `Features/Dashboard` |
| III. Test-First Discipline | PASS | Pure-function summary/variant-assignment logic unit tested; XCUITest for both new screens |
| IV. Spec-Driven, Incremental Delivery | PASS | Scope matches spec.md exactly — one experiment, five event types, no Settings tab, no message-generation or scanning features |
| V. Networking-Scoped Privacy | PASS | No new system-permission surface; events reference contacts/follow-ups already in scope, not new PII categories |
| VI. Observable Experimentation | PASS | This spec is the direct implementation of this principle |

No violations — Complexity Tracking table is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/004-experiments-analytics/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
NextStep/
├── App/
│   ├── NextStepApp.swift              # MODIFIED: constructs and injects AnalyticsTracking + ExperimentProviding
│   └── RootTabView.swift              # MODIFIED: tracks contactOpened / reminderDismissed at the notification-routing boundary
├── Core/
│   ├── Models/
│   │   ├── AnalyticsEvent.swift       # NEW: @Model, AnalyticsEventType enum
│   │   └── ExperimentAssignment.swift # NEW: @Model, ReminderCopyVariant enum
│   ├── Analytics/                     # NEW module
│   │   ├── AnalyticsTracking.swift            # protocol + environment key
│   │   └── SwiftDataAnalyticsTracker.swift    # real implementation: OSLog + persists AnalyticsEvent
│   ├── Experiments/                   # NEW module
│   │   ├── ExperimentProviding.swift          # protocol + environment key
│   │   └── SwiftDataExperimentProvider.swift  # real implementation: find-or-create ExperimentAssignment
│   └── Notifications/
│       └── UNNotificationScheduler.swift      # MODIFIED: reads ExperimentProviding for notification title copy
└── Features/
    ├── Contacts/
    │   └── ContactDetailView.swift    # MODIFIED: tracks contactOpened on appear; adds "Developer Info" to overflow menu
    ├── FollowUps/
    │   ├── TodayView.swift            # MODIFIED: adds "Insights" toolbar entry point; tracks followUpCompleted/Rescheduled
    │   └── FollowUpFormView.swift     # (unchanged — tracking happens at the call sites above, not inside the shared form)
    └── Dashboard/                     # NEW feature folder
        ├── FollowUpInsights.swift             # pure function: [FollowUp] -> FollowUpSummary
        ├── FollowUpSummaryView.swift           # User Story 1: completion rate + counts
        └── DeveloperAnalyticsView.swift        # User Story 3: event list + variant display

NextStepTests/
├── (existing Spec 1-3 test files unchanged)
├── FollowUpInsightsTests.swift                # NEW: completion-rate/count math, empty state, deleted-follow-up exclusion
├── SwiftDataAnalyticsTrackerTests.swift        # NEW: recording persists events with correct type/timestamp/context
└── SwiftDataExperimentProviderTests.swift      # NEW: first-access assignment persists and is stable across re-reads

NextStepUITests/
├── (existing Spec 1-3 test files unchanged)
└── ExperimentsAnalyticsFlowUITests.swift       # NEW: summary view shows correct numbers; developer screen lists events + variant
```

**Structure Decision**: Continues the single-app-target structure. Two small new `Core` modules
(`Analytics`, `Experiments`) mirror the existing `Notifications` module's real-implementation-only
shape — unlike `NotificationScheduling`, there is no separate "no-op" implementation needed here,
because neither module depends on an undrivable system permission dialog; the same real
implementation is safe to run under XCUITest (see research.md). One new feature folder,
`Features/Dashboard`, hosts both this spec's UI surfaces, matching the constitution's own naming
for this kind of overview screen rather than inventing a new folder name. `Features/Settings` is
intentionally not created — the developer screen is reached through the existing overflow menu
on `ContactListView` (see spec.md Assumptions).

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
