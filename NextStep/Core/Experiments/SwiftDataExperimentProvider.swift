import Foundation
import SwiftData
import OSLog

@MainActor
final class SwiftDataExperimentProvider: ExperimentProviding {
    static let reminderCopyExperimentKey = "reminderCopy"

    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.nextstep.app.NextStep", category: "Experiments")
    private var cachedVariant: ReminderCopyVariant?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var reminderCopyVariant: ReminderCopyVariant {
        if let cachedVariant {
            return cachedVariant
        }

        let key = Self.reminderCopyExperimentKey
        let descriptor = FetchDescriptor<ExperimentAssignment>(
            predicate: #Predicate { $0.experimentKey == key }
        )

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                cachedVariant = existing.variant
                return existing.variant
            }

            let variant = ReminderCopyVariant.allCases.randomElement() ?? .control
            let assignment = ExperimentAssignment(experimentKey: key, variant: variant)
            modelContext.insert(assignment)
            cachedVariant = variant
            return variant
        } catch {
            logger.fault("Failed to read/assign experiment variant: \(error, privacy: .public)")
            return .control
        }
    }
}
