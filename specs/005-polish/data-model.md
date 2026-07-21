# Phase 1 Data Model: Polish

No new persisted entities. This spec's only data-layer change is *where* the existing SwiftData
store lives, not its schema.

## Storage relocation (not a new entity)

| Before (Specifications 1-4) | After (this spec) |
|---|---|
| Default `ModelConfiguration()` — SwiftData's default per-target sandbox location, invisible to any other target | `ModelConfiguration(url:)` pointing inside the shared App Group container (`group.com.nextstep.app.NextStep`), readable by both the `NextStep` app target and the new `NextStepWidget` extension target |

All existing models (`NetworkingContact`, `Company`, `Interaction`, `FollowUp`,
`ExperimentAssignment`, `AnalyticsEvent`) are unchanged — same fields, same relationships, same
cascade-delete rules from Specifications 1-4. Only the container's on-disk location changes. See
research.md for why (a widget extension is a separate sandboxed process) and the accepted
consequence (any prior build's on-disk data at the old location is orphaned, not migrated).

## FollowUpWidgetContent (derived, not stored)

Mirrors `FollowUpBucketing`'s existing shape (Specification 3) — a pure function over already-
fetched `[FollowUp]`, not a persisted type:

| Field | Type | Notes |
|---|---|---|
| `topFollowUps` | `[FollowUp]` | Up to 3, most-urgent-first: overdue (oldest due date first) before due-today |
| `isEmpty` | `Bool` | True when there are no overdue or due-today follow-ups — drives the widget's "nothing due" state (FR-006) |

**Selection rule**: same overdue/due-today boundary `FollowUpBucketing` already defines
(`dueDate < startOfToday` = overdue, same-day = due-today); upcoming and completed follow-ups are
never shown on the widget, matching FR-005's "due today or overdue" scope exactly.
