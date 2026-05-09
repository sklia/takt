import Foundation

final class PlaybackObserver {
    static let notificationName = Notification.Name("com.spotify.client.PlaybackStateChanged")

    private let center: DistributedNotificationCenter
    private var token: NSObjectProtocol?

    init(center: DistributedNotificationCenter = .default()) {
        self.center = center
    }

    deinit {
        stop()
    }

    func start(handler: @escaping (PlaybackEvent) -> Void) {
        stop()
        token = center.addObserver(
            forName: Self.notificationName,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let event = SpotifyEventParser.parse(userInfo)
            else { return }
            handler(event)
        }
    }

    func stop() {
        if let token {
            center.removeObserver(token)
            self.token = nil
        }
    }
}
