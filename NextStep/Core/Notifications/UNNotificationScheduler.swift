import Foundation
import UserNotifications

@MainActor
final class UNNotificationScheduler: NotificationScheduling {
    /// Registered with `.customDismissAction` at launch (see NextStepApp) — required for
    /// UNNotificationDismissActionIdentifier to ever reach the delegate.
    static let reminderCategoryIdentifier = "followUpReminder"

    private let center = UNUserNotificationCenter.current()
    private let experimentProviding: ExperimentProviding

    init(experimentProviding: ExperimentProviding) {
        self.experimentProviding = experimentProviding
    }

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

        let name = followUp.contact?.name ?? "a contact"
        let content = UNMutableNotificationContent()
        content.title = switch experimentProviding.reminderCopyVariant {
        case .control: "Follow up with \(name)"
        case .variant: "Don't lose touch with \(name)"
        }
        content.body = followUp.suggestedAction?.isEmpty == false
            ? followUp.suggestedAction!
            : "This follow-up is due today."
        content.sound = .default
        content.categoryIdentifier = Self.reminderCategoryIdentifier
        if let contactID = followUp.contact?.id {
            content.userInfo = ["contactID": contactID.uuidString, "contactName": name]
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
