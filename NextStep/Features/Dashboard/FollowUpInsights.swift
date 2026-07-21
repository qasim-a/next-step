import Foundation

struct FollowUpSummary {
    var completedCount = 0
    var overdueCount = 0
    var upcomingCount = 0

    var isEmpty: Bool {
        completedCount == 0 && overdueCount == 0 && upcomingCount == 0
    }

    /// Completed ÷ (completed + overdue) — follow-ups that have already come due, one way or
    /// another. Upcoming follow-ups aren't due yet, so counting them against the rate would
    /// penalize the user for something they haven't had a chance to act on.
    var completionRate: Double? {
        let decided = completedCount + overdueCount
        guard decided > 0 else { return nil }
        return Double(completedCount) / Double(decided)
    }
}

enum FollowUpInsights {
    static func summarize(
        _ followUps: [FollowUp],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> FollowUpSummary {
        let startOfToday = calendar.startOfDay(for: today)

        var summary = FollowUpSummary()
        for followUp in followUps {
            if followUp.isCompleted {
                summary.completedCount += 1
            } else if followUp.dueDate < startOfToday {
                summary.overdueCount += 1
            } else {
                summary.upcomingCount += 1
            }
        }
        return summary
    }
}
