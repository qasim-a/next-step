import Testing
import SwiftData
import Foundation
@testable import NextStep

@MainActor
struct SwiftDataExperimentProviderTests {
    private let container: ModelContainer
    private let provider: SwiftDataExperimentProvider

    init() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
            ExperimentAssignment.self,
            configurations: configuration
        )
        provider = SwiftDataExperimentProvider(modelContext: container.mainContext)
    }

    @Test
    func firstAccessPersistsAnAssignment() throws {
        _ = provider.reminderCopyVariant

        let assignments = try container.mainContext.fetch(FetchDescriptor<ExperimentAssignment>())
        #expect(assignments.count == 1)
        #expect(assignments.first?.experimentKey == SwiftDataExperimentProvider.reminderCopyExperimentKey)
    }

    @Test
    func repeatedAccessReturnsTheSamePersistedVariant() throws {
        let first = provider.reminderCopyVariant
        let second = provider.reminderCopyVariant
        let third = provider.reminderCopyVariant

        #expect(first == second)
        #expect(second == third)

        let assignments = try container.mainContext.fetch(FetchDescriptor<ExperimentAssignment>())
        #expect(assignments.count == 1)
    }

    @Test
    func aFreshProviderOverTheSameStoreReadsThePersistedAssignment() throws {
        let firstVariant = provider.reminderCopyVariant

        let secondProvider = SwiftDataExperimentProvider(modelContext: container.mainContext)
        #expect(secondProvider.reminderCopyVariant == firstVariant)

        let assignments = try container.mainContext.fetch(FetchDescriptor<ExperimentAssignment>())
        #expect(assignments.count == 1)
    }
}
