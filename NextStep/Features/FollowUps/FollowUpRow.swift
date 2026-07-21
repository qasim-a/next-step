import SwiftUI

struct FollowUpRow: View {
    let followUp: FollowUp

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(followUp.contact?.name ?? "Unknown Contact")
                    .font(.headline)
                Spacer()
                priorityBadge
            }
            Text(followUp.dueDate.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let suggestedAction = followUp.suggestedAction, !suggestedAction.isEmpty {
                Text(suggestedAction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var priorityBadge: some View {
        Text(followUp.priority.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .foregroundStyle(priorityColor)
            .clipShape(Capsule())
    }

    private var priorityColor: Color {
        switch followUp.priority {
        case .low: .gray
        case .medium: .blue
        case .high: .red
        }
    }
}
