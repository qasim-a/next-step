import Testing
import Foundation
@testable import NextStep

struct ContactFilteringTests {
    private func contact(
        _ name: String,
        company: String? = nil,
        category: RelationshipCategory = .peer
    ) -> NetworkingContact {
        NetworkingContact(
            name: name,
            company: company.map { Company(name: $0) },
            relationshipCategory: category
        )
    }

    @Test
    func emptySearchAndNoCategoryReturnsAllContacts() {
        let contacts = [contact("Sarah Chen"), contact("Michael Osei")]

        let result = ContactFiltering.filter(contacts, searchText: "", category: nil)

        #expect(result.count == 2)
    }

    @Test
    func searchMatchesByPartialName() {
        let contacts = [contact("Sarah Chen"), contact("Michael Osei")]

        let result = ContactFiltering.filter(contacts, searchText: "sarah", category: nil)

        #expect(result.map(\.name) == ["Sarah Chen"])
    }

    @Test
    func searchMatchesByPartialCompany() {
        let contacts = [
            contact("Sarah Chen", company: "UBS"),
            contact("Michael Osei", company: "Google")
        ]

        let result = ContactFiltering.filter(contacts, searchText: "ubs", category: nil)

        #expect(result.map(\.name) == ["Sarah Chen"])
    }

    @Test
    func categoryFilterReturnsOnlyMatchingCategory() {
        let contacts = [
            contact("Sarah Chen", category: .recruiter),
            contact("Michael Osei", category: .peer)
        ]

        let result = ContactFiltering.filter(contacts, searchText: "", category: .recruiter)

        #expect(result.map(\.name) == ["Sarah Chen"])
    }

    @Test
    func searchAndCategoryFilterCombineWithAnd() {
        let contacts = [
            contact("Sarah Chen", company: "UBS", category: .recruiter),
            contact("Sarah Kim", company: "UBS", category: .peer),
            contact("Michael Osei", company: "UBS", category: .recruiter)
        ]

        let result = ContactFiltering.filter(contacts, searchText: "sarah", category: .recruiter)

        #expect(result.map(\.name) == ["Sarah Chen"])
    }

    @Test
    func searchWithNoMatchesReturnsEmpty() {
        let contacts = [contact("Sarah Chen"), contact("Michael Osei")]

        let result = ContactFiltering.filter(contacts, searchText: "nonexistent", category: nil)

        #expect(result.isEmpty)
    }

    @Test
    func contactWithNoCompanyIsExcludedByCompanySearchButNotByNameSearch() {
        let contacts = [contact("Sarah Chen", company: nil)]

        #expect(ContactFiltering.filter(contacts, searchText: "sarah", category: nil).count == 1)
        #expect(ContactFiltering.filter(contacts, searchText: "acme", category: nil).isEmpty)
    }
}
