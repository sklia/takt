struct PlaybackEvent: Equatable, Sendable {
    let artist: String
    let title: String
    var album: String? = nil
    let uri: String
}
