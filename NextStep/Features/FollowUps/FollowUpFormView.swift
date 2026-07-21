import SwiftUI

struct FollowUpFormView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: FollowUpViewModel
    var originatingInteraction: Interaction?

    @State private var dueDate: Date
    @State private var priority: FollowUpPriority
    @State private var suggestedAction: String

    init(viewModel: FollowUpViewModel, originatingInteraction: Interaction? = nil) {
        self.viewModel = viewModel
        self.originatingInteraction = originatingInteraction
        _dueDate = State(initialValue: .now)
        _priority = State(initialValue: .medium)
        _suggestedAction = State(initialValue: originatingInteraction?.nextAction ?? "")
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
            .navigationTitle("Create Follow-Up")
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
            let didSave = await viewModel.createFollowUp(
                dueDate: dueDate,
                priority: priority,
                suggestedAction: suggestedAction,
                originatingInteraction: originatingInteraction
            )
            if didSave {
                dismiss()
            }
        }
    }
}
