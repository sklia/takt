import XCTest
@testable import Takt

@MainActor
final class SpotifyEventParserTests: XCTestCase {
    private static let fullUserInfo: [AnyHashable: Any] = [
        "Name": "Get Lucky",
        "Artist": "Daft Punk",
        "Album": "Random Access Memories",
        "Track ID": "spotify:track:69kOkLUCkxIZYexIgSG8rq"
    ]

    func test_parse_fullUserInfo_returnsEvent() {
        XCTAssertEqual(
            SpotifyEventParser.parse(Self.fullUserInfo),
            PlaybackEvent(
                artist: "Daft Punk",
                title: "Get Lucky",
                uri: "spotify:track:69kOkLUCkxIZYexIgSG8rq"
            )
        )
    }

    func test_parse_missingName_returnsNil() {
        var userInfo = Self.fullUserInfo
        userInfo.removeValue(forKey: "Name")
        XCTAssertNil(SpotifyEventParser.parse(userInfo))
    }

    func test_parse_missingArtist_returnsNil() {
        var userInfo = Self.fullUserInfo
        userInfo.removeValue(forKey: "Artist")
        XCTAssertNil(SpotifyEventParser.parse(userInfo))
    }

    func test_parse_missingTrackID_returnsNil() {
        var userInfo = Self.fullUserInfo
        userInfo.removeValue(forKey: "Track ID")
        XCTAssertNil(SpotifyEventParser.parse(userInfo))
    }

    func test_parse_emptyDict_returnsNil() {
        XCTAssertNil(SpotifyEventParser.parse([:]))
    }

    func test_parse_wrongTypedValues_returnsNil() {
        let userInfo: [AnyHashable: Any] = [
            "Name": 42,
            "Artist": ["Daft", "Punk"],
            "Track ID": NSNull()
        ]
        XCTAssertNil(SpotifyEventParser.parse(userInfo))
    }
}
