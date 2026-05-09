import os

enum PermissionState: Sendable, Equatable {
    case unknown
    case granted
    case denied
}

final class NarratorEngine {
    private let speaker: any Speaker
    private let ducker: any Ducker
    private let duckingLevel: Float
    private let debounce: Duration
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
        duckingLevel: Float = 0.25,
        debounce: Duration = .milliseconds(250),
        permissionStateChangeHandler: (@Sendable (PermissionState) -> Void)? = nil
    ) {
        self.speaker = speaker
        self.ducker = ducker
        self.duckingLevel = duckingLevel
        self.debounce = debounce
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
            try ducker.duck(to: duckingLevel)
        } catch {
            transition(to: .denied)
            return
        }
        transition(to: .granted)
        await withTaskCancellationHandler {
            await speaker.speak("\(event.artist), \(event.title)")
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
