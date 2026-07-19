# Feature Specification: Follow-ups and Notifications

**Feature Branch**: `003-followups-notifications`

**Created**: 2026-07-19

**Status**: Draft

**Input**: User description: "Specification 3: Follow-ups and notifications for NextStep, building on Specifications 1 (contacts) and 2 (interactions). A FollowUp record (due date, priority, suggested action, completion status) tied to a contact and optionally an interaction. Users create follow-ups explicitly from a contact's detail screen, optionally pre-filled from an interaction's next-action text. A new Today tab becomes the app's first tab, showing follow-ups grouped into Due Today, Overdue, Upcoming, and Recently Completed. Users can complete, reschedule, edit, and delete follow-ups. The app requests notification permission and schedules a local reminder for each incomplete follow-up's due date, rescheduling or canceling as follow-ups change, degrading gracefully if permission is denied. Tapping a notification opens the relevant contact. Out of scope: Insights/Settings tabs, experiments/analytics, companies/opportunities, message drafts, business-card scanning, calendar integration, App Intents, widgets, auto-generating follow-ups. Notification scheduling goes through a protocol boundary for testability. Unit tests for due-date bucketing and repository/notification behavior, plus XCUITest coverage, are part of this spec's definition of done."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture a follow-up for a contact (Priority: P1)

After talking with a contact, the user decides they need to do something next — send a link, wait for a reply, check back in a few weeks — and creates a follow-up for that contact with a due date and, optionally, a note about what to do.

**Why this priority**: This is the entry point for everything else in this spec — without a way to capture a follow-up, there is nothing for the Today screen to show or notifications to remind about.

**Independent Test**: Can be fully tested by opening a contact, creating a follow-up with just a due date, and confirming it is saved (verifiable directly even before the Today screen exists to display it). Also test creating one from an interaction's next-action text and confirming the suggested action is pre-filled but editable.

**Acceptance Scenarios**:

1. **Given** a contact's detail screen, **When** the user creates a follow-up specifying a due date, **Then** the follow-up is saved for that contact.
2. **Given** the follow-up creation form, **When** the user also sets a priority and a suggested action, **Then** both are saved with the follow-up.
3. **Given** an interaction that has next-action text, **When** the user creates a follow-up from it, **Then** the suggested action field starts pre-filled with that text and can still be edited before saving.
4. **Given** the follow-up creation form, **When** the user cancels instead of saving, **Then** no follow-up is created.
5. **Given** any contact, **When** the user has not created a follow-up for it, **Then** nothing is created automatically — follow-ups only exist when a user explicitly creates one.

---

### User Story 2 - See what needs attention today (Priority: P2)

The user opens the app and wants to immediately see who they're overdue to follow up with, who needs attention today, what's coming up, and what they've recently wrapped up — without hunting through individual contacts.

**Why this priority**: This is the app's central value, but it only becomes useful once follow-ups exist to show (Story 1) — it is the second priority because it depends on that data existing.

**Independent Test**: Can be fully tested by creating follow-ups with due dates in the past, today, and the future for different contacts, then confirming the Today screen groups them correctly into Overdue, Due Today, and Upcoming sections without requiring navigation into individual contacts.

**Acceptance Scenarios**:

1. **Given** follow-ups with due dates before today that are not completed, **When** the user opens the Today screen, **Then** they appear in an Overdue section.
2. **Given** follow-ups due today that are not completed, **When** the user opens the Today screen, **Then** they appear in a Due Today section.
3. **Given** follow-ups due after today that are not completed, **When** the user opens the Today screen, **Then** they appear in an Upcoming section.
4. **Given** follow-ups completed within the last several days, **When** the user opens the Today screen, **Then** they appear in a Recently Completed section.
5. **Given** the app has just launched, **When** it finishes launching, **Then** the Today screen is what the user sees first.
6. **Given** no follow-ups exist yet, **When** the user opens the Today screen, **Then** it shows guidance rather than a blank, unexplained screen.

---

### User Story 3 - Act on a follow-up (Priority: P3)

Having seen what's due, the user marks something as done, pushes a due date back because plans changed, corrects a follow-up's details, or removes one that's no longer relevant.

**Why this priority**: Acting on follow-ups only matters once they exist (Story 1) and are visible somewhere to act on (Story 2).

**Independent Test**: Can be fully tested by completing a follow-up and confirming it moves out of Overdue/Due Today/Upcoming into Recently Completed; by rescheduling one and confirming it moves to the correct section for its new date; and by deleting one and confirming it disappears entirely.

**Acceptance Scenarios**:

1. **Given** an incomplete follow-up, **When** the user marks it complete, **Then** it moves to the Recently Completed section and records when it was completed.
2. **Given** an incomplete follow-up, **When** the user reschedules it to a new due date, **Then** it moves to whichever section matches the new date.
3. **Given** an existing follow-up, **When** the user edits its priority or suggested action and saves, **Then** the updated values are reflected immediately.
4. **Given** an existing follow-up, **When** the user deletes it and confirms the deletion, **Then** it no longer appears anywhere in the app.
5. **Given** a contact with follow-ups, **When** the user deletes that contact, **Then** its follow-ups are removed too.

---

### User Story 4 - Get reminded without having the app open (Priority: P4)

The user wants a nudge at the right time even if they haven't opened the app, so a follow-up doesn't quietly slip past its due date unnoticed.

**Why this priority**: This is a genuine enhancement on top of Stories 1-3, but the app's core follow-up value (capture, see, act) works completely without it — notifications are additive, not required, which is why they're last.

**Independent Test**: Can be fully tested by granting notification permission, creating a follow-up due at a specific time, and confirming a reminder arrives at that time; separately, by denying permission and confirming follow-up creation/viewing/completion/rescheduling all still work normally.

