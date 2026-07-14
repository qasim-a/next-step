# Feature Specification: Core Data & Contact Management

**Feature Branch**: `001-contact-management`

**Created**: 2026-07-14

**Status**: Draft

**Input**: User description: "Specification 1: Core data and contact management for NextStep, a native iOS relationship and follow-up tracker for job seekers. Scope: SwiftData models for NetworkingContact and Company, a searchable/filterable contact list, contact creation and editing via a sheet, a contact detail screen, and search/filtering by name, company, and relationship category. Out of scope: interaction logging/timeline, follow-ups/notifications, companies-as-first-class entities and opportunities, dashboard/insights, experiments/analytics, message drafts, business-card scanning, calendar integration, App Intents, widgets. The app intentionally does not replace the iOS Contacts app — only networking-specific fields are stored. Unit tests for filtering/search and repository behavior are part of this spec's definition of done."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture a new contact right after meeting someone (Priority: P1)

A job seeker just finished talking to a recruiter, alumnus, or engineer — at a career fair, on a call, or over LinkedIn — and wants to save what they learned before they forget it: who the person is, where they work, and how the two of them connected.

**Why this priority**: This is the entry point for every other piece of value in the app. Without the ability to capture a contact, there is nothing to search, view, or follow up on later.

**Independent Test**: Can be fully tested by creating a contact with just a name, saving it, and confirming it now appears in the contact list — delivers value on its own even before any other feature exists.

**Acceptance Scenarios**:

1. **Given** the user is on the contact list, **When** they choose to add a new contact and enter at least a name, **Then** the contact is saved and appears in the contact list.
2. **Given** the user is adding a new contact, **When** they fill in company, job title, email or LinkedIn profile, how they met, relationship category, relationship strength, and personal notes, **Then** all of those details are saved with the contact.
3. **Given** the user is adding a new contact, **When** they try to save without entering a name, **Then** the app prevents saving and indicates that a name is required.
4. **Given** the user is adding a new contact, **When** they cancel the creation flow, **Then** no contact is created and they return to where they started.

---

### User Story 2 - Find a contact again quickly (Priority: P2)

Weeks later, the user wants to recall details about someone they met — either because they're preparing for a follow-up or because a new contact reminds them of someone at the same company.

**Why this priority**: A contact list that can't be searched or filtered stops being useful once it has more than a handful of entries — this is what makes stored contacts actually retrievable.

**Independent Test**: Can be fully tested by seeding several contacts across different companies and relationship categories, then confirming that searching by name/company and filtering by relationship category each narrow the list to the expected contacts.

**Acceptance Scenarios**:

1. **Given** a list of contacts, **When** the user types part of a contact's name into search, **Then** only contacts whose name matches are shown.
2. **Given** a list of contacts, **When** the user types part of a company name into search, **Then** only contacts at matching companies are shown.
3. **Given** a list of contacts, **When** the user filters by a relationship category (e.g., recruiter), **Then** only contacts in that category are shown.
4. **Given** a list of contacts, **When** the user's search or filter matches no contacts, **Then** the app shows a clear empty-results state rather than an empty blank screen.
5. **Given** a list of contacts, **When** the user clears their search or filter, **Then** the full contact list is shown again.

---

### User Story 3 - Review and update a contact over time (Priority: P3)

The user opens a specific contact to review everything they know about that relationship, and updates details as circumstances change — a new job title, an updated relationship strength, or a correction to how they described the connection.

**Why this priority**: Networking relationships evolve; the app needs to let details be corrected and enriched, but this is only valuable once contacts can already be created and found (Stories 1 and 2).

**Independent Test**: Can be fully tested by opening an existing contact, changing one or more fields, saving, and confirming the contact detail and list both reflect the update; and by deleting a contact and confirming it no longer appears anywhere.

**Acceptance Scenarios**:

1. **Given** an existing contact, **When** the user opens it, **Then** they see all of that contact's stored fields.
2. **Given** an existing contact's detail view, **When** the user edits one or more fields and saves, **Then** the updated values are persisted and reflected immediately in both the detail view and the contact list.
3. **Given** an existing contact's detail view, **When** the user edits fields but cancels instead of saving, **Then** the contact's stored data is unchanged.
4. **Given** an existing contact, **When** the user deletes it and confirms the deletion, **Then** the contact no longer appears in the contact list or in search results.

---

### Edge Cases

