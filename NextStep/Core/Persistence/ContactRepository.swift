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

    func fetchFollowUps(for contact: NetworkingContact) throws -> [FollowUp]
    func fetchAllFollowUps() throws -> [FollowUp]
    func saveFollowUp(_ followUp: FollowUp, for contact: NetworkingContact) async throws
    func completeFollowUp(_ followUp: FollowUp) async throws
    func deleteFollowUp(_ followUp: FollowUp) async throws
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
