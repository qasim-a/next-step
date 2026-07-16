import Foundation

enum InteractionTimeline {
    /// Orders interactions most-recent-first by date, breaking ties between same-dated
    /// interactions by creation order (most recently created first) for a stable ordering.
    static func sorted(_ interactions: [Interaction]) -> [Interaction] {
        interactions.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date > rhs.date
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}
