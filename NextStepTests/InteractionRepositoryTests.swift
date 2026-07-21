import Testing
import SwiftData
import Foundation
@testable import NextStep

@MainActor
struct InteractionRepositoryTests {
    // Held as stored properties (not returned from a local helper) — see
    // SwiftDataContactRepositoryTests for why: a ModelContext does not keep its owning
    // ModelContainer alive.
    private let container: ModelContainer
    private let repository: SwiftDataContactRepository

    init() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
            configurations: configuration
        )
        repository = SwiftDataContactRepository(
            modelContext: container.mainContext,
            notificationScheduling: NoOpNotificationScheduler()
        )
    }

    private func makeContact(name: String = "Sarah Chen") throws -> NetworkingContact {
        let contact = NetworkingContact(name: name)
        try repository.save(contact)
        return contact
    }

    @Test
    func savingAnInteractionMakesItFetchable() throws {
        let contact = try makeContact()
        let interaction = Interaction(type: .email, date: .now)

        try repository.saveInteraction(interaction, for: contact)

        let fetched = try repository.fetchInteractions(for: contact)
        #expect(fetched.count == 1)
        #expect(fetched.first?.type == .email)
    }

    @Test
    func savingAnInteractionUpdatesContactLastInteractionDate() throws {
        let contact = try makeContact()
        let interactionDate = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        let interaction = Interaction(type: .phoneOrVideoCall, date: interactionDate)

        try repository.saveInteraction(interaction, for: contact)

        let refetchedContact = try repository.fetch(id: contact.id)
        #expect(refetchedContact?.lastInteractionDate == interactionDate)
    }

    @Test
    func savingASecondEarlierInteractionDoesNotMoveLastInteractionDateBackward() throws {
        let contact = try makeContact()
        let recent = Date.now
        let older = Calendar.current.date(byAdding: .day, value: -10, to: .now)!

        try repository.saveInteraction(Interaction(type: .email, date: recent), for: contact)
        try repository.saveInteraction(Interaction(type: .inPersonMeeting, date: older), for: contact)

        let refetchedContact = try repository.fetch(id: contact.id)
        #expect(refetchedContact?.lastInteractionDate == recent)
    }

    @Test
    func updatingAnInteractionPersistsChanges() throws {
        let contact = try makeContact()
        let interaction = Interaction(type: .email, date: .now)
        try repository.saveInteraction(interaction, for: contact)

        interaction.type = .interview
        interaction.outcome = "Moved to final round"
        try repository.saveInteraction(interaction, for: contact)

        let fetched = try repository.fetchInteractions(for: contact)
        #expect(fetched.count == 1)
        #expect(fetched.first?.type == .interview)
        #expect(fetched.first?.outcome == "Moved to final round")
    }

    @Test
    func deletingTheMostRecentInteractionFallsBackToNextMostRecentDate() throws {
        let contact = try makeContact()
        let recent = Date.now
        let older = Calendar.current.date(byAdding: .day, value: -10, to: .now)!

        let recentInteraction = Interaction(type: .email, date: recent)
        try repository.saveInteraction(recentInteraction, for: contact)
        try repository.saveInteraction(Interaction(type: .inPersonMeeting, date: older), for: contact)

        try repository.deleteInteraction(recentInteraction)

        let refetchedContact = try repository.fetch(id: contact.id)
        #expect(refetchedContact?.lastInteractionDate == older)
    }

    @Test
    func deletingTheOnlyInteractionRevertsLastInteractionDateToNil() throws {
        let contact = try makeContact()
        let interaction = Interaction(type: .email, date: .now)
        try repository.saveInteraction(interaction, for: contact)

        try repository.deleteInteraction(interaction)

        let refetchedContact = try repository.fetch(id: contact.id)
        #expect(refetchedContact?.lastInteractionDate == nil)
        #expect(try repository.fetchInteractions(for: contact).isEmpty)
    }

    @Test
    func deletingAContactCascadesToDeleteItsInteractions() throws {
        let contact = try makeContact()
        try repository.saveInteraction(Interaction(type: .email, date: .now), for: contact)
        try repository.saveInteraction(Interaction(type: .interview, date: .now), for: contact)

        try repository.delete(contact)

        let allInteractions = try container.mainContext.fetch(FetchDescriptor<Interaction>())
        #expect(allInteractions.isEmpty)
    }
}
