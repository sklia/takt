import XCTest
@testable import Takt

@MainActor
final class AnnouncementDelayTests: XCTestCase {
    private static let testDebounce: Duration = .milliseconds(20)
    private static let postFlushSlack: Duration = .milliseconds(60)

    private func waitForAnnouncementsToSettle() async throws {
        try await Task.sleep(for: Self.postFlushSlack)
    }

    func test_addsExtraWaitBeforeSpeaking() async throws {
        let log = CallLog()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            announcementDelay: { .milliseconds(80) },
            debounce: Self.testDebounce
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-delay"))
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(log.snapshot(), [])

        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("A, 1"),
            .restore
        ])
    }

    func test_cancelsOnNewEvent() async throws {
        let log = CallLog()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            announcementDelay: { .milliseconds(80) },
            debounce: Self.testDebounce
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-cancel-a"))
        try await Task.sleep(for: .milliseconds(40))
        engine.handle(PlaybackEvent(artist: "B", title: "2", uri: "uri-cancel-b"))
        await engine.pendingAnnouncement?.value
        try await waitForAnnouncementsToSettle()

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("B, 2"),
            .restore
        ])
    }

    func test_zero_behavesLikeBefore() async throws {
        let log = CallLog()
        let engine = NarratorEngine(
            speaker: SpeakerSpy(log: log),
            ducker: DuckerSpy(log: log),
            duckingLevel: { 0.25 },
            announcementDelay: { .zero },
            debounce: Self.testDebounce
        )

        engine.handle(PlaybackEvent(artist: "A", title: "1", uri: "uri-zero-delay"))
        await engine.pendingAnnouncement?.value

        XCTAssertEqual(log.snapshot(), [
            .duck(0.25),
            .speak("A, 1"),
            .restore
        ])
    }
}
