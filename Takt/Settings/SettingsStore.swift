import Foundation
import Observation

@Observable
final class SettingsStore {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private static let narratorEnabledKey = "narratorEnabled"
    @ObservationIgnored private static let hasShownWelcomeSheetKey = "hasShownWelcomeSheet"

    var narratorEnabled: Bool {
        didSet { defaults.set(narratorEnabled, forKey: Self.narratorEnabledKey) }
    }

    var hasShownWelcomeSheet: Bool {
        didSet { defaults.set(hasShownWelcomeSheet, forKey: Self.hasShownWelcomeSheetKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.narratorEnabled = defaults.bool(forKey: Self.narratorEnabledKey)
        self.hasShownWelcomeSheet = defaults.bool(forKey: Self.hasShownWelcomeSheetKey)
    }
}
