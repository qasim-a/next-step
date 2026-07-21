# Feature Specification: Experiments & Analytics

**Feature Branch**: `004-experiments-analytics`

**Created**: 2026-07-21

**Status**: Draft

**Input**: User description: "Specification 4: Experiments & Analytics — per the NextStep
constitution's Principle VI (Observable Experimentation) and Principle IV's sequence, this spec
adds: an AnalyticsTracking protocol that records key events (reminder displayed, contact opened,
follow-up completed, reminder dismissed, follow-up rescheduled) through OSLog-backed structured
logging; an ExperimentProviding protocol with deterministic (not random-per-launch) variant
assignment for reminder-copy experiments; and a hidden developer screen where the user can inspect
tracked analytics events and current experiment assignments. Target user: the same solo
job-seeker persona as Specs 1-3, who now wants basic visibility into their own follow-up behavior
(e.g. completion rates) and the app wants a lightweight internal way to A/B test reminder copy.
Keep scope to what the constitution already commits to — do not invent new features beyond the
AnalyticsTracking/ExperimentProviding protocols, event tracking, deterministic variant assignment,
and the inspection screen."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See how I'm doing on follow-ups (Priority: P1)

As a job seeker who has been using NextStep for a while, I want to see a simple summary of how
consistently I'm actually completing my follow-ups — not just the raw list on the Today screen —
so I can tell whether I'm falling behind on staying in touch with my network.

**Why this priority**: This is the only part of this spec with direct, everyday value to the
person using the app. Everything else in this spec is engineering infrastructure (event logging,
experiment plumbing) that exists to support future decisions, not to be looked at by the end user
today. This is also the smallest independently-shippable slice — it can be built from data the app
already has (`FollowUp.isCompleted`), without needing the analytics event log to exist first.

**Independent Test**: Can be fully tested by completing, rescheduling, and leaving overdue a mix
of follow-ups, then opening the summary and confirming the counts and completion rate match what
was actually done — independent of whether any analytics events or experiments exist yet.

**Acceptance Scenarios**:

1. **Given** a mix of completed and incomplete follow-ups across several contacts, **When** the
   user opens the follow-up summary, **Then** they see a completion rate (completed ÷ total,
   excluding follow-ups still pending) and counts broken out by status (completed, overdue, still
   upcoming).
2. **Given** no follow-ups have ever been created, **When** the user opens the summary, **Then**
   they see guidance that there's nothing to summarize yet, not a zero-filled or broken view.
3. **Given** the user just completed a follow-up from the Today screen, **When** they open the
   summary immediately after, **Then** the completion rate and counts already reflect that change.

---

### User Story 2 - Consistent reminder wording per person (Priority: P2)

As the app's internal behavior (not something the user directly interacts with), NextStep should
consistently show the same person the same phrasing of its follow-up reminder notifications,
rather than a different random wording every time — so that if this data is ever examined later,
differences in behavior between wording variants can be attributed to the wording itself rather
than to random noise.

**Why this priority**: This has no visible UI of its own — it changes notification copy — so it
delivers less direct, immediate value than User Story 1, but it's a named, specific commitment in
the constitution (deterministic, not random-per-launch, variant assignment) and is a prerequisite
for User Story 3 having anything meaningful to display.

**Independent Test**: Can be fully tested by triggering the reminder-scheduling path multiple
times for the same on-device identity across separate app launches and confirming the notification
body text is always the same variant, while a different fresh install may consistently land on
either variant.

**Acceptance Scenarios**:

1. **Given** a fresh install of the app, **When** the first follow-up reminder is scheduled,
   **Then** the app assigns one of the two reminder-copy variants and that assignment does not
   change on subsequent launches.
2. **Given** an existing variant assignment, **When** additional follow-up reminders are scheduled
   later, **Then** their notification text uses the same previously-assigned variant.
3. **Given** two separate fresh installs, **When** each schedules its first reminder, **Then** it
   is possible (not guaranteed) for them to land on different variants, confirming assignment is
   per-installation rather than hard-coded to one variant.

---

### User Story 3 - Inspect what's being tracked (Priority: P3)

As someone reviewing or demonstrating the app (developer, or a technically curious user who found
a hidden entry point), I want a simple screen listing the analytics events NextStep has recorded
and which reminder-copy variant this install was assigned, so I can verify the tracking described
in User Stories 1-2 is actually happening and inspect it without attaching a debugger.

**Why this priority**: Purely a verification/debugging aid layered on top of User Stories 1-2 —
it has no value if those aren't already emitting events, and no end user needs it to use the app
day-to-day. Lowest priority, but still in scope because the constitution explicitly requires
tracked events to be inspectable.

**Independent Test**: Can be fully tested by performing actions that are known to emit each of the
five tracked event types (see FR-001 through FR-005), then opening the developer screen and
confirming each event appears with its type and timestamp, most-recent-first, alongside the
current experiment variant assignment.

**Acceptance Scenarios**:

1. **Given** the app has recorded at least one of each tracked event type, **When** the user
   reaches the developer screen, **Then** they see every recorded event listed with its type and
   when it happened, ordered most-recent-first.
2. **Given** no events have been recorded yet, **When** the user reaches the developer screen,
   **Then** they see an empty-state message rather than a blank or broken list.
3. **Given** a reminder-copy variant has been assigned (User Story 2), **When** the user reaches
   the developer screen, **Then** the currently-assigned variant is displayed.

---

### Edge Cases

