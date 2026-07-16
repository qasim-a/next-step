# Feature Specification: Interactions

**Feature Branch**: `002-interactions`

**Created**: 2026-07-16

**Status**: Draft

**Input**: User description: "Specification 2: Interactions for NextStep, building on Specification 1's contact management. A new Interaction record type (LinkedIn connection request, LinkedIn message, email, phone or video call, in-person meeting, interview, referral request) with date, notes, outcome, and an optional free-text next-action note. Users log interactions against a contact from that contact's detail screen, see them as a chronological timeline (most recent first), and can edit or delete them with confirmation. Logging an interaction makes the contact's last-interaction date automatic instead of manually edited, as anticipated in Specification 1's Assumptions. Out of scope: follow-ups/reminders/notifications/scheduling (next action is descriptive text only), companies/opportunities as first-class entities, dashboard/insights, experiments/analytics, message drafts, business-card scanning, calendar integration, App Intents, widgets. Unit tests for timeline ordering and repository behavior, plus XCUITest coverage for log/edit/delete, are part of this spec's definition of done."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Log an interaction right after it happens (Priority: P1)

Right after talking with a contact — a call, a coffee chat, an email exchange — the user opens
that contact and records what kind of interaction it was, when it happened, and any notes or
outcome, so the relationship's history isn't lost to memory.

**Why this priority**: This is the entry point for everything else in this spec — without the
ability to log an interaction, there's no timeline and no automatic last-interaction date.

**Independent Test**: Can be fully tested by opening an existing contact, logging an interaction
with just a type and date, and confirming it appears on that contact's timeline and updates the
contact's last-interaction date.

**Acceptance Scenarios**:

1. **Given** a contact's detail screen, **When** the user logs a new interaction choosing a type
   and date, **Then** the interaction is saved and appears on that contact's timeline.
2. **Given** the interaction-logging form, **When** the user also fills in notes, an outcome, and
   a next-action note, **Then** all of those details are saved with the interaction.
3. **Given** the interaction-logging form, **When** the user cancels instead of saving, **Then**
   no interaction is created and the contact's timeline is unchanged.
4. **Given** a contact with no prior interactions, **When** the user logs their first interaction,
   **Then** the contact's last-interaction date updates to match it.

---

### User Story 2 - See a contact's interaction history at a glance (Priority: P2)

The user opens a contact they haven't spoken to in a while and wants to quickly see everything
that's happened with them — every logged interaction, most recent first, without digging.

**Why this priority**: Capturing interactions (Story 1) only pays off once they're visible again;
this is what turns logged data into something the user actually reads before reaching out.

**Independent Test**: Can be fully tested by logging several interactions with different dates
for one contact and confirming the timeline lists them ordered from most to least recent, each
showing at least its type, date, and outcome.

**Acceptance Scenarios**:

1. **Given** a contact with multiple logged interactions, **When** the user opens that contact,
   **Then** the timeline shows every interaction ordered from most recent to oldest.
2. **Given** a contact's timeline, **When** the user looks at an entry without opening it,
   **Then** they can see that interaction's type, date, and outcome (if one was recorded).
3. **Given** a contact with zero interactions, **When** the user opens that contact, **Then** the
   timeline area shows guidance to log the first interaction rather than an empty gap.

---

### User Story 3 - Correct or remove a logged interaction (Priority: P3)

The user notices they logged something wrong — the wrong type, a typo in the notes, the wrong
date — or realizes an interaction shouldn't have been logged at all, and fixes it.

**Why this priority**: Data entry mistakes are inevitable; this keeps the timeline (Story 2)
trustworthy, but only matters once interactions already exist to correct (Story 1) and are
visible to notice mistakes in (Story 2).

**Independent Test**: Can be fully tested by editing an existing interaction's fields and
confirming the timeline reflects the change, and by deleting an interaction (confirming the
prompt) and confirming it disappears from the timeline and the contact's last-interaction date
recalculates correctly.

**Acceptance Scenarios**:

1. **Given** an existing interaction, **When** the user opens it and changes its type, date,
   notes, outcome, or next-action note, then saves, **Then** the timeline reflects the updated
   values immediately.
2. **Given** an existing interaction being edited, **When** the user cancels instead of saving,
   **Then** the interaction's stored data is unchanged.
3. **Given** an existing interaction, **When** the user deletes it and confirms the deletion,
   **Then** it no longer appears on the timeline.
