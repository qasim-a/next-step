import Testing
import SwiftData
import Foundation
@testable import NextStep

@MainActor
struct SwiftDataContactRepositoryTests {
    // Held as stored properties (not returned from a local helper) because a ModelContext does
    // not keep its owning ModelContainer alive — letting the container fall out of scope while
    // the context is still in use crashes inside SwiftData on first access.
    private let container: ModelContainer
    private let repository: SwiftDataContactRepository

    init() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: NetworkingContact.self, Company.self,
            configurations: configuration
        )
        repository = SwiftDataContactRepository(modelContext: container.mainContext)
    }

    @Test
    func savingAContactMakesItFetchable() throws {
        let contact = NetworkingContact(name: "Sarah Chen")

        try repository.save(contact)

        let all = try repository.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.name == "Sarah Chen")
    }

    @Test
    func fetchByIdReturnsNilForUnknownContact() throws {
        let result = try repository.fetch(id: UUID())
        #expect(result == nil)
    }

    @Test
    func fetchByIdReturnsMatchingContact() throws {
        let contact = NetworkingContact(name: "Michael Osei")
        try repository.save(contact)

        let fetched = try repository.fetch(id: contact.id)
        #expect(fetched?.name == "Michael Osei")
    }

    @Test
    func findOrCreateCompanyCreatesNewCompanyWhenNoneExists() throws {
        let company = try repository.findOrCreateCompany(named: "UBS")

        #expect(company.name == "UBS")
        #expect(try repository.fetchAllCompanies().count == 1)
    }

    @Test
    func findOrCreateCompanyReusesExistingCompanyCaseInsensitively() throws {
        _ = try repository.findOrCreateCompany(named: "UBS")
        let second = try repository.findOrCreateCompany(named: "  ubs  ")

        #expect(try repository.fetchAllCompanies().count == 1)
        #expect(second.name == "UBS")
    }

    @Test
    func updatingAnAlreadySavedContactPersistsChanges() throws {
        let contact = NetworkingContact(name: "Priya Patel")
        try repository.save(contact)

        contact.jobTitle = "Staff Engineer"
        try repository.save(contact)

        let fetched = try repository.fetch(id: contact.id)
        #expect(fetched?.jobTitle == "Staff Engineer")
        #expect(try repository.fetchAll().count == 1)
    }

    @Test
    func deletingAContactRemovesItFromFetchAll() throws {
        let contact = NetworkingContact(name: "Diego Ramirez")
        try repository.save(contact)

        try repository.delete(contact)

        #expect(try repository.fetchAll().isEmpty)
    }

    @Test
    func deletingAContactRemovesItFromFetchById() throws {
        let contact = NetworkingContact(name: "Amara Okafor")
        try repository.save(contact)

        try repository.delete(contact)

        #expect(try repository.fetch(id: contact.id) == nil)
    }
}
