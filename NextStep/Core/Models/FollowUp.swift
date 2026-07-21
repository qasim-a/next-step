import Foundation
import SwiftData

enum FollowUpPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
}

@Model
final class FollowUp {
    var id: UUID
    var contact: NetworkingContact?
    var originatingInteraction: Interaction?
    var dueDate: Date
    var priority: FollowUpPriority
    var suggestedAction: String?
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        contact: NetworkingContact? = nil,
        originatingInteraction: Interaction? = nil,
        dueDate: Date,
        priority: FollowUpPriority = .medium,
        suggestedAction: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.contact = contact
        self.originatingInteraction = originatingInteraction
        self.dueDate = dueDate
        self.priority = priority
        self.suggestedAction = suggestedAction
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}
