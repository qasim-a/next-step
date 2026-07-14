# Phase 1 Data Model: Core Data & Contact Management

## NetworkingContact

The person the user has networked with. Maps to spec.md's "Networking Contact" entity and
FR-001 through FR-006.

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | `UUID` | yes | Identity, generated at creation |
| `name` | `String` | yes | Only required field (FR-001, FR-003); blank/whitespace-only rejected |
| `company` | `Company?` | no | Optional relationship to `Company` |
| `jobTitle` | `String?` | no | |
| `contactHandle` | `String?` | no | Email address or LinkedIn profile URL/handle — single free-text field, not separately typed/validated as email vs. URL in this spec |
| `howWeMet` | `String?` | no | Free text |
| `relationshipCategory` | `RelationshipCategory` | yes, with default | Enum; defaults to a neutral category (`peer`) when unset rather than being nullable, so filtering always has a defined value to filter on |
| `relationshipStrength` | `Int` | yes, with default | 1–5 bounded scale (see research.md); defaults to 3 (neutral/mid) |
| `notes` | `String?` | no | Free text, reasonable max length enforced in the form (e.g. 2,000 characters) to satisfy the "extremely long note" edge case |
| `lastInteractionDate` | `Date?` | no | Manually editable in this spec (see spec.md Assumptions); `nil` means "no interaction recorded yet" |
| `createdAt` | `Date` | yes | Set at creation, not user-editable; supports future sorting/analytics |

**Validation rules**:
- `name` must be non-empty after trimming whitespace (FR-003, Edge Cases).
- `relationshipStrength` must be within 1...5.
- `notes` truncated/rejected past the form's configured max length.

**Relationships**:
- `company: Company?` — many contacts may reference the same `Company`; deleting a contact does
  not delete its `Company` (a `Company` can be empty of contacts and still exist, e.g. if the
  last contact at that company is deleted — acceptable for this spec since `Company` is lightweight).

## Company

A lightweight, named association a contact can belong to. Maps to spec.md's "Company" entity.
Intentionally minimal in this spec — becomes a richer, independently browsable entity carrying
opportunities in a later specification (per spec.md Assumptions).

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | `UUID` | yes | Identity |
| `name` | `String` | yes | Non-empty; used for search/grouping (FR-008) |

**Validation rules**:
- `name` must be non-empty after trimming whitespace.
- No uniqueness constraint enforced in this spec (spec.md explicitly defers de-duplication);
  two `Company` records with the same name may exist if created independently — acceptable since
  `Company` selection in the form will offer existing companies first (typeahead) to discourage,
  but not prevent, duplicates.

## RelationshipCategory (enum, not a stored entity)

Fixed per FR-004 / constitution — no custom categories in v1:

```text
recruiter
referral
alumnus
hiringManager
peer
```

## State / lifecycle

- A `NetworkingContact` has no formal state machine in this spec — it exists once created and is
  either present or deleted (FR-014). No soft-delete/undo state.
- Edits (FR-012/FR-013) are transactional at the form level: the form holds its own draft state
  and only writes back to the persisted `NetworkingContact` on save; cancel discards the draft
  without touching the persisted record.