- What happens when a follow-up is deleted rather than completed? It MUST drop out of both the
  numerator and denominator of the completion-rate calculation in User Story 1, not count as
  either a completion or a miss.
- What happens when the analytics event log grows very large over long-term app use? The developer
  screen MUST remain responsive; the system is not required to retain events beyond a reasonable
  on-device history (see Assumptions).
- What happens if the app is reinstalled? A fresh reminder-copy variant assignment MUST be made
  (User Story 2's Acceptance Scenario 1 applies again) — variant assignment is not expected to
  survive a full uninstall/reinstall, since it is tied to on-device state, not an account.
- How does the system behave if analytics recording itself fails (e.g. an unexpected error while
  logging)? The triggering user action (opening a contact, completing a follow-up, etc.) MUST
  still succeed; a failure to record an event MUST never block or surface an error for the action
  it was tracking.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST record an analytics event whenever a follow-up reminder notification is
  displayed to the user.
- **FR-002**: System MUST record an analytics event whenever a contact's detail view is opened.
- **FR-003**: System MUST record an analytics event whenever a follow-up is marked complete.
- **FR-004**: System MUST record an analytics event whenever a reminder notification is dismissed
  without the user acting on it.
- **FR-005**: System MUST record an analytics event whenever a follow-up is rescheduled to a new
  due date.
- **FR-006**: Each recorded analytics event MUST include, at minimum, its event type, a timestamp,
  and enough identifying context (e.g. the related contact or follow-up) to be meaningful on its
  own when reviewed later.
- **FR-007**: System MUST assign each on-device installation exactly one variant of the
  reminder-copy experiment the first time a reminder is scheduled, and that assignment MUST persist
  unchanged across app launches and additional reminders for that installation.
- **FR-008**: The text of scheduled follow-up reminder notifications MUST reflect the installation's
  assigned reminder-copy variant.
- **FR-009**: System MUST provide a way to reach a developer screen from within the app that is not
  part of the app's primary tab navigation (Today / Contacts), so it stays out of the way of normal
  use while remaining reachable without a debugger or database inspection tool.
- **FR-010**: The developer screen MUST list recorded analytics events with their type and
  timestamp, ordered most-recent-first.
- **FR-011**: The developer screen MUST display the installation's current reminder-copy experiment
  variant assignment.
- **FR-012**: System MUST present a follow-up performance summary, reachable from the app's normal
  navigation (not the hidden developer screen), showing at minimum: a completion rate and counts of
  completed vs. overdue vs. still-upcoming follow-ups.
- **FR-013**: The follow-up performance summary MUST reflect the current state of the user's
  follow-ups (per Edge Cases) whenever it is viewed, without requiring an app relaunch.
- **FR-014**: All analytics events and experiment assignments MUST be stored and processed entirely
  on-device; the system MUST NOT transmit this data over the network, consistent with the app
  having no backend.
- **FR-015**: Recording an analytics event MUST NOT delay, block, or be capable of failing the
  user-facing action it accompanies.

### Key Entities

- **AnalyticsEvent**: A single recorded occurrence of one of the five tracked event types. Carries
  a type, a timestamp, and a reference to the contact and/or follow-up it relates to (where
  applicable). Immutable once recorded.
- **ExperimentAssignment**: The reminder-copy variant assigned to this on-device installation.
  Exactly one active assignment exists per experiment; created once and read thereafter, not
  re-evaluated per launch.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can see their overall follow-up completion rate within two taps from either
  main tab of the app.
- **SC-002**: All five tracked event types (reminder displayed, contact opened, follow-up
  completed, reminder dismissed, follow-up rescheduled) appear in the developer screen within one
  second of the action that triggers them.
- **SC-003**: A given on-device installation sees the same reminder-copy variant across at least
  10 consecutive app launches and reminder schedulings.
- **SC-004**: Zero analytics or experiment data leaves the device under any observable network
  activity — this app has no backend, and this spec MUST NOT introduce one.
- **SC-005**: The follow-up performance summary's numbers change within the same view session
  immediately after completing, rescheduling, or deleting a follow-up — no stale cached values.

## Assumptions

- The "hidden developer screen" is reachable via a low-prominence, discoverable-if-you-look
  affordance (e.g. a small icon or menu item tucked into an existing screen) rather than a gesture
  requiring external documentation to discover (e.g. shake-to-reveal) or a brand-new Settings tab
  — the constitution reserves a full `Features/Settings` area for later and this spec should not
  need to build one just to host a debug screen.
- "Reminder-copy experiment" means exactly two variants of the notification body text for a due
  follow-up reminder (not the in-app Today screen copy, which is out of scope for experimentation
  in this spec).
- The follow-up performance summary (User Story 1) is derived from existing `FollowUp` state
  (`isCompleted`, due dates) rather than from the analytics event log — these are two different
  data sources serving two different audiences (end user vs. developer/debug), consistent with
  the constitution treating `AnalyticsTracking` as event logging, not aggregate reporting.
- No minimum or maximum retention period is mandated for on-device analytics events beyond
  "the developer screen MUST remain responsive" (Edge Cases); the implementation may choose any
  reasonable bound (e.g. a rolling cap) without that being a spec-level requirement.
- There is exactly one experiment in scope for this spec (reminder copy). The `ExperimentProviding`
  protocol itself may be written to support more than one experiment in the future, but this spec
  does not require a second experiment to exist.
- Since NextStep has no accounts or cross-device sync, "per on-device installation" is the natural
  unit for experiment assignment — there is no user identity beyond the local install to key it to.
