import os
import XCTest
@testable import Takt

final class CallLog: @unchecked Sendable {
    enum Call: Equatable {
        case duck(Float)
        case speak(String)
        case restore
        case cancel
    }
    private let lock = NSLock()
    private var entries: [Call] = []
    func record(_ call: Call) {
        lock.lock(); defer { lock.unlock() }
        entries.append(call)
    }
    func snapshot() -> [Call] {
        lock.lock(); defer { lock.unlock() }
        return entries
    }
}

final class SpeakerSpy: Speaker, @unchecked Sendable {
    let log: CallLog
    let utteranceDuration: Duration
    private let _spokenSettings = OSAllocatedUnfairLock(initialState: [SpeechSettings]())
    var spokenSettings: [SpeechSettings] {
        _spokenSettings.withLock { $0 }
    }
    init(log: CallLog, utteranceDuration: Duration = .zero) {
        self.log = log
        self.utteranceDuration = utteranceDuration
    }
    func speak(_ phrase: String, settings: SpeechSettings) async {
        log.record(.speak(phrase))
        _spokenSettings.withLock { $0.append(settings) }
        if utteranceDuration > .zero {
            try? await Task.sleep(for: utteranceDuration)
        }
    }
    func cancel() { log.record(.cancel) }
}

final class DuckerSpy: Ducker {
    let log: CallLog
    var duckError: Error?
    var restoreError: Error?
    init(log: CallLog) { self.log = log }
    func duck(to level: Float) throws {
        if let error = duckError { throw error }
        log.record(.duck(level))
    }
    func restore() throws {
        if let error = restoreError { throw error }
        log.record(.restore)
    }
}

struct TestError: Error, Equatable {}

final class SpeechSettingsBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: SpeechSettings
    init(_ initial: SpeechSettings) { stored = initial }
    var current: SpeechSettings {
        lock.lock(); defer { lock.unlock() }
        return stored
    }
    func set(_ new: SpeechSettings) {
        lock.lock(); stored = new; lock.unlock()
    }
}
