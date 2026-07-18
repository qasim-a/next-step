import SwiftUI

struct InteractionFormView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: InteractionViewModel
    var existingInteraction: Interaction?

    @State private var type: InteractionType
    @State private var date: Date
    @State private var notes: String
    @State private var outcome: String
    @State private var nextAction: String

    init(viewModel: InteractionViewModel, existingInteraction: Interaction? = nil) {
        self.viewModel = viewModel
        self.existingInteraction = existingInteraction
        _type = State(initialValue: existingInteraction?.type ?? .email)
        _date = State(initialValue: existingInteraction?.date ?? .now)
        _notes = State(initialValue: existingInteraction?.notes ?? "")
        _outcome = State(initialValue: existingInteraction?.outcome ?? "")
        _nextAction = State(initialValue: existingInteraction?.nextAction ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Interaction") {
                    Picker("Type", selection: $type) {
                        ForEach(InteractionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .accessibilityIdentifier("interactionForm.typePicker")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("interactionForm.datePicker")
                }

                Section("Details") {
                    TextField("Outcome", text: $outcome)
                        .accessibilityIdentifier("interactionForm.outcomeField")
                    TextField("Next action", text: $nextAction)
                        .accessibilityIdentifier("interactionForm.nextActionField")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .accessibilityIdentifier("interactionForm.notesField")
                        .accessibilityLabel("Notes")
                }
            }
            .navigationTitle(existingInteraction == nil ? "Log Interaction" : "Edit Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("interactionForm.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier("interactionForm.saveButton")
                }
            }
        }
    }

    private func save() {
        let didSave: Bool
        if let existingInteraction {
            didSave = viewModel.updateInteraction(
                existingInteraction,
                type: type,
                date: date,
                notes: notes,
                outcome: outcome,
                nextAction: nextAction
            )
        } else {
            didSave = viewModel.logInteraction(
                type: type,
                date: date,
                notes: notes,
                outcome: outcome,
                nextAction: nextAction
            )
        }
        if didSave {
            dismiss()
        }
    }
}
