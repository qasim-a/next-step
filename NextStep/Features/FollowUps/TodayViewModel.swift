import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var allFollowUps: [FollowUp] = []
    var errorMessage: String?

    private let repository: ContactRepository

    init(repository: ContactRepository) {
        self.repository = repository
        loadFollowUps()
    }

    func loadFollowUps() {
        do {
            allFollowUps = try repository.fetchAllFollowUps()
        } catch {
            errorMessage = "Couldn't load follow-ups. Please try again."
        }
    }

    @discardableResult
    func completeFollowUp(_ followUp: FollowUp) async -> Bool {
        do {
            try await repository.completeFollowUp(followUp)
            loadFollowUps()
            return true
        } catch {
            errorMessage = "Couldn't complete follow-up. Please try again."
            return false
        }
    }

    @discardableResult
    func deleteFollowUp(_ followUp: FollowUp) async -> Bool {
        do {
            try await repository.deleteFollowUp(followUp)
            loadFollowUps()
            return true
        } catch {
            errorMessage = "Couldn't delete follow-up. Please try again."
            return false
        }
    }

    @discardableResult
    func rescheduleFollowUp(
        _ followUp: FollowUp,
        dueDate: Date,
        priority: FollowUpPriority,
        suggestedAction: String
    ) async -> Bool {
        guard let contact = followUp.contact else { return false }
        followUp.dueDate = dueDate
        followUp.priority = priority
        let trimmed = suggestedAction.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.suggestedAction = trimmed.isEmpty ? nil : trimmed
        do {
            try await repository.saveFollowUp(followUp, for: contact)
            loadFollowUps()
            return true
        } catch {
            errorMessage = "Couldn't save follow-up. Please try again."
            return false
        }
    }
}
