import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
    private let settings: SettingsStore
    private let permission: PermissionStateStore
    private let loginItem: LoginItemController
    private let voiceCatalog: VoiceCatalog
    private let preview: (SpeechSettings) -> Void
    private var window: NSWindow?

    init(
        settings: SettingsStore,
        permission: PermissionStateStore,
        loginItem: LoginItemController,
        voiceCatalog: VoiceCatalog,
        preview: @escaping (SpeechSettings) -> Void
    ) {
        self.settings = settings
        self.permission = permission
        self.loginItem = loginItem
        self.voiceCatalog = voiceCatalog
        self.preview = preview
    }

    func show() {
        if let window {
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
            return
        }
        let view = SettingsView(
            settings: settings,
            permission: permission,
            loginItem: loginItem,
            voiceCatalog: voiceCatalog,
            preview: preview
        )
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Takt Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
