import Foundation
import SwiftData

enum ReminderCopyVariant: String, Codable, CaseIterable {
    case control
    case variant
}

@Model
final class ExperimentAssignment {
    var id: UUID
    var experimentKey: String
    var variant: ReminderCopyVariant
    var assignedAt: Date

    init(
        id: UUID = UUID(),
        experimentKey: String,
        variant: ReminderCopyVariant,
        assignedAt: Date = .now
    ) {
        self.id = id
        self.experimentKey = experimentKey
        self.variant = variant
        self.assignedAt = assignedAt
    }
}
