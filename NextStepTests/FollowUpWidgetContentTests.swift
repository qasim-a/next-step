import Testing
import Foundation
@testable import NextStep

struct FollowUpWidgetContentTests {
    private let calendar = Calendar.current
    private let today = Date.now

    private func followUp(daysFromToday: Int, isCompleted: Bool = false) -> FollowUp {
        let dueDate = calendar.date(byAdding: .day, value: daysFromToday, to: today)!
        return FollowUp(dueDate: dueDate, isCompleted: isCompleted)
    }

    @Test
    func emptyInputReturnsEmpty() {
        #expect(FollowUpWidgetContent.select([], today: today, calendar: calendar).isEmpty)
    }

    @Test
    func excludesUpcomingAndCompletedFollowUps() {
        let upcoming = followUp(daysFromToday: 3)
        let completed = followUp(daysFromToday: -1, isCompleted: true)

        let result = FollowUpWidgetContent.select([upcoming, completed], today: today, calendar: calendar)
        #expect(result.isEmpty)
    }

    @Test
    func includesOverdueAndDueTodayOnly() {
        let overdue = followUp(daysFromToday: -2)
        let dueToday = followUp(daysFromToday: 0)
        let upcoming = followUp(daysFromToday: 5)

        let result = FollowUpWidgetContent.select([overdue, dueToday, upcoming], today: today, calendar: calendar)
        #expect(Set(result.map(\.id)) == Set([overdue.id, dueToday.id]))
    }

    @Test
    func overdueSortsOldestFirstBeforeDueToday() {
        let olderOverdue = followUp(daysFromToday: -5)
        let newerOverdue = followUp(daysFromToday: -1)
        let dueToday = followUp(daysFromToday: 0)

        let result = FollowUpWidgetContent.select(
            [dueToday, newerOverdue, olderOverdue], today: today, calendar: calendar
        )
        #expect(result.map(\.id) == [olderOverdue.id, newerOverdue.id, dueToday.id])
    }

    @Test
    func capsAtMaxCount() {
        let followUps = (0..<5).map { followUp(daysFromToday: -$0) }
        let result = FollowUpWidgetContent.select(followUps, today: today, calendar: calendar)
        #expect(result.count == FollowUpWidgetContent.maxCount)
    }
}
