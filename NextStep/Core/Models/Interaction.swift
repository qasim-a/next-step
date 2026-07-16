import Foundation
import SwiftData

enum InteractionType: String, Codable, CaseIterable, Identifiable {
    case linkedInConnectionRequest
    case linkedInMessage
    case email
    case phoneOrVideoCall
    case inPersonMeeting
    case interview
    case referralRequest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .linkedInConnectionRequest: "LinkedIn Connection Request"
        case .linkedInMessage: "LinkedIn Message"
        case .email: "Email"
        case .phoneOrVideoCall: "Phone or Video Call"
        case .inPersonMeeting: "In-Person Meeting"
        case .interview: "Interview"
        case .referralRequest: "Referral Request"
        }
    }
}

@Model
final class Interaction {
    var id: UUID
    var contact: NetworkingContact?
    var type: InteractionType
    var date: Date
    var notes: String?
    var outcome: String?
    var nextAction: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        contact: NetworkingContact? = nil,
        type: InteractionType,
        date: Date = .now,
        notes: String? = nil,
        outcome: String? = nil,
        nextAction: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.contact = contact
        self.type = type
        self.date = date
        self.notes = notes
        self.outcome = outcome
        self.nextAction = nextAction
        self.createdAt = createdAt
    }
}
