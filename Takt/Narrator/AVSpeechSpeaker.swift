import AVFoundation
import Foundation

final class AVSpeechSpeaker: NSObject, @unchecked Sendable, Speaker, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ phrase: String, settings: SpeechSettings) async {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = Self.voice(for: settings.voiceIdentifier)
        utterance.rate = settings.rate
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            lock.lock()
            continuation = cont
            lock.unlock()
            synthesizer.speak(utterance)
        }
    }

    func cancel() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish()
    }

    private func finish() {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        cont?.resume()
    }

    private static func voice(for identifier: String?) -> AVSpeechSynthesisVoice? {
        if let identifier, let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return bestVoiceForCurrentLocale()
    }

    private static func bestVoiceForCurrentLocale() -> AVSpeechSynthesisVoice? {
        let lang = AVSpeechSynthesisVoice.currentLanguageCode()
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == lang }
        if let best = candidates.max(by: { $0.quality.rawValue < $1.quality.rawValue }) {
            return best
        }
        return AVSpeechSynthesisVoice(language: lang)
    }
}
