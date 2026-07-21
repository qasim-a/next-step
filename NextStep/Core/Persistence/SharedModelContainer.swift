import Foundation
import SwiftData

/// Compiled into both the `NextStep` app target and the `NextStepWidget` extension target, so
/// both construct an identical `ModelContainer` pointing at the same on-disk location — a widget
/// extension is a separate sandboxed process and cannot read the app's private container, so the
/// real (non-test) store lives inside a shared App Group container instead. See
/// specs/005-polish/research.md.
enum SharedModelContainer {
    static let appGroupIdentifier = "group.com.nextstep.app.NextStep"

    static func make(inMemory: Bool) -> ModelContainer {
        let schema = Schema([
            NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
            ExperimentAssignment.self, AnalyticsEvent.self,
        ])

        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            ) else {
                fatalError("App Group container unavailable: \(appGroupIdentifier)")
            }
            let storeURL = containerURL.appendingPathComponent("NextStep.sqlite")
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        }

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }
}
