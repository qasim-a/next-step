# Implementation Plan: Core Data & Contact Management

**Branch**: `001-contact-management` | **Date**: 2026-07-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-contact-management/spec.md`

## Summary

Stand up NextStep's foundational SwiftData models (`NetworkingContact`, `Company`) and the first
vertical slice of UI on top of them: a searchable/filterable contact list, a contact detail
screen, and a create/edit form presented as a sheet. This is also the spec that bootstraps the
Xcode project itself and the `Core/` + `Features/Contacts` folder structure the constitution
requires, behind a `ContactRepository` protocol so persistence stays swappable and testable.

## Technical Context

**Language/Version**: Swift 5.10 (Xcode 16)

**Primary Dependencies**: SwiftUI, SwiftData — no third-party dependencies for this spec

**Storage**: SwiftData, on-device only, single local persistent store (no CloudKit sync in this spec)

**Testing**: Swift Testing for filtering/repository unit tests; XCTest/XCUITest for the end-to-end
contact create → search/filter → view → edit → delete flow, empty state, and relaunch/persistence

**Target Platform**: iOS 17.0+ (SwiftData's minimum), iPhone, portrait-first

**Project Type**: Native iOS mobile app — single Xcode app target

**Performance Goals**: Contact list search/filter results update within 100ms of query change for
up to 1,000 stored contacts; all interactions are local so no network latency applies

**Constraints**: Fully offline-capable (no network calls in this spec); on-device persistence only

**Scale/Scope**: Single local user; designed to stay smooth up to ~1,000 contacts; this spec
delivers 3 screens (contact list, contact detail, add/edit form) over 2 SwiftData models

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Native, Local-First iOS | PASS | Swift/SwiftUI/SwiftData only, no backend, no cross-platform framework introduced |
| II. Feature-Based MVVM with Protocol Boundaries | PASS | `Features/Contacts` + `Core/Models`, `Core/Persistence`; `ContactRepository` protocol introduced as the persistence boundary |
| III. Test-First Discipline | PASS | Swift Testing covers filtering + repository behavior; XCTest/XCUITest covers the full create/search/edit/delete/empty-state/relaunch flow — all required before this spec is done |
| IV. Spec-Driven, Incremental Delivery | PASS | Scope matches spec.md exactly; no interaction/follow-up/notification/experiment code introduced |
| V. Networking-Scoped Privacy | PASS | Only networking-specific fields modeled; no iOS Contacts (ContactsUI) integration in this spec (FR-017) |
| VI. Observable Experimentation | N/A | No experiment/analytics surface exists in this spec's scope; arrives in Spec 4 |

No violations — Complexity Tracking table is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-contact-management/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
NextStep/
├── NextStep.xcodeproj
├── NextStep/                          # App target sources
│   ├── App/
│   │   └── NextStepApp.swift          # @main, SwiftData ModelContainer setup
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── NetworkingContact.swift   # @Model
│   │   │   └── Company.swift             # @Model
│   │   ├── Persistence/
│   │   │   ├── ContactRepository.swift          # protocol
│   │   │   └── SwiftDataContactRepository.swift  # concrete SwiftData-backed implementation
│   │   └── DesignSystem/
│   │       └── (shared colors/type styles introduced as screens need them)
│   └── Features/
│       └── Contacts/
│           ├── ContactListView.swift
│           ├── ContactDetailView.swift
│           ├── ContactFormView.swift      # create/edit, presented as a sheet
│           ├── ContactViewModel.swift
│           └── ContactFiltering.swift     # pure search/filter logic, unit-testable
├── NextStepTests/                     # Swift Testing target
│   ├── ContactFilteringTests.swift
│   └── SwiftDataContactRepositoryTests.swift
└── NextStepUITests/                   # XCTest/XCUITest target
    └── ContactManagementFlowUITests.swift
```

**Structure Decision**: Single Xcode app target using feature-based folder groups (`Core/`,
`Features/Contacts`) as required by the constitution. No internal Swift Package Manager modules
are introduced yet — a single target is sufficient at this scope (avoids premature modularization);
SPM remains available for later third-party or extracted-module dependencies. `Core/Notifications`,
`Core/Analytics`, and `Core/Experiments` are intentionally not scaffolded until the specs that need
them (2–4), so this spec doesn't ship empty folders ahead of use.

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
