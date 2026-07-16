import Foundation
import SwiftData

enum RelationshipCategory: String, Codable, CaseIterable, Identifiable {
    case recruiter
    case referral
    case alumnus
    case hiringManager
    case peer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recruiter: "Recruiter"
        case .referral: "Referral"
        case .alumnus: "Alumnus"
        case .hiringManager: "Hiring Manager"
        case .peer: "Peer"
        }
    }
}

@Model
final class NetworkingContact {
    var id: UUID
    var name: String
    var company: Company?
    var jobTitle: String?
    var contactHandle: String?
    var howWeMet: String?
    var relationshipCategory: RelationshipCategory
    var relationshipStrength: Int
    var notes: String?
    var lastInteractionDate: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Interaction.contact)
    var interactions: [Interaction] = []

    init(
        id: UUID = UUID(),
        name: String,
        company: Company? = nil,
        jobTitle: String? = nil,
        contactHandle: String? = nil,
        howWeMet: String? = nil,
        relationshipCategory: RelationshipCategory = .peer,
        relationshipStrength: Int = 3,
        notes: String? = nil,
        lastInteractionDate: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.company = company
        self.jobTitle = jobTitle
        self.contactHandle = contactHandle
        self.howWeMet = howWeMet
        self.relationshipCategory = relationshipCategory
        self.relationshipStrength = relationshipStrength
        self.notes = notes
        self.lastInteractionDate = lastInteractionDate
        self.createdAt = createdAt
    }
}
