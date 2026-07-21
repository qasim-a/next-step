import Foundation
import SwiftUI

protocol NotificationScheduling {
    /// Requests notification permission only if the user hasn't already made a choice.
    /// Returns whether reminders can currently be scheduled.
    func requestAuthorizationIfNeeded() async -> Bool

    /// Schedules a reminder for the follow-up's due date. A no-op if authorization has not
    /// been granted — callers do not need to check authorization status themselves.
    func scheduleReminder(for followUp: FollowUp) async

    /// Cancels any pending reminder for the follow-up. Always safe to call, including for a
    /// follow-up with no scheduled reminder.
    func cancelReminder(for followUp: FollowUp) async
}

private struct NotificationSchedulingKey: EnvironmentKey {
    static let defaultValue: NotificationScheduling? = nil
}

extension EnvironmentValues {
    var notificationScheduling: NotificationScheduling? {
        get { self[NotificationSchedulingKey.self] }
        set { self[NotificationSchedulingKey.self] = newValue }
    }
}
