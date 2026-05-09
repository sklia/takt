import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleNarrator = Self("toggleNarrator")
}

@MainActor
final class GlobalHotkey {
    init(toggle: @escaping () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .toggleNarrator, action: toggle)
    }
}
