import AppKit
import Observation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var permissionStore: PermissionStateStore?
    private var settings: SettingsStore?
    private var engine: NarratorEngine?
    private var observer: PlaybackObserver?
    private var menuBar: MenuBarController?
    private var firstRunSheet: FirstRunSheet?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore()
        let permissionStore = PermissionStateStore()
        let engine = NarratorEngine(
            speaker: AVSpeechSpeaker(),
            ducker: SpotifyDucker(),
            permissionStateChangeHandler: { [weak permissionStore] newState in
                Task { @MainActor in
                    permissionStore?.state = newState
                }
            }
        )
        let observer = PlaybackObserver()
        let menuBar = MenuBarController(settings: settings, permission: permissionStore)
        let firstRunSheet = FirstRunSheet(settings: settings)

        self.settings = settings
        self.permissionStore = permissionStore
        self.engine = engine
        self.observer = observer
        self.menuBar = menuBar
        self.firstRunSheet = firstRunSheet

        applyNarratorState()
        observeSettings()
        firstRunSheet.presentIfNeeded()
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
