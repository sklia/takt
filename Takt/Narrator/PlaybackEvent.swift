struct PlaybackEvent: Equatable, Sendable {
    let artist: String
    let title: String
    let album: String?
    let uri: String

    init(artist: String, title: String, album: String? = nil, uri: String) {
        self.artist = artist
        self.title = title
        self.album = album
        self.uri = uri
    }
}
