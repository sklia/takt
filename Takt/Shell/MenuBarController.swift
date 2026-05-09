import AppKit
import Observation

@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let settings: SettingsStore

    init(settings: SettingsStore) {
        self.settings = settings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureButton()
        applyIcon()
        observeSettings()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            settings.narratorEnabled.toggle()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Narrator", action: #selector(toggleNarrator), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = settings.narratorEnabled ? .on : .off
        menu.addItem(toggleItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: nil, keyEquivalent: ","))
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

    private func applyIcon() {
        guard let button = statusItem.button else { return }
        let symbol = settings.narratorEnabled ? "music.note.list" : "music.note"
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Takt")
    }

    private func observeSettings() {
        withObservationTracking {
            _ = settings.narratorEnabled
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyIcon()
                self.observeSettings()
            }
        }
    }
}