4. **Given** a contact whose most recent interaction is deleted, **When** the deletion completes,
   **Then** the contact's last-interaction date updates to its next most recent interaction, or
   to "none recorded" if no interactions remain.

---

### Edge Cases

- What happens when a user logs an interaction dated in the future (e.g., recording plans made
  during a call)? Accepted — interaction dates are not restricted to the past.
- What happens when two interactions for the same contact share the exact same date? Both are
  shown on the timeline; a secondary, stable ordering (creation order) breaks the tie.
- What happens when a contact's last remaining interaction is deleted? The timeline returns to
  its empty-guidance state, and the contact's last-interaction date reverts to "none recorded."
- What happens when an interaction is logged with only a type and date, leaving notes, outcome,
  and next-action blank? Allowed — those fields are optional.
- What happens to a contact's interactions when the contact itself is deleted? They are deleted
  along with it; no orphaned interactions remain.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to log a new interaction for a specific contact from that
  contact's detail screen.
- **FR-002**: Each interaction MUST record a type, chosen from a fixed set: LinkedIn connection
  request, LinkedIn message, email, phone or video call, in-person meeting, interview, referral
  request.
- **FR-003**: Each interaction MUST record a date, defaulted to today and editable by the user.
- **FR-004**: Users MUST be able to optionally record notes, an outcome, and a free-text
  next-action note on an interaction, at logging time or later.
- **FR-005**: The contact detail screen MUST show that contact's interactions as a chronological
  timeline, ordered most recent first.
- **FR-006**: Each timeline entry MUST show, without being opened, at least its type, date, and
  outcome if one was recorded.
- **FR-007**: Users MUST be able to open an existing interaction and edit any of its fields.
- **FR-008**: Users MUST be able to discard in-progress edits to an interaction without changing
  its previously saved data.
- **FR-009**: Users MUST be able to delete an interaction, with confirmation required before the
  deletion is final.
- **FR-010**: System MUST keep each contact's last-interaction date equal to the date of its most
  recently dated interaction, recalculating it whenever an interaction is logged, edited, or
  deleted for that contact.
- **FR-011**: When a contact has no interactions, its last-interaction date MUST reflect "none
  recorded" rather than a stale or default value.
- **FR-012**: Deleting a contact MUST also delete all of that contact's interactions; no
  interaction may reference a contact that no longer exists.
- **FR-013**: A contact with zero interactions MUST show guidance to log the first one, not an
  empty or broken timeline section.
- **FR-014**: This spec MUST NOT create, schedule, or notify about any follow-up/reminder — the
  next-action note is descriptive text only.

### Key Entities

- **Interaction**: A single logged instance of contact with a person — type (one of the fixed
  set above), date, notes, outcome, and an optional next-action note. Belongs to exactly one
  Networking Contact; deleted automatically if that contact is deleted.
- **Networking Contact** *(extended from Specification 1)*: gains a collection of Interactions
  and a last-interaction date that is now derived from them instead of manually set.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can log an interaction (type + date only) in under 20 seconds.
- **SC-002**: A user can see a contact's most recent interaction within one glance of opening
  that contact's detail screen, with no additional taps.
- **SC-003**: 100% of logged interactions and their field values remain correctly available
  after force-quitting and relaunching the app.
- **SC-004**: A contact's last-interaction date matches its most recently dated interaction in
  100% of create/edit/delete scenarios tested, including when the most recent interaction is
  removed.
- **SC-005**: Editing or deleting an interaction is reflected on the timeline immediately, without
  the user needing to leave and reopen the contact.
- **SC-006**: A contact with zero interactions shows clear guidance to log the first one, rather
  than an unexplained empty section.

## Assumptions

- Interaction type is fixed to the seven types named in the product brief; custom/user-defined
  types are out of scope for this spec.
- Interaction dates are not restricted to the past; users may log interactions dated in the
  future (e.g., noting plans made during a call).
- The next-action note is purely descriptive in this spec — it does not create a schedulable
  reminder or appear on any follow-up list; that capability arrives in Specification 3, which may
  read this field but does not act on it yet.
- Deleting a contact cascades to delete all of its interactions; there is no orphaned-interaction
  state and no separate interaction browsing surface outside a contact's own timeline.
- No limit is placed on how many interactions a single contact may have in this spec.
- As in Specification 1, there is a single local user/device with no accounts, sign-in, or
  cross-device sync.
