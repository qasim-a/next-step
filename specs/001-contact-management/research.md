# Phase 0 Research: Core Data & Contact Management

No `NEEDS CLARIFICATION` markers remained in the Technical Context, so this research documents
the rationale behind the concrete choices made there rather than resolving open unknowns.

## Addendum (discovered during implementation): a `ModelContext` does not retain its `ModelContainer`

- **Finding**: A helper like `func makeRepository() throws -> SwiftDataContactRepository { let
  container = try ModelContainer(...); return SwiftDataContactRepository(modelContext:
  container.mainContext) }` crashes the moment the returned repository is used. `ModelContext`
  does not hold a strong reference back to the `ModelContainer` that created it, so once
  `makeRepository()` returns, ARC deallocates the local `container` — the context then points at
  a torn-down store, and the first `insert`/`fetch` call traps with `EXC_BREAKPOINT` inside
  `SwiftData.framework`.
- **Red herring ruled out**: This was initially misdiagnosed as a Swift Testing/SwiftData
  incompatibility (Swift Testing `@Test` crashed, a same-scope `XCTestCase` prototype didn't) —
  but the XCTest prototype only "worked" because it happened to keep everything, including the
  container, in one function scope. Once `SwiftDataContactRepositoryTests` was restructured with
  the same local-helper pattern under XCTest, it crashed identically, isolating the real cause to
  container lifetime, not the test framework.
- **Fix**: `SwiftDataContactRepositoryTests` holds `container` as a stored property (set in
  `init()`), not returned from a local helper — keeping it alive for the whole test. In
  production, `NextStepApp.modelContainer` is already a stored property held for the app's
  lifetime, so this bug never manifested there.
- **Takeaway for later specs**: Anywhere a `ModelContainer` is created for test setup, keep it
  as a retained property (test-suite instance property or `XCTestCase` `setUp`/instance var), not
  a local inside a factory function.

## SwiftData vs. Core Data

- **Decision**: SwiftData.
- **Rationale**: Native, declarative persistence that integrates directly with SwiftUI's
  data flow (`@Query`, `@Model`), matches the constitution's Technology Constraints, and avoids
  Core Data's NSManagedObject/NSFetchRequest boilerplate for a small model graph (2 entities in
  this spec, growing to 8 across the whole project).
- **Alternatives considered**: Core Data — more mature and flexible (e.g. richer migration
  tooling) but noticeably more boilerplate for a project this size and not what the constitution
  specifies. Plain file/JSON persistence — rejected, no real querying/filtering support.

## Minimum iOS version

- **Decision**: iOS 17.0+.
- **Rationale**: SwiftData itself requires iOS 17. Targeting 17.0 (rather than 18) maximizes
  device coverage while still getting the full SwiftData feature set this spec needs
  (`@Model`, `@Query`, predicates).
- **Alternatives considered**: iOS 18+ — would allow newer SwiftData refinements, but nothing in
  this spec's scope needs them, and it would needlessly shrink device coverage.

## App structure: single target vs. local SPM packages

- **Decision**: Single Xcode app target, feature-based folder groups (`Core/`, `Features/`).
- **Rationale**: The constitution asks for feature-based organization and protocol boundaries,
  not necessarily separate build modules. A single target keeps build times and project
  configuration simple while `ContactRepository` still gives the testability and dependency
  inversion the constitution requires. Splitting into local SPM packages before there's a second
  consumer of any module would be premature abstraction.
- **Alternatives considered**: Per-feature local SPM packages — offers stronger compile-time
  boundaries and parallel build benefits, but adds real overhead (per-package manifests, resource
  handling, cross-package access control) that isn't justified until the codebase or team size
  demands it. Can be introduced later without changing the app's external behavior.

## Persistence boundary shape

- **Decision**: A `ContactRepository` protocol (CRUD + search/filter query methods) backed by a
  `SwiftDataContactRepository` implementation that owns the `ModelContext`.
- **Rationale**: Matches the constitution's explicit requirement for a `ContactRepository`
  protocol; lets `ContactFilteringTests` and `SwiftDataContactRepositoryTests` run against the
  protocol (or an in-memory `ModelContainer`) without coupling tests to SwiftUI's `@Query`
  property wrapper, which is view-layer-only.
- **Alternatives considered**: Direct `@Query` usage inside views with no repository layer —
  simplest option, but fails the constitution's protocol-boundary principle and makes filtering
  logic harder to unit test in isolation from SwiftUI.

## Search/filter execution

- **Decision**: Implement search (name-or-company) and relationship-category filtering as a pure
  function (`ContactFiltering`) operating over an in-memory array of already-fetched contacts,
  invoked by the view model; not as a SwiftData `#Predicate` compiled into the fetch.
- **Rationale**: At the stated scale (~1,000 contacts), fetching all contacts and filtering in
  memory comfortably meets the 100ms responsiveness goal, and keeps the filtering logic as a
  plain, fully unit-testable function independent of SwiftData — directly satisfying the spec's
  "unit tests for contact filtering/search logic" requirement.
- **Alternatives considered**: `#Predicate`-based SwiftData fetch filtering — scales better past
  tens of thousands of records, but is harder to unit test in isolation and is unnecessary
  complexity at this spec's scale. Can be revisited if real-world usage outgrows in-memory
  filtering.

## Relationship strength representation

- **Decision**: A small closed `Int` scale (1–5) stored on `NetworkingContact`, presented in the
  UI as a discrete control (e.g. a segmented/stepper-style picker) rather than free text.
- **Rationale**: Keeps the field structured and testable (bounded range is easy to validate and
  to reason about later for any "recently neglected relationship" logic in future specs) while
  staying simple enough not to need its own entity.
- **Alternatives considered**: Free-text strength — rejected, not structured enough to filter or
  reason about later. A named enum (e.g. weak/medium/strong) — viable alternative, but a bounded
  integer scale is simpler to persist and to extend (e.g. averaging) without a migration later.
