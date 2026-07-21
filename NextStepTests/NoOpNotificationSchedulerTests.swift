import Testing
import Foundation
@testable import NextStep

@MainActor
struct NoOpNotificationSchedulerTests {
    @Test
    func requestAuthorizationIfNeededReturnsTrueByDefault() async {
        let scheduler = NoOpNotificationScheduler()
        #expect(await scheduler.requestAuthorizationIfNeeded())
    }

    @Test
    func requestAuthorizationIfNeededRespectsConfiguredDenial() async {
        let scheduler = NoOpNotificationScheduler()
        scheduler.authorizationGranted = false
        #expect(await scheduler.requestAuthorizationIfNeeded() == false)
    }

    @Test
    func scheduleReminderRecordsTheFollowUpID() async {
        let scheduler = NoOpNotificationScheduler()
        let followUp = FollowUp(dueDate: .now)

        await scheduler.scheduleReminder(for: followUp)

        #expect(scheduler.scheduledFollowUpIDs == [followUp.id])
    }

    @Test
    func scheduleReminderDoesNothingWhenAuthorizationIsDenied() async {
        let scheduler = NoOpNotificationScheduler()
        scheduler.authorizationGranted = false
        let followUp = FollowUp(dueDate: .now)

        await scheduler.scheduleReminder(for: followUp)

        #expect(scheduler.scheduledFollowUpIDs.isEmpty)
    }

    @Test
    func cancelReminderRecordsTheFollowUpIDEvenIfNeverScheduled() async {
        let scheduler = NoOpNotificationScheduler()
        let followUp = FollowUp(dueDate: .now)

        await scheduler.cancelReminder(for: followUp)

        #expect(scheduler.canceledFollowUpIDs == [followUp.id])
    }
}
