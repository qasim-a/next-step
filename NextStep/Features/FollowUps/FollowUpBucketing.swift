import Foundation

struct FollowUpBuckets {
    var overdue: [FollowUp] = []
    var dueToday: [FollowUp] = []
    var upcoming: [FollowUp] = []
    var recentlyCompleted: [FollowUp] = []

    var isEmpty: Bool {
        overdue.isEmpty && dueToday.isEmpty && upcoming.isEmpty && recentlyCompleted.isEmpty
    }
}

enum FollowUpBucketing {
    static let recentlyCompletedWindowInDays = 7

    static func bucket(
        _ followUps: [FollowUp],
        today: Date = .now,
        calendar: Calendar = .current
    ) -> FollowUpBuckets {
        let startOfToday = calendar.startOfDay(for: today)
        guard
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday),
            let recentWindowStart = calendar.date(
                byAdding: .day, value: -recentlyCompletedWindowInDays, to: startOfToday
            )
        else {
            return FollowUpBuckets()
        }

        var buckets = FollowUpBuckets()
        for followUp in followUps {
            if followUp.isCompleted {
                if let completedAt = followUp.completedAt, completedAt >= recentWindowStart {
                    buckets.recentlyCompleted.append(followUp)
                }
                continue
            }

            if followUp.dueDate < startOfToday {
                buckets.overdue.append(followUp)
            } else if followUp.dueDate < endOfToday {
                buckets.dueToday.append(followUp)
            } else {
                buckets.upcoming.append(followUp)
            }
        }

        buckets.overdue.sort { $0.dueDate < $1.dueDate }
        buckets.dueToday.sort { $0.dueDate < $1.dueDate }
        buckets.upcoming.sort { $0.dueDate < $1.dueDate }
        buckets.recentlyCompleted.sort { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }

        return buckets
    }
}
