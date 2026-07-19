# Phase 1 Data Model: Follow-ups and Notifications

## FollowUp

A user-created reminder to take action with a contact. Maps to spec.md's "Follow-Up" entity and
FR-001 through FR-011.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | `UUID` | yes | Identity, generated at creation |
| `contact` | `NetworkingContact?` | yes (enforced by caller) | Inverse of `NetworkingContact.followUps`; optional only because SwiftData relationship properties are declared optional |
| `originatingInteraction` | `Interaction?` | no | Set when created from an interaction's next-action text (FR-003); no delete rule cascades from this side — deleting the interaction does not delete the follow-up, it just leaves this reference nil-able context |
| `dueDate` | `Date` | yes | User-editable; not restricted to past or future (Edge Cases) |
| `priority` | `FollowUpPriority` | yes, with default | Enum; defaults to `.medium` |
| `suggestedAction` | `String?` | no | Free text; pre-filled from an interaction's next-action when created that way, still editable |
| `isCompleted` | `Bool` | yes, defaults false | |
| `completedAt` | `Date?` | no | Set when `isCompleted` becomes true; cleared if ever reverted (no UI to revert in this spec, but kept nil-able for correctness) |
| `createdAt` | `Date` | yes | Set at creation, not user-editable |

**Validation rules**:
- `priority` must be one of the fixed `FollowUpPriority` cases.
- `isCompleted` and `completedAt` are kept consistent by the repository (see contracts) — not
  independently settable by the UI layer.

## FollowUpPriority (enum, not a stored entity)

```text
low
medium
high
```

## NetworkingContact (extended from Specifications 1-2)

| Field | Change |
|---|---|
| `followUps` | **NEW**: `[FollowUp]`, `@Relationship(deleteRule: .cascade, inverse: \FollowUp.contact)` — deleting a contact deletes its follow-ups (FR-012), mirroring `interactions` from Specification 2 |

**Relationships**:
- `NetworkingContact.followUps: [FollowUp]` (cascade delete) ↔ `FollowUp.contact: NetworkingContact?`
  (inverse). One contact has many follow-ups; one follow-up belongs to exactly one contact.
- `FollowUp.originatingInteraction: Interaction?` — no delete rule; a follow-up outlives the
  interaction it was created from if that interaction is later edited or deleted, since the
  follow-up's `suggestedAction` was only ever pre-filled once, not kept in sync.

## Due-date buckets (derived, not stored)

Computed by `FollowUpBucketing`, not persisted as a field:

| Bucket | Rule |
|---|---|
| Overdue | `!isCompleted && dueDate < startOfToday` |
| Due Today | `!isCompleted && isSameDay(dueDate, today)` |
| Upcoming | `!isCompleted && dueDate > endOfToday` |
| Recently Completed | `isCompleted && completedAt` is within the recent window (a few days) of today |

## State / lifecycle

- A `FollowUp` starts incomplete. `isCompleted` transitions false → true when the user marks it
  complete (FR-008), setting `completedAt` to the completion moment. This spec has no UI to
  transition it back to incomplete.
- `dueDate` can change any number of times via rescheduling (FR-009) while incomplete.
- Deleting a `FollowUp` (FR-011) or its parent contact (FR-012) removes it permanently — no
  soft-delete, matching the precedent from Specifications 1-2.
- Each `dueDate` change or completion/deletion triggers a corresponding
  `NotificationScheduling` call (schedule/cancel) — see
  [contracts/contact-repository-followups.md](./contracts/contact-repository-followups.md).
