# Feature Specification: Polish

**Feature Branch**: `005-polish`

**Created**: 2026-07-21

**Status**: Draft

**Input**: User description: "Specification 5: Polish — the final specification in the NextStep
constitution's five-spec sequence (Principle IV). Scope: (1) cross-app visual/UX polish that spans
all screens built in Specs 1-4 (dark mode spot-checks, Dynamic Type support, consistent
empty-state/transition treatment, app icon and launch screen if not already set), (2) continuous
integration via GitHub Actions running the full NextStepTests + NextStepUITests suite on every
push/PR, and (3) exactly one "advanced feature beyond the MVP" as the constitution allows selecting
at most one or two afterward — a home-screen widget (WidgetKit) showing the user's next 1-3
due-today/overdue follow-ups, read-only (tapping it opens the app to the Today screen; no
interactivity inside the widget itself, since that would require App Intents which is out of
scope). Explicitly out of scope: message-generation assistant, business-card scanning, calendar
integration, App Intents, and any other advanced feature beyond the one widget. Target user: the
same solo job-seeker persona as Specs 1-4, who now wants the app to feel finished/shippable and to
glance at their next follow-up from the home screen without opening the app."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A finished-feeling app, not a prototype (Priority: P1)

As a job seeker using NextStep day-to-day, I want the app to look and feel like a real, finished
product — legible in dark mode, readable at larger text sizes, with a real icon instead of a
placeholder — so that using it (and showing it to someone else) doesn't feel like using an
unfinished prototype.

**Why this priority**: This is the only part of this spec with direct, felt value every time the
app is opened — unlike the widget (one screen) or CI (invisible to the user entirely), this touches
every screen built across Specs 1-4. It's also the natural first pass: fixing the app icon comes
before building a widget that needs an icon-adjacent set of assets, and dark-mode/Dynamic Type
fixes are prerequisites for the app being screenshot- or demo-ready at all.

**Independent Test**: Can be fully tested by switching the simulator/device to dark mode and to the
largest three Dynamic Type accessibility sizes, then walking through every screen from Specs 1-4
(Contacts list/detail/form, interaction timeline/form, Today screen, follow-up form, Insights,
Developer Info) confirming nothing is illegible, clipped, or unreadable — independent of whether
CI or the widget exist yet.

**Acceptance Scenarios**:

1. **Given** the system is set to dark mode, **When** any screen from Specs 1-4 is viewed, **Then**
   all text remains legible against its background and no custom-colored element (e.g. priority
   badges) becomes unreadable.
2. **Given** the system's text size is set to one of the largest three accessibility sizes, **When**
   any screen from Specs 1-4 is viewed, **Then** text wraps or scrolls rather than being truncated
   or overlapping other elements, and every interactive control remains tappable.
3. **Given** the app is freshly installed, **When** it appears on the home screen or in the app
   switcher, **Then** it shows a custom icon, not the system-default placeholder icon.
4. **Given** the app is cold-launched, **When** the launch screen briefly appears, **Then** it is a
   deliberate, branded screen rather than a blank system-generated placeholder.

---

### User Story 2 - See tomorrow's follow-up without opening the app (Priority: P2)

As a job seeker, I want to glance at my phone's home screen and see my next couple of follow-ups
without unlocking into the app, so I can stay aware of who I need to reach out to throughout the
day.

**Why this priority**: This is the one net-new, user-visible feature in this spec — real value, but
scoped to a single screen (the widget) rather than spanning the whole app like User Story 1, and it
depends on nothing else in this spec to be useful on its own.

**Independent Test**: Can be fully tested by adding the widget to a home screen with a mix of
overdue, due-today, and completed-only follow-ups, confirming it shows the correct up-to-3
follow-ups in the correct priority order, and that tapping it opens the app directly to the Today
screen.

**Acceptance Scenarios**:

1. **Given** the user has overdue and due-today follow-ups, **When** the widget is added to a home
   screen, **Then** it shows up to 3 of them, most-urgent-first (overdue before due-today).
2. **Given** the user has no overdue or due-today follow-ups (only upcoming or none at all),
   **When** the widget is viewed, **Then** it shows a clear "nothing due" state rather than an
   empty or broken layout.
3. **Given** the widget is showing a follow-up, **When** the user taps it, **Then** the app opens
   directly to the Today screen.
4. **Given** a follow-up shown on the widget is completed, rescheduled, or deleted from within the
   app, **When** the widget's content next refreshes, **Then** it reflects the change — it does not
   need to update instantly to the second, but it must not show stale data indefinitely.

---

### User Story 3 - Confidence that changes don't break the app (Priority: P3)

As the person maintaining NextStep, I want every push and pull request to automatically run the
full test suite, so that a regression is caught before it's merged rather than discovered later by
hand.

**Why this priority**: Purely a development-process safeguard with zero effect on what the app
looks like or does for its end user — valuable, but the lowest priority because nothing in Specs
1-4 has depended on it existing, and the project has shipped four specifications' worth of working,
tested software without it so far.

**Independent Test**: Can be fully tested by opening a pull request (or pushing a commit) with a
deliberately broken test and confirming the CI run reports failure; then fixing it and confirming
the same run reports success — independent of User Stories 1-2.

**Acceptance Scenarios**:

1. **Given** a commit is pushed to any branch, **When** the CI workflow runs, **Then** it builds the
   app and runs the full `NextStepTests` unit suite, reporting pass/fail.
