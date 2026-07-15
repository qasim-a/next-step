import SwiftUI

struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: ContactViewModel

    @State private var name = ""
    @State private var companyName = ""
    @State private var jobTitle = ""
    @State private var contactHandle = ""
    @State private var howWeMet = ""
    @State private var relationshipCategory: RelationshipCategory = .peer
    @State private var relationshipStrength = 3
    @State private var notes = ""
    @State private var showsNameRequiredError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("contactForm.nameField")
                    TextField("Company", text: $companyName)
                        .accessibilityIdentifier("contactForm.companyField")
                    TextField("Job Title", text: $jobTitle)
                    TextField("Email or LinkedIn", text: $contactHandle)
                }

                Section("Relationship") {
                    Picker("Category", selection: $relationshipCategory) {
                        ForEach(RelationshipCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .accessibilityIdentifier("contactForm.categoryPicker")
                    Stepper("Strength: \(relationshipStrength)", value: $relationshipStrength, in: 1...5)
                    TextField("How we met", text: $howWeMet)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .accessibilityIdentifier("contactForm.notesField")
                }

                if showsNameRequiredError {
                    Text("Name is required.")
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("contactForm.nameRequiredError")
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("contactForm.cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier("contactForm.saveButton")
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showsNameRequiredError = true
            return
        }
        let didSave = viewModel.createContact(
            name: name,
            companyName: companyName,
            jobTitle: jobTitle,
            contactHandle: contactHandle,
            howWeMet: howWeMet,
            relationshipCategory: relationshipCategory,
            relationshipStrength: relationshipStrength,
            notes: notes
        )
        if didSave {
            dismiss()
        }
    }
}
