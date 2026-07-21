import SwiftUI

struct FollowUpSummaryView: View {
    @Environment(\.contactRepository) private var contactRepository
    @Environment(\.dismiss) private var dismiss
    @State private var summary = FollowUpSummary()

    var body: some View {
        NavigationStack {
            Group {
                if summary.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Summarize Yet",
                        systemImage: "chart.bar",
                        description: Text("Create a follow-up to start tracking your completion rate.")
                    )
                    .accessibilityIdentifier("followUpSummary.emptyState")
                } else {
                    List {
                        Section {
                            LabeledContent("Completion Rate", value: completionRateText)
                                .accessibilityIdentifier("followUpSummary.completionRate")
                        }
                        Section("Follow-Ups") {
                            LabeledContent("Completed", value: "\(summary.completedCount)")
                                .accessibilityIdentifier("followUpSummary.completedCount")
                            LabeledContent("Overdue", value: "\(summary.overdueCount)")
                                .accessibilityIdentifier("followUpSummary.overdueCount")
                            LabeledContent("Upcoming", value: "\(summary.upcomingCount)")
                                .accessibilityIdentifier("followUpSummary.upcomingCount")
                        }
                    }
                    .accessibilityIdentifier("followUpSummary.list")
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("followUpSummary.doneButton")
                }
            }
        }
        .accessibilityIdentifier("followUpSummary.screen")
        .task { load() }
    }

    private var completionRateText: String {
        guard let rate = summary.completionRate else { return "—" }
        return rate.formatted(.percent.precision(.fractionLength(0)))
    }

    private func load() {
        guard let followUps = try? contactRepository?.fetchAllFollowUps() else { return }
        summary = FollowUpInsights.summarize(followUps)
    }
}
