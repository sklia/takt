import Foundation
import Observation

@Observable
final class SettingsStore {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private static let narratorEnabledKey = "narratorEnabled"

    var narratorEnabled: Bool {
        didSet { defaults.set(narratorEnabled, forKey: Self.narratorEnabledKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.narratorEnabled = defaults.bool(forKey: Self.narratorEnabledKey)
    }
}
