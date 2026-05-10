import Foundation
import Observation

@MainActor
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
    @ObservationIgnored private static let showHUDKey = "showHUD"
    @ObservationIgnored private static let hudStyleKey = "hudStyle"
    @ObservationIgnored private static let hudPositionKey = "hudPosition"
    @ObservationIgnored private static let hudFollowsFocusedScreenKey = "hudFollowsFocusedScreen"
    @ObservationIgnored private static let announceArtistKey = "announceArtist"
    @ObservationIgnored private static let announceTitleKey = "announceTitle"
    @ObservationIgnored private static let announceAlbumKey = "announceAlbum"
    @ObservationIgnored private static let hudDismissDelayKey = "hudDismissDelay"
    @ObservationIgnored private static let announcementDelayKey = "announcementDelay"

    static let defaultSpeechRate: Float = 0.52
    static let defaultDuckingLevel: Float = 0.25
    static let defaultHUDDismissDelay: TimeInterval = 4.0
    static let defaultAnnouncementDelay: TimeInterval = 0.0

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

    var showHUD: Bool {
        didSet { defaults.set(showHUD, forKey: Self.showHUDKey) }
    }

    var hudStyle: HUDStyle {
        didSet { defaults.set(hudStyle.rawValue, forKey: Self.hudStyleKey) }
    }

    var hudPosition: HUDPosition {
        didSet { defaults.set(hudPosition.rawValue, forKey: Self.hudPositionKey) }
    }

    var hudFollowsFocusedScreen: Bool {
        didSet { defaults.set(hudFollowsFocusedScreen, forKey: Self.hudFollowsFocusedScreenKey) }
    }

    var announceArtist: Bool {
        didSet { defaults.set(announceArtist, forKey: Self.announceArtistKey) }
    }

    var announceTitle: Bool {
        didSet { defaults.set(announceTitle, forKey: Self.announceTitleKey) }
    }

    var announceAlbum: Bool {
        didSet { defaults.set(announceAlbum, forKey: Self.announceAlbumKey) }
    }

    var hudDismissDelay: TimeInterval {
        didSet { defaults.set(hudDismissDelay, forKey: Self.hudDismissDelayKey) }
    }

    var announcementDelay: TimeInterval {
        didSet { defaults.set(announcementDelay, forKey: Self.announcementDelayKey) }
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
        let storedHUD = defaults.object(forKey: Self.showHUDKey) as? Bool
        self.showHUD = storedHUD ?? true
        let storedStyle = defaults.string(forKey: Self.hudStyleKey)
            .flatMap(HUDStyle.init(rawValue:))
        self.hudStyle = storedStyle ?? .standard
        let storedPosition = defaults.string(forKey: Self.hudPositionKey)
            .flatMap(HUDPosition.init(rawValue:))
        self.hudPosition = storedPosition ?? .topCenter
        let storedFollows = defaults.object(forKey: Self.hudFollowsFocusedScreenKey) as? Bool
        self.hudFollowsFocusedScreen = storedFollows ?? true
        let storedArtist = defaults.object(forKey: Self.announceArtistKey) as? Bool
        self.announceArtist = storedArtist ?? true
        let storedTitle = defaults.object(forKey: Self.announceTitleKey) as? Bool
        self.announceTitle = storedTitle ?? true
        self.announceAlbum = defaults.bool(forKey: Self.announceAlbumKey)
        let storedDismiss = defaults.object(forKey: Self.hudDismissDelayKey) as? TimeInterval
        self.hudDismissDelay = storedDismiss ?? Self.defaultHUDDismissDelay
        let storedAnnounceDelay = defaults.object(forKey: Self.announcementDelayKey) as? TimeInterval
        self.announcementDelay = storedAnnounceDelay ?? Self.defaultAnnouncementDelay
    }
}
