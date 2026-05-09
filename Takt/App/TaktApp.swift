import AppKit
import SwiftUI

@main
struct TaktApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsRoot()
        }
    }
}

private struct SettingsRoot: View {
    var body: some View {
        if let delegate = NSApp.delegate as? AppDelegate,
           let permission = delegate.permissionStore {
            SettingsView(permission: permission)
        } else {
            Text("Loading…")
                .frame(width: 320, height: 200)
        }
    }
}
