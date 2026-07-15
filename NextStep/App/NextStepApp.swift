import SwiftUI
import SwiftData

@main
struct NextStepApp: App {
    private let modelContainer: ModelContainer
    private let contactRepository: ContactRepository

    init() {
        do {
            if Self.isRunningUnderTest {
                // Unit tests (hosted inside this app process) and UI tests each manage their
                // own SwiftData container; avoid this app also standing up the real on-disk
                // store, which would otherwise double-initialize the same model types.
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(
                    for: NetworkingContact.self, Company.self,
                    configurations: configuration
                )
            } else {
                modelContainer = try ModelContainer(for: NetworkingContact.self, Company.self)
            }
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
        contactRepository = SwiftDataContactRepository(modelContext: modelContainer.mainContext)
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
    }
}
