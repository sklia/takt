import Foundation
import ScriptingBridge

final class SpotifyDucker: NSObject, Ducker, @unchecked Sendable, SBApplicationDelegate {
    enum DuckerError: Error {
        case spotifyUnreachable
    }

    private let bundleIdentifier = "com.spotify.client"
    private let lock = NSLock()
    private var savedVolume: Int?
    private var lastEventError: Error?

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

        lock.lock()
        savedVolume = current
        lock.unlock()

        lastEventError = nil
        app.setValue(Int((Float(current) * level).rounded()), forKey: "soundVolume")
        try throwIfEventFailed()
    }

    func restore() throws {
        let app = try connectedApp()

        lock.lock()
        let saved = savedVolume
        savedVolume = nil
        lock.unlock()

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

    // SBApplicationDelegate: ScriptingBridge calls this synchronously when an
    // Apple Event fails (e.g. errAEEventNotPermitted from TCC). Returning
    // NSNumber(0) is safe: ScriptingBridge unboxes via longLongValue, and we
    // detect the failure via lastEventError before using any returned value.
    func eventDidFail(_ event: UnsafePointer<AppleEvent>, withError error: any Error) -> Any? {
        lastEventError = error
        return NSNumber(value: 0)
    }
}
