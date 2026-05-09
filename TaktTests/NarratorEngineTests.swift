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
    func record(_ c: Call) {
        lock.lock(); defer { lock.unlock() }
        entries.append(c)
    }
    func snapshot() -> [Call] {
        lock.lock(); defer { lock.unlock() }
        return entries
    }
}

final class SpeakerSpy: Speaker, @unchecked Sendable {
    let log: CallLog
    let utteranceDuration: Duration
    private let lock = NSLock()
    private var _spokenSettings: [SpeechSettings] = []
    var spokenSettings: [SpeechSettings] {
        lock.lock(); defer { lock.unlock() }
        return _spokenSettings
    }
    init(log: CallLog, utteranceDuration: Duration = .zero) {
        self.log = log
        self.utteranceDuration = utteranceDuration
    }
    func speak(_ phrase: String, settings: SpeechSettings) async {
        log.record(.speak(phrase))
        lock.lock()
        _spokenSettings.append(settings)
        lock.unlock()
        if utteranceDuration > .zero {
            try? await Task.sleep(for: utteranceDuration)
        }
    }
    func cancel() { log.record(.cancel) }
}

final class DuckerSpy: Ducker, @unchecked Sendable {
    let log: CallLog
    var duckError: Error?
    var restoreError: Error?
    init(log: CallLog) { self.log = log }
    func duck(to level: Float) throws {
        if let e = duckError { throw e }
        log.record(.duck(level))
    }
    func restore() throws {
        if let e = restoreError { throw e }
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

final class NarratorEngineTests: XCTestCase {
    private static let testDebounce: Duration = .milliseconds(20)
    private static let postFlushSlack: Duration = .milliseconds(60)

    private func makeEngine(log: CallLog) -> NarratorEngine {
        NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: 0.25,
            debounce: Self.testDebounce
        )
    }

    private func waitForAnnouncementsToSettle() async throws {
        try await Task.sleep(for: Self.postFlushSlack)
    }

    func test_singleEvent_ducksThenSpeaksThenRestores() async throws {
        let log = CallLog()
        let engine = makeEngine(log: log)

        engine.handle(PlaybackEvent(
            artist: "Daft Punk",
            title: "Get Lucky",
            uri: "spotify:track:69kOkLUCkxIZYexIgSG8rq"
        ))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("Daft Punk, Get Lucky"),
            .restore
        ])
    }

    func test_repeatedEvent_announcesOnce() async throws {
        let log = CallLog()
        let engine = makeEngine(log: log)
        let event = PlaybackEvent(
            artist: "Daft Punk",
            title: "Get Lucky",
            uri: "spotify:track:69kOkLUCkxIZYexIgSG8rq"
        )

        engine.handle(event)
        engine.handle(event)
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("Daft Punk, Get Lucky"),
            .restore
        ])
    }

    func test_duckThrows_skipsSpeakAndRestore_andMarksPermissionDenied() async throws {
        let log = CallLog()
        let ducker = DuckerSpy(log: log)
        ducker.duckError = TestError()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: ducker,
            duckingLevel: 0.25,
            debounce: Self.testDebounce
        )

        engine.handle(PlaybackEvent(
            artist: "Daft Punk",
            title: "Get Lucky",
            uri: "spotify:track:abc"
        ))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [])
        XCTAssertEqual(engine.permissionState, .denied)
    }

    func test_deniedThenSuccessfulDuck_transitionsToGranted() async throws {
        let log = CallLog()
        let ducker = DuckerSpy(log: log)
        ducker.duckError = TestError()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: ducker,
            duckingLevel: 0.25,
            debounce: Self.testDebounce
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-a"))
        await engine.pendingAnnouncement?.value
        XCTAssertEqual(engine.permissionState, .denied)

        ducker.duckError = nil

        engine.handle(PlaybackEvent(artist: "B", title: "2", uri: "uri-b"))
        await engine.pendingAnnouncement?.value
        XCTAssertEqual(engine.permissionState, .granted)
    }

    func test_eventDuringSpeak_cancelsAndRestoresThenAnnouncesNew() async throws {
        let log = CallLog()
        let speaker = SpeakerSpy(log: log, utteranceDuration: .milliseconds(80))
        let engine = NarratorEngine(
            speaker: speaker,
            ducker: DuckerSpy(log: log),
            duckingLevel: 0.25,
            debounce: Self.testDebounce
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "spotify:track:a"))
        try await Task.sleep(for: .milliseconds(40))
        engine.handle(PlaybackEvent(artist: "B", title: "2", uri: "spotify:track:b"))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("A, 1"),
            .cancel,
            .restore,
            .duck(0.25),
            .speak("B, 2"),
            .restore
        ])
    }

    func test_speechSettings_runtimeUpdate_flowsToSpeaker() async throws {
        let log = CallLog()
        let speaker = SpeakerSpy(log: log)
        let box = SpeechSettingsBox(SpeechSettings(voiceIdentifier: "voice-A", rate: 0.5))
        let engine = NarratorEngine(
            speaker: speaker,
            ducker: DuckerSpy(log: log),
            duckingLevel: 0.25,
            debounce: Self.testDebounce,
            speechSettings: { box.current }
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-a"))
        await engine.pendingAnnouncement?.value

        box.set(SpeechSettings(voiceIdentifier: "voice-B", rate: 0.6))

        engine.handle(PlaybackEvent(artist: "B", title: "2", uri: "uri-b"))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(speaker.spokenSettings, [
            SpeechSettings(voiceIdentifier: "voice-A", rate: 0.5),
            SpeechSettings(voiceIdentifier: "voice-B", rate: 0.6)
        ])
    }

    func test_twoEventsWithinDebounce_onlyLatestAnnounces() async throws {
        let log = CallLog()
        let engine = makeEngine(log: log)

        engine.handle(PlaybackEvent(
            artist: "Daft Punk",
            title: "Get Lucky",
            uri: "spotify:track:abc"
        ))
        engine.handle(PlaybackEvent(
            artist: "Justice",
            title: "D.A.N.C.E.",
            uri: "spotify:track:xyz"
        ))
        await engine.pendingAnnouncement?.value
        try await waitForAnnouncementsToSettle()

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("Justice, D.A.N.C.E."),
            .restore
        ])
    }
}
