# Phase 0 Research: Interactions

No `NEEDS CLARIFICATION` markers remained in the Technical Context. This documents the rationale
behind the concrete choices made there.

## One repository vs. a second `InteractionRepository`

- **Decision**: Extend the existing `ContactRepository` protocol with interaction CRUD methods
  rather than introducing a separate `InteractionRepository`.
- **Rationale**: Interactions have no meaning independent of a contact in this spec — there's no
  cross-contact interaction browsing, search, or list. A second repository would duplicate the
  `ModelContext`-wrapping boilerplate for no real boundary benefit. This mirrors Spec 1's
  single-target decision: don't split until there's a second, genuinely independent consumer.
- **Alternatives considered**: A dedicated `InteractionRepository` — would match a purist
  one-repository-per-aggregate-root reading of the constitution's protocol list, but the
  constitution names `ContactRepository` as the persistence boundary and doesn't mandate a 1:1
  model-to-repository mapping; revisit if Specification 4's opportunities/companies work
  independently browsable interactions in some form.

## Where to recompute `lastInteractionDate`

- **Decision**: Recompute it inside `SwiftDataContactRepository`'s interaction save/delete
  methods, not in `InteractionViewModel`.
- **Rationale**: The invariant ("a contact's last-interaction date equals its most recent
  interaction's date") must hold regardless of which call site writes an interaction. Putting the
  recompute in the repository means it can't be forgotten by a future call site (e.g. a bulk
  import in a later spec); putting it in the view model would require every future caller to
  remember to call it too.
- **Alternatives considered**: A computed property on `NetworkingContact` that derives
  `lastInteractionDate` from `interactions.map(\.date).max()` on read, with no stored field at
  all — cleaner in principle (no invariant to maintain), but Specification 1 already shipped
  `lastInteractionDate` as a stored, directly-queryable field, and changing its storage shape now
  would be a breaking migration for no behavioral gain in this spec's scope. Kept as a
  repository-maintained stored field; a computed-property migration can be reconsidered later if
  a real reason to query/sort by it independently of loading full interaction lists emerges.

## Cascade delete: SwiftData relationship rule vs. manual cleanup

- **Decision**: Use SwiftData's `@Relationship(deleteRule: .cascade, inverse:)` on
  `NetworkingContact.interactions` rather than manually deleting a contact's interactions in
  repository code before deleting the contact.
- **Rationale**: This is exactly what the framework's declarative delete rule exists for, and
  avoids a manual two-step delete that could be forgotten or get out of sync with the model
  definition. It does need an explicit repository test confirming cascade actually fires — Spec
  1's `ModelContainer`-lifetime bug is a reminder that SwiftData relationship/lifecycle behavior
  in this toolchain is worth verifying empirically, not just trusting from documentation.
- **Alternatives considered**: Manual cleanup (`for interaction in contact.interactions {
  modelContext.delete(interaction) }` before deleting the contact) — more explicit and won't
  silently do the wrong thing if the relationship annotation is ever mistyped, but is redundant
  with a correctly-configured cascade rule and adds a maintenance burden if the model changes.

## Tie-breaking same-dated interactions on the timeline

- **Decision**: Sort by `date` descending, then by `createdAt` descending as a stable tiebreaker,
  in a small pure `InteractionTimeline.sorted(_:)` function — mirroring `ContactFiltering`'s
  shape from Spec 1 (a pure, independently unit-testable function rather than inline sort logic
  in the view or view model).
- **Rationale**: Satisfies the spec's edge case (two interactions sharing a date both appear, in
  a stable order) and keeps ordering logic testable without a `ModelContext`.
- **Alternatives considered**: Rely on SwiftData's default fetch order — unspecified/undefined
  ordering for ties, which could make the timeline visually reorder between launches; rejected as
  it fails the "stable tiebreak" requirement.
