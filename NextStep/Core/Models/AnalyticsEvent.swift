import Foundation
import SwiftData

enum AnalyticsEventType: String, Codable, CaseIterable {
    case reminderDisplayed
    case contactOpened
    case followUpCompleted
    case reminderDismissed
    case followUpRescheduled

    var displayName: String {
        switch self {
        case .reminderDisplayed: "Reminder Displayed"
        case .contactOpened: "Contact Opened"
        case .followUpCompleted: "Follow-Up Completed"
        case .reminderDismissed: "Reminder Dismissed"
        case .followUpRescheduled: "Follow-Up Rescheduled"
        }
    }
}

/// Deliberately has no `@Relationship` to `NetworkingContact`/`FollowUp` — see
/// specs/004-experiments-analytics/data-model.md. `contextLabel` is a snapshot captured at
/// record time so the event stays meaningful even after the contact/follow-up it references is
/// later deleted.
@Model
final class AnalyticsEvent {
    var id: UUID
    var type: AnalyticsEventType
    var timestamp: Date
    var contactID: UUID?
    var followUpID: UUID?
    var contextLabel: String?

    init(
        id: UUID = UUID(),
        type: AnalyticsEventType,
        timestamp: Date = .now,
        contactID: UUID? = nil,
        followUpID: UUID? = nil,
        contextLabel: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.contactID = contactID
        self.followUpID = followUpID
        self.contextLabel = contextLabel
    }
}
