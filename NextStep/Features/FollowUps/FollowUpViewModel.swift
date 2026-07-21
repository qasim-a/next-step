import Foundation
import Observation

@MainActor
@Observable
final class FollowUpViewModel {
    private(set) var followUps: [FollowUp] = []
    var errorMessage: String?

    private let repository: ContactRepository
    private let contact: NetworkingContact

    init(repository: ContactRepository, contact: NetworkingContact) {
        self.repository = repository
        self.contact = contact
        loadFollowUps()
    }

    func loadFollowUps() {
        do {
            followUps = try repository.fetchFollowUps(for: contact)
        } catch {
            errorMessage = "Couldn't load follow-ups. Please try again."
        }
    }

    @discardableResult
    func createFollowUp(
        dueDate: Date,
        priority: FollowUpPriority,
        suggestedAction: String,
        originatingInteraction: Interaction? = nil
    ) async -> Bool {
        let followUp = FollowUp(
            originatingInteraction: originatingInteraction,
            dueDate: dueDate,
            priority: priority,
            suggestedAction: nilIfBlank(suggestedAction)
        )
        do {
            try await repository.saveFollowUp(followUp, for: contact)
            loadFollowUps()
            return true
        } catch {
            errorMessage = "Couldn't save follow-up. Please try again."
            return false
        }
    }

    private func nilIfBlank(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
