import AppKit
import Observation
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var permissionStore: PermissionStateStore?
    private(set) var settings: SettingsStore?
    private(set) var voiceCatalog: VoiceCatalog?
    private(set) var loginItem: LoginItemController?
    private var engine: NarratorEngine?
    private var ducker: SpotifyDucker?
    private var observer: (any MusicSource)?
    private var menuBar: MenuBarController?
    private var firstRunSheet: FirstRunSheet?
    private var previewSpeaker: AVSpeechSpeaker?
    private var voiceQualityNudge: VoiceQualityNudge?
    private var globalHotkey: GlobalHotkey?
    private var updaterController: SPUStandardUpdaterController?

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
        let focusSuppressed: NarratorEngine.FocusSuppressedProvider = { [weak settings] in
            guard settings?.pauseDuringFocus == true else { return false }
            return UserDefaults.standard.bool(forKey: "focusPauseActive")
        }
        let ducker = SpotifyDucker()
        let engine = NarratorEngine(
            speaker: AVSpeechSpeaker(),
            ducker: ducker,
            duckingLevel: duckingLevelProvider,
            focusSuppressed: focusSuppressed,
            speechSettings: speechSettings,
            permissionStateChangeHandler: { [weak permissionStore] newState in
                permissionStore?.state = newState
            }
        )
        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        let observer = SpotifySource()
        let menuBar = MenuBarController(
            settings: settings,
            permission: permissionStore,
            updater: updaterController.updater,
            openSettings: { [weak self] in self?.showSettings() }
        )
        let firstRunSheet = FirstRunSheet(settings: settings)
        let voiceQualityNudge = VoiceQualityNudge(
            settings: settings,
            voiceCatalog: voiceCatalog,
            openSettings: { [weak self] in self?.showSettings() }
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
        self.ducker = ducker
        self.observer = observer
        self.menuBar = menuBar
        self.firstRunSheet = firstRunSheet
        self.previewSpeaker = previewSpeaker
        self.voiceQualityNudge = voiceQualityNudge
        self.loginItem = loginItem
        self.globalHotkey = globalHotkey
        self.updaterController = updaterController

        applyNarratorState()
        observeSettings()
        observePermission()
        firstRunSheet.presentIfNeeded()
    }

    func showSettings() {
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func previewVoice(_ speech: SpeechSettings) {
        guard let previewSpeaker else { return }
        Task {
            await previewSpeaker.speak("Daft Punk, Get Lucky", settings: speech)
        }
    }

    private func applyNarratorState() {
        guard let settings, let engine, let observer else { return }
        if settings.narratorEnabled {
            observer.start { event in
                MainActor.assumeIsolated { engine.handle(event) }
            }
        } else {
            observer.stop()
        }
    }

    private func observePermission() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let ducker = self.ducker, let store = self.permissionStore else { return }
                let probed = ducker.probePermission()
                guard probed != .unknown else { return }
                store.state = probed
            }
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
