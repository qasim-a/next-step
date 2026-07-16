import Foundation
import SwiftData

final class SwiftDataContactRepository: ContactRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [NetworkingContact] {
        try modelContext.fetch(FetchDescriptor<NetworkingContact>())
    }

    func fetch(id: UUID) throws -> NetworkingContact? {
        var descriptor = FetchDescriptor<NetworkingContact>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func save(_ contact: NetworkingContact) throws {
        if contact.modelContext == nil {
            modelContext.insert(contact)
        }
        try modelContext.save()
    }

    func delete(_ contact: NetworkingContact) throws {
        modelContext.delete(contact)
        try modelContext.save()
    }

    func fetchAllCompanies() throws -> [Company] {
        try modelContext.fetch(FetchDescriptor<Company>())
    }

    func findOrCreateCompany(named name: String) throws -> Company {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTarget = trimmed.lowercased()
        let existing = try fetchAllCompanies().first {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTarget
        }
        if let existing {
            return existing
        }
        let company = Company(name: trimmed)
        modelContext.insert(company)
        try modelContext.save()
        return company
    }

    func fetchInteractions(for contact: NetworkingContact) throws -> [Interaction] {
        let contactID = contact.id
        let descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { $0.contact?.id == contactID }
        )
        return try modelContext.fetch(descriptor)
    }

    func saveInteraction(_ interaction: Interaction, for contact: NetworkingContact) throws {
        if interaction.modelContext == nil {
            interaction.contact = contact
            modelContext.insert(interaction)
        }
        try modelContext.save()
        try recomputeLastInteractionDate(for: contact)
    }

    func deleteInteraction(_ interaction: Interaction) throws {
        let contact = interaction.contact
        modelContext.delete(interaction)
        try modelContext.save()
        if let contact {
            try recomputeLastInteractionDate(for: contact)
        }
    }

    private func recomputeLastInteractionDate(for contact: NetworkingContact) throws {
        let interactions = try fetchInteractions(for: contact)
        contact.lastInteractionDate = interactions.map(\.date).max()
        try modelContext.save()
    }
}
