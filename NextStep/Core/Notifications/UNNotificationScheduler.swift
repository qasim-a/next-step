import Foundation
import UserNotifications

@MainActor
final class UNNotificationScheduler: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func scheduleReminder(for followUp: FollowUp) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Follow up with \(followUp.contact?.name ?? "a contact")"
        content.body = followUp.suggestedAction?.isEmpty == false
            ? followUp.suggestedAction!
            : "This follow-up is due today."
        content.sound = .default
        if let contactID = followUp.contact?.id {
            content.userInfo = ["contactID": contactID.uuidString]
        }

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: followUp.dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: followUp.id.uuidString,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelReminder(for followUp: FollowUp) async {
        center.removePendingNotificationRequests(withIdentifiers: [followUp.id.uuidString])
    }
}
