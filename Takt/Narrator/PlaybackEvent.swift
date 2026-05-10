struct PlaybackEvent: Equatable, Sendable {
    let artist: String
    let title: String
    var album: String?
    let uri: String
}
