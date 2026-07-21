import SwiftUI

/// Closure-based rather than tied to a specific view model: creating a follow-up happens from
/// `ContactDetailView` (via `FollowUpViewModel`), while editing/rescheduling happens from
/// `TodayView` (via `TodayViewModel`) — this lets both reuse the same form.
struct FollowUpFormView: View {
    @Environment(\.dismiss) private var dismiss

    var existingFollowUp: FollowUp?
    var onSave: (_ dueDate: Date, _ priority: FollowUpPriority, _ suggestedAction: String) async -> Bool

    @State private var dueDate: Date
    @State private var priority: FollowUpPriority
    @State private var suggestedAction: String

    init(
        existingFollowUp: FollowUp? = nil,
        originatingInteraction: Interaction? = nil,
        onSave: @escaping (Date, FollowUpPriority, String) async -> Bool
    ) {
        self.existingFollowUp = existingFollowUp
        self.onSave = onSave
        _dueDate = State(initialValue: existingFollowUp?.dueDate ?? .now)
        _priority = State(initialValue: existingFollowUp?.priority ?? .medium)
        _suggestedAction = State(
            initialValue: existingFollowUp?.suggestedAction ?? originatingInteraction?.nextAction ?? ""
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Follow-Up") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .accessibilityIdentifier("followUpForm.dueDatePicker")
                    Picker("Priority", selection: $priority) {
                        ForEach(FollowUpPriority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .accessibilityIdentifier("followUpForm.priorityPicker")
                }

                Section("Suggested Action") {
                    TextEditor(text: $suggestedAction)
                        .frame(minHeight: 100)
                        .accessibilityIdentifier("followUpForm.suggestedActionField")
                        .accessibilityLabel("Suggested Action")
                }
            }
            .navigationTitle(existingFollowUp == nil ? "Create Follow-Up" : "Edit Follow-Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("followUpForm.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier("followUpForm.saveButton")
                }
            }
        }
    }

    private func save() {
        Task {
            let didSave = await onSave(dueDate, priority, suggestedAction)
            if didSave {
                dismiss()
            }
        }
    }
}
