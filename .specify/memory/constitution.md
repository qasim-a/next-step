<!--
Sync Impact Report
- Version change: none → 1.0.0 (initial ratification)
- Modified principles: n/a (first version)
- Added sections: Core Principles (6), Technology Constraints, Development Workflow, Governance
- Removed sections: none
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (generic "Gates determined based on constitution file" — no edit needed)
  - .specify/templates/spec-template.md ✅ (no project-specific references found)
  - .specify/templates/tasks-template.md ✅ (no project-specific references found)
  - .claude/skills/*/SKILL.md ✅ (agent-agnostic, no CLAUDE-only or other agent-specific naming found)
- Follow-up TODOs: none
-->

# NextStep Constitution

## Core Principles

### I. Native, Local-First iOS
NextStep is a native Swift/SwiftUI application built with Xcode and Swift Package
Manager. Persistence MUST use SwiftData as the primary store, `@AppStorage` for
small settings, and Keychain only once real authentication or API credentials
exist. Version 1 MUST ship with no backend and no network dependency — all
networking-specific data lives on-device. Cross-platform frameworks (e.g.
Flutter, React Native) MUST NOT be introduced; the point of this project is
demonstrable native iOS engineering.

**Rationale**: A local-first scope keeps the project focused on native iOS
skills (SwiftUI, SwiftData, concurrency, system frameworks) rather than
account management, auth, and cloud infrastructure, and keeps the codebase
honest evidence of Swift/SwiftUI ability rather than a cross-platform shim.

### II. Feature-Based MVVM with Protocol Boundaries
Code MUST be organized by feature (`Features/Dashboard`, `Features/Contacts`,
`Features/Interactions`, `Features/FollowUps`, `Features/Opportunities`,
`Features/Settings`) with shared concerns under `Core/` (`Models`,
`Persistence`, `Notifications`, `Analytics`, `Experiments`, `DesignSystem`).
Each feature follows a lightweight MVVM split (View / ViewModel, plus helper
types such as filtering). Cross-cutting boundaries MUST be expressed as
protocols — at minimum `ContactRepository`, `NotificationScheduling`,
`AnalyticsTracking`, `ExperimentProviding`, `MessageGenerating` — so features
depend on abstractions, not concrete persistence or system APIs.

**Rationale**: Protocol boundaries make the app testable without a full DI
framework and demonstrate dependency inversion without introducing
unnecessary architectural ceremony for what is still a small app.

### III. Test-First Discipline (NON-NEGOTIABLE)
Every feature MUST ship with tests before it is considered complete. Use
Swift Testing for unit/integration coverage (filtering, prioritization,
date math, experiment assignment, analytics events, message templates,
repository behavior) and XCTest/XCUITest for full user flows (create
contact → log interaction → schedule follow-up → see it on the dashboard →
complete it) and for search, validation, editing/deletion, accessibility,
empty states, and relaunch/persistence. A spec is NOT done until its
associated tests exist and pass.

**Rationale**: This project doubles as a portfolio artifact demonstrating
testing discipline (Swift Testing + XCTest/XCUITest), not just a working
app; skipping tests undermines that goal directly.

### IV. Spec-Driven, Incremental Delivery
Work proceeds through the Spec Kit workflow (`/speckit-specify` →
`/speckit-plan` → `/speckit-tasks` → `/speckit-implement`) one specification
at a time, following the sequence: (1) Core data & contact management,
(2) Interactions, (3) Follow-ups & notifications, (4) Experiments &
analytics, (5) Polish. Each increment MUST implement only the scope of its
current specification, MUST NOT add unrelated dependencies or features, and
MUST summarize architectural decisions and unresolved risks when complete.
Advanced features beyond the MVP (message assistant, business-card
scanning, calendar integration, App Intents, widgets) MUST NOT be started
until the five core specs are implemented, and at most one or two are
selected afterward.

**Rationale**: Small, reviewable increments keep an AI-assisted codebase
auditable and prevent scope creep from turning a portfolio project into an
unfinished one.

### V. Networking-Scoped Privacy
NextStep stores only networking-relevant data — it MUST NOT attempt to
replace the iOS Contacts app or duplicate its full data model. Any access to
system-protected data (Contacts, Calendar, Notifications, Camera) MUST go
through explicit user-permission prompts via the relevant native framework
(ContactsUI, EventKit, UserNotifications, VisionKit) and MUST degrade
gracefully if denied. Generated message drafts (thank-you, follow-up,
referral, reconnection, recruiter update) are ALWAYS drafts; the app MUST
NEVER send a message automatically on the user's behalf.

**Rationale**: Respecting system permission boundaries and never
auto-sending communication keeps the app trustworthy and avoids scope creep
into a full CRM or communications platform.

### VI. Observable Experimentation
Feature flags and reminder-copy experiments MUST be implemented behind
`ExperimentProviding` and `AnalyticsTracking` protocols, kept separate from
view code, with deterministic (not random-per-launch) variant assignment.
Key events (reminder displayed, contact opened, follow-up completed,
reminder dismissed, follow-up rescheduled) MUST be tracked through the
analytics protocol and MUST be inspectable via a hidden developer screen.
Structured logging MUST use OSLog rather than ad hoc `print` statements.

**Rationale**: The target role explicitly calls out experimentation
frameworks; this principle exists to force a real (if small) separation
between experiment logic, analytics, and UI rather than a token
implementation.

## Technology Constraints

- **Language/UI**: Swift, SwiftUI, Xcode, Swift Package Manager.
- **Persistence**: SwiftData models — `NetworkingContact`, `Company`,
  `Opportunity`, `Interaction`, `FollowUp`, `MessageDraft`,
  `ExperimentAssignment`, `AnalyticsEvent`.
- **Concurrency**: Modern Swift concurrency only (`async/await`, `Task`,
  `@MainActor`, actors for genuinely shared mutable state) — no completion-
  handler-based APIs introduced net-new.
- **System frameworks** (introduced only as the relevant spec requires them):
  UserNotifications, Swift Charts, ContactsUI, EventKit, VisionKit/Vision,
  App Intents, WidgetKit, LinkPresentation, OSLog.
- **Testing**: Swift Testing for unit/integration tests; XCTest/XCUITest for
  end-to-end flows; SwiftLint and SwiftFormat for static quality; GitHub
  Actions for CI.

## Development Workflow

- Follow the Spec Kit lifecycle for every feature: `/speckit-constitution`
  (this file) → `/speckit-specify` → optionally `/speckit-clarify` →
  `/speckit-plan` → optionally `/speckit-checklist` → `/speckit-tasks` →
  optionally `/speckit-analyze` → `/speckit-implement`.
- Each specification's tests MUST be written or updated, and MUST pass,
  before that specification is considered complete.
- Maintain `AI_USAGE.md` at the repository root, recording: tools used
  (Claude Code, Spec Kit), which features had AI assistance, code that was
  manually reviewed, bugs or poor suggestions that were rejected, and tests
  used to validate AI-generated work. Update it as part of completing each
  specification, not retroactively at the end.
- Commits should stay scoped to the current specification; do not bundle
  unrelated refactors into a feature's implementation commit.

## Governance

This constitution supersedes ad hoc practices and prior informal
conventions for this repository. Amendments require: a documented reason,
a version bump per the rules below, and a Sync Impact Report prepended to
this file describing what changed and which dependent templates were
checked or updated.

Versioning policy (semantic versioning applied to governance):
- **MAJOR**: Backward-incompatible principle removal or redefinition.
- **MINOR**: A new principle or materially expanded section is added.
- **PATCH**: Wording, clarification, or non-semantic refinement.

Every `/speckit-plan` run MUST pass the Constitution Check gate against the
principles above before Phase 0 research begins, and MUST re-check after
Phase 1 design. Any violation MUST be justified in that plan's Complexity
Tracking table or the simpler alternative MUST be adopted instead.

**Version**: 1.0.0 | **Ratified**: 2026-07-14 | **Last Amended**: 2026-07-14
