# Contract: ContactRepository

NextStep has no external/network API in this spec. The contract that matters here is the
internal boundary the constitution requires between `Features/Contacts` and persistence: the
`ContactRepository` protocol. Everything above this line is UI/view-model code; everything below
it is SwiftData. Tests target this contract directly (with an in-memory `ModelContainer`) so they
don't depend on SwiftUI.

## Protocol shape

```swift
protocol ContactRepository {
    func fetchAll() throws -> [NetworkingContact]
    func fetch(id: UUID) throws -> NetworkingContact?
    func save(_ contact: NetworkingContact) throws
    func delete(_ contact: NetworkingContact) throws

    func fetchAllCompanies() throws -> [Company]
    func findOrCreateCompany(named name: String) throws -> Company
}
```

## Behavioral contract

- `fetchAll()` returns every non-deleted `NetworkingContact`, in an unspecified order — ordering
  for display is the view model's responsibility (not the repository's), so `ContactFiltering`
  can be tested independently of persistence ordering.
- `fetch(id:)` returns `nil` (not a thrown error) when no contact with that id exists.
- `save(_:)` inserts a new contact if it isn't already tracked by the underlying context, or
  persists in-place edits if it is. Callers are responsible for validation (name non-empty,
  strength in range) before calling `save` — the repository does not re-validate.
- `delete(_:)` removes the contact permanently; no soft-delete, matching FR-014 and the spec's
  Assumptions (no undo/trash in this spec).
- `fetchAllCompanies()` returns every distinct `Company` currently stored, for the form's
  typeahead.
- `findOrCreateCompany(named:)` returns an existing `Company` matching `name`
  (case-insensitive, trimmed) if one exists, otherwise creates and returns a new one. This is the
  one place duplicate-avoidance is attempted, per data-model.md's note that `Company`
  de-duplication is not strictly enforced elsewhere.

## Error handling

- All throwing methods surface underlying SwiftData/`ModelContext` errors unchanged (no custom
  error type introduced in this spec) — the view model is responsible for translating a thrown
  error into a user-facing message ("Couldn't save contact, please try again").

## Consumers

- `ContactViewModel` (Features/Contacts) is the only production consumer in this spec.
- `SwiftDataContactRepositoryTests` exercises `SwiftDataContactRepository` directly against an
  in-memory `ModelContainer`.
- `ContactManagementFlowUITests` exercises the app end-to-end and does not call the protocol
  directly, but its assertions (e.g. "contact persists after relaunch") are only meaningful
  because this contract guarantees persistence semantics.
