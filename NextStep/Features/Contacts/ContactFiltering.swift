import Foundation

enum ContactFiltering {
    static func filter(
        _ contacts: [NetworkingContact],
        searchText: String,
        category: RelationshipCategory?
    ) -> [NetworkingContact] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return contacts.filter { contact in
            matchesSearch(contact, trimmedSearch) && matchesCategory(contact, category)
        }
    }

    private static func matchesSearch(_ contact: NetworkingContact, _ searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }

        let name = contact.name
        let company = contact.company?.name ?? ""

        return name.localizedCaseInsensitiveContains(searchText)
            || company.localizedCaseInsensitiveContains(searchText)
    }

    private static func matchesCategory(_ contact: NetworkingContact, _ category: RelationshipCategory?) -> Bool {
        guard let category else { return true }
        return contact.relationshipCategory == category
    }
}
