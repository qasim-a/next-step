import Foundation
import SwiftUI

@MainActor
protocol AnalyticsTracking {
    /// The primitive form — takes raw identifying data rather than live model objects, since not
    /// every call site (e.g. `NotificationDelegate`, which only has a notification's `userInfo`)
    /// has a `NetworkingContact`/`FollowUp` instance on hand. Synchronous and never throws or
    /// blocks — recording an event must never be able to fail or delay the action it accompanies.
    func track(_ type: AnalyticsEventType, contactID: UUID?, contactName: String?, followUpID: UUID?)

    /// Returns recorded events, most-recent-first.
    func fetchRecentEvents() throws -> [AnalyticsEvent]
}

extension AnalyticsTracking {
    func track(_ type: AnalyticsEventType) {
        track(type, contactID: nil, contactName: nil, followUpID: nil)
    }

    func track(_ type: AnalyticsEventType, contact: NetworkingContact?, followUp: FollowUp? = nil) {
        let resolvedContact = contact ?? followUp?.contact
        track(
            type,
            contactID: resolvedContact?.id,
            contactName: resolvedContact?.name,
            followUpID: followUp?.id
        )
    }

    func track(_ type: AnalyticsEventType, followUp: FollowUp?) {
        track(type, contact: followUp?.contact, followUp: followUp)
    }
}

private struct AnalyticsTrackingKey: EnvironmentKey {
    static let defaultValue: AnalyticsTracking? = nil
}

extension EnvironmentValues {
    var analyticsTracking: AnalyticsTracking? {
        get { self[AnalyticsTrackingKey.self] }
        set { self[AnalyticsTrackingKey.self] = newValue }
    }
}
