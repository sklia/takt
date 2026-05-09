import Foundation
import Observation

@Observable
final class SettingsStore {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private static let narratorEnabledKey = "narratorEnabled"
    @ObservationIgnored private static let hasShownWelcomeSheetKey = "hasShownWelcomeSheet"
    @ObservationIgnored private static let selectedVoiceIDKey = "selectedVoiceID"
    @ObservationIgnored private static let speechRateKey = "speechRate"
    @ObservationIgnored private static let showAllVoicesInPickerKey = "showAllVoicesInPicker"
    @ObservationIgnored private static let hasShownVoiceQualityNudgeKey = "hasShownVoiceQualityNudge"
    @ObservationIgnored private static let duckingLevelKey = "duckingLevel"
    @ObservationIgnored private static let pauseDuringFocusKey = "pauseDuringFocus"

    static let defaultSpeechRate: Float = 0.52
    static let defaultDuckingLevel: Float = 0.25

    var narratorEnabled: Bool {
        didSet { defaults.set(narratorEnabled, forKey: Self.narratorEnabledKey) }
    }

    var hasShownWelcomeSheet: Bool {
        didSet { defaults.set(hasShownWelcomeSheet, forKey: Self.hasShownWelcomeSheetKey) }
    }

    var selectedVoiceID: String? {
        didSet {
            if let selectedVoiceID {
                defaults.set(selectedVoiceID, forKey: Self.selectedVoiceIDKey)
            } else {
                defaults.removeObject(forKey: Self.selectedVoiceIDKey)
            }
        }
    }

    var speechRate: Float {
        didSet { defaults.set(speechRate, forKey: Self.speechRateKey) }
    }

    var showAllVoicesInPicker: Bool {
        didSet { defaults.set(showAllVoicesInPicker, forKey: Self.showAllVoicesInPickerKey) }
    }

    var hasShownVoiceQualityNudge: Bool {
        didSet { defaults.set(hasShownVoiceQualityNudge, forKey: Self.hasShownVoiceQualityNudgeKey) }
    }

    var duckingLevel: Float {
        didSet { defaults.set(duckingLevel, forKey: Self.duckingLevelKey) }
    }

    var pauseDuringFocus: Bool {
        didSet { defaults.set(pauseDuringFocus, forKey: Self.pauseDuringFocusKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.narratorEnabled = defaults.bool(forKey: Self.narratorEnabledKey)
        self.hasShownWelcomeSheet = defaults.bool(forKey: Self.hasShownWelcomeSheetKey)
        self.selectedVoiceID = defaults.string(forKey: Self.selectedVoiceIDKey)
        let storedRate = defaults.object(forKey: Self.speechRateKey) as? Float
        self.speechRate = storedRate ?? Self.defaultSpeechRate
        self.showAllVoicesInPicker = defaults.bool(forKey: Self.showAllVoicesInPickerKey)
        self.hasShownVoiceQualityNudge = defaults.bool(forKey: Self.hasShownVoiceQualityNudgeKey)
        let storedDuck = defaults.object(forKey: Self.duckingLevelKey) as? Float
        self.duckingLevel = storedDuck ?? Self.defaultDuckingLevel
        let storedPause = defaults.object(forKey: Self.pauseDuringFocusKey) as? Bool
        self.pauseDuringFocus = storedPause ?? true
    }
}
