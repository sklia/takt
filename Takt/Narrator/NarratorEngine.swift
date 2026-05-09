import os

enum PermissionState: Sendable, Equatable {
    case unknown
    case granted
    case denied
}

final class NarratorEngine {
    typealias SpeechSettingsProvider = @Sendable () -> SpeechSettings
    typealias DuckingLevelProvider = @Sendable () -> Float

    private let speaker: any Speaker
    private let ducker: any Ducker
    private let duckingLevelProvider: DuckingLevelProvider
    private let debounce: Duration
    private let speechSettings: SpeechSettingsProvider
    private let permissionStateChangeHandler: (@Sendable (PermissionState) -> Void)?
    private var lastAnnouncedURI: String?
    private(set) var pendingAnnouncement: Task<Void, Never>?

    private let permissionStateBox = OSAllocatedUnfairLock(initialState: PermissionState.unknown)
    var permissionState: PermissionState {
        permissionStateBox.withLock { $0 }
    }

    init(
        speaker: any Speaker,
        ducker: any Ducker,
        duckingLevel: @escaping DuckingLevelProvider = { 0.25 },
        debounce: Duration = .milliseconds(250),
        speechSettings: @escaping SpeechSettingsProvider = { SpeechSettings(voiceIdentifier: nil, rate: 0.5) },
        permissionStateChangeHandler: (@Sendable (PermissionState) -> Void)? = nil
    ) {
        self.speaker = speaker
        self.ducker = ducker
        self.duckingLevelProvider = duckingLevel
        self.debounce = debounce
        self.speechSettings = speechSettings
        self.permissionStateChangeHandler = permissionStateChangeHandler
    }

    func handle(_ event: PlaybackEvent) {
        guard event.uri != lastAnnouncedURI else { return }
        lastAnnouncedURI = event.uri
        pendingAnnouncement?.cancel()
        pendingAnnouncement = Task { [weak self] in
            await self?.runAnnouncement(for: event)
        }
    }

    private func runAnnouncement(for event: PlaybackEvent) async {
        do {
            try await Task.sleep(for: debounce)
        } catch {
            return
        }
        do {
            try ducker.duck(to: duckingLevelProvider())
        } catch {
            transition(to: .denied)
            return
        }
        transition(to: .granted)
        let phrase = "\(event.artist), \(event.title)"
        let settings = speechSettings()
        await withTaskCancellationHandler {
            await speaker.speak(phrase, settings: settings)
        } onCancel: { [speaker] in
            speaker.cancel()
        }
        try? ducker.restore()
    }

    private func transition(to newState: PermissionState) {
        let didChange = permissionStateBox.withLock { current -> Bool in
            guard current != newState else { return false }
            current = newState
            return true
        }
        if didChange {
            permissionStateChangeHandler?(newState)
        }
    }
}
