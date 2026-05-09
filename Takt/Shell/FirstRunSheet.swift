import AppKit
import SwiftUI

@MainActor
final class FirstRunSheet {
    private let settings: SettingsStore
    private var window: NSWindow?

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func presentIfNeeded() {
        guard !settings.hasShownWelcomeSheet else { return }
        present()
    }

    private func present() {
        let view = WelcomeView { [weak self] in
            self?.dismiss()
        }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to Takt"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .floating

        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func dismiss() {
        settings.hasShownWelcomeSheet = true
        window?.close()
        window = nil
    }
}

private struct WelcomeView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Takt")
                .font(.title2)
                .bold()
            Text("Takt narrates Spotify track changes. The first time you turn on the narrator, macOS will ask for permission to control Spotify's volume.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Got it", action: onDismiss)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
        }
        .padding(28)
        .frame(width: 420)
    }
}
