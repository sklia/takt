protocol MusicSource {
    func start(handler: @escaping (PlaybackEvent) -> Void)
    func stop()
}
