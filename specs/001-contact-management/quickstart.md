# Quickstart: Core Data & Contact Management

Validation guide for this spec once implementation is complete. See [data-model.md](./data-model.md)
for field details and [contracts/contact-repository.md](./contracts/contact-repository.md) for the
persistence boundary being exercised.

## Prerequisites

- Xcode 16+ with an iOS 17+ simulator installed.
- Repository checked out on branch `001-contact-management`.

## Build & run

```bash
open NextStep.xcodeproj
# Select the "NextStep" scheme and an iOS 17+ simulator, then Run (Cmd+R)
```

## Run automated tests

```bash
# Unit tests (Swift Testing): ContactFiltering + SwiftDataContactRepository
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:NextStepTests

# UI tests (XCUITest): full contact management flow
xcodebuild test -project NextStep.xcodeproj -scheme NextStep \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:NextStepUITests
```

Expected: all tests pass; `ContactFilteringTests` and `SwiftDataContactRepositoryTests` cover the
scenarios below at the unit level, `ContactManagementFlowUITests` covers them end-to-end.

## Manual validation scenarios

These mirror spec.md's acceptance scenarios — walk through them once in the simulator after
implementation to confirm the feature works end-to-end, not just in tests.

1. **Create a contact (User Story 1)**
   - Launch the app with zero contacts → see the empty-state guidance (SC-006), not a blank screen.
   - Add a contact with only a name → it appears in the list immediately.
   - Add another contact filling in every field (company, title, contact handle, how met,
     category, strength, notes) → all fields save and are visible on its detail screen.
   - Try saving a new contact with an empty name → save is blocked with a clear message.
   - Start creating a contact, then cancel → no new contact appears in the list.

2. **Find a contact (User Story 2)**
   - With several contacts across different companies/categories saved, search by a partial name
     → only matching contacts show.
   - Search by a partial company name → only contacts at matching companies show.
   - Filter by a relationship category (e.g. "recruiter") → only that category shows.
   - Combine search + category filter → results satisfy both.
   - Search for something matching nothing → see a clear empty-results state, not a blank screen.
   - Clear search/filter → full list returns.

3. **Review, edit, delete (User Story 3)**
   - Open a contact → all stored fields are visible on the detail screen.
   - Edit a field (e.g. job title) and save → change reflected on both the detail screen and back
     in the list.
   - Edit a field but cancel instead of saving → original value is unchanged.
   - Delete a contact (confirm the deletion prompt) → it disappears from the list and from search
     results.

4. **Persistence (SC-003)**
   - Force-quit the app after making several changes, relaunch → all contacts and their field
     values are exactly as left.

## Out of scope for this validation pass

Interaction timeline, follow-ups/reminders, opportunities, dashboard/insights, message drafts,
and experiments are not part of this spec — do not expect to see them yet (see spec.md
Assumptions).
