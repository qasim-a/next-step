import SwiftUI
import SwiftData

@main
struct NextStepApp: App {
    private let modelContainer: ModelContainer
    private let contactRepository: ContactRepository
    private let notificationScheduling: NotificationScheduling

    init() {
        do {
            if Self.isRunningUnderTest {
                // Unit tests (hosted inside this app process) and UI tests each manage their
                // own SwiftData container; avoid this app also standing up the real on-disk
                // store, which would otherwise double-initialize the same model types.
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(
                    for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
                    configurations: configuration
                )
            } else {
                modelContainer = try ModelContainer(
                    for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self
                )
            }
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }

        // Under automated tests, the real UNUserNotificationCenter permission dialog cannot be
        // reliably driven by XCUITest, so the app runs against a no-op scheduler instead — see
        // specs/003-followups-notifications/research.md.
        notificationScheduling = Self.isRunningUnderTest
            ? NoOpNotificationScheduler()
            : UNNotificationScheduler()

        contactRepository = SwiftDataContactRepository(
            modelContext: modelContainer.mainContext,
            notificationScheduling: notificationScheduling
        )
    }

    private static var isRunningUnderTest: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.arguments.contains("-UITestResetState")
    }

    var body: some Scene {
        WindowGroup {
            ContactListView()
        }
        .modelContainer(modelContainer)
        .environment(\.contactRepository, contactRepository)
        .environment(\.notificationScheduling, notificationScheduling)
    }
}
