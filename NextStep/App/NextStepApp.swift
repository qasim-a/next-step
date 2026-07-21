import SwiftUI
import SwiftData
import UserNotifications

@main
struct NextStepApp: App {
    private let modelContainer: ModelContainer
    private let contactRepository: ContactRepository
    private let notificationScheduling: NotificationScheduling
    private let experimentProviding: ExperimentProviding
    private let analyticsTracking: AnalyticsTracking
    private let notificationRouter = NotificationRouter()
    private let notificationDelegate: NotificationDelegate

    init() {
        do {
            if Self.isRunningUnderTest {
                // Unit tests (hosted inside this app process) and UI tests each manage their
                // own SwiftData container; avoid this app also standing up the real on-disk
                // store, which would otherwise double-initialize the same model types.
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(
                    for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
                    ExperimentAssignment.self, AnalyticsEvent.self,
                    configurations: configuration
                )
            } else {
                modelContainer = try ModelContainer(
                    for: NetworkingContact.self, Company.self, Interaction.self, FollowUp.self,
                    ExperimentAssignment.self, AnalyticsEvent.self
                )
            }
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }

        experimentProviding = SwiftDataExperimentProvider(modelContext: modelContainer.mainContext)
        analyticsTracking = SwiftDataAnalyticsTracker(modelContext: modelContainer.mainContext)

        // Under automated tests, the real UNUserNotificationCenter permission dialog cannot be
        // reliably driven by XCUITest, so the app runs against a no-op scheduler instead — see
        // specs/003-followups-notifications/research.md.
        notificationScheduling = Self.isRunningUnderTest
            ? NoOpNotificationScheduler()
            : UNNotificationScheduler(experimentProviding: experimentProviding)

        contactRepository = SwiftDataContactRepository(
            modelContext: modelContainer.mainContext,
            notificationScheduling: notificationScheduling,
            analyticsTracking: analyticsTracking
        )

        notificationDelegate = NotificationDelegate(router: notificationRouter, analyticsTracking: analyticsTracking)
        UNUserNotificationCenter.current().delegate = notificationDelegate

        // Required for UNNotificationDismissActionIdentifier to ever reach the delegate — by
        // default, swiping away a notification without opening the app is not reported at all.
        // See specs/004-experiments-analytics/research.md.
        let category = UNNotificationCategory(
            identifier: UNNotificationScheduler.reminderCategoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private static var isRunningUnderTest: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.arguments.contains("-UITestResetState")
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
        .environment(\.contactRepository, contactRepository)
        .environment(\.notificationScheduling, notificationScheduling)
        .environment(\.notificationRouter, notificationRouter)
        .environment(\.experimentProviding, experimentProviding)
        .environment(\.analyticsTracking, analyticsTracking)
    }
}
