import AVFoundation
import XCTest
@testable import Takt

final class VoiceCatalogTests: XCTestCase {
    // MARK: tier classification

    func test_tier_noveltyIdentifier_isNovelty() {
        XCTAssertEqual(
            VoiceTier.tier(forIdentifier: "com.apple.speech.synthesis.voice.Albert", quality: .default),
            .novelty
        )
    }

    func test_tier_siriIdentifier_isSiri() {
        XCTAssertEqual(
            VoiceTier.tier(forIdentifier: "com.apple.voice.tts.en-US.helena", quality: .default),
            .siri
        )
    }

    func test_tier_premiumQuality_isPremium() {
        XCTAssertEqual(
            VoiceTier.tier(forIdentifier: "com.apple.voice.premium.en-US.Ava", quality: .premium),
            .premium
        )
    }

    func test_tier_enhancedQuality_isEnhanced() {
        XCTAssertEqual(
            VoiceTier.tier(forIdentifier: "com.apple.voice.enhanced.en-US.Samantha", quality: .enhanced),
            .enhanced
        )
    }

    func test_tier_defaultQuality_isStandard() {
        XCTAssertEqual(
            VoiceTier.tier(forIdentifier: "com.apple.voice.compact.en-US.Samantha", quality: .default),
            .standard
        )
    }

    // MARK: voices grouping

    private static let stub: [VoiceInfo] = [
        VoiceInfo(identifier: "com.apple.voice.compact.en-US.Samantha", name: "Samantha", language: "en-US", tier: .standard),
        VoiceInfo(identifier: "com.apple.voice.premium.en-US.Ava", name: "Ava", language: "en-US", tier: .premium),
        VoiceInfo(identifier: "com.apple.voice.tts.en-US.helena", name: "Helena", language: "en-US", tier: .siri),
        VoiceInfo(identifier: "com.apple.speech.synthesis.voice.Albert", name: "Albert", language: "en-US", tier: .novelty),
        VoiceInfo(identifier: "com.apple.voice.premium.fr-FR.Amelie", name: "Amelie", language: "fr-FR", tier: .premium)
    ]

    func test_voices_excludesNoveltyByDefault() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        let groups = catalog.voices(showAll: false, locale: Locale(identifier: "en-US"))
        XCTAssertNil(groups.first(where: { $0.tier == .novelty }))
    }

    func test_voices_showAllIncludesNovelty() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        let groups = catalog.voices(showAll: true, locale: Locale(identifier: "en-US"))
        XCTAssertNotNil(groups.first(where: { $0.tier == .novelty }))
    }

    func test_voices_filtersByLanguage() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        let groups = catalog.voices(showAll: true, locale: Locale(identifier: "en-US"))
        let allIds = groups.flatMap { $0.voices.map(\.identifier) }
        XCTAssertFalse(allIds.contains("com.apple.voice.premium.fr-FR.Amelie"))
    }

    func test_voices_groupsAreOrderedByTier() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        let tiers = catalog.voices(showAll: true, locale: Locale(identifier: "en-US")).map(\.tier)
        XCTAssertEqual(tiers, [.siri, .premium, .standard, .novelty])
    }

    // MARK: default voice

    func test_defaultVoice_picksHighestTierForLocale() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        XCTAssertEqual(
            catalog.defaultVoice(for: Locale(identifier: "en-US"))?.identifier,
            "com.apple.voice.tts.en-US.helena"
        )
    }

    func test_defaultVoice_filtersByLocale() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        XCTAssertEqual(
            catalog.defaultVoice(for: Locale(identifier: "fr-FR"))?.identifier,
            "com.apple.voice.premium.fr-FR.Amelie"
        )
    }

    func test_tier_forVoiceID_returnsStoredTier() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        XCTAssertEqual(catalog.tier(for: "com.apple.voice.tts.en-US.helena"), .siri)
        XCTAssertEqual(catalog.tier(for: "com.apple.voice.compact.en-US.Samantha"), .standard)
    }

    func test_tier_forUnknownVoiceID_returnsStandard() {
        let catalog = VoiceCatalog(provider: { Self.stub })
        XCTAssertEqual(catalog.tier(for: "unknown.voice.id"), .standard)
    }
}
