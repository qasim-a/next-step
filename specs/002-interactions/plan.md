# Implementation Plan: Interactions

**Branch**: `002-interactions` | **Date**: 2026-07-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-interactions/spec.md`

## Summary

Add an `Interaction` SwiftData model (contact-scoped: type, date, notes, outcome, next-action
note) with cascade delete from `NetworkingContact`, a chronological timeline on the contact
detail screen, and a log/edit form mirroring `ContactFormView`'s create-or-edit pattern. Extends
`ContactRepository` with interaction CRUD rather than introducing a second repository, and
recomputes `NetworkingContact.lastInteractionDate` at the repository layer on every interaction
write so the invariant holds regardless of caller.

## Technical Context

**Language/Version**: Swift 5.10 (Xcode 26.6)

**Primary Dependencies**: SwiftUI, SwiftData — no new dependencies

**Storage**: SwiftData, same store as Specification 1; adds `Interaction` and a cascade-delete
relationship from `NetworkingContact`

**Testing**: Swift Testing for repository behavior (with the container-retention discipline
learned in Spec 1) and for the pure timeline-ordering function; XCTest/XCUITest for the full
log/edit/delete flow

**Target Platform**: iOS 17.0+ (unchanged)

**Project Type**: Native iOS mobile app — continuation of the existing single Xcode app target

**Performance Goals**: Timeline renders without perceptible delay for up to ~200 interactions on
a single contact

**Constraints**: Fully offline-capable, on-device only (unchanged)

**Scale/Scope**: Adds 1 model, extends 1 protocol/implementation, adds a new `Features/Interactions`
feature folder (view model + 2 views), extends `ContactDetailView` with a timeline section

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Native, Local-First iOS | PASS | Same SwiftData store, no backend, no new frameworks |
| II. Feature-Based MVVM with Protocol Boundaries | PASS | New `Features/Interactions` folder (per the constitution's own architecture sketch) with its own `InteractionViewModel`; persistence still goes through the `ContactRepository` protocol boundary |
| III. Test-First Discipline | PASS | Swift Testing for repository + timeline-ordering logic; XCUITest for log/edit/delete end-to-end, matching Spec 1's rigor |
| IV. Spec-Driven, Incremental Delivery | PASS | Scope matches spec.md exactly; next-action stays descriptive text only, no reminder/notification code introduced |
| V. Networking-Scoped Privacy | PASS | No new system permissions; interaction data stays networking-specific |
| VI. Observable Experimentation | N/A | No experiment/analytics surface in this spec's scope |

No violations — Complexity Tracking table is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/002-interactions/
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
├── Core/
│   ├── Models/
│   │   ├── NetworkingContact.swift        # MODIFIED: adds `interactions` relationship + recomputed lastInteractionDate
│   │   ├── Company.swift
│   │   └── Interaction.swift              # NEW: @Model, InteractionType enum
│   └── Persistence/
│       ├── ContactRepository.swift        # MODIFIED: protocol gains interaction CRUD
│       └── SwiftDataContactRepository.swift  # MODIFIED: implements interaction CRUD + lastInteractionDate recompute
└── Features/
    ├── Contacts/
    │   └── ContactDetailView.swift        # MODIFIED: adds timeline section + "Log Interaction" entry point
    └── Interactions/                      # NEW feature folder
        ├── InteractionViewModel.swift
        ├── InteractionFormView.swift      # log/edit, mirrors ContactFormView's create-or-edit pattern
        └── InteractionRow.swift           # timeline row (type, date, outcome preview)

NextStepTests/
├── SwiftDataContactRepositoryTests.swift  # unchanged
├── ContactFilteringTests.swift            # unchanged
├── InteractionRepositoryTests.swift       # NEW: CRUD + cascade delete + lastInteractionDate recompute
└── InteractionTimelineOrderingTests.swift # NEW: pure ordering/tie-break logic

NextStepUITests/
├── ContactManagementFlowUITests.swift     # unchanged
└── InteractionManagementFlowUITests.swift # NEW: log/edit/delete + timeline end-to-end
```

**Structure Decision**: Continues the single-app-target structure from Specification 1. Adds the
`Features/Interactions` folder called for in the constitution's architecture sketch, but keeps
persistence on the existing `ContactRepository` protocol rather than introducing a second
repository — interactions are always contact-scoped in this spec (no independent interaction
browsing), so a separate repository would be premature abstraction. `lastInteractionDate`
recomputation lives in `SwiftDataContactRepository` itself (not the view model) so the invariant
holds no matter which call site writes an interaction.

## Complexity Tracking

*No Constitution Check violations — this section is intentionally empty.*
