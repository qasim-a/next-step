import Foundation
import SwiftData

@MainActor
final class SwiftDataContactRepository: ContactRepository {
    private let modelContext: ModelContext
    private let notificationScheduling: NotificationScheduling
    private let analyticsTracking: AnalyticsTracking

    init(
        modelContext: ModelContext,
        notificationScheduling: NotificationScheduling,
        analyticsTracking: AnalyticsTracking
    ) {
        self.modelContext = modelContext
        self.notificationScheduling = notificationScheduling
        self.analyticsTracking = analyticsTracking
    }

    func fetchAll() throws -> [NetworkingContact] {
        try modelContext.fetch(FetchDescriptor<NetworkingContact>())
    }

    func fetch(id: UUID) throws -> NetworkingContact? {
        var descriptor = FetchDescriptor<NetworkingContact>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func save(_ contact: NetworkingContact) throws {
        if contact.modelContext == nil {
            modelContext.insert(contact)
        }
        try modelContext.save()
    }

    func delete(_ contact: NetworkingContact) throws {
        // SwiftData's cascade delete rule removes the contact's follow-ups automatically, but it
        // has no way to know about the separate notification system, so pending reminders for
        // them are canceled here first. Fire-and-forget: cancellation is not correctness-critical
        // (the FollowUp row itself is synchronously cascade-deleted regardless), and keeping
        // delete(_:) synchronous avoids an async ripple through every Specification 1/2 call site.
        let followUpsToCancel = contact.followUps
        let scheduler = notificationScheduling
        Task {
            for followUp in followUpsToCancel {
                await scheduler.cancelReminder(for: followUp)
            }
        }

        modelContext.delete(contact)
        try modelContext.save()
    }

    func fetchAllCompanies() throws -> [Company] {
        try modelContext.fetch(FetchDescriptor<Company>())
    }

    func findOrCreateCompany(named name: String) throws -> Company {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTarget = trimmed.lowercased()
        let existing = try fetchAllCompanies().first {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTarget
        }
        if let existing {
            return existing
        }
        let company = Company(name: trimmed)
        modelContext.insert(company)
        try modelContext.save()
        return company
    }

    func fetchInteractions(for contact: NetworkingContact) throws -> [Interaction] {
        let contactID = contact.id
        let descriptor = FetchDescriptor<Interaction>(
            predicate: #Predicate { $0.contact?.id == contactID }
        )
        return try modelContext.fetch(descriptor)
    }

    func saveInteraction(_ interaction: Interaction, for contact: NetworkingContact) throws {
        if interaction.modelContext == nil {
            interaction.contact = contact
            modelContext.insert(interaction)
        }
        try modelContext.save()
        try recomputeLastInteractionDate(for: contact)
    }

    func deleteInteraction(_ interaction: Interaction) throws {
        let contact = interaction.contact
        modelContext.delete(interaction)
        try modelContext.save()
        if let contact {
            try recomputeLastInteractionDate(for: contact)
        }
    }

    private func recomputeLastInteractionDate(for contact: NetworkingContact) throws {
        let interactions = try fetchInteractions(for: contact)
        contact.lastInteractionDate = interactions.map(\.date).max()
        try modelContext.save()
    }

    func fetchFollowUps(for contact: NetworkingContact) throws -> [FollowUp] {
        let contactID = contact.id
        let descriptor = FetchDescriptor<FollowUp>(
            predicate: #Predicate { $0.contact?.id == contactID }
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllFollowUps() throws -> [FollowUp] {
        try modelContext.fetch(FetchDescriptor<FollowUp>())
    }

    func saveFollowUp(_ followUp: FollowUp, for contact: NetworkingContact) async throws {
        // Checked before insert: modelContext is nil only for a follow-up that has never been
        // persisted. This app's only path to calling saveFollowUp on an already-persisted
        // follow-up is the edit/reschedule form (see TodayViewModel.rescheduleFollowUp), so this
        // doubles as the create-vs-reschedule signal for analytics — see research.md.
        let isReschedule = followUp.modelContext != nil
        if followUp.modelContext == nil {
            followUp.contact = contact
            modelContext.insert(followUp)
        }
        try modelContext.save()

        if isReschedule {
            analyticsTracking.track(.followUpRescheduled, followUp: followUp)
        }

        // Cancel-then-reschedule covers both brand-new follow-ups and due-date changes on
        // existing ones uniformly; cancelReminder is always safe to call even when nothing was
        // previously scheduled.
        await notificationScheduling.cancelReminder(for: followUp)
        if !followUp.isCompleted {
            await notificationScheduling.scheduleReminder(for: followUp)
        }
    }

    func completeFollowUp(_ followUp: FollowUp) async throws {
        followUp.isCompleted = true
        followUp.completedAt = .now
        try modelContext.save()
        analyticsTracking.track(.followUpCompleted, followUp: followUp)
        await notificationScheduling.cancelReminder(for: followUp)
    }

    func deleteFollowUp(_ followUp: FollowUp) async throws {
        await notificationScheduling.cancelReminder(for: followUp)
        modelContext.delete(followUp)
        try modelContext.save()
    }
}
