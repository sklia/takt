import AppKit
import Observation
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var permissionStore = PermissionStateStore()
    private(set) var settings = SettingsStore()
    private(set) var voiceCatalog = VoiceCatalog()
    private(set) var loginItem = LoginItemController()
    private var engine: NarratorEngine?
    private var ducker: SpotifyDucker?
    private var observer: (any MusicSource)?
    private var menuBar: MenuBarController?
    private var firstRunSheet: FirstRunSheet?
    private var previewSpeaker: AVSpeechSpeaker?
    private var settingsWindow: SettingsWindow?
    private var voiceQualityNudge: VoiceQualityNudge?
    private var hudController: HUDController?
    private var globalHotkey: GlobalHotkey?
    private var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        SpotifyDucker.restoreIfNeeded()
        let settings = self.settings
        let permissionStore = self.permissionStore
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
        let phraseComposer: NarratorEngine.PhraseComposer = { [weak settings] event in
            guard let settings else { return "\(event.artist), \(event.title)" }
            var parts: [String] = []
            if settings.announceArtist { parts.append(event.artist) }
            if settings.announceTitle { parts.append(event.title) }
            if settings.announceAlbum, let album = event.album { parts.append(album) }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
        let ducker = SpotifyDucker()
        let engine = NarratorEngine(
            speaker: AVSpeechSpeaker(),
            ducker: ducker,
            duckingLevel: duckingLevelProvider,
            focusSuppressed: focusSuppressed,
            phraseComposer: phraseComposer,
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
        let settingsWindow = SettingsWindow(
            settings: settings,
            permission: permissionStore,
            loginItem: loginItem,
            voiceCatalog: voiceCatalog,
            preview: { [weak previewSpeaker, phraseComposer] speech in
                guard let previewSpeaker else { return }
                let sample = PlaybackEvent(
                    artist: "Daft Punk", title: "Get Lucky",
                    album: "Random Access Memories", uri: ""
                )
                guard let phrase = phraseComposer(sample) else { return }
                Task {
                    await previewSpeaker.speak(phrase, settings: speech)
                }
            }
        )
        let voiceQualityNudge = VoiceQualityNudge(
            settings: settings,
            voiceCatalog: voiceCatalog,
            openSettings: { [weak self] in self?.showSettings() }
        )
        let hudController = HUDController(
            style: { [weak settings] in settings?.hudStyle ?? .standard },
            position: { [weak settings] in settings?.hudPosition ?? .topCenter },
            screen: { [weak settings] in
                guard settings?.hudFollowsFocusedScreen == true else {
                    return NSScreen.screens.first
                }
                return NSScreen.main
            }
        )
        let globalHotkey = GlobalHotkey(toggle: { [weak settings, weak permissionStore] in
            guard let settings, let permissionStore else { return }
            guard permissionStore.state != .denied else { return }
            settings.narratorEnabled.toggle()
        })

        self.engine = engine
        self.ducker = ducker
        self.observer = observer
        self.menuBar = menuBar
        self.firstRunSheet = firstRunSheet
        self.previewSpeaker = previewSpeaker
        self.settingsWindow = settingsWindow
        self.voiceQualityNudge = voiceQualityNudge
        self.hudController = hudController
        self.globalHotkey = globalHotkey
        self.updaterController = updaterController

        applyObserverState()
        observeSettings()
        observePermission()
        firstRunSheet.presentIfNeeded()
    }

    func showSettings() {
        settingsWindow?.show()
    }

    private func applyObserverState() {
        guard let engine, let observer, let hudController else { return }
        let needsObserver = settings.narratorEnabled || settings.showHUD
        if needsObserver {
            let narratorOn = settings.narratorEnabled
            let hudOn = settings.showHUD
            observer.start { event in
                MainActor.assumeIsolated {
                    if narratorOn { engine.handle(event) }
                    if hudOn { hudController.show(event) }
                }
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
                guard let self, let ducker = self.ducker else { return }
                let probed = ducker.probePermission()
                guard probed != .unknown else { return }
                self.permissionStore.state = probed
            }
        }
    }

    private func observeSettings() {
        withObservationTracking {
            _ = settings.narratorEnabled
            _ = settings.showHUD
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyObserverState()
                self.observeSettings()
            }
        }
    }
}
