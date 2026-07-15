import Foundation
import SwiftUI

protocol ContactRepository {
    func fetchAll() throws -> [NetworkingContact]
    func fetch(id: UUID) throws -> NetworkingContact?
    func save(_ contact: NetworkingContact) throws
    func delete(_ contact: NetworkingContact) throws

    func fetchAllCompanies() throws -> [Company]
    func findOrCreateCompany(named name: String) throws -> Company
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
