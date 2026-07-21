import Foundation
import Observation
import SwiftUI

/// Bridges app-level events that happen outside SwiftUI's view hierarchy (a tapped reminder
/// notification, handled by `NotificationDelegate`; a tapped home-screen widget, handled by
/// `NextStepApp`'s `onOpenURL`) to the app's navigation, which lives inside it. `RootTabView`
/// observes both properties — a tapped notification or widget can arrive while any tab is active,
/// so the routing decision has to happen above both tabs, not inside a single tab's view.
@MainActor
@Observable
final class NotificationRouter {
    var pendingContactID: UUID?
    var shouldSelectTodayTab = false
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
