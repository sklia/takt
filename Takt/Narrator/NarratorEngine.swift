import os

enum PermissionState: Sendable, Equatable {
    case unknown
    case granted
    case denied
}

@MainActor
final class NarratorEngine {
    typealias SpeechSettingsProvider = () -> SpeechSettings
    typealias DuckingLevelProvider = () -> Float
    typealias FocusSuppressedProvider = () -> Bool
    typealias PhraseComposer = (PlaybackEvent) -> String?

    private let speaker: any Speaker
    private let ducker: any Ducker
    private let duckingLevelProvider: DuckingLevelProvider
    private let focusSuppressed: FocusSuppressedProvider
    private let debounce: Duration
    private let speechTimeout: Duration
    private let phraseComposer: PhraseComposer
    private let speechSettings: SpeechSettingsProvider
    private let permissionStateChangeHandler: ((PermissionState) -> Void)?
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
        focusSuppressed: @escaping FocusSuppressedProvider = { false },
        debounce: Duration = .milliseconds(250),
        speechTimeout: Duration = .seconds(10),
        phraseComposer: @escaping PhraseComposer = { "\($0.artist), \($0.title)" },
        speechSettings: @escaping SpeechSettingsProvider = { SpeechSettings(voiceIdentifier: nil, rate: 0.5) },
        permissionStateChangeHandler: ((PermissionState) -> Void)? = nil
    ) {
        self.speaker = speaker
        self.ducker = ducker
        self.duckingLevelProvider = duckingLevel
        self.focusSuppressed = focusSuppressed
        self.debounce = debounce
        self.speechTimeout = speechTimeout
        self.phraseComposer = phraseComposer
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
        if focusSuppressed() { return }
        do {
            try ducker.duck(to: duckingLevelProvider())
        } catch {
            transition(to: .denied)
            return
        }
        transition(to: .granted)
        guard let phrase = phraseComposer(event) else {
            try? ducker.restore()
            return
        }
        let settings = speechSettings()
        await withTaskCancellationHandler {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [speaker] in
                    await speaker.speak(phrase, settings: settings)
                }
                group.addTask { [speechTimeout] in
                    try? await Task.sleep(for: speechTimeout)
                }
                await group.next()
                group.cancelAll()
            }
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
