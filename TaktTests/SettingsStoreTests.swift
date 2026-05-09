import XCTest
import Observation
@testable import Takt

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
}
