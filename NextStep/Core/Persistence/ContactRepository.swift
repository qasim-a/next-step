import Foundation
import SwiftUI

protocol ContactRepository {
    func fetchAll() throws -> [NetworkingContact]
    func fetch(id: UUID) throws -> NetworkingContact?
    func save(_ contact: NetworkingContact) throws
    func delete(_ contact: NetworkingContact) throws

    func fetchAllCompanies() throws -> [Company]
    func findOrCreateCompany(named name: String) throws -> Company

    func fetchInteractions(for contact: NetworkingContact) throws -> [Interaction]
    func saveInteraction(_ interaction: Interaction, for contact: NetworkingContact) throws
    func deleteInteraction(_ interaction: Interaction) throws
}

private struct ContactRepositoryKey: EnvironmentKey {
    static let defaultValue: ContactRepository? = nil
}

extension EnvironmentValues {
    var contactRepository: ContactRepository? {
        get { self[ContactRepositoryKey.self] }
        set { self[ContactRepositoryKey.self] = newValue }
    }
}
