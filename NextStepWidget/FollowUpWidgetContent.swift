import Foundation

enum FollowUpWidgetContent {
    static let maxCount = 3

    /// Up to `maxCount` follow-ups that are overdue or due today, most-urgent-first (overdue,
    /// oldest first, before due-today). Upcoming and completed follow-ups are never included —
    /// same boundary FollowUpBucketing already uses for the Today screen.
    static func select(
        _ followUps: [FollowUp],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> [FollowUp] {
        let startOfToday = calendar.startOfDay(for: today)
        guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return []
        }

        let overdue = followUps
            .filter { !$0.isCompleted && $0.dueDate < startOfToday }
            .sorted { $0.dueDate < $1.dueDate }
        let dueToday = followUps
            .filter { !$0.isCompleted && $0.dueDate >= startOfToday && $0.dueDate < endOfToday }
            .sorted { $0.dueDate < $1.dueDate }

        return Array((overdue + dueToday).prefix(maxCount))
    }
}
