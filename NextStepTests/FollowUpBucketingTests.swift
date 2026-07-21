import Testing
import Foundation
@testable import NextStep

struct FollowUpBucketingTests {
    private let calendar = Calendar.current
    private let today = Date.now

    private func followUp(
        daysFromToday: Int,
        isCompleted: Bool = false,
        completedDaysAgo: Int? = nil
    ) -> FollowUp {
        let dueDate = calendar.date(byAdding: .day, value: daysFromToday, to: today)!
        let completedAt = completedDaysAgo.map {
            calendar.date(byAdding: .day, value: -$0, to: today)!
        }
        return FollowUp(
            dueDate: dueDate,
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }

    @Test
    func pastIncompleteFollowUpIsOverdue() {
        let followUp = followUp(daysFromToday: -3)
        let buckets = FollowUpBucketing.bucket([followUp], today: today, calendar: calendar)

        #expect(buckets.overdue.map(\.id) == [followUp.id])
        #expect(buckets.dueToday.isEmpty)
        #expect(buckets.upcoming.isEmpty)
    }

    @Test
    func todayIncompleteFollowUpIsDueToday() {
        let followUp = followUp(daysFromToday: 0)
        let buckets = FollowUpBucketing.bucket([followUp], today: today, calendar: calendar)

        #expect(buckets.dueToday.map(\.id) == [followUp.id])
        #expect(buckets.overdue.isEmpty)
        #expect(buckets.upcoming.isEmpty)
    }

    @Test
    func futureIncompleteFollowUpIsUpcoming() {
        let followUp = followUp(daysFromToday: 5)
        let buckets = FollowUpBucketing.bucket([followUp], today: today, calendar: calendar)

        #expect(buckets.upcoming.map(\.id) == [followUp.id])
        #expect(buckets.overdue.isEmpty)
        #expect(buckets.dueToday.isEmpty)
    }

    @Test
    func recentlyCompletedFollowUpAppearsInRecentlyCompleted() {
        let followUp = followUp(daysFromToday: -2, isCompleted: true, completedDaysAgo: 2)
        let buckets = FollowUpBucketing.bucket([followUp], today: today, calendar: calendar)

        #expect(buckets.recentlyCompleted.map(\.id) == [followUp.id])
        #expect(buckets.overdue.isEmpty)
    }

    @Test
    func completedFollowUpOutsideRecentWindowIsExcludedEntirely() {
        let followUp = followUp(
            daysFromToday: -20,
            isCompleted: true,
            completedDaysAgo: FollowUpBucketing.recentlyCompletedWindowInDays + 5
        )
        let buckets = FollowUpBucketing.bucket([followUp], today: today, calendar: calendar)

        #expect(buckets.isEmpty)
    }

    @Test
    func emptyInputReturnsEmptyBuckets() {
        let buckets = FollowUpBucketing.bucket([], today: today, calendar: calendar)
        #expect(buckets.isEmpty)
    }

    @Test
    func mixedFollowUpsSortIntoCorrectBucketsSimultaneously() {
        let overdue = followUp(daysFromToday: -1)
        let dueToday = followUp(daysFromToday: 0)
        let upcoming = followUp(daysFromToday: 3)
        let completed = followUp(daysFromToday: -1, isCompleted: true, completedDaysAgo: 1)

        let buckets = FollowUpBucketing.bucket(
            [overdue, dueToday, upcoming, completed],
            today: today,
            calendar: calendar
        )

        #expect(buckets.overdue.map(\.id) == [overdue.id])
        #expect(buckets.dueToday.map(\.id) == [dueToday.id])
        #expect(buckets.upcoming.map(\.id) == [upcoming.id])
        #expect(buckets.recentlyCompleted.map(\.id) == [completed.id])
    }

    @Test
    func overdueSortsOldestFirst() {
        let older = followUp(daysFromToday: -10)
        let newer = followUp(daysFromToday: -1)

        let buckets = FollowUpBucketing.bucket([newer, older], today: today, calendar: calendar)

        #expect(buckets.overdue.map(\.id) == [older.id, newer.id])
    }

    @Test
    func recentlyCompletedSortsMostRecentFirst() {
        let longerAgo = followUp(daysFromToday: -5, isCompleted: true, completedDaysAgo: 5)
        let recent = followUp(daysFromToday: -1, isCompleted: true, completedDaysAgo: 1)

        let buckets = FollowUpBucketing.bucket([longerAgo, recent], today: today, calendar: calendar)

        #expect(buckets.recentlyCompleted.map(\.id) == [recent.id, longerAgo.id])
    }
}
