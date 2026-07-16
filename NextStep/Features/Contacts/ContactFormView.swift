import SwiftUI

struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: ContactViewModel
    var existingContact: NetworkingContact?

    @State private var name: String
    @State private var companyName: String
    @State private var jobTitle: String
    @State private var contactHandle: String
    @State private var howWeMet: String
    @State private var relationshipCategory: RelationshipCategory
    @State private var relationshipStrength: Int
    @State private var notes: String
    @State private var showsNameRequiredError = false

    init(viewModel: ContactViewModel, existingContact: NetworkingContact? = nil) {
        self.viewModel = viewModel
        self.existingContact = existingContact
        _name = State(initialValue: existingContact?.name ?? "")
        _companyName = State(initialValue: existingContact?.company?.name ?? "")
        _jobTitle = State(initialValue: existingContact?.jobTitle ?? "")
        _contactHandle = State(initialValue: existingContact?.contactHandle ?? "")
        _howWeMet = State(initialValue: existingContact?.howWeMet ?? "")
        _relationshipCategory = State(initialValue: existingContact?.relationshipCategory ?? .peer)
        _relationshipStrength = State(initialValue: existingContact?.relationshipStrength ?? 3)
        _notes = State(initialValue: existingContact?.notes ?? "")
    }

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
            .navigationTitle(existingContact == nil ? "New Contact" : "Edit Contact")
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

        let didSave: Bool
        if let existingContact {
            didSave = viewModel.updateContact(
                existingContact,
                name: name,
                companyName: companyName,
                jobTitle: jobTitle,
                contactHandle: contactHandle,
                howWeMet: howWeMet,
                relationshipCategory: relationshipCategory,
                relationshipStrength: relationshipStrength,
                notes: notes
            )
        } else {
            didSave = viewModel.createContact(
                name: name,
                companyName: companyName,
                jobTitle: jobTitle,
                contactHandle: contactHandle,
                howWeMet: howWeMet,
                relationshipCategory: relationshipCategory,
                relationshipStrength: relationshipStrength,
                notes: notes
            )
        }

        if didSave {
            dismiss()
        }
    }
}
