import Testing
import SwiftData
import Foundation
@testable import NextStep

@MainActor
struct SwiftDataAnalyticsTrackerTests {
    private let container: ModelContainer
    private let tracker: SwiftDataAnalyticsTracker

    init() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
            AnalyticsEvent.self,
            configurations: configuration
        )
        tracker = SwiftDataAnalyticsTracker(modelContext: container.mainContext)
    }

    @Test
    func trackingAnEventPersistsItWithCorrectFields() throws {
        let contactID = UUID()
        let followUpID = UUID()

        tracker.track(.contactOpened, contactID: contactID, contactName: "Sarah Chen", followUpID: followUpID)

        let events = try tracker.fetchRecentEvents()
        #expect(events.count == 1)
        #expect(events.first?.type == .contactOpened)
        #expect(events.first?.contactID == contactID)
        #expect(events.first?.followUpID == followUpID)
        #expect(events.first?.contextLabel == "Sarah Chen")
    }

    @Test
    func fetchRecentEventsReturnsMostRecentFirst() throws {
        tracker.track(.contactOpened, contactID: nil, contactName: nil, followUpID: nil)
        tracker.track(.followUpCompleted, contactID: nil, contactName: nil, followUpID: nil)
        tracker.track(.reminderDisplayed, contactID: nil, contactName: nil, followUpID: nil)

        let events = try tracker.fetchRecentEvents()
        #expect(events.map(\.type) == [.reminderDisplayed, .followUpCompleted, .contactOpened])
    }

    @Test
    func eventRemainsMeaningfulAfterTheReferencedContactIsDeleted() throws {
        let contact = NetworkingContact(name: "Deleted Later")
        container.mainContext.insert(contact)
        try container.mainContext.save()

        tracker.track(.contactOpened, contact: contact)

        container.mainContext.delete(contact)
        try container.mainContext.save()

        let events = try tracker.fetchRecentEvents()
        #expect(events.first?.contextLabel == "Deleted Later")
    }
}
