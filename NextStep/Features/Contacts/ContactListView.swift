import SwiftUI

struct ContactListView: View {
    @Environment(\.contactRepository) private var contactRepository
    @State private var viewModel: ContactViewModel?
    @State private var isPresentingContactForm = false
    @State private var searchText = ""
    @State private var selectedCategory: RelationshipCategory?
    @State private var isShowingDeveloperAnalytics = false
    @Binding var navigationPath: NavigationPath

    init(navigationPath: Binding<NavigationPath> = .constant(NavigationPath())) {
        _navigationPath = navigationPath
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Contacts")
            .searchable(text: $searchText, prompt: "Search by name or company")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingContactForm = true
                    } label: {
                        Label("Add Contact", systemImage: "plus")
                    }
                    .accessibilityIdentifier("contactList.addButton")
                }
                ToolbarItem(placement: .secondaryAction) {
                    categoryFilterMenu
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        isShowingDeveloperAnalytics = true
                    } label: {
                        Label("Developer Info", systemImage: "wrench.and.screwdriver")
                    }
                    .accessibilityIdentifier("contactList.developerInfoButton")
                    .accessibilityHint("Shows tracked analytics events and the current experiment variant")
                }
            }
            .sheet(isPresented: $isPresentingContactForm) {
                if let viewModel {
                    ContactFormView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $isShowingDeveloperAnalytics) {
                DeveloperAnalyticsView()
            }
            .navigationDestination(for: NetworkingContact.self) { contact in
                if let viewModel {
                    ContactDetailView(contact: contact, viewModel: viewModel)
                }
            }
        }
        .task {
            if viewModel == nil, let contactRepository {
                viewModel = ContactViewModel(repository: contactRepository)
            }
        }
    }

    private var categoryFilterMenu: some View {
        Menu {
            Button("All Categories") {
                selectedCategory = nil
            }
            Divider()
            ForEach(RelationshipCategory.allCases) { category in
                Button(category.displayName) {
                    selectedCategory = category
                }
            }
        } label: {
            Label(
                selectedCategory?.displayName ?? "Filter",
                systemImage: selectedCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill"
            )
        }
        .accessibilityIdentifier("contactList.categoryFilterMenu")
        .accessibilityHint("Filters contacts by relationship category")
    }

    @ViewBuilder
    private func content(for viewModel: ContactViewModel) -> some View {
        if viewModel.contacts.isEmpty {
            ContentUnavailableView(
                "No Contacts Yet",
                systemImage: "person.crop.circle.badge.plus",
                description: Text("Tap + to add the first person you've networked with.")
            )
            .accessibilityIdentifier("contactList.emptyState")
        } else {
            let filteredContacts = ContactFiltering.filter(
                viewModel.contacts,
                searchText: searchText,
                category: selectedCategory
            )

            if filteredContacts.isEmpty {
                ContentUnavailableView(
                    "No Matching Contacts",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search or clear the category filter.")
                )
                .accessibilityIdentifier("contactList.noResultsState")
            } else {
                List(filteredContacts) { contact in
                    NavigationLink(value: contact) {
                        ContactRow(contact: contact)
                    }
                }
                .accessibilityIdentifier("contactList.list")
            }
        }
    }
}

private struct ContactRow: View {
    let contact: NetworkingContact

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contact.name)
                .font(.headline)
            if let company = contact.company?.name, !company.isEmpty {
                Text(company)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
