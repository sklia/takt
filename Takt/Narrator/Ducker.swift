@MainActor
protocol Ducker {
    func duck(to level: Float) throws
    func restore() throws
}
