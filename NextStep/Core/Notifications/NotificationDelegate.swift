import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let router: NotificationRouter
    private let analyticsTracking: AnalyticsTracking

    // Dedupes "displayed" across willPresent (foreground) and didReceive (tap on a notification
    // delivered while backgrounded, which implies it was shown even though this delegate was
    // never told at delivery time) — in-memory only, reset on relaunch, which is acceptable for
    // a debug-oriented event log rather than a billed analytics pipeline. Accessed only from the
    // @MainActor Task hops below, so it's safe despite this class not itself being @MainActor.
    @MainActor private var trackedDisplayedIdentifiers = Set<String>()

    init(router: NotificationRouter, analyticsTracking: AnalyticsTracking) {
        self.router = router
        self.analyticsTracking = analyticsTracking
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        let contactID = (userInfo["contactID"] as? String).flatMap(UUID.init(uuidString:))
        let contactName = userInfo["contactName"] as? String
        let followUpID = UUID(uuidString: identifier)
        let isDismiss = response.actionIdentifier == UNNotificationDismissActionIdentifier

        Task { @MainActor in
            if isDismiss {
                analyticsTracking.track(
                    .reminderDismissed, contactID: contactID, contactName: contactName, followUpID: followUpID
                )
            } else {
                trackDisplayedIfNeeded(
                    identifier: identifier, contactID: contactID, contactName: contactName, followUpID: followUpID
                )
                if let contactID {
                    router.pendingContactID = contactID
                }
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        let userInfo = notification.request.content.userInfo
        let contactID = (userInfo["contactID"] as? String).flatMap(UUID.init(uuidString:))
        let contactName = userInfo["contactName"] as? String
        let followUpID = UUID(uuidString: identifier)

        Task { @MainActor in
            trackDisplayedIfNeeded(
                identifier: identifier, contactID: contactID, contactName: contactName, followUpID: followUpID
            )
        }
        completionHandler([.banner, .sound])
    }

    @MainActor
    private func trackDisplayedIfNeeded(
        identifier: String, contactID: UUID?, contactName: String?, followUpID: UUID?
    ) {
        guard !trackedDisplayedIdentifiers.contains(identifier) else { return }
        trackedDisplayedIdentifiers.insert(identifier)
        analyticsTracking.track(
            .reminderDisplayed, contactID: contactID, contactName: contactName, followUpID: followUpID
        )
    }
}
