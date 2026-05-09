import Foundation
import ScriptingBridge

@MainActor
final class SpotifyDucker: NSObject, Ducker, SBApplicationDelegate {
    enum DuckerError: Error {
        case spotifyUnreachable
    }

    private static let savedVolumeKey = "ducking.savedVolume"

    private let bundleIdentifier = "com.spotify.client"
    private let defaults: UserDefaults
    private var savedVolume: Int?
    private var lastEventError: Error?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
    }

    private lazy var app: SBApplication? = {
        let app = SBApplication(bundleIdentifier: bundleIdentifier)
        app?.delegate = self
        return app
    }()

    func duck(to level: Float) throws {
        let app = try connectedApp()

        lastEventError = nil
        let rawVolume = app.value(forKey: "soundVolume")
        try throwIfEventFailed()

        guard let current = rawVolume as? Int else {
            throw DuckerError.spotifyUnreachable
        }

        savedVolume = current
        defaults.set(current, forKey: Self.savedVolumeKey)

        lastEventError = nil
        app.setValue(Int((Float(current) * level).rounded()), forKey: "soundVolume")
        try throwIfEventFailed()
    }

    func restore() throws {
        let app = try connectedApp()

        let saved = savedVolume
        savedVolume = nil
        defaults.removeObject(forKey: Self.savedVolumeKey)

        if let saved {
            lastEventError = nil
            app.setValue(saved, forKey: "soundVolume")
            try throwIfEventFailed()
        }
    }

    private func connectedApp() throws -> SBApplication {
        guard let app else { throw DuckerError.spotifyUnreachable }
        guard app.isRunning else { throw DuckerError.spotifyUnreachable }
        return app
    }

    private func throwIfEventFailed() throws {
        if lastEventError != nil {
            throw DuckerError.spotifyUnreachable
        }
    }

    func probePermission() -> PermissionState {
        guard let app, app.isRunning else { return .unknown }
        lastEventError = nil
        _ = app.value(forKey: "soundVolume")
        return lastEventError == nil ? .granted : .denied
    }

    static func restoreIfNeeded(defaults: UserDefaults = .standard) {
        guard let volume = defaults.object(forKey: savedVolumeKey) as? Int else { return }
        defaults.removeObject(forKey: savedVolumeKey)
        guard let app = SBApplication(bundleIdentifier: "com.spotify.client"),
              app.isRunning else { return }
        app.setValue(volume, forKey: "soundVolume")
    }

    // SBApplicationDelegate: ScriptingBridge calls this synchronously when an
    // Apple Event fails (e.g. errAEEventNotPermitted from TCC). Returning
    // NSNumber(0) is safe: ScriptingBridge unboxes via longLongValue, and we
    // detect the failure via lastEventError before using any returned value.
    nonisolated func eventDidFail(_ event: UnsafePointer<AppleEvent>, withError error: any Error) -> Any? {
        MainActor.assumeIsolated {
            lastEventError = error
        }
        return NSNumber(value: 0)
    }
}
