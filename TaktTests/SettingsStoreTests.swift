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
}