2. **Given** a pull request is opened, **When** the CI workflow runs, **Then** its pass/fail status
   is visible on the pull request before merging.
3. **Given** a test is failing, **When** the CI workflow runs, **Then** the run is marked failed and
   the failing test(s) are identifiable from the run's output.

---

### Edge Cases

- What happens to the widget when the user has never created a follow-up at all? Same "nothing
  due" empty state as User Story 2's Acceptance Scenario 2 — not a distinct state, since from the
  widget's perspective "no follow-ups exist" and "no follow-ups are due" look identical and need no
  different treatment.
- What happens to the widget if notification/reminder permission was denied? Nothing — the widget
  reads the same on-device follow-up data the Today screen does, entirely independent of
  notification permission (see Specification 3, FR-017's precedent: the rest of the app keeps
  working regardless of notification permission).
- What happens to the CI run's UI-test job if the hosted runner's simulator behaves flakily (a
  documented recurring issue in this project's own history, per `AI_USAGE.md`)? Out of scope to
  solve generally in this spec; the workflow should still run and report accurately, even if that
  means an occasional environmentally-flaky failure — retry logic is not required.
- How does Dynamic Type interact with the Today screen's four sections and the developer screen's
  event list, which can already be long? Scrolling is expected and acceptable; the requirement is
  no clipping/truncation of individual rows, not that everything fits without scrolling.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every screen introduced in Specifications 1-4 MUST remain legible in dark mode — no
  hard-coded colors that become invisible or illegible against a dark background.
- **FR-002**: Every screen introduced in Specifications 1-4 MUST remain usable (no truncated or
  overlapping text, no untappable controls) at the three largest Dynamic Type accessibility sizes.
- **FR-003**: The app MUST have a custom app icon, replacing the system-default placeholder, visible
  on the home screen, in the app switcher, and in Settings.
- **FR-004**: The app MUST have a deliberate launch screen, replacing the blank system-generated
  default.
- **FR-005**: System MUST provide a home-screen widget showing the user's next follow-ups due today
  or overdue, ordered most-urgent-first (overdue before due-today), showing up to 3.
- **FR-006**: The widget MUST show a distinct "nothing due" state when there are no overdue or
  due-today follow-ups, rather than an empty or broken layout.
- **FR-007**: Tapping the widget MUST open the app directly to the Today screen.
- **FR-008**: The widget's content MUST refresh to reflect completions, reschedulings, deletions,
  and new follow-ups within a reasonable interval — it is not required to update instantly, but
  MUST NOT display indefinitely stale data (see Success Criteria for the specific bound).
- **FR-009**: The widget MUST read the same on-device follow-up data the rest of the app uses; it
  MUST NOT require any additional permission beyond what Specifications 1-4 already require.
- **FR-010**: A continuous integration workflow MUST run automatically on every push and on every
  pull request.
- **FR-011**: The CI workflow MUST build the app and run the full `NextStepTests` unit test suite,
  reporting pass/fail status.
- **FR-012**: The CI workflow's pass/fail status MUST be visible from the pull request or commit
  that triggered it, without requiring the maintainer to manually re-run anything locally to see
  the result.

### Key Entities

- No new persisted data entities. The widget reads existing `FollowUp`/`NetworkingContact` data
  (Specifications 1 and 3); this spec adds a presentation surface, not new data.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every screen from Specifications 1-4 is confirmed legible and usable in both dark
  mode and at the largest three Dynamic Type sizes, with zero unreadable or clipped elements found
  during a full manual pass.
- **SC-002**: The app shows a custom icon and a deliberate launch screen on 100% of cold launches
  and home-screen views — never the system-default placeholder.
- **SC-003**: A user can see their next due follow-up from the home screen without unlocking into
  the app, and the widget's content is never more than 15 minutes stale relative to the last change
  made in the app (WidgetKit's standard background-refresh budget, not a custom polling mechanism).
- **SC-004**: 100% of pushes and pull requests produce a visible CI pass/fail result without any
  manual step by the maintainer.

## Assumptions

- "Cross-app visual/UX polish" means auditing and fixing what Specifications 1-4 already built, not
  redesigning any screen's layout or information architecture — this spec fixes legibility and
  finish, not structure.
- The widget shows read-only content with no in-widget interactivity (no complete/snooze buttons
  inside the widget) — that would require App Intents, explicitly out of scope per the user's
  description. The only interaction is tapping the widget to open the app.
- The 15-minute staleness bound in SC-003 follows from WidgetKit's own platform-standard timeline
  refresh budget (the system decides exact refresh timing, not the app), not a spec-specific
  requirement invented for this feature — an app cannot force more frequent updates than the system
  allows without unusual cost to battery life, which would conflict with treating this as a
  lightweight glanceable surface.
- CI (User Story 3) targets the unit test suite (`NextStepTests`) specifically. The full
  `NextStepUITests` XCUITest suite may also run in CI if the hosted runner's simulator proves
  reliable enough during planning/implementation, but is not a hard requirement of this spec —
  this project's own history (`AI_USAGE.md`) documents real, unresolved simulator flakiness even
  in local runs, and CI infrastructure work to fully solve that is out of scope for a "polish" spec.
- No new backend, account system, or push-notification infrastructure is introduced by the widget —
  it stays fully on-device and local-first, consistent with Principle I.
