import SwiftUI

struct InteractionRow: View {
    let interaction: Interaction

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(interaction.type.displayName)
                    .font(.headline)
                Spacer()
                Text(interaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let outcome = interaction.outcome, !outcome.isEmpty {
                Text(outcome)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
