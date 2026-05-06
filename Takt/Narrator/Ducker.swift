protocol Ducker: Sendable {
    func duck(to level: Float) throws
    func restore() throws
}
