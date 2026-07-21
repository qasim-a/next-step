# Phase 0 Research: Polish

No `NEEDS CLARIFICATION` markers remained in the Technical Context. This documents the rationale
behind the concrete choices made there.

## A widget extension cannot read the main app's default SwiftData store

- **Decision**: Add an App Group (e.g. `group.com.nextstep.app.NextStep`) shared by both the
  `NextStep` and `NextStepWidget` targets, and construct the `ModelContainer` in both targets with
  a `ModelConfiguration(url:)` pointing inside
  `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)` instead of the
  default per-target sandbox location the app has used since Specification 1.
- **Rationale**: iOS sandboxes each extension separately from its containing app — a Widget
  Extension is a distinct process with its own container and cannot read the main app's private
  `Application Support` directory at all. An App Group is the standard, Apple-documented mechanism
  for two targets of the same app to share on-device files, and requires no new user-facing
  permission prompt (unlike Contacts/Calendar/Notifications), so it doesn't touch Principle V.
- **Alternatives considered**: `NSUbiquitousKeyValueStore`/CloudKit sync between app and widget —
  rejected outright, introduces a cloud dependency for a same-device, same-app problem, directly
  contradicting Principle I. A separate, duplicated read-only copy of follow-up data written out
  for the widget to read — rejected as needless complexity; the App Group's shared container lets
  both targets point at the literal same SwiftData store with zero duplication.
- **Accepted consequence**: relocating the store's file location means any previously-installed
  build's on-disk data (at the old, non-App-Group location) is orphaned — SwiftData creates a fresh
  empty store at the new location. Acceptable here since this project has no real production
  install base yet; documented rather than silently accepted, since it would matter for a shipped
  app with real users.

## Keeping the widget's content fresh without custom polling

- **Decision**: The widget's `TimelineProvider` relies on WidgetKit's normal system-scheduled
  refresh budget (a `.after(date)` timeline policy, not a tight custom interval) for routine
  updates, plus an explicit `WidgetCenter.shared.reloadAllTimelines()` call added to
  `SwiftDataContactRepository`'s follow-up mutation methods (`saveFollowUp`, `completeFollowUp`,
  `deleteFollowUp`) so the widget refreshes promptly after something the user actually did in the
  app, rather than only on the system's own schedule.
- **Rationale**: iOS deliberately limits how often a widget can redraw to protect battery life —
  fighting that with aggressive custom polling isn't possible and wouldn't be good behavior even if
  it were. Explicitly requesting a reload at the exact moments data changes (mirroring how
  Specification 3's repository already triggers notification scheduling as a side effect of the
  same mutations) gets near-immediate freshness for the common case — completing a follow-up while
  the app is open — without fighting the system's passive budget, which still applies as the
  ceiling for the app-closed case. This is exactly what SC-003's "not a custom polling mechanism"
  framing describes.
- **Alternatives considered**: A fixed short timeline policy (e.g. reload every 15 minutes
  regardless of activity) — simpler, but wastes battery updating a widget that hasn't changed and
  still wouldn't reflect an in-app completion instantly, which the explicit-reload approach does
  for free.

## Generating a real app icon without external design assets

- **Decision**: Render the icon programmatically: a small SwiftUI view (a colored rounded
  background plus an SF Symbol glyph consistent with the app's own iconography — `checklist`, the
  same symbol already used for the Today tab) captured via `ImageRenderer` at each required pixel
  size, assembled into `Assets.xcassets/AppIcon.appiconset` with a generated `Contents.json`.
- **Rationale**: There is no existing brand/design asset to draw from, and this project has no
  design tool in its toolchain — a programmatically generated icon, reusing a symbol already
  established elsewhere in the app's own UI, is the only icon this implementation can produce
  without inventing visual design out of scope for this spec. It satisfies FR-003 (a real icon,
  not the placeholder) without claiming to be a finished brand identity.
- **Alternatives considered**: Leaving the icon as the system-default placeholder and treating
  FR-003 as informational-only — rejected, it's a stated functional requirement with its own
  acceptance scenario and success criterion (SC-002), not optional.

## CI targets the unit suite; UI tests are a stretch goal, not a hard requirement

- **Decision**: `.github/workflows/ci.yml` builds the app and runs `NextStepTests` (Swift Testing)
  on every push and pull request, on a `macos` GitHub-hosted runner with `xcode-select` pointed at
  the latest Xcode available on that runner image. `NextStepUITests` is not included in the
  required CI job for this spec.
- **Rationale**: matches spec.md's Assumptions directly — this project's own `AI_USAGE.md` already
  documents real, recurring XCUITest/simulator flakiness encountered even in local development
  (multi-hour stalls, dictation-button crashes, resolved only by manually rebooting the simulator).
  Putting that same flakiness in front of every push/PR would make CI an unreliable, ignorable
  signal rather than a trustworthy one — worse than not having it. The unit suite has shown none of
  that flakiness across Specifications 1-4 and is fast, making it the right required gate.
- **Alternatives considered**: Running both suites as one required job — rejected per above.
  Running UI tests as a separate, non-blocking/informational job — a reasonable future addition,
  but out of scope for this spec to keep CI setup itself simple and its first version trustworthy;
  noted as a natural follow-up rather than built now.

## Dark mode and Dynamic Type: audit, not new abstraction

- **Decision**: No new design-system module or theming abstraction is introduced. The audit
  (FR-001/FR-002) is a pass over existing `Features/*` views, replacing any hard-coded `Color`
  literals with semantic system colors (e.g. `.primary`/`.secondary`, system background roles) and
  confirming text uses default Dynamic-Type-respecting `Font` styles rather than fixed point sizes,
  fixing what's found rather than building new infrastructure.
- **Rationale**: the constitution's Principle II rationale explicitly warns against "unnecessary
  architectural ceremony for what is still a small app" — a full design-system layer would be that,
  for a fix that's really about removing a small number of hard-coded values (e.g.
  `FollowUpRow`/`DeveloperAnalyticsView`'s priority-badge colors) that were written without a
  dark-mode pass in mind.
- **Alternatives considered**: A `Core/DesignSystem` module (named in the constitution's Principle
  II folder list as a place such work *could* live) — considered, but deferred until there's a
  second or third reason to centralize color/type definitions; introducing the folder for a
  one-spec audit would be premature.
