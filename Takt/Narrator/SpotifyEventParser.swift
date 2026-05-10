enum SpotifyEventParser {
    static func parse(_ userInfo: [AnyHashable: Any]) -> PlaybackEvent? {
        guard let title = userInfo["Name"] as? String,
              let artist = userInfo["Artist"] as? String,
              let uri = userInfo["Track ID"] as? String
        else { return nil }
        let album = userInfo["Album"] as? String
        return PlaybackEvent(artist: artist, title: title, album: album, uri: uri)
    }
}
