import SwiftUI

struct ContactDetailView: View {
    let contact: NetworkingContact
    var viewModel: ContactViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.contactRepository) private var contactRepository
    @State private var isPresentingEditForm = false
    @State private var isPresentingDeleteConfirmation = false
    @State private var interactionViewModel: InteractionViewModel?
    @State private var isPresentingLogInteractionForm = false
    @State private var interactionBeingEdited: Interaction?
    @State private var interactionPendingDeletion: Interaction?

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

            // Opportunities sections are added in later specifications; this List-of-Sections
            // structure lets them slot in without reworking the fields above.

            Section {
                Button("Log Interaction") {
                    isPresentingLogInteractionForm = true
                }
                .accessibilityIdentifier("contactDetail.logInteractionButton")
            }

            Section("Timeline") {
                let sortedInteractions = InteractionTimeline.sorted(interactionViewModel?.interactions ?? [])
                if sortedInteractions.isEmpty {
                    Text("No interactions logged yet. Tap Log Interaction to add the first one.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("contactDetail.timelineEmptyState")
                } else {
                    ForEach(sortedInteractions) { interaction in
                        Button {
                            interactionBeingEdited = interaction
                        } label: {
                            InteractionRow(interaction: interaction)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                interactionPendingDeletion = interaction
                            }
                            .accessibilityIdentifier("contactDetail.deleteInteractionButton")
                        }
                    }
                }
            }

            Section {
                Button("Delete Contact", role: .destructive) {
                    isPresentingDeleteConfirmation = true
                }
                .accessibilityIdentifier("contactDetail.deleteButton")
                .accessibilityHint("Requires confirmation")
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
        .sheet(isPresented: $isPresentingLogInteractionForm) {
            if let interactionViewModel {
                InteractionFormView(viewModel: interactionViewModel)
            }
        }
        .sheet(item: $interactionBeingEdited) { interaction in
            if let interactionViewModel {
                InteractionFormView(viewModel: interactionViewModel, existingInteraction: interaction)
            }
        }
        .confirmationDialog(
            "Delete this interaction?",
            isPresented: Binding(
                get: { interactionPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented { interactionPendingDeletion = nil }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let interactionPendingDeletion {
                    interactionViewModel?.deleteInteraction(interactionPendingDeletion)
                }
                interactionPendingDeletion = nil
            }
            .accessibilityIdentifier("contactDetail.confirmDeleteInteractionButton")
            Button("Cancel", role: .cancel) {
                interactionPendingDeletion = nil
            }
        } message: {
            Text("This can't be undone.")
        }
        .task {
            if interactionViewModel == nil, let contactRepository {
                interactionViewModel = InteractionViewModel(repository: contactRepository, contact: contact)
            }
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
