import Testing
import Foundation
@testable import NextStep

struct FollowUpInsightsTests {
    private let calendar = Calendar.current
    private let today = Date.now

    private func followUp(
        daysFromToday: Int,
        isCompleted: Bool = false
    ) -> FollowUp {
        let dueDate = calendar.date(byAdding: .day, value: daysFromToday, to: today)!
        return FollowUp(dueDate: dueDate, isCompleted: isCompleted)
    }

    @Test
    func emptyInputIsEmptySummary() {
        let summary = FollowUpInsights.summarize([], today: today, calendar: calendar)
        #expect(summary.isEmpty)
        #expect(summary.completionRate == nil)
    }

    @Test
    func completedFollowUpCountsAsCompleted() {
        let summary = FollowUpInsights.summarize(
            [followUp(daysFromToday: -3, isCompleted: true)], today: today, calendar: calendar
        )
        #expect(summary.completedCount == 1)
        #expect(summary.overdueCount == 0)
        #expect(summary.upcomingCount == 0)
    }

    @Test
    func pastIncompleteFollowUpCountsAsOverdue() {
        let summary = FollowUpInsights.summarize(
            [followUp(daysFromToday: -1)], today: today, calendar: calendar
        )
        #expect(summary.overdueCount == 1)
        #expect(summary.completedCount == 0)
        #expect(summary.upcomingCount == 0)
    }

    @Test
    func todayOrFutureIncompleteFollowUpCountsAsUpcoming() {
        let summary = FollowUpInsights.summarize(
            [followUp(daysFromToday: 0), followUp(daysFromToday: 5)], today: today, calendar: calendar
        )
        #expect(summary.upcomingCount == 2)
        #expect(summary.overdueCount == 0)
        #expect(summary.completedCount == 0)
    }

    @Test
    func completionRateExcludesUpcomingFromTheDenominator() {
        let followUps = [
            followUp(daysFromToday: -1, isCompleted: true),
            followUp(daysFromToday: -2, isCompleted: true),
            followUp(daysFromToday: -3),
            followUp(daysFromToday: 5),
        ]
        let summary = FollowUpInsights.summarize(followUps, today: today, calendar: calendar)

        #expect(summary.completedCount == 2)
        #expect(summary.overdueCount == 1)
        #expect(summary.upcomingCount == 1)
        #expect(summary.completionRate == 2.0 / 3.0)
    }

    @Test
    func completionRateIsNilWhenOnlyUpcomingFollowUpsExist() {
        let summary = FollowUpInsights.summarize(
            [followUp(daysFromToday: 3)], today: today, calendar: calendar
        )
        #expect(summary.completionRate == nil)
    }

    @Test
    func deletedFollowUpIsSimplyAbsentFromTheInput() {
        let kept = followUp(daysFromToday: -1, isCompleted: true)
        let deleted = followUp(daysFromToday: -2)
        // "Deleting" a follow-up in this codebase means it's no longer in the fetched array —
        // there's no soft-delete flag, so simulating deletion means simply not including it.
        let summary = FollowUpInsights.summarize([kept], today: today, calendar: calendar)

        #expect(summary.completedCount == 1)
        #expect(summary.overdueCount == 0)
        _ = deleted
    }
}
