import Foundation
import SwiftData
import OSLog

@MainActor
final class SwiftDataAnalyticsTracker: AnalyticsTracking {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.nextstep.app.NextStep", category: "Analytics")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func track(_ type: AnalyticsEventType, contactID: UUID?, contactName: String?, followUpID: UUID?) {
        let event = AnalyticsEvent(
            type: type,
            contactID: contactID,
            followUpID: followUpID,
            contextLabel: contactName
        )

        logger.log("\(type.rawValue, privacy: .public) contact=\(contactName ?? "-", privacy: .private)")

        modelContext.insert(event)
        do {
            try modelContext.save()
        } catch {
            logger.fault("Failed to persist analytics event: \(error, privacy: .public)")
        }
    }

    func fetchRecentEvents() throws -> [AnalyticsEvent] {
        var descriptor = FetchDescriptor<AnalyticsEvent>()
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
}
