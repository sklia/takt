import os

enum PermissionState: Sendable, Equatable {
    case unknown
    case denied
}

final class NarratorEngine {
    private let speaker: any Speaker
    private let ducker: any Ducker
    private let duckingLevel: Float
    private let debounce: Duration
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
        debounce: Duration = .milliseconds(250)
    ) {
        self.speaker = speaker
        self.ducker = ducker
        self.duckingLevel = duckingLevel
        self.debounce = debounce
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
            markPermissionDenied()
            return
        }
        await withTaskCancellationHandler {
            await speaker.speak("\(event.artist), \(event.title)")
        } onCancel: { [speaker] in
            speaker.cancel()
        }
        try? ducker.restore()
    }

    private func markPermissionDenied() {
        permissionStateBox.withLock { $0 = .denied }
    }
}
