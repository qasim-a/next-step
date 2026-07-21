import Testing
import SwiftData
import Foundation
@testable import NextStep

@MainActor
struct FollowUpRepositoryTests {
    // Held as stored properties (not returned from a local helper) — see
    // SwiftDataContactRepositoryTests for why: a ModelContext does not keep its owning
    // ModelContainer alive.
    private let container: ModelContainer
    private let repository: SwiftDataContactRepository
    private let scheduler: NoOpNotificationScheduler

    init() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
            configurations: configuration
        )
        scheduler = NoOpNotificationScheduler()
        repository = SwiftDataContactRepository(
            modelContext: container.mainContext,
            notificationScheduling: scheduler
        )
    }

    private func makeContact(name: String = "Sarah Chen") throws -> NetworkingContact {
        let contact = NetworkingContact(name: name)
        try repository.save(contact)
        return contact
    }

    @Test
    func savingAFollowUpMakesItFetchable() async throws {
        let contact = try makeContact()
        let followUp = FollowUp(dueDate: .now)

        try await repository.saveFollowUp(followUp, for: contact)

        let fetched = try repository.fetchFollowUps(for: contact)
        #expect(fetched.count == 1)
        #expect(fetched.first?.id == followUp.id)
    }

    @Test
    func savingAnIncompleteFollowUpSchedulesAReminder() async throws {
        let contact = try makeContact()
        let followUp = FollowUp(dueDate: .now)

        try await repository.saveFollowUp(followUp, for: contact)

        #expect(scheduler.scheduledFollowUpIDs == [followUp.id])
    }

    @Test
    func fetchAllFollowUpsReturnsFollowUpsAcrossContacts() async throws {
        let contactA = try makeContact(name: "Sarah Chen")
        let contactB = try makeContact(name: "Michael Osei")
        try await repository.saveFollowUp(FollowUp(dueDate: .now), for: contactA)
        try await repository.saveFollowUp(FollowUp(dueDate: .now), for: contactB)

        let all = try repository.fetchAllFollowUps()
        #expect(all.count == 2)
    }
}
