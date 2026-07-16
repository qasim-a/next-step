# Contract: ContactRepository interaction methods

Extends the `ContactRepository` contract from Specification 1
([001-contact-management/contracts/contact-repository.md](../../001-contact-management/contracts/contact-repository.md))
with interaction CRUD. Still no external/network API — this is the same internal
`Features/*` ↔ `SwiftData` boundary, just with more methods.

## Protocol shape (additions)

```swift
protocol ContactRepository {
    // ... Specification 1 methods unchanged ...

    func fetchInteractions(for contact: NetworkingContact) throws -> [Interaction]
    func saveInteraction(_ interaction: Interaction, for contact: NetworkingContact) throws
    func deleteInteraction(_ interaction: Interaction) throws
}
```

## Behavioral contract

- `fetchInteractions(for:)` returns every `Interaction` belonging to the given contact, in an
  unspecified order — ordering for the timeline is `InteractionTimeline.sorted(_:)`'s
  responsibility (a pure function, tested independently), not the repository's, matching Spec 1's
  precedent of keeping display ordering out of the persistence layer.
- `saveInteraction(_:for:)` inserts a new interaction if it isn't already tracked (setting its
  `contact` relationship to the given contact), or persists in-place edits if it is. After saving,
  it recomputes `contact.lastInteractionDate` as the max date across that contact's interactions
  and persists that change too. Callers are responsible for field validation before calling this
  (same convention as `save(_:)` for contacts) — the repository does not re-validate interaction
  fields.
- `deleteInteraction(_:)` removes the interaction permanently (no soft-delete, matching FR-009
  and Spec 1's no-undo precedent), then recomputes the owning contact's `lastInteractionDate`
  (falling back to `nil` if no interactions remain — FR-011).
- Deleting a contact via the existing `delete(_ contact: NetworkingContact)` method cascades to
  delete all of that contact's interactions automatically via the SwiftData relationship's
  `.cascade` delete rule — no explicit interaction cleanup call is needed at that call site.

## Error handling

- All throwing methods surface underlying SwiftData/`ModelContext` errors unchanged, consistent
  with Specification 1's contract — no custom error type introduced.

## Consumers

- `InteractionViewModel` (Features/Interactions) is the production consumer.
- `InteractionRepositoryTests` exercises `SwiftDataContactRepository`'s interaction methods
  directly against an in-memory `ModelContainer`, including a dedicated test that deleting a
  contact removes its interactions (verifying the cascade rule actually fires in this toolchain,
  not just trusting the annotation).
- `InteractionManagementFlowUITests` exercises the app end-to-end; its assertions about the
  timeline and about `lastInteractionDate` behavior are only meaningful because this contract
  guarantees the recompute-on-write semantics above.
