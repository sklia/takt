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
            Section {
                Toggle("Narrator", isOn: $settings.narratorEnabled)
            }
            Section("Announcement") {
                Toggle("Artist", isOn: $settings.announceArtist)
                Toggle("Title", isOn: $settings.announceTitle)
                Toggle("Album", isOn: $settings.announceAlbum)
            }
            Section("Delay") {
                HStack {
                    Text("None")
                        .foregroundStyle(.secondary)
                    Slider(value: $settings.announcementDelay, in: 0...5, step: 0.5)
                    Text("5s")
                        .foregroundStyle(.secondary)
                }
                Text("Wait \(formattedDelay) before speaking")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            Section("Speech") {
                HStack {
                    Text("Slow")
                        .foregroundStyle(.secondary)
                    Slider(value: $settings.speechRate, in: 0.45...0.6)
                    Text("Fast")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Volume ducking") {
                HStack {
                    Text("0%")
                        .foregroundStyle(.secondary)
                    Slider(value: $settings.duckingLevel, in: 0...1)
                    Text("100%")
                        .foregroundStyle(.secondary)
                }
                Text("Spotify plays at \(Int((settings.duckingLevel * 100).rounded()))% while speaking")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }

    private var formattedDelay: String {
        if settings.announcementDelay == 0 {
            return "0s"
        }
        if settings.announcementDelay.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(settings.announcementDelay))s"
        }
        return String(format: "%.1fs", settings.announcementDelay)
    }
}

struct DisplayTab: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section("Overlay") {
                Toggle("Show track overlay on song change", isOn: $settings.showHUD)
                Picker("Style", selection: $settings.hudStyle) {
                    ForEach(HUDStyle.allCases, id: \.self) { style in
                        Text(style.label).tag(style)
                    }
                }
                Picker("Position", selection: $settings.hudPosition) {
                    ForEach(HUDPosition.allCases, id: \.self) { position in
                        Text(position.label).tag(position)
                    }
                }
            }
            Section("Duration") {
                HStack {
                    Text("2s")
                        .foregroundStyle(.secondary)
                    Slider(value: $settings.hudDismissDelay, in: 2...10, step: 0.5)
                    Text("10s")
                        .foregroundStyle(.secondary)
                }
                Text("Overlay stays for \(formattedDuration)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Screen") {
                Toggle("Follow focused screen", isOn: $settings.hudFollowsFocusedScreen)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }

    private var formattedDuration: String {
        if settings.hudDismissDelay.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(settings.hudDismissDelay))s"
        }
        return String(format: "%.1fs", settings.hudDismissDelay)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spotify automation permission denied", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("Takt can't lower Spotify's volume during announcements until you grant automation permission.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open System Settings") {
                if let url = SystemSettingsURL.automation {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
