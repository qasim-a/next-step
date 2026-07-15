import SwiftUI

struct ContactListView: View {
    @Environment(\.contactRepository) private var contactRepository
    @State private var viewModel: ContactViewModel?
    @State private var isPresentingContactForm = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingContactForm = true
                    } label: {
                        Label("Add Contact", systemImage: "plus")
                    }
                    .accessibilityIdentifier("contactList.addButton")
                }
            }
            .sheet(isPresented: $isPresentingContactForm) {
                if let viewModel {
                    ContactFormView(viewModel: viewModel)
                }
            }
        }
        .task {
            if viewModel == nil, let contactRepository {
                viewModel = ContactViewModel(repository: contactRepository)
            }
        }
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
            List(viewModel.contacts) { contact in
                ContactRow(contact: contact)
            }
            .accessibilityIdentifier("contactList.list")
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
