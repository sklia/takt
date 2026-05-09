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

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore()
        let permissionStore = PermissionStateStore()
        let voiceCatalog = VoiceCatalog()
        let previewSpeaker = AVSpeechSpeaker()
        let speechSettings: NarratorEngine.SpeechSettingsProvider = { [weak settings] in
            guard let settings else { return SpeechSettings(voiceIdentifier: nil, rate: 0.5) }
            return SpeechSettings(voiceIdentifier: settings.selectedVoiceID, rate: settings.speechRate)
        }
        let engine = NarratorEngine(
            speaker: AVSpeechSpeaker(),
            ducker: SpotifyDucker(),
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
            voiceCatalog: voiceCatalog,
            preview: { [weak previewSpeaker] speech in
                guard let previewSpeaker else { return }
                Task {
                    await previewSpeaker.speak("Daft Punk, Get Lucky", settings: speech)
                }
            }
        )

        self.settings = settings
        self.permissionStore = permissionStore
        self.voiceCatalog = voiceCatalog
        self.engine = engine
        self.observer = observer
        self.menuBar = menuBar
        self.firstRunSheet = firstRunSheet
        self.previewSpeaker = previewSpeaker
        self.settingsWindow = settingsWindow

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
