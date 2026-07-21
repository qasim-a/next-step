import WidgetKit
import SwiftUI

struct FollowUpWidget: Widget {
    let kind = "FollowUpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FollowUpWidgetTimelineProvider()) { entry in
            FollowUpWidgetView(entry: entry)
                .widgetURL(URL(string: "nextstep://today"))
        }
        .configurationDisplayName("Follow-Ups")
        .description("See your next overdue or due-today follow-ups.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FollowUpWidgetView: View {
    let entry: FollowUpWidgetEntry

    var body: some View {
        Group {
            if entry.followUps.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Nothing Due")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.followUps) { followUp in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(followUp.contact?.name ?? "Unknown Contact")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text(followUp.dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

#Preview(as: .systemSmall) {
    FollowUpWidget()
} timeline: {
    FollowUpWidgetEntry(date: .now, followUps: [])
}
