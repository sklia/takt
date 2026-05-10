import AppKit

actor AlbumArtFetcher {
    private let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 50
        return cache
    }()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(uri: String) async -> NSImage? {
        let key = uri as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let thumbnailURL = await fetchThumbnailURL(uri: uri) else { return nil }
        guard let (data, _) = try? await session.data(from: thumbnailURL),
              let image = NSImage(data: data)
        else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    static func oEmbedURL(for uri: String) -> URL? {
        var components = URLComponents(string: "https://open.spotify.com/oembed")
        components?.queryItems = [URLQueryItem(name: "url", value: uri)]
        return components?.url
    }

    private func fetchThumbnailURL(uri: String) async -> URL? {
        guard let url = Self.oEmbedURL(for: uri) else { return nil }
        guard let (data, _) = try? await session.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let thumbnailString = json["thumbnail_url"] as? String,
              let thumbnailURL = URL(string: thumbnailString)
        else { return nil }
        return thumbnailURL
    }
}
