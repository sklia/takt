import XCTest
@testable import Takt

@MainActor
final class NarratorEngineTests: XCTestCase {
    private static let testDebounce: Duration = .milliseconds(20)
    private static let postFlushSlack: Duration = .milliseconds(60)

    private func makeEngine(log: CallLog) -> NarratorEngine {
        NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
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
            duckingLevel: { 0.25 },
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
            duckingLevel: { 0.25 },
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
            duckingLevel: { 0.25 },
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
            duckingLevel: { 0.25 },
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

    func test_focusSuppressed_skipsAnnouncement() async throws {
        let log = CallLog()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            focusSuppressed: { true },
            debounce: Self.testDebounce
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-focus"))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [])
    }

    func test_speechTimeout_restoresAfterDeadline() async throws {
        let log = CallLog()
        let speaker = SpeakerSpy(log: log, utteranceDuration: .milliseconds(200))
        let engine = NarratorEngine(
            speaker: speaker,
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            debounce: Self.testDebounce,
            speechTimeout: .milliseconds(50)
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-timeout"))
        await engine.pendingAnnouncement?.value

        let calls = log.snapshot()
        XCTAssertEqual(calls.first, .duck(0.25))
        XCTAssertEqual(calls.last, .restore)
    }

    func test_phraseComposer_customPhrase_flowsToSpeaker() async throws {
        let log = CallLog()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            debounce: Self.testDebounce,
            phraseComposer: { "\($0.title) by \($0.artist)" }
        )

        engine.handle(PlaybackEvent(artist: "A", title: "Song", uri: "uri-composer"))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("Song by A"),
            .restore
        ])
    }

    func test_phraseComposer_returnsNil_skipsSpeech() async throws {
        let log = CallLog()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            debounce: Self.testDebounce,
            phraseComposer: { _ in nil }
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-nil"))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .restore
        ])
    }

    func test_phraseComposer_albumIncluded() async throws {
        let log = CallLog()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            debounce: Self.testDebounce,
            phraseComposer: { event in
                [event.artist, event.title, event.album].compactMap { $0 }.joined(separator: ", ")
            }
        )

        engine.handle(PlaybackEvent(
            artist: "Daft Punk", title: "Get Lucky",
            album: "Random Access Memories", uri: "uri-album"
        ))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("Daft Punk, Get Lucky, Random Access Memories"),
            .restore
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
