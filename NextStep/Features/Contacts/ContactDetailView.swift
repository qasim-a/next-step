import SwiftUI

struct ContactDetailView: View {
    let contact: NetworkingContact
    var viewModel: ContactViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isPresentingEditForm = false
    @State private var isPresentingDeleteConfirmation = false

    var body: some View {
        List {
            Section("Contact") {
                LabeledContent("Name", value: contact.name)
                    .accessibilityIdentifier("contactDetail.name")
                if let company = contact.company?.name, !company.isEmpty {
                    LabeledContent("Company", value: company)
                        .accessibilityIdentifier("contactDetail.company")
                }
                if let jobTitle = contact.jobTitle, !jobTitle.isEmpty {
                    LabeledContent("Job Title", value: jobTitle)
                }
                if let contactHandle = contact.contactHandle, !contactHandle.isEmpty {
                    LabeledContent("Email or LinkedIn", value: contactHandle)
                }
            }

            Section("Relationship") {
                LabeledContent("Category", value: contact.relationshipCategory.displayName)
                LabeledContent("Strength", value: "\(contact.relationshipStrength)/5")
                if let howWeMet = contact.howWeMet, !howWeMet.isEmpty {
                    LabeledContent("How We Met", value: howWeMet)
                }
                if let lastInteractionDate = contact.lastInteractionDate {
                    LabeledContent("Last Interaction", value: lastInteractionDate.formatted(date: .abbreviated, time: .omitted))
                }
            }

            if let notes = contact.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            // Interaction history and opportunities sections are added in later specifications;
            // this List-of-Sections structure lets them slot in without reworking the fields above.

            Section {
                Button("Delete Contact", role: .destructive) {
                    isPresentingDeleteConfirmation = true
                }
                .accessibilityIdentifier("contactDetail.deleteButton")
            }
        }
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("contactDetail.screen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isPresentingEditForm = true
                }
                .accessibilityIdentifier("contactDetail.editButton")
            }
        }
        .sheet(isPresented: $isPresentingEditForm) {
            ContactFormView(viewModel: viewModel, existingContact: contact)
        }
        .confirmationDialog(
            "Delete \(contact.name)?",
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteContact(contact)
                dismiss()
            }
            .accessibilityIdentifier("contactDetail.confirmDeleteButton")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }
}
