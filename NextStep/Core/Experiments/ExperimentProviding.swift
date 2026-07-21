import Foundation
import SwiftUI

@MainActor
protocol ExperimentProviding {
    /// The reminder-copy variant assigned to this on-device installation. Assigned once, on
    /// first access, and persisted — every subsequent read returns the same value, never
    /// re-rolled per launch or per call.
    var reminderCopyVariant: ReminderCopyVariant { get }
}

private struct ExperimentProvidingKey: EnvironmentKey {
    static let defaultValue: ExperimentProviding? = nil
}

extension EnvironmentValues {
    var experimentProviding: ExperimentProviding? {
        get { self[ExperimentProvidingKey.self] }
        set { self[ExperimentProvidingKey.self] = newValue }
    }
}
