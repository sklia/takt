import AppKit
import Observation
import Sparkle

@MainActor
final class MenuBarController {
    private static let automationSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
    )

    private let statusItem: NSStatusItem
    private let settings: SettingsStore
    private let permission: PermissionStateStore
    private let updater: SPUUpdater
    private let openSettingsAction: () -> Void

    init(
        settings: SettingsStore,
        permission: PermissionStateStore,
        updater: SPUUpdater,
        openSettings: @escaping () -> Void
    ) {
        self.settings = settings
        self.permission = permission
        self.updater = updater
        self.openSettingsAction = openSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configureButton()
        applyIcon()
        observeState()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick)
    }

    @objc private func handleClick() {
        showMenu()
    }

    private func showMenu() {
        let menu = NSMenu()

        if permission.state == .denied {
            let denied = NSMenuItem(title: "Permission denied", action: nil, keyEquivalent: "")
            denied.isEnabled = false
            menu.addItem(denied)
            menu.addItem(.separator())
            let openItem = NSMenuItem(
                title: "Open System Settings…",
                action: #selector(openAutomationSettings),
                keyEquivalent: ""
            )
            openItem.target = self
            menu.addItem(openItem)
        } else {
            let toggle = NSMenuItem(title: "Narrator", action: #selector(toggleNarrator), keyEquivalent: "")
            toggle.target = self
            toggle.state = settings.narratorEnabled ? .on : .off
            menu.addItem(toggle)
            menu.addItem(.separator())
            let settingsItem = NSMenuItem(
                title: "Settings…",
                action: #selector(openSettingsWindow),
                keyEquivalent: ","
            )
            settingsItem.target = self
            menu.addItem(settingsItem)
        }

        menu.addItem(.separator())
        let updateItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Takt",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleNarrator() {
        settings.narratorEnabled.toggle()
    }

    @objc private func openSettingsWindow() {
        openSettingsAction()
    }

    @objc private func checkForUpdates() {
        updater.checkForUpdates()
    }

    @objc private func openAutomationSettings() {
        if let url = Self.automationSettingsURL {
            NSWorkspace.shared.open(url)
        }
    }

    private func applyIcon() {
        guard let button = statusItem.button else { return }
        let symbol: String
        if permission.state == .denied {
            symbol = "exclamationmark.triangle"
        } else {
            symbol = settings.narratorEnabled ? "music.note.list" : "music.note"
        }
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Takt")
            ?? NSImage(systemSymbolName: "music.note", accessibilityDescription: "Takt")
        image?.isTemplate = true
        button.image = image
        button.title = image == nil ? "Takt" : ""
    }

    private func observeState() {
        withObservationTracking {
            _ = settings.narratorEnabled
            _ = permission.state
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyIcon()
                self.observeState()
            }
        }
    }
}
