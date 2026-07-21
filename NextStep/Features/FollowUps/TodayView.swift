import SwiftUI

struct TodayView: View {
    @Environment(\.contactRepository) private var contactRepository
    @Environment(\.notificationScheduling) private var notificationScheduling
    @State private var viewModel: TodayViewModel?
    @State private var followUpBeingEdited: FollowUp?
    @State private var followUpPendingDeletion: FollowUp?
    @State private var hasRequestedNotificationAuthorization = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Today")
            .sheet(item: $followUpBeingEdited) { followUp in
                FollowUpFormView(existingFollowUp: followUp) { dueDate, priority, suggestedAction in
                    await viewModel?.rescheduleFollowUp(
                        followUp, dueDate: dueDate, priority: priority, suggestedAction: suggestedAction
                    ) ?? false
                }
            }
            .confirmationDialog(
                "Delete this follow-up?",
                isPresented: Binding(
                    get: { followUpPendingDeletion != nil },
                    set: { isPresented in
                        if !isPresented { followUpPendingDeletion = nil }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let followUpPendingDeletion {
                        Task { await viewModel?.deleteFollowUp(followUpPendingDeletion) }
                    }
                    followUpPendingDeletion = nil
                }
                .accessibilityIdentifier("today.confirmDeleteButton")
                Button("Cancel", role: .cancel) {
                    followUpPendingDeletion = nil
                }
            } message: {
                Text("This can't be undone.")
            }
        }
        .onAppear {
            // TabView keeps every tab's view alive, so .task (which only runs once per view
            // identity) isn't enough to catch follow-ups created elsewhere while this tab wasn't
            // visible — .onAppear fires every time the user switches back to this tab too.
            viewModel?.loadFollowUps()
        }
        .task {
            if viewModel == nil, let contactRepository {
                viewModel = TodayViewModel(repository: contactRepository)
            }
            if !hasRequestedNotificationAuthorization, let notificationScheduling {
                hasRequestedNotificationAuthorization = true
                _ = await notificationScheduling.requestAuthorizationIfNeeded()
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: TodayViewModel) -> some View {
        let buckets = FollowUpBucketing.bucket(viewModel.allFollowUps)
        if buckets.isEmpty {
            ContentUnavailableView(
                "No Follow-Ups Yet",
                systemImage: "checkmark.circle",
                description: Text("Create a follow-up from a contact to see it here.")
            )
            .accessibilityIdentifier("today.emptyState")
        } else {
            List {
                section("Overdue", followUps: buckets.overdue, identifier: "today.overdueSection", viewModel: viewModel)
                section("Due Today", followUps: buckets.dueToday, identifier: "today.dueTodaySection", viewModel: viewModel)
                section("Upcoming", followUps: buckets.upcoming, identifier: "today.upcomingSection", viewModel: viewModel)
                section(
                    "Recently Completed", followUps: buckets.recentlyCompleted,
                    identifier: "today.recentlyCompletedSection", viewModel: viewModel, allowsActions: false
                )
            }
            .accessibilityIdentifier("today.list")
        }
    }

    @ViewBuilder
    private func section(
        _ title: String,
        followUps: [FollowUp],
        identifier: String,
        viewModel: TodayViewModel,
        allowsActions: Bool = true
    ) -> some View {
        if !followUps.isEmpty {
            Section(title) {
                ForEach(followUps) { followUp in
                    if allowsActions {
                        FollowUpRow(followUp: followUp)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                followUpBeingEdited = followUp
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    followUpPendingDeletion = followUp
                                }
                                .accessibilityIdentifier("today.deleteFollowUpButton")
                                .accessibilityHint("Requires confirmation")
                            }
                            .swipeActions(edge: .leading) {
                                Button("Complete") {
                                    Task { await viewModel.completeFollowUp(followUp) }
                                }
                                .tint(.green)
                                .accessibilityIdentifier("today.completeFollowUpButton")
                                .accessibilityHint("Marks this follow-up as done")
                            }
                    } else {
                        FollowUpRow(followUp: followUp)
                    }
                }
            }
            .accessibilityIdentifier(identifier)
        }
    }
}
