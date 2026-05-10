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

        let tabVC = NSTabViewController()
        tabVC.tabStyle = .toolbar

        let narratorHost = NSHostingController(rootView: NarratorTab(
            settings: settings,
            permission: permission,
            voiceCatalog: voiceCatalog,
            preview: preview
        ))
        narratorHost.title = "Takt Settings"
        narratorHost.sizingOptions = .preferredContentSize
        let narratorItem = NSTabViewItem(viewController: narratorHost)
        narratorItem.label = "Narrator"
        narratorItem.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)
        tabVC.addTabViewItem(narratorItem)

        let displayHost = NSHostingController(rootView: DisplayTab(settings: settings))
        displayHost.title = "Takt Settings"
        displayHost.sizingOptions = .preferredContentSize
        let displayItem = NSTabViewItem(viewController: displayHost)
        displayItem.label = "Display"
        displayItem.image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: nil)
        tabVC.addTabViewItem(displayItem)

        let generalHost = NSHostingController(rootView: GeneralTab(
            settings: settings,
            loginItem: loginItem
        ))
        generalHost.title = "Takt Settings"
        generalHost.sizingOptions = .preferredContentSize
        let generalItem = NSTabViewItem(viewController: generalHost)
        generalItem.label = "General"
        generalItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        tabVC.addTabViewItem(generalItem)

        let window = NSWindow(contentViewController: tabVC)
        window.title = "Takt Settings"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
