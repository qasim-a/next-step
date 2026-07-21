# Phase 1 Data Model: Experiments & Analytics

## AnalyticsEvent

A single recorded occurrence of one of the five tracked event types. Maps to spec.md's
`AnalyticsEvent` entity and FR-001 through FR-006.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | `UUID` | yes | Identity, generated at creation |
| `type` | `AnalyticsEventType` | yes | Enum; see below |
| `timestamp` | `Date` | yes | Set at recording time, not user-editable |
| `contactID` | `UUID?` | no | Plain UUID, **not** a `NetworkingContact` relationship — see Design rationale |
| `followUpID` | `UUID?` | no | Plain UUID, **not** a `FollowUp` relationship — see Design rationale |
| `contextLabel` | `String?` | no | Human-readable snapshot captured at record time (e.g. the contact's name), so the event stays meaningful in the developer screen even after the referenced contact or follow-up is later deleted |

**Design rationale — plain UUIDs instead of model relationships**: `AnalyticsEvent` intentionally
does **not** use a SwiftData `@Relationship` to `NetworkingContact` or `FollowUp`. A relationship
would either need a cascade-delete rule (which would silently destroy analytics history — an
audit-style log — the moment a user deletes a contact, contradicting the idea of a historical
record) or leave a dangling relationship reference. Storing a plain `UUID` plus a `contextLabel`
snapshot means an event about a since-deleted contact remains fully readable on the developer
screen (FR-006's "meaningful on its own"), matching how an analytics log behaves in a real system —
independent of the mutable entities it describes.

**Validation rules**:
- `type` must be one of the fixed `AnalyticsEventType` cases.
- `contactID`/`followUpID`/`contextLabel` are populated by the tracking call site per event type
  (see contracts) — not independently settable elsewhere.

## AnalyticsEventType (enum, not a stored entity)

```text
reminderDisplayed
contactOpened
followUpCompleted
reminderDismissed
followUpRescheduled
```

## ExperimentAssignment

The reminder-copy variant assigned to this on-device installation. Maps to spec.md's
`ExperimentAssignment` entity and FR-007/FR-008.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | `UUID` | yes | Identity, generated at creation |
| `experimentKey` | `String` | yes | Fixed to `"reminderCopy"` in this spec (only one experiment exists — see spec.md Assumptions); kept as a string field, not hard-coded to a single row, so a second experiment could be added later without a schema change |
| `variant` | `ReminderCopyVariant` | yes | Enum; see below |
| `assignedAt` | `Date` | yes | Set once, at first assignment; never updated |

**Validation rules**:
- At most one `ExperimentAssignment` row exists per distinct `experimentKey` value — enforced by
  the repository's find-or-create logic (see contracts), not a database-level uniqueness
  constraint (SwiftData has none available for this).
- `variant` is fixed once written; nothing in this spec updates an existing assignment's `variant`.

## ReminderCopyVariant (enum, not a stored entity)

```text
control    // "Follow up with {name}"
variant    // e.g. "Don't lose touch with {name}"
```

## State / lifecycle

- An `AnalyticsEvent` is created once, at the moment of the action it records, and never modified
  or soft-deleted by this spec — it is an append-only log. (Edge Cases in spec.md allows the
  implementation to bound total retention for developer-screen responsiveness, but that is an
  implementation choice, not a state transition.)
- An `ExperimentAssignment` is created at most once per `experimentKey`, the first time
  `ExperimentProviding` is asked for a variant and no row yet exists for that key (FR-007). Every
  subsequent read for the same key returns the same persisted row — this is what makes the
  assignment deterministic across launches (spec.md User Story 2), as distinct from a
  random-per-launch or hash-based scheme.
- Neither entity has a relationship to `NetworkingContact`, `Interaction`, or `FollowUp` — see
  `AnalyticsEvent`'s design rationale above. Deleting a contact or follow-up therefore has no
  cascade effect on either table; existing events referencing a since-deleted ID simply keep their
  `contextLabel` snapshot.
