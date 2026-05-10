enum HUDStyle: String, CaseIterable, Sendable {
    case standard
    case compact

    var label: String {
        switch self {
        case .standard: "Standard"
        case .compact: "Compact"
        }
    }
}