- What happens when the user tries to save a contact with only whitespace in the name field? Treated the same as an empty name — save is blocked.
- What happens when two contacts share the exact same name? Both are kept as separate contacts; the app does not attempt de-duplication in this spec.
- What happens when the contact list is empty (first launch, or all contacts deleted)? The app shows guidance on how to add the first contact rather than a blank screen.
- What happens when a user enters an extremely long note or an implausible relationship-strength value? The app accepts and stores free-text notes up to a reasonable length and constrains relationship strength to a fixed, valid range.
- What happens when the user backgrounds or force-quits the app mid-edit without saving? Unsaved edits are discarded; previously saved data is untouched.
- What happens when search text matches a contact by company but not by name, or vice versa? The contact is still shown, since search matches across both fields.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create a new networking contact by providing at minimum a name.
- **FR-002**: Users MUST be able to optionally provide, at creation or later, a contact's company, job title, email or LinkedIn profile, how they met, relationship category, relationship strength, and personal notes.
- **FR-003**: System MUST prevent saving a contact whose name is empty or blank.
- **FR-004**: System MUST offer a fixed set of relationship categories to choose from: recruiter, referral, alumnus, hiring manager, peer.
- **FR-005**: System MUST let users record a relationship strength for a contact.
- **FR-006**: System MUST let users record a last-interaction date on a contact.
- **FR-007**: Users MUST be able to view a list of all saved contacts.
- **FR-008**: Users MUST be able to search the contact list by contact name and by company name simultaneously (a single search matches either field).
- **FR-009**: Users MUST be able to filter the contact list by relationship category.
- **FR-010**: Search and category filtering MUST be usable together, narrowing the list to contacts that satisfy both.
- **FR-011**: Users MUST be able to open a contact to view all of its stored fields on a dedicated detail view.
- **FR-012**: Users MUST be able to edit an existing contact's fields and save the changes.
- **FR-013**: Users MUST be able to discard in-progress edits without changing the previously saved contact.
- **FR-014**: Users MUST be able to delete a contact, with confirmation required before the deletion is final.
- **FR-015**: System MUST persist all contact data locally on-device so it survives app restarts.
- **FR-016**: Contact creation and editing MUST be presented as a temporary overlay to the current screen rather than as a permanent, separately navigable section of the app.
- **FR-017**: System MUST NOT require or attempt to import, sync with, or replace entries from the device's system Contacts app in this spec.
- **FR-018**: The contact detail view MUST be structured so that future sections (interaction history, opportunities) can be added without restructuring the fields defined in this spec.

### Key Entities

- **Networking Contact**: A person the user has networked with. Holds identity and relationship information: name (required), company, job title, email or LinkedIn profile, how the user met them, relationship category (recruiter, referral, alumnus, hiring manager, or peer), relationship strength, personal notes, and last-interaction date. Intentionally limited to networking-relevant fields, not a general-purpose contact card.
- **Company**: A lightweight named association a contact can belong to (e.g., "UBS"), used to group and search contacts by employer in this spec. Becomes a richer, independently browsable entity with opportunities attached in a later spec.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can capture a new contact (name only) in under 15 seconds.
- **SC-002**: A user can locate a specific contact by name or company, out of 200 saved contacts, in under 5 seconds.
- **SC-003**: 100% of contacts and their field values remain correctly available after force-quitting and relaunching the app.
- **SC-004**: A user can narrow the contact list to a single relationship category in one interaction.
- **SC-005**: Users can edit and save an existing contact's details with zero data loss across 100% of attempts in testing.
- **SC-006**: A first-time user with zero contacts is shown clear guidance for adding their first contact, rather than an unexplained empty screen.

## Assumptions

- Single local user on a single device; no multi-user accounts, sign-in, or cross-device sync exist in this spec.
- Contact name is the only required field; every other field can be left blank at creation and filled in later.
- "Last interaction date" is a manually editable field in this spec, since interaction logging does not exist yet; a later specification will populate it automatically from logged interactions.
- Company is a lightweight, name-based association in this spec (not yet a separately browsable directory with its own detail screen); that comes with the opportunities specification.
- No contact photo capture or business-card scanning is included in this spec.
- Relationship categories are fixed to the five named in the product brief; custom/user-defined categories are out of scope for v1.
- Deleting a contact is a permanent action once confirmed; no undo/trash/recovery is provided in this spec.
- No interaction timeline, follow-ups, notifications, dashboard, experiments, or message drafting are part of this spec, even though the data model and detail screen should not block adding them later.
