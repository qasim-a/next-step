import Testing
import Foundation
@testable import NextStep

struct InteractionTimelineOrderingTests {
    private func interaction(date: Date, createdAt: Date = .now) -> Interaction {
        Interaction(type: .email, date: date, createdAt: createdAt)
    }

    @Test
    func sortsByDateDescending() {
        let today = Date.now
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let interactions = [
            interaction(date: lastWeek),
            interaction(date: today),
            interaction(date: yesterday)
        ]

        let sorted = InteractionTimeline.sorted(interactions)

        #expect(sorted.map(\.date) == [today, yesterday, lastWeek])
    }

    @Test
    func breaksTiesOnSameDateByMostRecentlyCreatedFirst() {
        let sameDate = Date.now
        let earlierCreated = Calendar.current.date(byAdding: .minute, value: -10, to: .now)!
        let laterCreated = Date.now

        let older = interaction(date: sameDate, createdAt: earlierCreated)
        let newer = interaction(date: sameDate, createdAt: laterCreated)

        let sorted = InteractionTimeline.sorted([older, newer])

        #expect(sorted.first === newer)
        #expect(sorted.last === older)
    }

    @Test
    func emptyArrayReturnsEmpty() {
        #expect(InteractionTimeline.sorted([]).isEmpty)
    }

    @Test
    func singleInteractionReturnsSingleInteraction() {
        let only = interaction(date: .now)
        #expect(InteractionTimeline.sorted([only]) == [only])
    }
}
