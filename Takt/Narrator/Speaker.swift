struct SpeechSettings: Sendable, Equatable {
    let voiceIdentifier: String?
    let rate: Float
}

protocol Speaker: Sendable {
    func speak(_ phrase: String, settings: SpeechSettings) async
    func cancel()
}