**Acceptance Scenarios**:

1. **Given** the user has not yet responded to the notification permission request, **When** a moment in the app first calls for it, **Then** the system permission prompt is shown.
2. **Given** notification permission has been granted, **When** the user creates an incomplete follow-up with a due date, **Then** a reminder is scheduled for that due date.
3. **Given** a follow-up with a scheduled reminder, **When** the user reschedules its due date, **Then** the reminder updates to match the new date.
4. **Given** a follow-up with a scheduled reminder, **When** the user completes or deletes it, **Then** the reminder is canceled.
5. **Given** notification permission has been denied, **When** the user creates, views, completes, reschedules, or deletes follow-ups, **Then** all of these continue to work exactly as they would with permission granted, simply without a reminder being sent.
6. **Given** a delivered follow-up reminder notification, **When** the user taps it, **Then** the app opens directly to that follow-up's contact.

---

### Edge Cases

- What happens when a follow-up is rescheduled to a date in the past? It's allowed and simply appears in the Overdue section, same as any other overdue follow-up.
- What happens once a "recently completed" follow-up ages out of the recent window? It stops appearing on the Today screen; its data is not deleted.
- What happens if the user grants notification permission after previously denying it? Follow-ups created or rescheduled from that point onward get reminders scheduled normally; this spec does not require retroactively scheduling reminders for follow-ups that existed before permission was granted.
- What happens when multiple follow-ups share the same due date? All of them appear in the same section, in a stable, predictable order.
- What happens when a follow-up's contact is deleted while a reminder is still pending? The reminder is canceled along with the follow-up.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create a follow-up for a contact from that contact's detail screen, specifying at minimum a due date.
- **FR-002**: Users MUST be able to optionally set a priority and a suggested action when creating or editing a follow-up.
- **FR-003**: When a follow-up is created from an interaction's next-action text, the suggested action MUST start pre-filled with that text while remaining editable before saving.
- **FR-004**: The system MUST NOT create follow-ups automatically; creating one is always an explicit user action.
- **FR-005**: The Today screen MUST group incomplete follow-ups into an Overdue section (due date before today) and a Due Today section (due date is today).
- **FR-006**: The Today screen MUST show incomplete follow-ups due after today in an Upcoming section.
- **FR-007**: The Today screen MUST show follow-ups completed within a recent window in a Recently Completed section.
- **FR-008**: Users MUST be able to mark an incomplete follow-up complete, recording when it was completed.
- **FR-009**: Users MUST be able to reschedule an incomplete follow-up to a new due date.
- **FR-010**: Users MUST be able to edit a follow-up's priority and suggested action.
- **FR-011**: Users MUST be able to delete a follow-up, with confirmation required before the deletion is final.
- **FR-012**: Deleting a contact MUST also delete its follow-ups.
- **FR-013**: The app MUST introduce tab-based navigation with Today as the first tab and Contacts as the second; launching the app MUST land on the Today tab.
- **FR-014**: The app MUST explicitly request notification permission from the user before attempting to schedule any notification; it MUST NOT assume permission is granted.
- **FR-015**: For each incomplete follow-up, the system MUST schedule a local reminder for its due date whenever notification permission has been granted.
- **FR-016**: When a follow-up's due date changes, or it becomes complete or is deleted, any previously scheduled reminder for it MUST be updated or canceled accordingly.
- **FR-017**: If notification permission is denied or not yet granted, follow-up creation, viewing, completion, rescheduling, editing, and deletion MUST all continue to work normally.
- **FR-018**: Tapping a follow-up's reminder notification MUST open the app directly to that follow-up's associated contact.

### Key Entities

- **Follow-Up**: A user-created reminder to take action with a contact — due date, priority (low/medium/high), a free-text suggested action, and completion status (with the date it was completed, once done). Belongs to exactly one Networking Contact, and may optionally reference the Interaction it was created from. Deleted automatically if its contact is deleted.
- **Networking Contact** *(extended from Specification 1)*: gains a collection of Follow-Ups.
- **Interaction** *(extended from Specification 2)*: its next-action text may be used to pre-fill a new follow-up's suggested action, but the interaction and follow-up remain otherwise independent records.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a follow-up (due date only) in under 20 seconds.
- **SC-002**: A user sees all of today's and overdue follow-ups within one screen, with no additional taps, immediately upon opening the app.
- **SC-003**: 100% of follow-ups and their completion state remain correctly available after force-quitting and relaunching the app.
- **SC-004**: Marking a follow-up complete moves it out of Overdue/Due Today/Upcoming and into Recently Completed on the same screen, with no additional navigation required.
- **SC-005**: A user who grants notification permission receives a reminder for an incomplete follow-up at its due date without the app being open.
- **SC-006**: A user who denies notification permission can still fully create, view, complete, reschedule, and delete follow-ups with no degraded functionality beyond the absence of reminders.
- **SC-007**: Deleting a contact removes its follow-ups from the Today screen and cancels any pending reminders for them, in 100% of tested scenarios.

## Assumptions

- Priority is a fixed set (low, medium, high); no custom priorities in this spec.
- The "recently completed" window is a short, fixed period (a handful of days) after which completed follow-ups quietly stop appearing on the Today screen without their data being deleted.
- Only one reminder is scheduled per follow-up; there is no escalating or repeating reminder sequence.
- If notification permission is granted after initially being denied, this spec does not require retroactively scheduling reminders for follow-ups that already existed at that point — only follow-ups created or rescheduled afterward.
- The Today tab is the app's default landing tab on launch, ahead of Contacts.
- As with Specifications 1 and 2, there is a single local user on a single device — no accounts, sign-in, or cross-device sync.
- Insights and Settings tabs are not introduced in this spec; the tab bar has exactly two tabs (Today, Contacts) after this spec.
