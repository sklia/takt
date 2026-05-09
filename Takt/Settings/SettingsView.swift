import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var permission: PermissionStateStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if permission.state == .denied {
                PermissionBanner()
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 480, height: 320)
    }
}

private struct PermissionBanner: View {
    private static let automationSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spotify automation permission denied", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Takt can't lower Spotify's volume during announcements until you grant automation permission.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open System Settings", action: openAutomationSettings)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openAutomationSettings() {
        if let url = Self.automationSettingsURL {
            NSWorkspace.shared.open(url)
        }
    }
}
