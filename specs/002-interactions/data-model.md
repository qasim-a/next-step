# Phase 1 Data Model: Interactions

## Interaction

A single logged instance of contact with a person. Maps to spec.md's "Interaction" entity and
FR-001 through FR-009.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | `UUID` | yes | Identity, generated at creation |
| `contact` | `NetworkingContact?` | yes (enforced by caller, not nullability) | Inverse of `NetworkingContact.interactions`; optional only because SwiftData relationship properties are declared optional, but the app never creates an `Interaction` without one |
| `type` | `InteractionType` | yes | Enum, fixed set — see below |
| `date` | `Date` | yes, defaults to today | User-editable; not restricted to past dates (spec.md Edge Cases) |
| `notes` | `String?` | no | Free text |
| `outcome` | `String?` | no | Free text; shown on the collapsed timeline row |
| `nextAction` | `String?` | no | Free text only in this spec — does not schedule anything (FR-014) |
| `createdAt` | `Date` | yes | Set at creation, not user-editable; used as the timeline's tiebreaker for same-dated interactions |

**Validation rules**:
- `type` must be one of the fixed `InteractionType` cases (enforced by the type system, not
  runtime validation).
- `date` has no range restriction.

## InteractionType (enum, not a stored entity)

Fixed per FR-002 — matches spec.md's named set:

```text
linkedInConnectionRequest
linkedInMessage
email
phoneOrVideoCall
inPersonMeeting
interview
referralRequest
```

## NetworkingContact (extended from Specification 1)

| Field | Change |
|---|---|
| `interactions` | **NEW**: `[Interaction]`, `@Relationship(deleteRule: .cascade, inverse: \Interaction.contact)` — deleting a contact deletes its interactions (FR-012) |
| `lastInteractionDate` | **Behavior change, same field/type** (`Date?`): now recomputed by `SwiftDataContactRepository` on every interaction save/delete for that contact, equal to `interactions.map(\.date).max()`, or `nil` when `interactions` is empty (FR-010, FR-011). No longer manually edited via `ContactFormView` as of this spec — see Assumptions below. |

**Relationships**:
- `NetworkingContact.interactions: [Interaction]` (cascade delete) ↔ `Interaction.contact:
  NetworkingContact?` (inverse). One contact has many interactions; one interaction belongs to
  exactly one contact.

## State / lifecycle

- An `Interaction` has no formal state machine — it exists once logged and is either present or
  deleted (FR-009), or removed automatically when its contact is deleted (FR-012).
- Edits (FR-007/FR-008) follow the same transactional pattern as `ContactFormView`: the form holds
  its own draft state and only writes back to the persisted `Interaction` on save; cancel discards
  the draft.
- `NetworkingContact.lastInteractionDate` is derived, not independently editable — it changes only
  as a side effect of an interaction being logged, edited (if its date changed), or deleted for
  that contact.

## Assumptions carried over from Specification 1, now resolved

Specification 1's data-model.md noted: *"`lastInteractionDate` is a manually editable field in
this spec, since interaction logging does not exist yet; a later specification will populate it
automatically from logged interactions."* This spec is that later specification —
`ContactFormView`'s manual last-interaction-date editing (which never actually existed as a form
field in Spec 1's implementation; only the underlying model field did) is superseded by automatic
recomputation. No UI change is needed in `ContactFormView` since it never exposed that field.
