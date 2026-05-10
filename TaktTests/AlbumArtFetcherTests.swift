import XCTest
@testable import Takt

final class AlbumArtFetcherTests: XCTestCase {
    func test_oEmbedURL_validURI_returnsURL() {
        let url = AlbumArtFetcher.oEmbedURL(for: "spotify:track:69kOkLUCkxIZYexIgSG8rq")
        XCTAssertEqual(
            url?.absoluteString,
            "https://open.spotify.com/oembed?url=spotify:track:69kOkLUCkxIZYexIgSG8rq"
        )
    }

    func test_oEmbedURL_encodesSpecialCharacters() {
        let url = AlbumArtFetcher.oEmbedURL(for: "spotify:track:abc def")
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("abc%20def"))
    }
}
