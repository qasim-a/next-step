import SwiftUI

struct DeveloperAnalyticsView: View {
    @Environment(\.analyticsTracking) private var analyticsTracking
    @Environment(\.experimentProviding) private var experimentProviding
    @Environment(\.dismiss) private var dismiss
    @State private var events: [AnalyticsEvent] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Reminder Copy Variant") {
                    LabeledContent("Assigned Variant", value: variantText)
                        .accessibilityIdentifier("developerAnalytics.variant")
                }

                Section("Events") {
                    if events.isEmpty {
                        Text("Analytics events will appear here as you use the app.")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("developerAnalytics.emptyState")
                    } else {
                        ForEach(events) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.type.displayName)
                                    .font(.headline)
                                Text(eventSubtitle(for: event))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityIdentifier("developerAnalytics.event")
                        }
                    }
                }
            }
            .navigationTitle("Developer Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("developerAnalytics.doneButton")
                }
            }
        }
        .accessibilityIdentifier("developerAnalytics.screen")
        .task { load() }
    }

    private var variantText: String {
        guard let experimentProviding else { return "—" }
        switch experimentProviding.reminderCopyVariant {
        case .control: return "Control"
        case .variant: return "Variant"
        }
    }

    private func eventSubtitle(for event: AnalyticsEvent) -> String {
        let timestamp = event.timestamp.formatted(date: .abbreviated, time: .shortened)
        if let contextLabel = event.contextLabel, !contextLabel.isEmpty {
            return "\(contextLabel) · \(timestamp)"
        }
        return timestamp
    }

    private func load() {
        guard let analyticsTracking else { return }
        events = (try? analyticsTracking.fetchRecentEvents()) ?? []
    }
}
