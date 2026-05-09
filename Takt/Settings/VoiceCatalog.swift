import AVFoundation
import Foundation

enum VoiceTier: Int, Sendable, Equatable, Comparable {
    case siri = 0
    case premium = 1
    case enhanced = 2
    case standard = 3
    case novelty = 4

    static func < (lhs: VoiceTier, rhs: VoiceTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func tier(forIdentifier identifier: String, quality: AVSpeechSynthesisVoiceQuality) -> VoiceTier {
        if identifier.hasPrefix("com.apple.speech.synthesis.voice.") {
            return .novelty
        }
        if identifier.hasPrefix("com.apple.voice.tts.") {
            return .siri
        }
        switch quality {
        case .premium: return .premium
        case .enhanced: return .enhanced
        default: return .standard
        }
    }
}

struct VoiceInfo: Sendable, Equatable {
    let identifier: String
    let name: String
    let language: String
    let tier: VoiceTier
}

extension VoiceInfo {
    init(_ voice: AVSpeechSynthesisVoice) {
        self.init(
            identifier: voice.identifier,
            name: voice.name,
            language: voice.language,
            tier: VoiceTier.tier(forIdentifier: voice.identifier, quality: voice.quality)
        )
    }
}

struct VoiceCatalog: Sendable {
    typealias Provider = @Sendable () -> [VoiceInfo]

    private let provider: Provider

    init(provider: @escaping Provider = { AVSpeechSynthesisVoice.speechVoices().map(VoiceInfo.init) }) {
        self.provider = provider
    }

    func voices(showAll: Bool, locale: Locale) -> [(tier: VoiceTier, voices: [VoiceInfo])] {
        let langPrefix = locale.language.languageCode?.identifier ?? "en"
        var infos = provider().filter { $0.language.hasPrefix(langPrefix) }
        if !showAll {
            infos.removeAll { $0.tier == .novelty }
        }
        let grouped = Dictionary(grouping: infos, by: \.tier)
        return grouped
            .sorted { $0.key < $1.key }
            .map { (tier: $0.key, voices: $0.value.sorted { $0.name < $1.name }) }
    }

    func defaultVoice(for locale: Locale) -> VoiceInfo? {
        voices(showAll: false, locale: locale).first?.voices.first
    }

    func tier(for voiceID: String) -> VoiceTier {
        provider().first(where: { $0.identifier == voiceID })?.tier ?? .standard
    }
}
