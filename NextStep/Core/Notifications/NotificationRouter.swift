import Foundation
import Observation
import SwiftUI

/// Bridges a tapped follow-up reminder notification (handled by `NotificationDelegate`, which
/// runs outside SwiftUI's view hierarchy) to the app's navigation, which lives inside it. Setting
/// `pendingContactID` is observed by `RootTabView`, which switches to the Contacts tab and
/// pushes that contact — a tapped notification can arrive while any tab is active, so the
/// routing decision has to happen above both tabs, not inside `TodayView` itself.
@MainActor
@Observable
final class NotificationRouter {
    var pendingContactID: UUID?
}

private struct NotificationRouterKey: EnvironmentKey {
    static let defaultValue: NotificationRouter? = nil
}

extension EnvironmentValues {
    var notificationRouter: NotificationRouter? {
        get { self[NotificationRouterKey.self] }
        set { self[NotificationRouterKey.self] = newValue }
    }
}
