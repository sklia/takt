import SwiftUI

@main
struct TaktApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            if let settings = appDelegate.settings,
               let permission = appDelegate.permissionStore,
               let loginItem = appDelegate.loginItem,
               let voiceCatalog = appDelegate.voiceCatalog {
                SettingsView(
                    settings: settings,
                    permission: permission,
                    loginItem: loginItem,
                    voiceCatalog: voiceCatalog,
                    preview: { [weak appDelegate] speech in
                        appDelegate?.previewVoice(speech)
                    }
                )
            }
        }
    }
}
