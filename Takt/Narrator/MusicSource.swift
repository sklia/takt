@MainActor
protocol MusicSource {
    func start(handler: @escaping @Sendable (PlaybackEvent) -> Void)
    func stop()
}
