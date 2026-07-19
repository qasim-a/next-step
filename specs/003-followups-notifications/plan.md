# Implementation Plan: Follow-ups and Notifications

**Branch**: `003-followups-notifications` | **Date**: 2026-07-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-followups-notifications/spec.md`

## Summary

Add a `FollowUp` SwiftData model (contact-scoped, optionally linked to the `Interaction` it came
from: due date, priority, suggested action, completion) with cascade delete from
`NetworkingContact`. Introduce tab-based root navigation (Today, Contacts) for the first time, a
due-date bucketing function driving the Today screen's four sections, and local reminder
notifications behind a `NotificationScheduling` protocol so both the app and its tests can swap
the real `UNUserNotificationCenter` for a deterministic fake — sidestepping the fact that the
system permission dialog cannot be reliably driven from XCUITest.

## Technical Context

**Language/Version**: Swift 5.10 (Xcode 26.6)

**Primary Dependencies**: SwiftUI, SwiftData, UserNotifications (new — local notifications only,
no push/APNs entitlement needed)

**Storage**: SwiftData, same store as Specifications 1-2; adds `FollowUp` with a cascade-delete
relationship from `NetworkingContact` and an optional reference to the originating `Interaction`

**Testing**: Swift Testing for due-date bucketing (pure function) and repository behavior;
XCTest/XCUITest for the full create/see/act flow. Notification scheduling is tested against a
fake `NotificationScheduling` implementation, both in unit tests and in the app itself when
running under UI tests — the real system permission prompt is never exercised by automated tests

**Target Platform**: iOS 17.0+ (unchanged)

**Project Type**: Native iOS mobile app — continuation of the existing single Xcode app target

**Performance Goals**: Today screen renders without perceptible delay for up to ~500 follow-ups

**Constraints**: Fully on-device; no network calls anywhere in this spec (local notifications
require no server)

**Scale/Scope**: Adds 1 model, extends the repository, adds a `Core/Notifications` module (the
constitution's `NotificationScheduling` protocol boundary), a new `Features/FollowUps` folder, and
restructures the app's root into a `TabView`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Native, Local-First iOS | PASS | UserNotifications is on-device only; no backend, no network |
| II. Feature-Based MVVM with Protocol Boundaries | PASS | New `Core/Notifications/NotificationScheduling` protocol (explicitly named in the constitution) + `Features/FollowUps` |
| III. Test-First Discipline | PASS | Bucketing + repository unit tests; XCUITest for full flows; notification logic tested via a fake scheduler, not the real permission dialog |
| IV. Spec-Driven, Incremental Delivery | PASS | Scope matches spec.md; no Insights/Settings tabs, no experiments, no auto-generated follow-ups |
| V. Networking-Scoped Privacy | PASS | Notification permission requested explicitly, only when relevant; app fully functional if denied (FR-017) |
| VI. Observable Experimentation | N/A | No experiment/analytics surface in this spec's scope |

No violations — Complexity Tracking table is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/003-followups-notifications/
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
│   └── NextStepApp.swift              # MODIFIED: TabView root, notification tap routing, scheduler injection
├── Core/
│   ├── Models/
│   │   ├── NetworkingContact.swift    # MODIFIED: adds `followUps` relationship
│   │   ├── Company.swift
│   │   ├── Interaction.swift
│   │   └── FollowUp.swift             # NEW: @Model, Priority enum
│   ├── Persistence/
│   │   ├── ContactRepository.swift            # MODIFIED: protocol gains FollowUp CRUD
│   │   └── SwiftDataContactRepository.swift    # MODIFIED: implements FollowUp CRUD
│   └── Notifications/                 # NEW module
│       ├── NotificationScheduling.swift        # protocol + environment key
│       ├── UNNotificationScheduler.swift       # real UNUserNotificationCenter-backed implementation
│       └── NoOpNotificationScheduler.swift     # fake used under -UITestResetState and in unit tests
└── Features/
    ├── Contacts/
    │   └── ContactDetailView.swift    # MODIFIED: adds a "Create Follow-Up" entry point
    └── FollowUps/                     # NEW feature folder
        ├── FollowUpBucketing.swift            # pure due-date bucketing function
        ├── FollowUpViewModel.swift
        ├── FollowUpFormView.swift             # create/edit, mirrors ContactFormView/InteractionFormView
        ├── FollowUpRow.swift
        └── TodayView.swift                    # the Today tab

NextStepTests/
├── (existing Spec 1/2 test files unchanged)
├── FollowUpRepositoryTests.swift              # NEW: CRUD, cascade delete, completion/reschedule
├── FollowUpBucketingTests.swift               # NEW: overdue/due-today/upcoming/recently-completed logic
└── NoOpNotificationSchedulerTests.swift        # NEW: verifies the fake records schedule/cancel calls correctly

NextStepUITests/
├── (existing Spec 1/2 test files unchanged)
└── FollowUpManagementFlowUITests.swift        # NEW: create/see/complete/reschedule/delete + Today screen
```

**Structure Decision**: Continues the single-app-target structure. The root view becomes a
`TabView` with Today first and the existing `ContactListView` moved under a Contacts tab — this is
the one genuine architectural change in this spec. Notification scheduling is isolated behind a
protocol with two implementations (real + no-op) rather than calling `UNUserNotificationCenter`
directly from view models, both for the constitution's testability requirement and because the
system permission dialog cannot be driven by XCUITest — UI tests run against the no-op scheduler
so they never depend on it.

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
