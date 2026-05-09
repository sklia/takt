import Foundation
import ScriptingBridge

final class SpotifyDucker: Ducker, @unchecked Sendable {
    enum DuckerError: Error {
        case spotifyUnreachable
    }

    private let bundleIdentifier = "com.spotify.client"
    private let lock = NSLock()
    private var savedVolume: Int?

    func duck(to level: Float) throws {
        let app = try connectedApp()
        guard let current = app.value(forKey: "soundVolume") as? Int else {
            throw DuckerError.spotifyUnreachable
        }
        lock.lock()
        savedVolume = current
        lock.unlock()
        app.setValue(Int((Float(current) * level).rounded()), forKey: "soundVolume")
    }

    func restore() throws {
        let app = try connectedApp()
        lock.lock()
        let saved = savedVolume
        savedVolume = nil
        lock.unlock()
        if let saved {
            app.setValue(saved, forKey: "soundVolume")
        }
    }

    private func connectedApp() throws -> SBApplication {
        guard let app = SBApplication(bundleIdentifier: bundleIdentifier) else {
            throw DuckerError.spotifyUnreachable
        }
        guard app.isRunning else {
            throw DuckerError.spotifyUnreachable
        }
        return app
    }
}
