import SwiftUI

struct InteractionFormView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: InteractionViewModel

    @State private var type: InteractionType = .email
    @State private var date: Date = .now
    @State private var notes: String = ""
    @State private var outcome: String = ""
    @State private var nextAction: String = ""

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
            .navigationTitle("Log Interaction")
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
        let didSave = viewModel.logInteraction(
            type: type,
            date: date,
            notes: notes,
            outcome: outcome,
            nextAction: nextAction
        )
        if didSave {
            dismiss()
        }
    }
}
