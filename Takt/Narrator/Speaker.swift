protocol Speaker: Sendable {
    func speak(_ phrase: String) async
    func cancel()
}
