import SwiftUI

struct ContactDetailView: View {
    // SwiftUI does not reliably present more than one .sheet(...) modifier attached to the same
    // view — a third sheet added for interaction-editing silently failed to present. All sheet
    // content is now dispatched through this single enum + one .sheet(item:) instead.
    private enum ActiveSheet: Identifiable {
        case editContact
        case logInteraction
        case editInteraction(Interaction)
        case createFollowUp
        case createFollowUpFromInteraction(Interaction)

        var id: String {
            switch self {
            case .editContact: "editContact"
            case .logInteraction: "logInteraction"
            case .editInteraction(let interaction): "editInteraction-\(interaction.id)"
            case .createFollowUp: "createFollowUp"
            case .createFollowUpFromInteraction(let interaction): "createFollowUpFromInteraction-\(interaction.id)"
            }
        }
    }

    let contact: NetworkingContact
    var viewModel: ContactViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.contactRepository) private var contactRepository
    @Environment(\.analyticsTracking) private var analyticsTracking
    @State private var activeSheet: ActiveSheet?
    @State private var isPresentingDeleteConfirmation = false
    @State private var interactionViewModel: InteractionViewModel?
    @State private var interactionPendingDeletion: Interaction?
    @State private var followUpViewModel: FollowUpViewModel?
    @State private var hasTrackedOpen = false

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
                    activeSheet = .logInteraction
                }
                .accessibilityHint("Adds a new interaction to this contact's timeline")
                .accessibilityIdentifier("contactDetail.logInteractionButton")

                Button("Create Follow-Up") {
                    activeSheet = .createFollowUp
                }
                .accessibilityIdentifier("contactDetail.createFollowUpButton")
                .accessibilityHint("Schedules a reminder to follow up with this contact")
            }

            Section("Timeline") {
                let sortedInteractions = InteractionTimeline.sorted(interactionViewModel?.interactions ?? [])
                if sortedInteractions.isEmpty {
                    Text("No interactions logged yet. Tap Log Interaction to add the first one.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("contactDetail.timelineEmptyState")
                } else {
                    ForEach(sortedInteractions) { interaction in
                        InteractionRow(interaction: interaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeSheet = .editInteraction(interaction)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    interactionPendingDeletion = interaction
                                }
                                .accessibilityIdentifier("contactDetail.deleteInteractionButton")
                                .accessibilityHint("Requires confirmation")
                            }
                            .swipeActions(edge: .leading) {
                                Button("Follow Up") {
                                    activeSheet = .createFollowUpFromInteraction(interaction)
                                }
                                .tint(.blue)
                                .accessibilityIdentifier("contactDetail.createFollowUpFromInteractionButton")
                                .accessibilityHint("Creates a follow-up pre-filled from this interaction's next action")
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
                    activeSheet = .editContact
                }
                .accessibilityIdentifier("contactDetail.editButton")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editContact:
                ContactFormView(viewModel: viewModel, existingContact: contact)
            case .logInteraction:
                if let interactionViewModel {
                    InteractionFormView(viewModel: interactionViewModel)
                }
            case .editInteraction(let interaction):
                if let interactionViewModel {
                    InteractionFormView(viewModel: interactionViewModel, existingInteraction: interaction)
                }
            case .createFollowUp:
                if let followUpViewModel {
                    FollowUpFormView { dueDate, priority, suggestedAction in
                        await followUpViewModel.createFollowUp(
                            dueDate: dueDate, priority: priority, suggestedAction: suggestedAction
                        )
                    }
                }
            case .createFollowUpFromInteraction(let interaction):
                if let followUpViewModel {
                    FollowUpFormView(originatingInteraction: interaction) { dueDate, priority, suggestedAction in
                        await followUpViewModel.createFollowUp(
                            dueDate: dueDate, priority: priority, suggestedAction: suggestedAction,
                            originatingInteraction: interaction
                        )
                    }
                }
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
            if followUpViewModel == nil, let contactRepository {
                followUpViewModel = FollowUpViewModel(repository: contactRepository, contact: contact)
            }
        }
        .onAppear {
            // Guarded because SwiftUI re-invokes onAppear when a sheet presented from this view
            // is dismissed (editing, logging an interaction, creating a follow-up) — without this,
            // one visit would record several contactOpened events. See
            // specs/004-experiments-analytics/research.md.
            guard !hasTrackedOpen else { return }
            hasTrackedOpen = true
            analyticsTracking?.track(.contactOpened, contact: contact)
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
