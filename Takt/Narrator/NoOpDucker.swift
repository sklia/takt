struct NoOpDucker: Ducker {
    func duck(to level: Float) throws {}
    func restore() throws {}
}
