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

        let contact = NetworkingContact(name: trimmedName)
        return applyAndSave(
            name: name, companyName: companyName, jobTitle: jobTitle,
            contactHandle: contactHandle, howWeMet: howWeMet,
            relationshipCategory: relationshipCategory,
            relationshipStrength: relationshipStrength, notes: notes,
            to: contact
        )
    }

    @discardableResult
    func updateContact(
        _ contact: NetworkingContact,
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

        return applyAndSave(
            name: name, companyName: companyName, jobTitle: jobTitle,
            contactHandle: contactHandle, howWeMet: howWeMet,
            relationshipCategory: relationshipCategory,
            relationshipStrength: relationshipStrength, notes: notes,
            to: contact
        )
    }

    @discardableResult
    func deleteContact(_ contact: NetworkingContact) -> Bool {
        do {
            try repository.delete(contact)
            loadContacts()
            return true
        } catch {
            errorMessage = "Couldn't delete contact. Please try again."
            return false
        }
    }

    private func applyAndSave(
        name: String,
        companyName: String,
        jobTitle: String,
        contactHandle: String,
        howWeMet: String,
        relationshipCategory: RelationshipCategory,
        relationshipStrength: Int,
        notes: String,
        to contact: NetworkingContact
    ) -> Bool {
        do {
            contact.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            contact.company = try resolvedCompany(from: companyName)
            contact.jobTitle = nilIfBlank(jobTitle)
            contact.contactHandle = nilIfBlank(contactHandle)
            contact.howWeMet = nilIfBlank(howWeMet)
            contact.relationshipCategory = relationshipCategory
            contact.relationshipStrength = relationshipStrength
            contact.notes = nilIfBlank(notes)
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
