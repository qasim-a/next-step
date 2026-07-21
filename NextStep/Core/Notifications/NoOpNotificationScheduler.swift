import Foundation

/// Used under `-UITestResetState`/`XCTestConfigurationFilePath` and directly by unit tests, so
/// automated tests never depend on the real, system-owned notification permission dialog (which
/// XCUITest cannot reliably drive). Records calls in memory instead of scheduling anything real.
@MainActor
final class NoOpNotificationScheduler: NotificationScheduling {
    private(set) var scheduledFollowUpIDs: [UUID] = []
    private(set) var canceledFollowUpIDs: [UUID] = []
    var authorizationGranted = true

    func requestAuthorizationIfNeeded() async -> Bool {
        authorizationGranted
    }

    func scheduleReminder(for followUp: FollowUp) async {
        guard authorizationGranted else { return }
        scheduledFollowUpIDs.append(followUp.id)
    }

    func cancelReminder(for followUp: FollowUp) async {
        canceledFollowUpIDs.append(followUp.id)
    }
}
