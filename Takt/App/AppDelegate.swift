import AppKit
import Observation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var permissionStore: PermissionStateStore?
    private(set) var settings: SettingsStore?
    private(set) var voiceCatalog: VoiceCatalog?
    private var engine: NarratorEngine?
    private var observer: PlaybackObserver?
    private var menuBar: MenuBarController?
    private var firstRunSheet: FirstRunSheet?
    private var previewSpeaker: AVSpeechSpeaker?
    private var settingsWindow: SettingsWindow?
    private var voiceQualityNudge: VoiceQualityNudge?
    private var loginItem: LoginItemController?
    private var globalHotkey: GlobalHotkey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        SpotifyDucker.restoreIfNeeded()
        let settings = SettingsStore()
        let permissionStore = PermissionStateStore()
        let voiceCatalog = VoiceCatalog()
        let loginItem = LoginItemController()
        let previewSpeaker = AVSpeechSpeaker()
        let speechSettings: NarratorEngine.SpeechSettingsProvider = { [weak settings] in
            guard let settings else { return SpeechSettings(voiceIdentifier: nil, rate: 0.5) }
            return SpeechSettings(voiceIdentifier: settings.selectedVoiceID, rate: settings.speechRate)
        }
        let duckingLevelProvider: NarratorEngine.DuckingLevelProvider = { [weak settings] in
            settings?.duckingLevel ?? SettingsStore.defaultDuckingLevel
        }
        let engine = NarratorEngine(
            speaker: AVSpeechSpeaker(),
            ducker: SpotifyDucker(),
            duckingLevel: duckingLevelProvider,
            speechSettings: speechSettings,
            permissionStateChangeHandler: { [weak permissionStore] newState in
                Task { @MainActor in
                    permissionStore?.state = newState
                }
            }
        )
        let observer = PlaybackObserver()
        let menuBar = MenuBarController(
            settings: settings,
            permission: permissionStore,
            openSettings: { [weak self] in self?.showSettings() }
        )
        let firstRunSheet = FirstRunSheet(settings: settings)
        let settingsWindow = SettingsWindow(
            settings: settings,
            permission: permissionStore,
            loginItem: loginItem,
            voiceCatalog: voiceCatalog,
            preview: { [weak previewSpeaker] speech in
                guard let previewSpeaker else { return }
                Task {
                    await previewSpeaker.speak("Daft Punk, Get Lucky", settings: speech)
                }
            }
        )
        let voiceQualityNudge = VoiceQualityNudge(
            settings: settings,
            voiceCatalog: voiceCatalog,
            openSettings: { [weak settingsWindow] in settingsWindow?.show() }
        )
        let globalHotkey = GlobalHotkey(toggle: { [weak settings, weak permissionStore] in
            guard let settings, let permissionStore else { return }
            guard permissionStore.state != .denied else { return }
            settings.narratorEnabled.toggle()
        })

        self.settings = settings
        self.permissionStore = permissionStore
        self.voiceCatalog = voiceCatalog
        self.engine = engine
        self.observer = observer
        self.menuBar = menuBar
        self.firstRunSheet = firstRunSheet
        self.previewSpeaker = previewSpeaker
        self.settingsWindow = settingsWindow
        self.voiceQualityNudge = voiceQualityNudge
        self.loginItem = loginItem
        self.globalHotkey = globalHotkey

        applyNarratorState()
        observeSettings()
        firstRunSheet.presentIfNeeded()
    }

    func showSettings() {
        settingsWindow?.show()
    }

    private func applyNarratorState() {
        guard let settings, let engine, let observer else { return }
        if settings.narratorEnabled {
            observer.start { event in engine.handle(event) }
        } else {
            observer.stop()
        }
    }

    private func observeSettings() {
        withObservationTracking {
            _ = settings?.narratorEnabled
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyNarratorState()
                self.observeSettings()
            }
        }
    }
}
