import XCTest
import Observation
@testable import Takt

@MainActor
final class SettingsStoreTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    }

    func test_narratorEnabled_defaultsToFalse() {
        XCTAssertFalse(SettingsStore(defaults: makeDefaults()).narratorEnabled)
    }

    func test_narratorEnabled_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).narratorEnabled = true
        XCTAssertTrue(SettingsStore(defaults: defaults).narratorEnabled)
    }

    func test_narratorEnabled_writeIsObservable() async {
        let store = SettingsStore(defaults: makeDefaults())
        let exp = expectation(description: "observation fires")
        withObservationTracking {
            _ = store.narratorEnabled
        } onChange: {
            exp.fulfill()
        }
        store.narratorEnabled = true
        await fulfillment(of: [exp], timeout: 1)
    }

    func test_hasShownWelcomeSheet_defaultsToFalse() {
        XCTAssertFalse(SettingsStore(defaults: makeDefaults()).hasShownWelcomeSheet)
    }

    func test_hasShownWelcomeSheet_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).hasShownWelcomeSheet = true
        XCTAssertTrue(SettingsStore(defaults: defaults).hasShownWelcomeSheet)
    }

    func test_selectedVoiceID_defaultsToNil() {
        XCTAssertNil(SettingsStore(defaults: makeDefaults()).selectedVoiceID)
    }

    func test_selectedVoiceID_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).selectedVoiceID = "com.apple.voice.premium.en-US.Ava"
        XCTAssertEqual(
            SettingsStore(defaults: defaults).selectedVoiceID,
            "com.apple.voice.premium.en-US.Ava"
        )
    }

    func test_selectedVoiceID_settingNil_clearsStoredValue() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        store.selectedVoiceID = "some.voice"
        store.selectedVoiceID = nil
        XCTAssertNil(SettingsStore(defaults: defaults).selectedVoiceID)
    }

    func test_speechRate_defaultsTo052() {
        XCTAssertEqual(SettingsStore(defaults: makeDefaults()).speechRate, 0.52)
    }

    func test_speechRate_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).speechRate = 0.45
        XCTAssertEqual(SettingsStore(defaults: defaults).speechRate, 0.45)
    }

    func test_showAllVoicesInPicker_defaultsToFalse() {
        XCTAssertFalse(SettingsStore(defaults: makeDefaults()).showAllVoicesInPicker)
    }

    func test_showAllVoicesInPicker_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).showAllVoicesInPicker = true
        XCTAssertTrue(SettingsStore(defaults: defaults).showAllVoicesInPicker)
    }

    func test_hasShownVoiceQualityNudge_defaultsToFalse() {
        XCTAssertFalse(SettingsStore(defaults: makeDefaults()).hasShownVoiceQualityNudge)
    }

    func test_hasShownVoiceQualityNudge_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).hasShownVoiceQualityNudge = true
        XCTAssertTrue(SettingsStore(defaults: defaults).hasShownVoiceQualityNudge)
    }

    func test_duckingLevel_defaultsTo025() {
        XCTAssertEqual(SettingsStore(defaults: makeDefaults()).duckingLevel, 0.25)
    }

    func test_duckingLevel_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).duckingLevel = 0.6
        XCTAssertEqual(SettingsStore(defaults: defaults).duckingLevel, 0.6)
    }

    func test_announceArtist_defaultsToTrue() {
        XCTAssertTrue(SettingsStore(defaults: makeDefaults()).announceArtist)
    }

    func test_announceArtist_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).announceArtist = false
        XCTAssertFalse(SettingsStore(defaults: defaults).announceArtist)
    }

    func test_announceTitle_defaultsToTrue() {
        XCTAssertTrue(SettingsStore(defaults: makeDefaults()).announceTitle)
    }

    func test_announceTitle_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).announceTitle = false
        XCTAssertFalse(SettingsStore(defaults: defaults).announceTitle)
    }

    func test_announceAlbum_defaultsToFalse() {
        XCTAssertFalse(SettingsStore(defaults: makeDefaults()).announceAlbum)
    }

    func test_announceAlbum_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).announceAlbum = true
        XCTAssertTrue(SettingsStore(defaults: defaults).announceAlbum)
    }

    func test_hudDismissDelay_defaultsTo4() {
        XCTAssertEqual(SettingsStore(defaults: makeDefaults()).hudDismissDelay, 4.0)
    }

    func test_hudDismissDelay_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).hudDismissDelay = 7.0
        XCTAssertEqual(SettingsStore(defaults: defaults).hudDismissDelay, 7.0)
    }

    func test_announcementDelay_defaultsTo0() {
        XCTAssertEqual(SettingsStore(defaults: makeDefaults()).announcementDelay, 0.0)
    }

    func test_announcementDelay_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).announcementDelay = 2.5
        XCTAssertEqual(SettingsStore(defaults: defaults).announcementDelay, 2.5)
    }

    func test_hudStyle_defaultsToStandard() {
        XCTAssertEqual(SettingsStore(defaults: makeDefaults()).hudStyle, .standard)
    }

    func test_hudStyle_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).hudStyle = .compact
        XCTAssertEqual(SettingsStore(defaults: defaults).hudStyle, .compact)
    }

    func test_hudPosition_defaultsToTopCenter() {
        XCTAssertEqual(SettingsStore(defaults: makeDefaults()).hudPosition, .topCenter)
    }

    func test_hudPosition_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).hudPosition = .bottomLeft
        XCTAssertEqual(SettingsStore(defaults: defaults).hudPosition, .bottomLeft)
    }

    func test_hudFollowsFocusedScreen_defaultsToTrue() {
        XCTAssertTrue(SettingsStore(defaults: makeDefaults()).hudFollowsFocusedScreen)
    }

    func test_hudFollowsFocusedScreen_persistsAcrossInstances() {
        let defaults = makeDefaults()
        SettingsStore(defaults: defaults).hudFollowsFocusedScreen = false
        XCTAssertFalse(SettingsStore(defaults: defaults).hudFollowsFocusedScreen)
    }
}
