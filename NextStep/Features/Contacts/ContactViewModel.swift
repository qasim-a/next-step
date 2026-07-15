import Foundation
import Observation

@MainActor
@Observable
final class ContactViewModel {
    private(set) var contacts: [NetworkingContact] = []
    var errorMessage: String?

    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
        loadContacts()
    }

    func loadContacts() {
        do {
            contacts = try repository.fetchAll()
        } catch {
            errorMessage = "Couldn't load contacts. Please try again."
        }
    }

    @discardableResult
    func createContact(
        name: String,
        companyName: String,
        jobTitle: String,
        contactHandle: String,
        howWeMet: String,
        relationshipCategory: RelationshipCategory,
        relationshipStrength: Int,
        notes: String
    ) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        do {
            let company = try resolvedCompany(from: companyName)
            let contact = NetworkingContact(
                name: trimmedName,
                company: company,
                jobTitle: nilIfBlank(jobTitle),
                contactHandle: nilIfBlank(contactHandle),
                howWeMet: nilIfBlank(howWeMet),
                relationshipCategory: relationshipCategory,
                relationshipStrength: relationshipStrength,
                notes: nilIfBlank(notes)
            )
            try repository.save(contact)
            loadContacts()
            return true
        } catch {
            errorMessage = "Couldn't save contact. Please try again."
            return false
        }
    }

    private func resolvedCompany(from name: String) throws -> Company? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try repository.findOrCreateCompany(named: trimmed)
    }

    private func nilIfBlank(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
