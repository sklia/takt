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
        let phraseComposer = buildPhraseComposer()
        buildNarrator(phraseComposer: phraseComposer)
        let previewSpeaker = AVSpeechSpeaker()
        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        self.observer = SpotifySource()
        self.previewSpeaker = previewSpeaker
        self.updaterController = updaterController
        self.menuBar = MenuBarController(
            settings: settings,
            permission: permissionStore,
            updater: updaterController.updater,
            openSettings: { [weak self] in self?.showSettings() }
        )
        self.firstRunSheet = FirstRunSheet(settings: settings)
        self.settingsWindow = buildSettingsWindow(
            previewSpeaker: previewSpeaker,
            phraseComposer: phraseComposer
        )
        self.voiceQualityNudge = VoiceQualityNudge(
            settings: settings,
            voiceCatalog: voiceCatalog,
            openSettings: { [weak self] in self?.showSettings() }
        )
        self.hudController = buildHUDController()
        self.globalHotkey = GlobalHotkey(toggle: { [weak self] in
            guard let self else { return }
            guard self.permissionStore.state != .denied else { return }
            self.settings.narratorEnabled.toggle()
        })

        applyObserverState()
        observeSettings()
        observePermission()
        firstRunSheet?.presentIfNeeded()
    }

    private func buildPhraseComposer() -> NarratorEngine.PhraseComposer {
        let settings = self.settings
        return { [weak settings] event in
            guard let settings else { return "\(event.artist), \(event.title)" }
            var parts: [String] = []
            if settings.announceArtist { parts.append(event.artist) }
            if settings.announceTitle { parts.append(event.title) }
            if settings.announceAlbum, let album = event.album { parts.append(album) }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
    }

    private func buildNarrator(phraseComposer: @escaping NarratorEngine.PhraseComposer) {
        let settings = self.settings
        let permissionStore = self.permissionStore
        let ducker = SpotifyDucker()
        self.ducker = ducker
        self.engine = NarratorEngine(
            speaker: AVSpeechSpeaker(),
            ducker: ducker,
            duckingLevel: { [weak settings] in
                settings?.duckingLevel ?? SettingsStore.defaultDuckingLevel
            },
            focusSuppressed: { [weak settings] in
                guard settings?.pauseDuringFocus == true else { return false }
                return UserDefaults.standard.bool(forKey: "focusPauseActive")
            },
            announcementDelay: { [weak settings] in
                .seconds(settings?.announcementDelay ?? SettingsStore.defaultAnnouncementDelay)
            },
            phraseComposer: phraseComposer,
            speechSettings: { [weak settings] in
                guard let settings else { return SpeechSettings(voiceIdentifier: nil, rate: 0.5) }
                return SpeechSettings(voiceIdentifier: settings.selectedVoiceID, rate: settings.speechRate)
            },
            permissionStateChangeHandler: { [weak permissionStore] newState in
                permissionStore?.state = newState
            }
        )
    }

    private func buildSettingsWindow(
        previewSpeaker: AVSpeechSpeaker,
        phraseComposer: @escaping NarratorEngine.PhraseComposer
    ) -> SettingsWindow {
        SettingsWindow(
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
                Task { await previewSpeaker.speak(phrase, settings: speech) }
            }
        )
    }

    private func buildHUDController() -> HUDController {
        let settings = self.settings
        return HUDController(
            dismissDelay: { [weak settings] in settings?.hudDismissDelay ?? SettingsStore.defaultHUDDismissDelay },
            style: { [weak settings] in settings?.hudStyle ?? .standard },
            position: { [weak settings] in settings?.hudPosition ?? .topCenter },
            screen: { [weak settings] in
                guard settings?.hudFollowsFocusedScreen == true else {
                    return NSScreen.screens.first
                }
                return NSScreen.main
            }
        )
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
