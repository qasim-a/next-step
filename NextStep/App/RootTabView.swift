import SwiftUI

struct RootTabView: View {
    private enum Tab {
        case today
        case contacts
    }

    @Environment(\.contactRepository) private var contactRepository
    @Environment(\.notificationRouter) private var notificationRouter
    @State private var selectedTab: Tab = .today
    @State private var contactsPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "checklist") }
                .tag(Tab.today)

            ContactListView(navigationPath: $contactsPath)
                .tabItem { Label("Contacts", systemImage: "person.crop.circle") }
                .tag(Tab.contacts)
        }
        .onChange(of: notificationRouter?.pendingContactID) { _, contactID in
            guard let contactID, let contactRepository else { return }
            guard let contact = try? contactRepository.fetch(id: contactID) else {
                notificationRouter?.pendingContactID = nil
                return
            }
            selectedTab = .contacts
            contactsPath = NavigationPath([contact])
            notificationRouter?.pendingContactID = nil
        }
    }
}
