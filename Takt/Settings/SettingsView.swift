import AppKit
import KeyboardShortcuts
import SwiftUI

struct NarratorTab: View {
    @Bindable var settings: SettingsStore
    @Bindable var permission: PermissionStateStore
    let voiceCatalog: VoiceCatalog
    let preview: (SpeechSettings) -> Void

    var body: some View {
        Form {
            if permission.state == .denied {
                Section {
                    PermissionBanner()
                }
            }
            Section("Voice") {
                VoicePicker(settings: settings, voiceCatalog: voiceCatalog)
                Toggle("Show all voices", isOn: $settings.showAllVoicesInPicker)
                HStack {
                    Spacer()
                    Button("Preview") {
                        preview(SpeechSettings(
                            voiceIdentifier: settings.selectedVoiceID,
                            rate: settings.speechRate
                        ))
                    }
                }
            }
            Section("Speech rate") {
                HStack {
                    Text("Slow")
                        .foregroundStyle(.secondary)
                    Slider(value: $settings.speechRate, in: 0.45...0.6)
                    Text("Fast")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Spotify volume while narrator speaks") {
                HStack {
                    Text("0%")
                        .foregroundStyle(.secondary)
                    Slider(value: $settings.duckingLevel, in: 0...1)
                    Text("100%")
                        .foregroundStyle(.secondary)
                }
                Text("Currently \(Int((settings.duckingLevel * 100).rounded()))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}

struct GeneralTab: View {
    @Bindable var settings: SettingsStore
    @Bindable var loginItem: LoginItemController

    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Toggle narrator", name: .toggleNarrator)
            }
            Section("Focus") {
                Toggle("Pause narration during Focus modes", isOn: $settings.pauseDuringFocus)
            }
            Section("Startup") {
                Toggle("Start Takt automatically when you log in", isOn: $loginItem.isEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}

private struct VoicePicker: View {
    @Bindable var settings: SettingsStore
    let voiceCatalog: VoiceCatalog

    var body: some View {
        Picker("Voice", selection: $settings.selectedVoiceID) {
            Text("System default").tag(String?.none)
            ForEach(displayGroups, id: \.label) { group in
                Section(group.label) {
                    ForEach(group.voices, id: \.identifier) { voice in
                        Text(voice.name).tag(String?.some(voice.identifier))
                    }
                }
            }
        }
    }

    private var displayGroups: [(label: String, voices: [VoiceInfo])] {
        let allGroups = voiceCatalog.voices(showAll: settings.showAllVoicesInPicker, locale: Locale.current)
        let recommended = allGroups
            .filter { [.siri, .premium, .enhanced].contains($0.tier) }
            .flatMap(\.voices)
        let other = allGroups
            .filter { $0.tier == .standard }
            .flatMap(\.voices)
        let novelty = allGroups
            .filter { $0.tier == .novelty }
            .flatMap(\.voices)
        var result: [(String, [VoiceInfo])] = []
        if !recommended.isEmpty {
            result.append(("Recommended (Siri / Premium)", recommended))
        }
        if !other.isEmpty {
            result.append(("Other", other))
        }
        if !novelty.isEmpty {
            result.append(("Novelty", novelty))
        }
        return result
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openAutomationSettings() {
        if let url = Self.automationSettingsURL {
            NSWorkspace.shared.open(url)
        }
    }
}
