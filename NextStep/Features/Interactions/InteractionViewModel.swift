import Foundation
import Observation

@MainActor
@Observable
final class InteractionViewModel {
    private(set) var interactions: [Interaction] = []
    var errorMessage: String?

    private let repository: ContactRepository
    private let contact: NetworkingContact

    init(repository: ContactRepository, contact: NetworkingContact) {
        self.repository = repository
        self.contact = contact
        loadInteractions()
    }

    func loadInteractions() {
        do {
            interactions = try repository.fetchInteractions(for: contact)
        } catch {
            errorMessage = "Couldn't load interactions. Please try again."
        }
    }

    @discardableResult
    func logInteraction(
        type: InteractionType,
        date: Date,
        notes: String,
        outcome: String,
        nextAction: String
    ) -> Bool {
        let interaction = Interaction(type: type, date: date)
        return applyAndSave(
            type: type, date: date, notes: notes, outcome: outcome, nextAction: nextAction,
            to: interaction
        )
    }

    @discardableResult
    func updateInteraction(
        _ interaction: Interaction,
        type: InteractionType,
        date: Date,
        notes: String,
        outcome: String,
        nextAction: String
    ) -> Bool {
        applyAndSave(
            type: type, date: date, notes: notes, outcome: outcome, nextAction: nextAction,
            to: interaction
        )
    }

    @discardableResult
    func deleteInteraction(_ interaction: Interaction) -> Bool {
        do {
            try repository.deleteInteraction(interaction)
            loadInteractions()
            return true
        } catch {
            errorMessage = "Couldn't delete interaction. Please try again."
            return false
        }
    }

    private func applyAndSave(
        type: InteractionType,
        date: Date,
        notes: String,
        outcome: String,
        nextAction: String,
        to interaction: Interaction
    ) -> Bool {
        do {
            interaction.type = type
            interaction.date = date
            interaction.notes = nilIfBlank(notes)
            interaction.outcome = nilIfBlank(outcome)
            interaction.nextAction = nilIfBlank(nextAction)
            try repository.saveInteraction(interaction, for: contact)
            loadInteractions()
            return true
        } catch {
            errorMessage = "Couldn't save interaction. Please try again."
            return false
        }
    }

    private func nilIfBlank(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
